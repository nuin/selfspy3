use eframe::egui;

pub struct Dashboard {
    last_refresh: std::time::Instant,
}

impl Dashboard {
    pub fn new() -> Self {
        Self {
            last_refresh: std::time::Instant::now(),
        }
    }
    
    pub fn show(&mut self, ui: &mut egui::Ui, is_monitoring: bool, database_connected: bool) {
        ui.heading("📊 Activity Dashboard");
        ui.separator();
        
        // Live metrics cards
        ui.columns(4, |columns| {
            self.show_metric_card(&mut columns[0], "⌨️ Keystrokes", 1234, 
                egui::Color32::from_rgb(100, 150, 255));
                
            self.show_metric_card(&mut columns[1], "🖱️ Clicks", 567, 
                egui::Color32::from_rgb(255, 150, 100));
                
            self.show_metric_card(&mut columns[2], "🪟 Windows", 89, 
                egui::Color32::from_rgb(150, 255, 100));
                
            self.show_metric_card(&mut columns[3], "📱 Processes", 15, 
                egui::Color32::from_rgb(255, 100, 150));
        });
        
        ui.add_space(20.0);
        
        // Current activity section
        ui.group(|ui| {
            ui.heading("🔴 Current Activity");
            ui.separator();
            
            if is_monitoring {
                ui.horizontal(|ui| {
                    ui.colored_label(egui::Color32::from_rgb(100, 255, 100), "● MONITORING");
                    ui.label("Actively tracking your activity");
                });
                
                ui.horizontal(|ui| {
                    ui.label("📱 Most Active:");
                    ui.colored_label(egui::Color32::from_rgb(150, 200, 255), "VS Code");
                });
                
                // Show real-time activity indicators
                ui.horizontal(|ui| {
                    ui.label("Activity Level:");
                    let activity_level = self.calculate_activity_level();
                    self.show_activity_bar(ui, activity_level);
                });
            } else {
                ui.horizontal(|ui| {
                    ui.colored_label(egui::Color32::from_rgb(255, 200, 100), "⏸ PAUSED");
                    ui.label("Click 'Start' to begin monitoring");
                });
            }
        });
        
        ui.add_space(20.0);
        
        // Database connection status
        ui.group(|ui| {
            ui.heading("💾 Database Status");
            ui.separator();
            
            if database_connected {
                ui.horizontal(|ui| {
                    ui.colored_label(egui::Color32::from_rgb(100, 255, 100), "✅ Connected");
                    ui.label("Data is being stored successfully");
                });
            } else {
                ui.horizontal(|ui| {
                    ui.colored_label(egui::Color32::from_rgb(255, 100, 100), "❌ Disconnected");
                    ui.label("Unable to connect to database");
                });
            }
        });
        
        ui.add_space(20.0);
        
        // Recent activity timeline
        ui.group(|ui| {
            ui.heading("📅 Recent Activity");
            ui.separator();
            
            if database_connected {
                // Show activity summary
                ui.horizontal(|ui| {
                    ui.label("Session Duration:");
                    ui.label("2h 45m");
                });
                
                // Simple activity timeline visualization
                self.show_activity_timeline(ui);
            } else {
                ui.label("No activity data available - database not connected");
            }
        });
        
        ui.add_space(20.0);
        
        // Quick actions
        ui.group(|ui| {
            ui.heading("⚡ Quick Actions");
            ui.separator();
            
            ui.horizontal(|ui| {
                if ui.button("📊 View Detailed Stats").clicked() {
                    // Would switch to statistics tab
                }
                
                if ui.button("📈 Open Charts").clicked() {
                    // Would switch to charts tab
                }
                
                if ui.button("💾 Export Data").clicked() {
                    self.export_data();
                }
                
                if ui.button("🗑️ Clear Data").clicked() {
                    self.show_clear_confirmation(ui);
                }
            });
        });
    }
    
    fn show_metric_card(&self, ui: &mut egui::Ui, title: &str, value: i64, color: egui::Color32) {
        ui.group(|ui| {
            ui.set_min_height(80.0);
            ui.vertical_centered(|ui| {
                ui.colored_label(color, title);
                ui.heading(self.format_large_number(value));
            });
        });
    }
    
    fn format_large_number(&self, num: i64) -> String {
        if num >= 1_000_000 {
            format!("{:.1}M", num as f64 / 1_000_000.0)
        } else if num >= 1_000 {
            format!("{:.1}K", num as f64 / 1_000.0)
        } else {
            num.to_string()
        }
    }
    
    fn calculate_activity_level(&self) -> f32 {
        // Calculate based on recent activity
        // This is a placeholder - would use real activity data
        0.7 // 70% activity level
    }
    
    fn show_activity_bar(&self, ui: &mut egui::Ui, level: f32) {
        let desired_size = egui::vec2(200.0, 20.0);
        let (rect, _response) = ui.allocate_exact_size(desired_size, egui::Sense::hover());
        
        // Background
        ui.painter().rect_filled(rect, 3.0, egui::Color32::from_gray(50));
        
        // Activity level bar
        let fill_width = rect.width() * level;
        let fill_rect = egui::Rect::from_min_size(rect.min, egui::vec2(fill_width, rect.height()));
        
        let color = if level > 0.8 {
            egui::Color32::from_rgb(255, 100, 100)
        } else if level > 0.5 {
            egui::Color32::from_rgb(255, 200, 100)
        } else {
            egui::Color32::from_rgb(100, 255, 100)
        };
        
        ui.painter().rect_filled(fill_rect, 3.0, color);
        
        // Label
        ui.painter().text(
            rect.center(),
            egui::Align2::CENTER_CENTER,
            format!("{:.0}%", level * 100.0),
            egui::FontId::default(),
            egui::Color32::WHITE,
        );
    }
    
    fn show_activity_timeline(&self, ui: &mut egui::Ui) {
        // Simple timeline visualization
        let desired_size = egui::vec2(ui.available_width(), 60.0);
        let (rect, _response) = ui.allocate_exact_size(desired_size, egui::Sense::hover());
        
        // Background
        ui.painter().rect_filled(rect, 3.0, egui::Color32::from_gray(30));
        
        // Draw timeline bars (simulated data)
        let bar_width = rect.width() / 24.0; // 24 hours
        for hour in 0..24 {
            let activity = ((hour as f32 * 0.3).sin() + 1.0) * 0.5; // Simulated activity
            let bar_height = rect.height() * activity;
            let bar_rect = egui::Rect::from_min_size(
                egui::pos2(rect.min.x + hour as f32 * bar_width, rect.max.y - bar_height),
                egui::vec2(bar_width - 1.0, bar_height),
            );
            
            ui.painter().rect_filled(bar_rect, 1.0, egui::Color32::from_rgb(100, 150, 255));
        }
        
        // Hour labels
        for hour in (0..24).step_by(4) {
            let x = rect.min.x + hour as f32 * bar_width;
            ui.painter().text(
                egui::pos2(x, rect.max.y + 5.0),
                egui::Align2::LEFT_TOP,
                format!("{:02}:00", hour),
                egui::FontId::proportional(12.0),
                egui::Color32::GRAY,
            );
        }
    }
    
    fn export_data(&self) {
        // Placeholder for data export functionality
        println!("Export data functionality would go here");
    }
    
    fn show_clear_confirmation(&self, ui: &mut egui::Ui) {
        // Placeholder for clear data confirmation dialog
        ui.label("Clear data confirmation would be shown here");
    }
}