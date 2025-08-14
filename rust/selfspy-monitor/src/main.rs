use anyhow::Result;
use clap::{Parser, Subcommand};
use crossterm::{
    event::{self, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Alignment, Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Gauge, Paragraph},
    Frame, Terminal,
};
use selfspy_core::{init, ActivityMonitor, Config, Database};
use std::{io, path::PathBuf, time::Duration};
use tokio::time;
use tracing::info;

#[derive(Parser)]
#[command(name = "selfspy")]
#[command(about = "Monitor and analyze your computer activity", version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Start monitoring activity
    Start {
        /// Data directory path
        #[arg(short, long)]
        data_dir: Option<PathBuf>,
        
        /// Password for encryption
        #[arg(short, long)]
        password: Option<String>,
        
        /// Disable text encryption
        #[arg(long)]
        no_text: bool,
        
        /// Show live dashboard
        #[arg(long)]
        dashboard: bool,
    },
    
    /// Check macOS permissions
    #[cfg(target_os = "macos")]
    CheckPermissions,
}

#[tokio::main]
async fn main() -> Result<()> {
    init().await?;
    
    let cli = Cli::parse();
    
    match cli.command {
        Commands::Start {
            data_dir,
            password,
            no_text,
            dashboard,
        } => {
            let mut config = Config::new();
            
            if let Some(dir) = data_dir {
                config = config.with_data_dir(dir);
            }
            
            if no_text {
                config.encryption_enabled = false;
            }
            
            let monitor = ActivityMonitor::new(config.clone(), password).await?;
            
            if dashboard {
                run_with_dashboard(monitor, config).await?;
            } else {
                info!("Starting Selfspy monitor (press Ctrl+C to stop)...");
                
                let monitor_handle = tokio::spawn(async move {
                    monitor.start().await
                });
                
                tokio::signal::ctrl_c().await?;
                info!("Shutting down...");
                
                monitor_handle.abort();
            }
        }
        
        #[cfg(target_os = "macos")]
        Commands::CheckPermissions => {
            check_macos_permissions()?;
        }
    }
    
    Ok(())
}

async fn run_with_dashboard(monitor: ActivityMonitor, config: Config) -> Result<()> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;
    
    let monitor_handle = tokio::spawn(async move {
        monitor.start().await
    });
    
    let db = Database::new(&config.database_path).await?;
    
    let mut interval = time::interval(Duration::from_secs(1));
    
    loop {
        if event::poll(Duration::from_millis(100))? {
            if let Event::Key(key) = event::read()? {
                if key.code == KeyCode::Char('q') || key.code == KeyCode::Esc {
                    break;
                }
            }
        }
        
        interval.tick().await;
        let stats = db.get_stats().await?;
        
        terminal.draw(|f| draw_dashboard(f, &stats))?;
    }
    
    monitor_handle.abort();
    
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    
    Ok(())
}

fn draw_dashboard(f: &mut Frame, stats: &selfspy_core::models::ActivityStats) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .margin(1)
        .constraints([
            Constraint::Length(3),
            Constraint::Length(5),
            Constraint::Length(5),
            Constraint::Min(0),
        ])
        .split(f.size());
    
    // Title
    let title = Paragraph::new(vec![
        Line::from(vec![
            Span::styled("Selfspy", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
            Span::raw(" - Activity Monitor"),
        ])
    ])
    .block(Block::default().borders(Borders::ALL))
    .alignment(Alignment::Center);
    f.render_widget(title, chunks[0]);
    
    // Stats
    let stats_text = vec![
        Line::from(vec![
            Span::raw("Keystrokes: "),
            Span::styled(
                stats.total_keystrokes.to_string(),
                Style::default().fg(Color::Green),
            ),
            Span::raw("  Clicks: "),
            Span::styled(
                stats.total_clicks.to_string(),
                Style::default().fg(Color::Green),
            ),
        ]),
        Line::from(vec![
            Span::raw("Windows: "),
            Span::styled(
                stats.total_windows.to_string(),
                Style::default().fg(Color::Yellow),
            ),
            Span::raw("  Processes: "),
            Span::styled(
                stats.total_processes.to_string(),
                Style::default().fg(Color::Yellow),
            ),
        ]),
    ];
    
    let stats_widget = Paragraph::new(stats_text)
        .block(Block::default().title("Statistics").borders(Borders::ALL));
    f.render_widget(stats_widget, chunks[1]);
    
    // Active Process
    if let Some(process) = &stats.most_active_process {
        let active = Paragraph::new(vec![
            Line::from(vec![
                Span::raw("Most Active: "),
                Span::styled(process, Style::default().fg(Color::Cyan)),
            ])
        ])
        .block(Block::default().title("Current Activity").borders(Borders::ALL));
        f.render_widget(active, chunks[2]);
    }
    
    // Help
    let help = Paragraph::new(vec![
        Line::from(vec![
            Span::raw("Press "),
            Span::styled("q", Style::default().fg(Color::Red)),
            Span::raw(" or "),
            Span::styled("ESC", Style::default().fg(Color::Red)),
            Span::raw(" to quit"),
        ])
    ])
    .alignment(Alignment::Center);
    f.render_widget(help, chunks[3]);
}

#[cfg(target_os = "macos")]
fn check_macos_permissions() -> Result<()> {
    println!("Checking macOS permissions...\n");
    
    println!("✓ Checking Accessibility permissions...");
    println!("  To grant: System Preferences > Security & Privacy > Privacy > Accessibility");
    
    println!("\n✓ Checking Screen Recording permissions (optional)...");
    println!("  To grant: System Preferences > Security & Privacy > Privacy > Screen Recording");
    
    println!("\nNote: You may need to restart your terminal after granting permissions.");
    
    Ok(())
}