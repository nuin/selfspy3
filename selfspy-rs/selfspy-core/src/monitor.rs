use anyhow::Result;
use chrono::Utc;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::RwLock;
use tokio::time;
use tracing::{info, debug, error};

use crate::{Config, Database};
use crate::encryption::Encryptor;
use crate::platform::{create_tracker, PlatformTracker, WindowInfo, InputEvent, MouseButton};

pub struct ActivityMonitor {
    config: Config,
    db: Arc<Database>,
    tracker: Box<dyn PlatformTracker>,
    encryptor: Option<Encryptor>,
    current_window: Arc<RwLock<Option<(i64, WindowInfo)>>>,
    keystroke_buffer: Arc<RwLock<String>>,
    running: Arc<RwLock<bool>>,
}

impl ActivityMonitor {
    pub async fn new(config: Config, password: Option<String>) -> Result<Self> {
        config.ensure_directories()?;
        
        let db = Arc::new(Database::new(&config.database_path).await?);
        let tracker = create_tracker();
        
        let encryptor = if config.encryption_enabled {
            password.map(|p| Encryptor::new(&p).ok()).flatten()
        } else {
            None
        };
        
        Ok(Self {
            config,
            db,
            tracker,
            encryptor,
            current_window: Arc::new(RwLock::new(None)),
            keystroke_buffer: Arc::new(RwLock::new(String::new())),
            running: Arc::new(RwLock::new(false)),
        })
    }
    
    pub async fn start(&self) -> Result<()> {
        info!("Starting activity monitor");
        
        *self.running.write().await = true;
        self.tracker.start_input_tracking().await?;
        
        // Simple main loop for now
        let mut interval = time::interval(Duration::from_secs(1));
        
        while *self.running.read().await {
            interval.tick().await;
            
            // Track window changes
            if let Ok(window) = self.tracker.get_active_window().await {
                let mut current = self.current_window.write().await;
                
                let should_update = current.as_ref()
                    .map(|(_, w)| w.process_name != window.process_name || w.window_title != window.window_title)
                    .unwrap_or(true);
                
                if should_update && !self.config.exclude_apps.contains(&window.process_name) {
                    debug!("Window changed to: {} - {}", window.process_name, window.window_title);
                    
                    let process_id = self.db.insert_process(
                        &window.process_name,
                        window.bundle_id.as_deref()
                    ).await?;
                    
                    let window_id = self.db.insert_window(
                        process_id,
                        &window.window_title,
                        window.x,
                        window.y,
                        window.width,
                        window.height,
                    ).await?;
                    
                    *current = Some((window_id, window));
                }
            }
            
            // Process input events
            let events = self.tracker.get_input_events();
            for event in events {
                match event {
                    InputEvent::KeyPress { key } => {
                        let mut buffer = self.keystroke_buffer.write().await;
                        buffer.push_str(&key);
                    }
                    InputEvent::MouseClick { x, y, button } => {
                        if let Some((window_id, _)) = *self.current_window.read().await {
                            self.db.insert_click(window_id, x, y, button.as_str(), false).await?;
                        }
                    }
                    _ => {}
                }
            }
            
            // Flush keystrokes periodically
            if let Err(e) = self.flush_keystrokes().await {
                error!("Failed to flush keystrokes: {}", e);
            }
        }
        
        Ok(())
    }
    
    pub async fn stop(&self) -> Result<()> {
        info!("Stopping activity monitor");
        *self.running.write().await = false;
        self.tracker.stop_input_tracking().await?;
        self.flush_keystrokes().await?;
        Ok(())
    }
    
    async fn flush_keystrokes(&self) -> Result<()> {
        let mut buffer = self.keystroke_buffer.write().await;
        
        if buffer.is_empty() {
            return Ok(());
        }
        
        if let Some((window_id, _)) = *self.current_window.read().await {
            let key_data = if let Some(encryptor) = &self.encryptor {
                encryptor.encrypt(buffer.as_bytes())?
            } else {
                buffer.as_bytes().to_vec()
            };
            
            let key_count = buffer.len() as i32;
            self.db.insert_keys(window_id, key_data, key_count).await?;
            
            debug!("Flushed {} keystrokes", key_count);
            buffer.clear();
        }
        
        Ok(())
    }
}