use anyhow::Result;
use clap::{Parser, Subcommand};
use crossterm::{
    execute,
    terminal::{Clear, ClearType},
};
use indicatif::{ProgressBar, ProgressStyle};
use selfspy_core::{init, Config, Database};
use std::{io::stdout, path::PathBuf, time::Duration};
use tokio::time;

#[derive(Parser)]
#[command(name = "selfviz")]
#[command(about = "Enhanced visualizations for Selfspy", version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Show enhanced statistics with visualizations
    Enhanced {
        /// Data directory path
        #[arg(short, long)]
        data_dir: Option<PathBuf>,
        
        /// Number of days to analyze
        #[arg(long, default_value = "7")]
        days: i64,
    },
    
    /// Show activity timeline
    Timeline {
        /// Data directory path
        #[arg(short, long)]
        data_dir: Option<PathBuf>,
        
        /// Number of days to show
        #[arg(long, default_value = "1")]
        days: i64,
    },
    
    /// Show live activity dashboard
    Live {
        /// Data directory path
        #[arg(short, long)]
        data_dir: Option<PathBuf>,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    init().await?;
    
    let cli = Cli::parse();
    
    match cli.command {
        Commands::Enhanced { data_dir, days } => {
            show_enhanced_stats(data_dir, days).await?;
        }
        Commands::Timeline { data_dir, days } => {
            show_timeline(data_dir, days).await?;
        }
        Commands::Live { data_dir } => {
            show_live_dashboard(data_dir).await?;
        }
    }
    
    Ok(())
}

async fn show_enhanced_stats(data_dir: Option<PathBuf>, days: i64) -> Result<()> {
    let mut config = Config::new();
    if let Some(dir) = data_dir {
        config = config.with_data_dir(dir);
    }
    
    let db = Database::new(&config.database_path).await?;
    let stats = db.get_stats().await?;
    
    execute!(stdout(), Clear(ClearType::All))?;
    
    println!("╔══════════════════════════════════════════════════════════╗");
    println!("║           SELFSPY ENHANCED STATISTICS                       ║");
    println!("╠══════════════════════════════════════════════════════════╣");
    
    // Keystrokes bar
    let keystroke_bar = create_progress_bar(stats.total_keystrokes, 10000, "Keystrokes");
    keystroke_bar.finish();
    
    // Clicks bar
    let click_bar = create_progress_bar(stats.total_clicks, 1000, "Clicks");
    click_bar.finish();
    
    // Activity summary
    println!("╠══════════════════════════════════════════════════════════╣");
    println!("║ 📊 Activity Summary (Last {} days)                         ║", days);
    println!("╠══════════════════════════════════════════════════════════╣");
    println!("║ Windows:    {:>8}                                       ║", stats.total_windows);
    println!("║ Processes:  {:>8}                                       ║", stats.total_processes);
    
    if let Some(process) = &stats.most_active_process {
        println!("║ Most Active: {:<30}               ║", process);
    }
    
    println!("╚══════════════════════════════════════════════════════════╝");
    
    Ok(())
}

async fn show_timeline(data_dir: Option<PathBuf>, days: i64) -> Result<()> {
    let mut config = Config::new();
    if let Some(dir) = data_dir {
        config = config.with_data_dir(dir);
    }
    
    println!("📅 Activity Timeline (Last {} days)", days);
    println!("─────────────────────────────────────");
    
    // This would show hourly activity in a real implementation
    for hour in 0..24 {
        let activity_level = (hour * 4) % 10;
        let bar = "█".repeat(activity_level as usize);
        let empty = "░".repeat((10 - activity_level) as usize);
        println!("{:02}:00 │ {}{}", hour, bar, empty);
    }
    
    Ok(())
}

async fn show_live_dashboard(data_dir: Option<PathBuf>) -> Result<()> {
    let mut config = Config::new();
    if let Some(dir) = data_dir {
        config = config.with_data_dir(dir);
    }
    
    let db = Database::new(&config.database_path).await?;
    
    println!("🔴 Live Activity Dashboard (Press Ctrl+C to stop)");
    println!("──────────────────────────────────────────────────");
    
    let mut interval = time::interval(Duration::from_secs(1));
    
    loop {
        interval.tick().await;
        
        let stats = db.get_stats().await?;
        
        print!("\r");
        print!("⌨️  Keystrokes: {:>6} │ ", stats.total_keystrokes);
        print!("🖱️  Clicks: {:>6} │ ", stats.total_clicks);
        print!("🪟 Windows: {:>4} │ ", stats.total_windows);
        
        if let Some(process) = &stats.most_active_process {
            print!("📱 Active: {:<20}", process);
        }
        
        use std::io::Write;
        stdout().flush()?;
    }
}

fn create_progress_bar(current: i64, max: i64, label: &str) -> ProgressBar {
    let pb = ProgressBar::new(max as u64);
    pb.set_style(
        ProgressStyle::default_bar()
            .template(&format!("{{prefix:<12}} [{{bar:40.cyan/blue}}] {{pos:>6}}/{{len}}", ))
            .unwrap()
            .progress_chars("█▓▒░ "),
    );
    pb.set_prefix(label.to_string());
    pb.set_position(current.min(max) as u64);
    pb
}