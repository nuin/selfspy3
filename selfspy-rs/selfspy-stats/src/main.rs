use anyhow::Result;
use chrono::{DateTime, Duration, Utc};
use clap::{Parser, ValueEnum};
use comfy_table::{modifiers::UTF8_ROUND_CORNERS, presets::UTF8_FULL, Table};
use selfspy_core::{init, Config, Database};
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "selfstats")]
#[command(about = "View activity statistics from Selfspy", version)]
struct Cli {
    /// Data directory path
    #[arg(short, long)]
    data_dir: Option<PathBuf>,
    
    /// Start date (YYYY-MM-DD)
    #[arg(short, long)]
    start: Option<String>,
    
    /// End date (YYYY-MM-DD)
    #[arg(short, long)]
    end: Option<String>,
    
    /// Output format
    #[arg(short, long, value_enum, default_value = "table")]
    format: OutputFormat,
    
    /// Number of days to show (overrides start/end)
    #[arg(long)]
    days: Option<i64>,
}

#[derive(Debug, Clone, ValueEnum)]
enum OutputFormat {
    Table,
    Json,
    Csv,
}

#[tokio::main]
async fn main() -> Result<()> {
    init().await?;
    
    let cli = Cli::parse();
    
    let mut config = Config::new();
    if let Some(dir) = cli.data_dir {
        config = config.with_data_dir(dir);
    }
    
    let db = Database::new(&config.database_path).await?;
    let stats = db.get_stats().await?;
    
    match cli.format {
        OutputFormat::Table => print_table_stats(&stats),
        OutputFormat::Json => print_json_stats(&stats)?,
        OutputFormat::Csv => print_csv_stats(&stats),
    }
    
    Ok(())
}

fn print_table_stats(stats: &selfspy_core::models::ActivityStats) {
    let mut table = Table::new();
    table
        .load_preset(UTF8_FULL)
        .apply_modifier(UTF8_ROUND_CORNERS)
        .set_header(vec!["Metric", "Value"]);
    
    table.add_row(vec!["Total Keystrokes", &stats.total_keystrokes.to_string()]);
    table.add_row(vec!["Total Clicks", &stats.total_clicks.to_string()]);
    table.add_row(vec!["Total Windows", &stats.total_windows.to_string()]);
    table.add_row(vec!["Total Processes", &stats.total_processes.to_string()]);
    
    if let Some(process) = &stats.most_active_process {
        table.add_row(vec!["Most Active Process", process]);
    }
    
    println!("\n{table}\n");
}

fn print_json_stats(stats: &selfspy_core::models::ActivityStats) -> Result<()> {
    let json = serde_json::to_string_pretty(stats)?;
    println!("{}", json);
    Ok(())
}

fn print_csv_stats(stats: &selfspy_core::models::ActivityStats) {
    println!("metric,value");
    println!("total_keystrokes,{}", stats.total_keystrokes);
    println!("total_clicks,{}", stats.total_clicks);
    println!("total_windows,{}", stats.total_windows);
    println!("total_processes,{}", stats.total_processes);
    
    if let Some(process) = &stats.most_active_process {
        println!("most_active_process,{}", process);
    }
}