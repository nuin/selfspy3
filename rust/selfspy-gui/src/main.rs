mod app;
mod dashboard;
mod settings;
mod statistics;
mod charts;
mod system_tray;

use app::SelfspyApp;
use eframe::egui;

#[tokio::main]
async fn main() -> Result<(), eframe::Error> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_inner_size([1200.0, 800.0])
            .with_min_inner_size([800.0, 600.0])
            .with_icon(load_icon()),
        ..Default::default()
    };

    eframe::run_native(
        "Selfspy - Activity Monitor",
        options,
        Box::new(|cc| {
            // Set up custom font
            setup_custom_fonts(&cc.egui_ctx);
            
            // Enable dark mode by default
            cc.egui_ctx.set_visuals(egui::Visuals::dark());
            
            Ok(Box::new(SelfspyApp::new(cc)))
        }),
    )
}

fn load_icon() -> egui::IconData {
    // Create a simple icon (32x32 pixels, RGBA)
    let icon_size = 32;
    let mut icon_data = vec![0u8; icon_size * icon_size * 4];
    
    // Create a simple blue circle icon
    for y in 0..icon_size {
        for x in 0..icon_size {
            let dx = x as f32 - icon_size as f32 / 2.0;
            let dy = y as f32 - icon_size as f32 / 2.0;
            let distance = (dx * dx + dy * dy).sqrt();
            
            let idx = (y * icon_size + x) * 4;
            if distance < icon_size as f32 / 2.0 - 2.0 {
                icon_data[idx] = 100;     // R
                icon_data[idx + 1] = 150; // G
                icon_data[idx + 2] = 255; // B
                icon_data[idx + 3] = 255; // A
            } else {
                icon_data[idx + 3] = 0;   // Transparent
            }
        }
    }
    
    egui::IconData {
        rgba: icon_data,
        width: icon_size as u32,
        height: icon_size as u32,
    }
}

fn setup_custom_fonts(ctx: &egui::Context) {
    // Use default fonts for now - could add custom fonts later
    let fonts = egui::FontDefinitions::default();
    ctx.set_fonts(fonts);
}