use eframe::egui;

#[derive(PartialEq)]
enum StatsPeriod {
    Today,
    Week,
    Month,
    Year,
    All,
}

pub struct Statistics {
    selected_period: StatsPeriod,
    last_refresh: std::time::Instant,
    detailed_view: bool,
}

impl Statistics {
    pub fn new() -> Self {
        Self {
            selected_period: StatsPeriod::Today,
            last_refresh: std::time::Instant::now(),
            detailed_view: false,
        }
    }
    
    pub fn show(&mut self, ui: &mut egui::Ui, database_connected: bool) {
        ui.heading("📈 Activity Statistics");
        ui.separator();
        
        // Period selection
        ui.horizontal(|ui| {
            ui.label("Time Period:");
            ui.selectable_value(&mut self.selected_period, StatsPeriod::Today, "Today");
            ui.selectable_value(&mut self.selected_period, StatsPeriod::Week, "This Week");
            ui.selectable_value(&mut self.selected_period, StatsPeriod::Month, "This Month");
            ui.selectable_value(&mut self.selected_period, StatsPeriod::Year, "This Year");
            ui.selectable_value(&mut self.selected_period, StatsPeriod::All, "All Time");
            
            ui.separator();
            ui.checkbox(&mut self.detailed_view, "Detailed View");
        });
        
        ui.add_space(10.0);
        
        if database_connected {
            self.show_overview_stats(ui);
            
            ui.add_space(20.0);
            
            if self.detailed_view {
                self.show_detailed_stats(ui);
            } else {
                self.show_summary_stats(ui);
            }
        } else {
            ui.centered_and_justified(|ui| {
                ui.colored_label(egui::Color32::from_rgb(255, 200, 100), "⚠️ Database not connected");
                ui.label("Connect to database to view statistics");
            });
        }
    }
    
    fn show_overview_stats(&self, ui: &mut egui::Ui) {
        ui.group(|ui| {
            ui.heading("📊 Overview");
            ui.separator();
            
            // Create a grid layout for stats
            egui::Grid::new("stats_grid")
                .num_columns(4)
                .spacing([20.0, 10.0])
                .show(ui, |ui| {
                    // Headers
                    ui.strong("Metric");
                    ui.strong("Total");
                    ui.strong("Average/Day");
                    ui.strong("Trend");
                    ui.end_row();
                    
                    // Keystrokes
                    ui.label("⌨️ Keystrokes");
                    ui.label(self.format_number(25430));
                    ui.label(self.format_number(3633));
                    self.show_trend_indicator(ui, 0.15); // +15%
                    ui.end_row();
                    
                    // Clicks
                    ui.label("🖱️ Mouse Clicks");
                    ui.label(self.format_number(8920));
                    ui.label(self.format_number(1274));
                    self.show_trend_indicator(ui, -0.05); // -5%
                    ui.end_row();
                    
                    // Windows
                    ui.label("🪟 Windows");
                    ui.label(self.format_number(142));
                    ui.label(self.format_number(20));
                    self.show_trend_indicator(ui, 0.08); // +8%
                    ui.end_row();
                    
                    // Processes
                    ui.label("📱 Applications");
                    ui.label(self.format_number(28));
                    ui.label(self.format_number(4));
                    self.show_trend_indicator(ui, 0.03); // +3%
                    ui.end_row();
                });
        });
    }
    
    fn show_summary_stats(&self, ui: &mut egui::Ui) {
        ui.columns(2, |columns| {
            // Left column - Activity Breakdown
            columns[0].group(|ui| {
                ui.heading("🎯 Activity Breakdown");
                ui.separator();
                
                // Productivity metrics
                ui.horizontal(|ui| {
                    ui.label("Productive Time:");
                    ui.colored_label(egui::Color32::from_rgb(100, 255, 100), "6h 32m");
                });
                
                ui.horizontal(|ui| {
                    ui.label("Idle Time:");
                    ui.colored_label(egui::Color32::from_rgb(255, 200, 100), "1h 15m");
                });
                
                ui.horizontal(|ui| {
                    ui.label("Entertainment:");
                    ui.colored_label(egui::Color32::from_rgb(255, 150, 150), "45m");
                });
                
                ui.add_space(10.0);
                
                // Activity intensity
                ui.label("Activity Intensity:");
                self.show_intensity_bars(ui);
            });
            
            // Right column - Top Applications
            columns[1].group(|ui| {
                ui.heading("🏆 Top Applications");
                ui.separator();
                
                // Top apps with usage data
                self.show_app_usage_item(ui, "Visual Studio Code", 100.0, "2h 15m");
                self.show_app_usage_item(ui, "Chrome", 85.0, "1h 52m");
                self.show_app_usage_item(ui, "Terminal", 70.0, "1h 32m");
                self.show_app_usage_item(ui, "Slack", 55.0, "1h 12m");
                self.show_app_usage_item(ui, "Spotify", 40.0, "52m");
                self.show_app_usage_item(ui, "Discord", 25.0, "34m");
            });
        });
    }
    
    fn show_detailed_stats(&self, ui: &mut egui::Ui) {
        ui.group(|ui| {
            ui.heading("🔍 Detailed Analysis");
            ui.separator();
            
            // Tabs for different detailed views
            ui.horizontal(|ui| {
                ui.selectable_label(true, "📊 Productivity");
                ui.selectable_label(false, "⏰ Time Tracking");
                ui.selectable_label(false, "🎯 Focus Analysis");
                ui.selectable_label(false, "📱 App Usage");
            });
            
            ui.separator();
            
            // Detailed productivity analysis
            egui::ScrollArea::vertical().show(ui, |ui| {
                self.show_productivity_analysis(ui);
                ui.add_space(10.0);
                self.show_pattern_analysis(ui);
                ui.add_space(10.0);
                self.show_comparison_analysis(ui);
            });
        });
    }
    
    fn show_productivity_analysis(&self, ui: &mut egui::Ui) {
        ui.group(|ui| {
            ui.heading("🎯 Productivity Analysis");
            ui.separator();
            
            // Productivity score
            ui.horizontal(|ui| {
                ui.label("Overall Productivity Score:");
                ui.add(egui::ProgressBar::new(0.78).text("78%"));
            });
            
            ui.add_space(5.0);
            
            // Key insights
            ui.label("📈 Key Insights:");
            ui.indent("insights", |ui| {
                ui.label("• 23% increase in coding time this week");
                ui.label("• Peak productivity: 10:00-12:00 AM");
                ui.label("• Most focused on: Development tasks");
                ui.label("• Distraction events: 12 (down from 18 last week)");
            });
        });
    }
    
    fn show_pattern_analysis(&self, ui: &mut egui::Ui) {
        ui.group(|ui| {
            ui.heading("📊 Activity Patterns");
            ui.separator();
            
            // Hourly pattern visualization
            ui.label("Hourly Activity Distribution:");
            let desired_size = egui::vec2(ui.available_width(), 80.0);
            let (rect, _response) = ui.allocate_exact_size(desired_size, egui::Sense::hover());
            
            // Draw hourly activity bars
            let bar_width = rect.width() / 24.0;
            for hour in 0..24 {
                let activity = self.get_hourly_activity(hour);
                let bar_height = rect.height() * activity;
                let bar_rect = egui::Rect::from_min_size(
                    egui::pos2(rect.min.x + hour as f32 * bar_width, rect.max.y - bar_height),
                    egui::vec2(bar_width - 2.0, bar_height),
                );
                
                let color = if hour >= 9 && hour <= 17 {
                    egui::Color32::from_rgb(100, 150, 255) // Work hours
                } else {
                    egui::Color32::from_rgb(150, 150, 150) // Off hours
                };
                
                ui.painter().rect_filled(bar_rect, 2.0, color);
            }
            
            // Hour labels
            for hour in (0..24).step_by(6) {
                let x = rect.min.x + hour as f32 * bar_width;
                ui.painter().text(
                    egui::pos2(x, rect.max.y + 5.0),
                    egui::Align2::LEFT_TOP,
                    format!("{:02}:00", hour),
                    egui::FontId::proportional(12.0),
                    egui::Color32::GRAY,
                );
            }
        });
    }
    
    fn show_comparison_analysis(&self, ui: &mut egui::Ui) {
        ui.group(|ui| {
            ui.heading("📈 Trend Comparison");
            ui.separator();
            
            ui.columns(3, |columns| {
                // Today vs Yesterday
                columns[0].group(|ui| {
                    ui.heading("Today vs Yesterday");
                    ui.separator();
                    self.show_comparison_metric(ui, "Keystrokes", 3250, 2980, true);
                    self.show_comparison_metric(ui, "Active Time", 420, 380, true);
                    self.show_comparison_metric(ui, "Applications", 12, 15, false);
                });
                
                // This Week vs Last Week
                columns[1].group(|ui| {
                    ui.heading("This Week vs Last Week");
                    ui.separator();
                    self.show_comparison_metric(ui, "Avg Daily Keys", 3100, 2750, true);
                    self.show_comparison_metric(ui, "Avg Active Time", 410, 360, true);
                    self.show_comparison_metric(ui, "Focus Score", 78, 72, true);
                });
                
                // This Month vs Last Month
                columns[2].group(|ui| {
                    ui.heading("This Month vs Last Month");
                    ui.separator();
                    self.show_comparison_metric(ui, "Total Hours", 120, 95, true);
                    self.show_comparison_metric(ui, "Productivity", 76, 68, true);
                    self.show_comparison_metric(ui, "Consistency", 82, 79, true);
                });
            });
        });
    }
    
    fn show_comparison_metric(&self, ui: &mut egui::Ui, label: &str, current: i32, previous: i32, higher_is_better: bool) {
        ui.horizontal(|ui| {
            ui.label(format!("{}:", label));
            
            let diff = current - previous;
            let diff_percent = (diff as f32 / previous as f32) * 100.0;
            
            let (color, symbol) = if diff > 0 {
                if higher_is_better {
                    (egui::Color32::from_rgb(100, 255, 100), "↗")
                } else {
                    (egui::Color32::from_rgb(255, 150, 150), "↗")
                }
            } else {
                if higher_is_better {
                    (egui::Color32::from_rgb(255, 150, 150), "↘")
                } else {
                    (egui::Color32::from_rgb(100, 255, 100), "↘")
                }
            };
            
            ui.colored_label(color, format!("{} {:+.1}%", symbol, diff_percent));
        });
    }
    
    fn show_trend_indicator(&self, ui: &mut egui::Ui, trend: f32) {
        let (color, symbol) = if trend > 0.0 {
            (egui::Color32::from_rgb(100, 255, 100), "↗")
        } else {
            (egui::Color32::from_rgb(255, 150, 150), "↘")
        };
        
        ui.colored_label(color, format!("{} {:+.1}%", symbol, trend * 100.0));
    }
    
    fn show_intensity_bars(&self, ui: &mut egui::Ui) {
        let periods = ["Morning", "Afternoon", "Evening"];
        let intensities = [0.6, 0.9, 0.4];
        
        for (period, intensity) in periods.iter().zip(intensities.iter()) {
            ui.horizontal(|ui| {
                ui.label(format!("{}:", period));
                ui.add(egui::ProgressBar::new(*intensity).text(format!("{:.0}%", intensity * 100.0)));
            });
        }
    }
    
    fn show_app_usage_item(&self, ui: &mut egui::Ui, app_name: &str, percentage: f32, time: &str) {
        ui.horizontal(|ui| {
            ui.label(format!("📱 {}", app_name));
            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                ui.label(time);
                ui.add(egui::ProgressBar::new(percentage / 100.0).desired_width(60.0));
            });
        });
    }
    
    fn get_hourly_activity(&self, hour: usize) -> f32 {
        // Simulated hourly activity pattern
        match hour {
            0..=6 => 0.1,
            7..=8 => 0.3,
            9..=11 => 0.8,
            12 => 0.4, // Lunch
            13..=16 => 0.9,
            17..=18 => 0.6,
            19..=21 => 0.5,
            _ => 0.2,
        }
    }
    
    fn format_number(&self, num: i64) -> String {
        if num >= 1_000_000 {
            format!("{:.1}M", num as f64 / 1_000_000.0)
        } else if num >= 1_000 {
            format!("{:.1}K", num as f64 / 1_000.0)
        } else {
            num.to_string()
        }
    }
}