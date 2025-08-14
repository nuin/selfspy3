use tray_icon::{TrayIcon, TrayIconBuilder, menu::{Menu, MenuItem}};
use winit::event_loop::EventLoopProxy;

pub enum TrayEvent {
    Show,
    Hide,
    Quit,
    ToggleMonitoring,
    ShowSettings,
}

pub struct SystemTray {
    _tray_icon: Option<TrayIcon>,
}

impl SystemTray {
    pub fn new(event_proxy: EventLoopProxy<TrayEvent>) -> Self {
        let tray_icon = Self::create_tray_icon(event_proxy).ok();
        
        Self {
            _tray_icon: tray_icon,
        }
    }
    
    fn create_tray_icon(event_proxy: EventLoopProxy<TrayEvent>) -> Result<TrayIcon, Box<dyn std::error::Error>> {
        // Create context menu
        let show_item = MenuItem::new("Show Selfspy", true, None);
        let hide_item = MenuItem::new("Hide Selfspy", true, None);
        let separator1 = MenuItem::new("", false, None); // Separator
        let toggle_monitoring = MenuItem::new("Start Monitoring", true, None);
        let settings_item = MenuItem::new("Settings", true, None);
        let separator2 = MenuItem::new("", false, None); // Separator
        let quit_item = MenuItem::new("Quit", true, None);
        
        let menu = Menu::new();
        menu.append(&show_item)?;
        menu.append(&hide_item)?;
        menu.append(&separator1)?;
        menu.append(&toggle_monitoring)?;
        menu.append(&settings_item)?;
        menu.append(&separator2)?;
        menu.append(&quit_item)?;
        
        // Create tray icon
        let tray_icon = TrayIconBuilder::new()
            .with_menu(Box::new(menu))
            .with_tooltip("Selfspy - Activity Monitor")
            .with_icon(Self::create_icon())
            .build()?;
        
        // Handle menu events
        let menu_channel = tray_icon::menu::MenuEvent::receiver();
        std::thread::spawn(move || {
            loop {
                if let Ok(event) = menu_channel.recv() {
                    match event.id.0.as_str() {
                        "Show Selfspy" => {
                            let _ = event_proxy.send_event(TrayEvent::Show);
                        }
                        "Hide Selfspy" => {
                            let _ = event_proxy.send_event(TrayEvent::Hide);
                        }
                        "Start Monitoring" | "Stop Monitoring" => {
                            let _ = event_proxy.send_event(TrayEvent::ToggleMonitoring);
                        }
                        "Settings" => {
                            let _ = event_proxy.send_event(TrayEvent::ShowSettings);
                        }
                        "Quit" => {
                            let _ = event_proxy.send_event(TrayEvent::Quit);
                        }
                        _ => {}
                    }
                }
            }
        });
        
        Ok(tray_icon)
    }
    
    fn create_icon() -> tray_icon::Icon {
        // Create a simple icon (32x32 pixels, RGBA)
        let icon_size = 32;
        let mut icon_data = vec![0u8; icon_size * icon_size * 4];
        
        // Create a simple blue circle icon with "S" in the center
        for y in 0..icon_size {
            for x in 0..icon_size {
                let dx = x as f32 - icon_size as f32 / 2.0;
                let dy = y as f32 - icon_size as f32 / 2.0;
                let distance = (dx * dx + dy * dy).sqrt();
                
                let idx = (y * icon_size + x) * 4;
                if distance < icon_size as f32 / 2.0 - 2.0 {
                    // Blue background
                    icon_data[idx] = 50;      // R
                    icon_data[idx + 1] = 120; // G
                    icon_data[idx + 2] = 200; // B
                    icon_data[idx + 3] = 255; // A
                    
                    // Add "S" in the center (very simple)
                    if Self::is_part_of_s(x as i32, y as i32, icon_size as i32) {
                        icon_data[idx] = 255;     // R - white
                        icon_data[idx + 1] = 255; // G
                        icon_data[idx + 2] = 255; // B
                        icon_data[idx + 3] = 255; // A
                    }
                } else {
                    icon_data[idx + 3] = 0;   // Transparent
                }
            }
        }
        
        tray_icon::Icon::from_rgba(icon_data, icon_size as u32, icon_size as u32)
            .expect("Failed to create icon")
    }
    
    fn is_part_of_s(x: i32, y: i32, size: i32) -> bool {
        let center = size / 2;
        let rel_x = x - center;
        let rel_y = y - center;
        
        // Very simple "S" shape - just some pixels
        // This is a placeholder - a real implementation would use a proper font or vector graphics
        match (rel_x, rel_y) {
            (-4..=-2, -6..=-4) => true, // Top horizontal
            (-4..=-2, -2..=0) => true,  // Middle horizontal
            (-4..=-2, 2..=4) => true,   // Bottom horizontal
            (-6..=-4, -4..=-2) => true, // Top left vertical
            (2..=4, 0..=2) => true,     // Bottom right vertical
            _ => false,
        }
    }
    
    pub fn update_monitoring_status(&self, is_monitoring: bool) {
        // Update the menu item text based on monitoring status
        // This would require storing references to menu items
        // For now, this is a placeholder
        let _status_text = if is_monitoring {
            "Stop Monitoring"
        } else {
            "Start Monitoring"
        };
    }
    
    pub fn show_notification(&self, title: &str, message: &str) {
        // Show system notification
        // This would use the notification crate or system APIs
        println!("Notification: {} - {}", title, message);
    }
}