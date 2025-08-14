use eframe::egui;
use std::sync::Arc;
use tokio::sync::RwLock;
use selfspy_core::{ActivityMonitor, Config, Database};
use crate::{dashboard::Dashboard, settings::Settings, statistics::Statistics, charts::Charts};

#[derive(PartialEq)]
pub enum AppTab {
    Dashboard,
    Statistics,
    Charts,
    Settings,
}

pub struct SelfspyApp {
    // Core components
    pub config: Config,
    pub database: Option<Arc<Database>>,
    pub monitor: Option<Arc<ActivityMonitor>>,
    pub monitoring_active: Arc<RwLock<bool>>,
    
    // UI state
    pub current_tab: AppTab,
    pub dashboard: Dashboard,
    pub statistics: Statistics,
    pub charts: Charts,
    pub settings: Settings,
    
    // UI state
    pub status_message: String,
    pub last_update: std::time::Instant,
}

impl SelfspyApp {
    pub fn new(_cc: &eframe::CreationContext<'_>) -> Self {
        let config = Config::new();
        
        Self {
            config: config.clone(),
            database: None,
            monitor: None,
            monitoring_active: Arc::new(RwLock::new(false)),
            current_tab: AppTab::Dashboard,
            dashboard: Dashboard::new(),
            statistics: Statistics::new(),
            charts: Charts::new(),
            settings: Settings::new(config),
            status_message: "Ready".to_string(),
            last_update: std::time::Instant::now(),
        }
    }
    
    pub fn initialize_database(&mut self) {
        if self.database.is_none() {
            // For now, we'll just show that database initialization was requested
            // In a real implementation, this would be handled asynchronously
            self.status_message = "Database initialization requested".to_string();
        }
    }
    
    pub fn start_monitoring(&mut self) {
        if self.database.is_none() {
            self.initialize_database();
        }
        
        // For demo purposes, just simulate starting monitoring
        self.status_message = "Monitoring started (demo mode)".to_string();
    }
    
    pub fn stop_monitoring(&mut self) {
        self.status_message = "Monitoring stopped (demo mode)".to_string();
    }
    
    pub fn is_monitoring_active(&self) -> bool {
        // For demo purposes, just return false
        false
    }
}

impl eframe::App for SelfspyApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        // Update data periodically
        if self.last_update.elapsed().as_secs() >= 1 {
            self.refresh_data();
            self.last_update = std::time::Instant::now();
        }
        
        // Top panel with navigation
        egui::TopBottomPanel::top("top_panel").show(ctx, |ui| {
            ui.horizontal(|ui| {
                ui.heading("🔍 Selfspy");
                ui.separator();
                
                ui.selectable_value(&mut self.current_tab, AppTab::Dashboard, "📊 Dashboard");
                ui.selectable_value(&mut self.current_tab, AppTab::Statistics, "📈 Statistics");
                ui.selectable_value(&mut self.current_tab, AppTab::Charts, "📉 Charts");
                ui.selectable_value(&mut self.current_tab, AppTab::Settings, "⚙️ Settings");
                
                ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                    // Monitoring toggle
                    let monitoring = self.is_monitoring_active();
                    let button_text = if monitoring { "⏹ Stop" } else { "▶ Start" };
                    let button_color = if monitoring { 
                        egui::Color32::from_rgb(255, 100, 100) 
                    } else { 
                        egui::Color32::from_rgb(100, 255, 100) 
                    };
                    
                    if ui.add(egui::Button::new(button_text).fill(button_color)).clicked() {
                        if monitoring {
                            self.stop_monitoring();
                        } else {
                            self.start_monitoring();
                        }
                    }
                });
            });
        });
        
        // Bottom panel with status
        egui::TopBottomPanel::bottom("bottom_panel").show(ctx, |ui| {
            ui.horizontal(|ui| {
                ui.label("Status:");
                ui.colored_label(
                    if self.is_monitoring_active() { 
                        egui::Color32::from_rgb(100, 255, 100) 
                    } else { 
                        egui::Color32::from_rgb(255, 200, 100) 
                    },
                    &self.status_message
                );
                
                ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                    ui.label(format!("Selfspy GUI v{}", env!("CARGO_PKG_VERSION")));
                });
            });
        });
        
        // Main content area
        egui::CentralPanel::default().show(ctx, |ui| {
            let monitoring = self.is_monitoring_active();
            let database_connected = self.database.is_some();
            
            match self.current_tab {
                AppTab::Dashboard => {
                    self.dashboard.show(ui, monitoring, database_connected);
                },
                AppTab::Statistics => {
                    self.statistics.show(ui, database_connected);
                },
                AppTab::Charts => {
                    self.charts.show(ui, database_connected);
                },
                AppTab::Settings => {
                    let config = self.config.clone();
                    self.settings.show(ui, config, database_connected);
                },
            }
        });
        
        // Request repaint for live updates
        ctx.request_repaint_after(std::time::Duration::from_secs(1));
    }
}

impl SelfspyApp {
    fn refresh_data(&mut self) {
        // For demo purposes, just update the last refresh time
        self.last_update = std::time::Instant::now();
    }
}