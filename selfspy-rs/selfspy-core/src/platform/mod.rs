use async_trait::async_trait;
use anyhow::Result;

#[derive(Debug, Clone)]
pub struct WindowInfo {
    pub process_name: String,
    pub window_title: String,
    pub bundle_id: Option<String>,
    pub x: Option<i32>,
    pub y: Option<i32>,
    pub width: Option<i32>,
    pub height: Option<i32>,
}

#[derive(Debug, Clone)]
pub enum InputEvent {
    KeyPress { key: String },
    KeyRelease { key: String },
    MouseMove { x: i32, y: i32 },
    MouseClick { x: i32, y: i32, button: MouseButton },
    MouseScroll { delta_x: f64, delta_y: f64 },
}

#[derive(Debug, Clone)]
pub enum MouseButton {
    Left,
    Right,
    Middle,
}

impl MouseButton {
    pub fn as_str(&self) -> &str {
        match self {
            MouseButton::Left => "left",
            MouseButton::Right => "right",
            MouseButton::Middle => "middle",
        }
    }
}

#[async_trait]
pub trait PlatformTracker: Send + Sync {
    async fn get_active_window(&self) -> Result<WindowInfo>;
    async fn start_input_tracking(&self) -> Result<()>;
    async fn stop_input_tracking(&self) -> Result<()>;
    fn get_input_events(&self) -> Vec<InputEvent>;
}

// Simple fallback implementation for now
pub struct FallbackTracker;

#[async_trait]
impl PlatformTracker for FallbackTracker {
    async fn get_active_window(&self) -> Result<WindowInfo> {
        Ok(WindowInfo {
            process_name: "Unknown".to_string(),
            window_title: "Unknown Window".to_string(),
            bundle_id: None,
            x: None,
            y: None,
            width: None,
            height: None,
        })
    }
    
    async fn start_input_tracking(&self) -> Result<()> {
        Ok(())
    }
    
    async fn stop_input_tracking(&self) -> Result<()> {
        Ok(())
    }
    
    fn get_input_events(&self) -> Vec<InputEvent> {
        Vec::new()
    }
}

pub fn create_tracker() -> Box<dyn PlatformTracker> {
    Box::new(FallbackTracker)
}