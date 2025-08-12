use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Process {
    pub id: i64,
    pub name: String,
    pub bundle_id: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Window {
    pub id: i64,
    pub process_id: i64,
    pub title: String,
    pub x: Option<i32>,
    pub y: Option<i32>,
    pub width: Option<i32>,
    pub height: Option<i32>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Keys {
    pub id: i64,
    pub window_id: i64,
    pub encrypted_keys: Vec<u8>,
    pub key_count: i32,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Click {
    pub id: i64,
    pub window_id: i64,
    pub x: i32,
    pub y: i32,
    pub button: String,
    pub double_click: bool,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActivityStats {
    pub total_keystrokes: i64,
    pub total_clicks: i64,
    pub total_windows: i64,
    pub total_processes: i64,
    pub session_duration: i64,
    pub most_active_process: Option<String>,
    pub most_active_window: Option<String>,
}