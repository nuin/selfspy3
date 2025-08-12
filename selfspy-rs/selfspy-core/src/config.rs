use directories::ProjectDirs;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use anyhow::Result;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub data_dir: PathBuf,
    pub database_path: PathBuf,
    pub encryption_enabled: bool,
    pub exclude_apps: Vec<String>,
    pub idle_timeout_seconds: u64,
    pub flush_interval_seconds: u64,
}

impl Default for Config {
    fn default() -> Self {
        let project_dirs = ProjectDirs::from("com", "selfspy", "selfspy")
            .expect("Failed to determine project directories");
        
        let data_dir = project_dirs.data_dir().to_path_buf();
        let database_path = data_dir.join("selfspy.db");
        
        Self {
            data_dir,
            database_path,
            encryption_enabled: true,
            exclude_apps: vec![
                "1Password".to_string(),
                "Bitwarden".to_string(),
                "KeePass".to_string(),
            ],
            idle_timeout_seconds: 180,
            flush_interval_seconds: 10,
        }
    }
}

impl Config {
    pub fn new() -> Self {
        Self::default()
    }
    
    pub fn with_data_dir(mut self, dir: PathBuf) -> Self {
        self.data_dir = dir.clone();
        self.database_path = dir.join("selfspy.db");
        self
    }
    
    pub fn ensure_directories(&self) -> Result<()> {
        std::fs::create_dir_all(&self.data_dir)?;
        Ok(())
    }
}