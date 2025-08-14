use eframe::egui;
use egui_plot::{Line, Plot, PlotPoints, Bar, BarChart, Legend};

#[derive(PartialEq)]
enum ChartType {
    ActivityOverTime,
    ApplicationUsage,
    ProductivityTrends,
    HourlyPatterns,
}

pub struct Charts {
    selected_chart: ChartType,
    time_range: usize, // Days
    last_refresh: std::time::Instant,
}

impl Charts {
    pub fn new() -> Self {
        Self {
            selected_chart: ChartType::ActivityOverTime,
            time_range: 7,
            last_refresh: std::time::Instant::now(),
        }
    }
    
    pub fn show(&mut self, ui: &mut egui::Ui, database_connected: bool) {
        ui.heading("📉 Activity Charts");
        ui.separator();
        
        // Chart selection and controls
        ui.horizontal(|ui| {
            ui.label("Chart Type:");
            ui.selectable_value(&mut self.selected_chart, ChartType::ActivityOverTime, "📈 Activity Over Time");
            ui.selectable_value(&mut self.selected_chart, ChartType::ApplicationUsage, "📱 App Usage");
            ui.selectable_value(&mut self.selected_chart, ChartType::ProductivityTrends, "🎯 Productivity");
            ui.selectable_value(&mut self.selected_chart, ChartType::HourlyPatterns, "⏰ Hourly Patterns");
            
            ui.separator();
            
            ui.label("Time Range:");
            ui.selectable_value(&mut self.time_range, 1, "1 Day");
            ui.selectable_value(&mut self.time_range, 7, "1 Week");
            ui.selectable_value(&mut self.time_range, 30, "1 Month");
            ui.selectable_value(&mut self.time_range, 365, "1 Year");
        });
        
        ui.add_space(10.0);
        
        // Main chart area
        if database_connected {
            match self.selected_chart {
                ChartType::ActivityOverTime => self.show_activity_over_time_chart(ui),
                ChartType::ApplicationUsage => self.show_application_usage_chart(ui),
                ChartType::ProductivityTrends => self.show_productivity_trends_chart(ui),
                ChartType::HourlyPatterns => self.show_hourly_patterns_chart(ui),
            }
        } else {
            ui.centered_and_justified(|ui| {
                ui.colored_label(egui::Color32::from_rgb(255, 200, 100), "⚠️ Database not connected");
                ui.label("Connect to database to view charts");
            });
        }
    }
    
    fn show_activity_over_time_chart(&self, ui: &mut egui::Ui) {
        ui.group(|ui| {
            ui.heading("📈 Activity Over Time");
            ui.separator();
            
            Plot::new("activity_over_time")
                .legend(Legend::default())
                .height(400.0)
                .show(ui, |plot_ui| {
                    // Generate sample data
                    let keystrokes_data: PlotPoints = (0..self.time_range)
                        .map(|i| {
                            let x = i as f64;
                            let y = 1000.0 + 500.0 * (x * 0.1).sin() + 200.0 * (x * 0.3).cos();
                            [x, y]
                        })
                        .collect();
                    
                    let clicks_data: PlotPoints = (0..self.time_range)
                        .map(|i| {
                            let x = i as f64;
                            let y = 200.0 + 100.0 * (x * 0.15).sin() + 50.0 * (x * 0.25).cos();
                            [x, y]
                        })
                        .collect();
                    
                    let active_time_data: PlotPoints = (0..self.time_range)
                        .map(|i| {
                            let x = i as f64;
                            let y = 6.0 + 2.0 * (x * 0.2).sin() + (x * 0.1).cos();
                            [x, y]
                        })
                        .collect();
                    
                    plot_ui.line(
                        Line::new(keystrokes_data)
                            .color(egui::Color32::from_rgb(100, 150, 255))
                            .name("Keystrokes")
                    );
                    
                    plot_ui.line(
                        Line::new(clicks_data)
                            .color(egui::Color32::from_rgb(255, 150, 100))
                            .name("Mouse Clicks")
                    );
                    
                    plot_ui.line(
                        Line::new(active_time_data)
                            .color(egui::Color32::from_rgb(150, 255, 100))
                            .name("Active Hours")
                    );
                });
        });
    }
    
    fn show_application_usage_chart(&self, ui: &mut egui::Ui) {
        ui.group(|ui| {
            ui.heading("📱 Application Usage");
            ui.separator();
            
            Plot::new("app_usage")
                .height(400.0)
                .show(ui, |plot_ui| {
                    let apps = vec![
                        ("VS Code", 4.5),
                        ("Chrome", 3.2),
                        ("Terminal", 2.8),
                        ("Slack", 1.5),
                        ("Spotify", 1.0),
                        ("Discord", 0.8),
                        ("Notes", 0.5),
                    ];
                    
                    let bars: Vec<Bar> = apps
                        .into_iter()
                        .enumerate()
                        .map(|(i, (name, hours))| {
                            Bar::new(i as f64, hours)
                                .name(name)
                                .fill(self.get_app_color(i))
                        })
                        .collect();
                    
                    plot_ui.bar_chart(BarChart::new(bars).name("Hours Used"));
                });
        });
    }
    
    fn show_productivity_trends_chart(&self, ui: &mut egui::Ui) {
        ui.group(|ui| {
            ui.heading("🎯 Productivity Trends");
            ui.separator();
            
            Plot::new("productivity_trends")
                .legend(Legend::default())
                .height(400.0)
                .show(ui, |plot_ui| {
                    // Productivity score over time
                    let productivity_data: PlotPoints = (0..self.time_range)
                        .map(|i| {
                            let x = i as f64;
                            let base = 75.0;
                            let trend = x * 0.5; // Gradual improvement
                            let variation = 10.0 * (x * 0.3).sin();
                            let y = (base + trend + variation).clamp(0.0, 100.0);
                            [x, y]
                        })
                        .collect();
                    
                    // Focus score
                    let focus_data: PlotPoints = (0..self.time_range)
                        .map(|i| {
                            let x = i as f64;
                            let base = 70.0;
                            let variation = 15.0 * (x * 0.2).cos() + 8.0 * (x * 0.5).sin();
                            let y = (base + variation).clamp(0.0, 100.0);
                            [x, y]
                        })
                        .collect();
                    
                    // Efficiency score
                    let efficiency_data: PlotPoints = (0..self.time_range)
                        .map(|i| {
                            let x = i as f64;
                            let base = 80.0;
                            let variation = 12.0 * (x * 0.25).sin();
                            let y = (base + variation).clamp(0.0, 100.0);
                            [x, y]
                        })
                        .collect();
                    
                    plot_ui.line(
                        Line::new(productivity_data)
                            .color(egui::Color32::from_rgb(100, 255, 100))
                            .name("Productivity Score")
                    );
                    
                    plot_ui.line(
                        Line::new(focus_data)
                            .color(egui::Color32::from_rgb(255, 150, 100))
                            .name("Focus Score")
                    );
                    
                    plot_ui.line(
                        Line::new(efficiency_data)
                            .color(egui::Color32::from_rgb(150, 150, 255))
                            .name("Efficiency Score")
                    );
                });
        });
    }
    
    fn show_hourly_patterns_chart(&self, ui: &mut egui::Ui) {
        ui.group(|ui| {
            ui.heading("⏰ Hourly Activity Patterns");
            ui.separator();
            
            Plot::new("hourly_patterns")
                .height(400.0)
                .show(ui, |plot_ui| {
                    // Average activity by hour
                    let hourly_activity: Vec<Bar> = (0..24)
                        .map(|hour| {
                            let activity = self.get_hourly_activity_level(hour);
                            Bar::new(hour as f64, activity)
                                .fill(self.get_hour_color(hour))
                        })
                        .collect();
                    
                    plot_ui.bar_chart(
                        BarChart::new(hourly_activity)
                            .name("Activity Level")
                    );
                });
            
            ui.add_space(10.0);
            
            // Heatmap-style hourly breakdown
            ui.group(|ui| {
                ui.heading("📅 Weekly Activity Heatmap");
                ui.separator();
                
                let desired_size = egui::vec2(ui.available_width(), 200.0);
                let (rect, _response) = ui.allocate_exact_size(desired_size, egui::Sense::hover());
                
                let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                let cell_width = rect.width() / 24.0;
                let cell_height = rect.height() / 7.0;
                
                // Draw heatmap
                for (day_idx, _day) in days.iter().enumerate() {
                    for hour in 0..24 {
                        let activity = self.get_activity_for_day_hour(day_idx, hour);
                        let intensity = (activity * 255.0) as u8;
                        let color = egui::Color32::from_rgba_unmultiplied(
                            100, 150, 255, intensity
                        );
                        
                        let cell_rect = egui::Rect::from_min_size(
                            egui::pos2(
                                rect.min.x + hour as f32 * cell_width,
                                rect.min.y + day_idx as f32 * cell_height,
                            ),
                            egui::vec2(cell_width - 1.0, cell_height - 1.0),
                        );
                        
                        ui.painter().rect_filled(cell_rect, 2.0, color);
                    }
                }
                
                // Labels
                for (day_idx, day) in days.iter().enumerate() {
                    ui.painter().text(
                        egui::pos2(rect.min.x - 30.0, rect.min.y + day_idx as f32 * cell_height + cell_height / 2.0),
                        egui::Align2::RIGHT_CENTER,
                        day,
                        egui::FontId::proportional(12.0),
                        egui::Color32::GRAY,
                    );
                }
                
                for hour in (0..24).step_by(4) {
                    ui.painter().text(
                        egui::pos2(rect.min.x + hour as f32 * cell_width + cell_width / 2.0, rect.max.y + 10.0),
                        egui::Align2::CENTER_TOP,
                        format!("{:02}", hour),
                        egui::FontId::proportional(12.0),
                        egui::Color32::GRAY,
                    );
                }
            });
        });
    }
    
    fn get_app_color(&self, index: usize) -> egui::Color32 {
        let colors = [
            egui::Color32::from_rgb(100, 150, 255),
            egui::Color32::from_rgb(255, 150, 100),
            egui::Color32::from_rgb(150, 255, 100),
            egui::Color32::from_rgb(255, 100, 150),
            egui::Color32::from_rgb(150, 100, 255),
            egui::Color32::from_rgb(255, 255, 100),
            egui::Color32::from_rgb(100, 255, 255),
        ];
        colors[index % colors.len()]
    }
    
    fn get_hour_color(&self, hour: usize) -> egui::Color32 {
        if hour >= 9 && hour <= 17 {
            egui::Color32::from_rgb(100, 150, 255) // Work hours - blue
        } else if hour >= 6 && hour <= 22 {
            egui::Color32::from_rgb(150, 255, 100) // Active hours - green
        } else {
            egui::Color32::from_rgb(100, 100, 100) // Sleep hours - gray
        }
    }
    
    fn get_hourly_activity_level(&self, hour: usize) -> f64 {
        // Simulate realistic activity patterns
        match hour {
            0..=5 => 0.1,           // Late night/early morning
            6..=7 => 0.3,           // Getting ready
            8 => 0.6,               // Commute/start work
            9..=11 => 0.9,          // Morning productivity peak
            12 => 0.4,              // Lunch break
            13..=15 => 0.85,        // Afternoon work
            16..=17 => 0.7,         // End of work day
            18..=19 => 0.5,         // Evening activities
            20..=22 => 0.6,         // Evening relaxation/hobbies
            _ => 0.2,               // Late evening
        }
    }
    
    fn get_activity_for_day_hour(&self, day: usize, hour: usize) -> f32 {
        let base_activity = self.get_hourly_activity_level(hour) as f32;
        
        // Modify based on day of week
        let day_modifier = match day {
            0..=4 => 1.0,           // Weekdays - normal
            5 => 0.8,               // Saturday - reduced
            6 => 0.6,               // Sunday - more reduced
            _ => 1.0,
        };
        
        // Add some randomness
        let variation = ((day * 7 + hour) as f32 * 0.1).sin() * 0.2;
        
        (base_activity * day_modifier + variation).clamp(0.0, 1.0)
    }
}