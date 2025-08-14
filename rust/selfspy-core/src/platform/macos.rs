use async_trait::async_trait;
use anyhow::{Result, anyhow};
use std::sync::{Arc, Mutex};
use core_foundation::base::TCFType;
use core_foundation::string::CFString;
use core_graphics::event::{CGEvent, CGEventType, CGEventTapLocation, CGEventTapPlacement, CGEventTapOptions};
use cocoa::base::{id, nil};
use cocoa::appkit::{NSWorkspace, NSRunningApplication};
use objc::runtime::{Object, Sel};
use objc::{msg_send, sel, sel_impl};

use super::{PlatformTracker, WindowInfo, InputEvent, MouseButton};

pub struct MacOSTracker {
    events: Arc<Mutex<Vec<InputEvent>>>,
}

impl MacOSTracker {
    pub fn new() -> Self {
        Self {
            events: Arc::new(Mutex::new(Vec::new())),
        }
    }
    
    fn get_frontmost_app() -> Result<(String, Option<String>)> {
        unsafe {
            let workspace: id = msg_send![class!(NSWorkspace), sharedWorkspace];
            let frontmost_app: id = msg_send![workspace, frontmostApplication];
            
            if frontmost_app == nil {
                return Err(anyhow!("No frontmost application"));
            }
            
            let localized_name: id = msg_send![frontmost_app, localizedName];
            let bundle_id: id = msg_send![frontmost_app, bundleIdentifier];
            
            let name = if localized_name != nil {
                let name_str: id = msg_send![localized_name, UTF8String];
                std::ffi::CStr::from_ptr(name_str as *const i8)
                    .to_string_lossy()
                    .to_string()
            } else {
                "Unknown".to_string()
            };
            
            let bundle = if bundle_id != nil {
                let bundle_str: id = msg_send![bundle_id, UTF8String];
                Some(
                    std::ffi::CStr::from_ptr(bundle_str as *const i8)
                        .to_string_lossy()
                        .to_string()
                )
            } else {
                None
            };
            
            Ok((name, bundle))
        }
    }
}

#[async_trait]
impl PlatformTracker for MacOSTracker {
    async fn get_active_window(&self) -> Result<WindowInfo> {
        let (process_name, bundle_id) = Self::get_frontmost_app()?;
        
        Ok(WindowInfo {
            process_name,
            window_title: "".to_string(), // macOS doesn't easily provide window titles
            bundle_id,
            x: None,
            y: None,
            width: None,
            height: None,
        })
    }
    
    async fn start_input_tracking(&self) -> Result<()> {
        // This would require setting up CGEventTap for real implementation
        // For now, returning Ok to make it compile
        Ok(())
    }
    
    async fn stop_input_tracking(&self) -> Result<()> {
        Ok(())
    }
    
    fn get_input_events(&self) -> Vec<InputEvent> {
        let mut events = self.events.lock().unwrap();
        let result = events.clone();
        events.clear();
        result
    }
}

// Helper to get Objective-C class
fn class(name: &str) -> *mut Object {
    unsafe {
        objc::runtime::Class::get(name)
            .expect(&format!("Class {} not found", name))
            as *mut Object
    }
}