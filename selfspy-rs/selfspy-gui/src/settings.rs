use eframe::egui;
use selfspy_core::Config;

pub struct Settings {
    config: Config,
    temp_config: Config,
    show_advanced: bool,
    password_field: String,
    confirm_password_field: String,
    excluded_apps_text: String,
}

impl Settings {
    pub fn new(config: Config) -> Self {
        let excluded_apps_text = config.exclude_apps.join("\n");
        
        Self {
            temp_config: config.clone(),
            config,
            show_advanced: false,
            password_field: String::new(),
            confirm_password_field: String::new(),
            excluded_apps_text,
        }
    }
    
    pub fn show(&mut self, ui: &mut egui::Ui, config: Config, database_connected: bool) {
        ui.heading("⚙️ Settings");
        ui.separator();
        
        egui::ScrollArea::vertical().show(ui, |ui| {
            // General Settings
            self.show_general_settings(ui);
            ui.add_space(20.0);
            
            // Privacy Settings
            self.show_privacy_settings(ui);
            ui.add_space(20.0);
            
            // Data Settings
            self.show_data_settings(ui, database_connected);
            ui.add_space(20.0);
            
            // Advanced Settings
            self.show_advanced_settings(ui);
            ui.add_space(20.0);
            
            // Action Buttons
            self.show_action_buttons(ui);
        });
    }
    
    fn show_general_settings(&mut self, ui: &mut egui::Ui) {
        ui.group(|ui| {
            ui.heading("🔧 General Settings");
            ui.separator();
            
            egui::Grid::new("general_settings")
                .num_columns(2)
                .spacing([40.0, 10.0])
                .show(ui, |ui| {
                    // Data Directory
                    ui.label("Data Directory:");
                    ui.horizontal(|ui| {
                        ui.text_edit_singleline(&mut self.temp_config.data_dir.to_string_lossy().to_mut().to_string());
                        if ui.button("📁 Browse").clicked() {
                            // File dialog would go here
                        }
                    });
                    ui.end_row();
                    
                    // Flush Interval
                    ui.label("Flush Interval (seconds):");
                    ui.add(egui::Slider::new(&mut self.temp_config.flush_interval_seconds, 1..=60));
                    ui.end_row();
                    
                    // Idle Timeout
                    ui.label("Idle Timeout (seconds):");
                    ui.add(egui::Slider::new(&mut self.temp_config.idle_timeout_seconds, 30..=3600));
                    ui.end_row();
                });
        });
    }
    
    fn show_privacy_settings(&mut self, ui: &mut egui::Ui) {
        ui.group(|ui| {
            ui.heading("🔒 Privacy & Security");
            ui.separator();
            
            // Encryption
            ui.horizontal(|ui| {
                ui.checkbox(&mut self.temp_config.encryption_enabled, "Enable keystroke encryption");
                ui.label("(Recommended for privacy)");
            });
            
            if self.temp_config.encryption_enabled {
                ui.indent("encryption_settings", |ui| {
                    ui.horizontal(|ui| {
                        ui.label("Password:");
                        ui.add(egui::TextEdit::singleline(&mut self.password_field).password(true));
                    });
                    
                    ui.horizontal(|ui| {
                        ui.label("Confirm Password:");
                        ui.add(egui::TextEdit::singleline(&mut self.confirm_password_field).password(true));
                    });
                    
                    if !self.password_field.is_empty() && !self.confirm_password_field.is_empty() {
                        if self.password_field != self.confirm_password_field {
                            ui.colored_label(egui::Color32::from_rgb(255, 100, 100), "❌ Passwords do not match");
                        } else {
                            ui.colored_label(egui::Color32::from_rgb(100, 255, 100), "✅ Passwords match");
                        }
                    }
                });
            }
            
            ui.add_space(10.0);
            
            // Excluded Applications
            ui.label("🚫 Excluded Applications:");
            ui.label("(One application per line)");
            ui.add(
                egui::TextEdit::multiline(&mut self.excluded_apps_text)
                    .desired_rows(5)
                    .hint_text("Enter application names to exclude from monitoring...")
            );
            
            ui.add_space(10.0);
            
            // Privacy Quick Actions
            ui.horizontal(|ui| {
                if ui.button("🛡️ Add Current App").clicked() {
                    // Add currently active application to exclusions
                }
                
                if ui.button("📝 Reset to Defaults").clicked() {
                    self.reset_excluded_apps();
                }
            });
        });
    }
    
    fn show_data_settings(&mut self, ui: &mut egui::Ui, database_connected: bool) {
        ui.group(|ui| {
            ui.heading("💾 Data Management");
            ui.separator();
            
            // Database info
            if database_connected {
                ui.horizontal(|ui| {
                    ui.label("Database Status:");
                    ui.colored_label(egui::Color32::from_rgb(100, 255, 100), "✅ Connected");
                });
                
                ui.horizontal(|ui| {
                    ui.label("Database Path:");
                    ui.label(self.temp_config.database_path.to_string_lossy());
                });
            } else {
                ui.horizontal(|ui| {
                    ui.label("Database Status:");
                    ui.colored_label(egui::Color32::from_rgb(255, 200, 100), "⚠️ Not Connected");
                });
            }
            
            ui.add_space(10.0);
            
            // Data Actions
            ui.horizontal(|ui| {
                if ui.button("📤 Export Data").clicked() {
                    self.export_data();
                }
                
                if ui.button("📥 Import Data").clicked() {
                    self.import_data();
                }
                
                if ui.button("🔄 Backup Data").clicked() {
                    self.backup_data();
                }
            });
            
            ui.add_space(10.0);
            
            // Dangerous Actions
            ui.group(|ui| {
                ui.heading("⚠️ Dangerous Actions");
                ui.separator();
                
                ui.horizontal(|ui| {
                    if ui.button("🗑️ Clear All Data").clicked() {
                        // Show confirmation dialog
                    }
                    
                    if ui.button("🔄 Reset to Defaults").clicked() {
                        self.reset_to_defaults();
                    }
                });
                
                ui.label("⚠️ These actions cannot be undone!");
            });
        });
    }
    
    fn show_advanced_settings(&mut self, ui: &mut egui::Ui) {
        ui.group(|ui| {
            ui.horizontal(|ui| {
                ui.heading("🔬 Advanced Settings");
                ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                    ui.checkbox(&mut self.show_advanced, "Show Advanced");
                });
            });
            ui.separator();
            
            if self.show_advanced {
                egui::Grid::new("advanced_settings")
                    .num_columns(2)
                    .spacing([40.0, 10.0])
                    .show(ui, |ui| {
                        // Buffer sizes and performance settings would go here
                        ui.label("Max Buffer Size:");
                        ui.add(egui::Slider::new(&mut 1000, 100..=10000).text("entries"));
                        ui.end_row();
                        
                        ui.label("Update Frequency:");
                        ui.add(egui::Slider::new(&mut 60, 10..=300).text("ms"));
                        ui.end_row();
                        
                        ui.label("Log Level:");
                        egui::ComboBox::from_id_source("log_level")
                            .selected_text("Info")
                            .show_ui(ui, |ui| {
                                ui.selectable_value(&mut "Debug", "Debug", "Debug");
                                ui.selectable_value(&mut "Info", "Info", "Info");
                                ui.selectable_value(&mut "Warn", "Warn", "Warning");
                                ui.selectable_value(&mut "Error", "Error", "Error");
                            });
                        ui.end_row();
                    });
                
                ui.add_space(10.0);
                
                // System Integration
                ui.group(|ui| {
                    ui.heading("🖥️ System Integration");
                    ui.separator();
                    
                    ui.checkbox(&mut true, "Start with system");
                    ui.checkbox(&mut true, "Minimize to system tray");
                    ui.checkbox(&mut false, "Show notifications");
                    ui.checkbox(&mut true, "Auto-update");
                });
            }
        });
    }
    
    fn show_action_buttons(&mut self, ui: &mut egui::Ui) {
        ui.horizontal(|ui| {
            if ui.button("💾 Save Settings").clicked() {
                self.save_settings();
            }
            
            if ui.button("↶ Revert Changes").clicked() {
                self.revert_changes();
            }
            
            if ui.button("🔄 Reset to Defaults").clicked() {
                self.reset_to_defaults();
            }
            
            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                if ui.button("ℹ️ Help").clicked() {
                    self.show_help();
                }
            });
        });
    }
    
    fn save_settings(&mut self) {
        // Parse excluded apps from text
        self.temp_config.exclude_apps = self.excluded_apps_text
            .lines()
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())
            .collect();
        
        // Apply settings
        self.config = self.temp_config.clone();
        
        // Show success message (would use a toast/notification in real app)
        println!("Settings saved successfully!");
    }
    
    fn revert_changes(&mut self) {
        self.temp_config = self.config.clone();
        self.excluded_apps_text = self.config.exclude_apps.join("\n");
        self.password_field.clear();
        self.confirm_password_field.clear();
    }
    
    fn reset_to_defaults(&mut self) {
        self.temp_config = Config::new();
        self.excluded_apps_text = self.temp_config.exclude_apps.join("\n");
        self.password_field.clear();
        self.confirm_password_field.clear();
    }
    
    fn reset_excluded_apps(&mut self) {
        let default_config = Config::new();
        self.excluded_apps_text = default_config.exclude_apps.join("\n");
    }
    
    fn export_data(&self) {
        // File dialog and export logic would go here
        println!("Export data functionality");
    }
    
    fn import_data(&self) {
        // File dialog and import logic would go here
        println!("Import data functionality");
    }
    
    fn backup_data(&self) {
        // Backup creation logic would go here
        println!("Backup data functionality");
    }
    
    fn show_help(&self) {
        // Open help documentation or show help dialog
        println!("Help functionality");
    }
}