use anyhow::Result;
use sqlx::{Pool, Sqlite, SqlitePool, Row};
use std::path::Path;

use crate::models::*;

pub struct Database {
    pool: Pool<Sqlite>,
}

impl Database {
    pub async fn new(path: &Path) -> Result<Self> {
        // Ensure parent directory exists
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        
        let url = format!("sqlite:{}?mode=rwc", path.display());
        let pool = SqlitePool::connect(&url).await?;
        
        let db = Self { pool };
        db.migrate().await?;
        Ok(db)
    }
    
    async fn migrate(&self) -> Result<()> {
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS processes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                bundle_id TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
            "#,
        )
        .execute(&self.pool)
        .await?;
        
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS windows (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                process_id INTEGER NOT NULL,
                title TEXT NOT NULL,
                x INTEGER,
                y INTEGER,
                width INTEGER,
                height INTEGER,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (process_id) REFERENCES processes(id)
            )
            "#,
        )
        .execute(&self.pool)
        .await?;
        
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS keys (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                window_id INTEGER NOT NULL,
                encrypted_keys BLOB NOT NULL,
                key_count INTEGER NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (window_id) REFERENCES windows(id)
            )
            "#,
        )
        .execute(&self.pool)
        .await?;
        
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS clicks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                window_id INTEGER NOT NULL,
                x INTEGER NOT NULL,
                y INTEGER NOT NULL,
                button TEXT NOT NULL,
                double_click BOOLEAN DEFAULT FALSE,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (window_id) REFERENCES windows(id)
            )
            "#,
        )
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    pub async fn insert_process(&self, name: &str, bundle_id: Option<&str>) -> Result<i64> {
        let result = sqlx::query(
            r#"
            INSERT OR IGNORE INTO processes (name, bundle_id)
            VALUES (?, ?)
            "#,
        )
        .bind(name)
        .bind(bundle_id)
        .execute(&self.pool)
        .await?;
        
        if result.rows_affected() == 0 {
            let row = sqlx::query("SELECT id FROM processes WHERE name = ?")
                .bind(name)
                .fetch_one(&self.pool)
                .await?;
            Ok(row.get::<i64, _>("id"))
        } else {
            Ok(result.last_insert_rowid())
        }
    }
    
    pub async fn insert_window(
        &self,
        process_id: i64,
        title: &str,
        x: Option<i32>,
        y: Option<i32>,
        width: Option<i32>,
        height: Option<i32>,
    ) -> Result<i64> {
        let result = sqlx::query(
            r#"
            INSERT INTO windows (process_id, title, x, y, width, height)
            VALUES (?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(process_id)
        .bind(title)
        .bind(x)
        .bind(y)
        .bind(width)
        .bind(height)
        .execute(&self.pool)
        .await?;
        
        Ok(result.last_insert_rowid())
    }
    
    pub async fn insert_keys(
        &self,
        window_id: i64,
        encrypted_keys: Vec<u8>,
        key_count: i32,
    ) -> Result<i64> {
        let result = sqlx::query(
            r#"
            INSERT INTO keys (window_id, encrypted_keys, key_count)
            VALUES (?, ?, ?)
            "#,
        )
        .bind(window_id)
        .bind(encrypted_keys)
        .bind(key_count)
        .execute(&self.pool)
        .await?;
        
        Ok(result.last_insert_rowid())
    }
    
    pub async fn insert_click(
        &self,
        window_id: i64,
        x: i32,
        y: i32,
        button: &str,
        double_click: bool,
    ) -> Result<i64> {
        let result = sqlx::query(
            r#"
            INSERT INTO clicks (window_id, x, y, button, double_click)
            VALUES (?, ?, ?, ?, ?)
            "#,
        )
        .bind(window_id)
        .bind(x)
        .bind(y)
        .bind(button)
        .bind(double_click)
        .execute(&self.pool)
        .await?;
        
        Ok(result.last_insert_rowid())
    }
    
    pub async fn get_stats(&self) -> Result<ActivityStats> {
        let keystrokes_row = sqlx::query("SELECT COALESCE(SUM(key_count), 0) as total FROM keys")
            .fetch_one(&self.pool)
            .await?;
        let keystrokes = keystrokes_row.get::<i64, _>("total");
        
        let clicks_row = sqlx::query("SELECT COUNT(*) as total FROM clicks")
            .fetch_one(&self.pool)
            .await?;
        let clicks = clicks_row.get::<i64, _>("total");
        
        let windows_row = sqlx::query("SELECT COUNT(*) as total FROM windows")
            .fetch_one(&self.pool)
            .await?;
        let windows = windows_row.get::<i64, _>("total");
        
        let processes_row = sqlx::query("SELECT COUNT(*) as total FROM processes")
            .fetch_one(&self.pool)
            .await?;
        let processes = processes_row.get::<i64, _>("total");
        
        let most_active_process = sqlx::query(
            r#"
            SELECT p.name
            FROM processes p
            JOIN windows w ON p.id = w.process_id
            GROUP BY p.id
            ORDER BY COUNT(*) DESC
            LIMIT 1
            "#
        )
        .fetch_optional(&self.pool)
        .await?
        .map(|row| row.get::<String, _>("name"));
        
        Ok(ActivityStats {
            total_keystrokes: keystrokes,
            total_clicks: clicks,
            total_windows: windows,
            total_processes: processes,
            session_duration: 0,
            most_active_process,
            most_active_window: None,
        })
    }
}