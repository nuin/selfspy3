pub mod config;
pub mod db;
pub mod encryption;
pub mod models;
pub mod monitor;
pub mod platform;

pub use config::Config;
pub use db::Database;
pub use models::*;
pub use monitor::ActivityMonitor;

use anyhow::Result;

pub async fn init() -> Result<()> {
    // Simple tracing setup - can be enhanced later
    tracing::subscriber::set_global_default(
        tracing_subscriber::FmtSubscriber::new()
    )?;
    Ok(())
}