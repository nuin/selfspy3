require "db"
require "sqlite3"
require "json"
require "log"
require "crypto/bcrypt"

module Selfspy
  # Database storage and data management
  class Storage
    Log = ::Log.for(self)

    getter db_path : String
    private getter db : DB::Database?
    private getter initialized : Bool = false

    def initialize(@db_path : String)
      @db = nil
    end

    def initialize!
      unless @initialized
        setup_database
        create_tables
        @initialized = true
        Log.info { "Database initialized at #{@db_path}" }
      end
    end

    def initialized?
      @initialized
    end

    def close
      if @db
        @db.not_nil!.close
        @db = nil
        @initialized = false
        Log.info { "Database connection closed" }
      end
    end

    def insert_keystroke(key : String, modifiers : Array(String), window_id : Int64?, encrypted : Bool = false)
      ensure_connection

      db.not_nil!.exec(
        "INSERT INTO keystrokes (timestamp, key_data, modifiers, window_id, encrypted) VALUES (?, ?, ?, ?, ?)",
        Time.utc.to_unix_ms,
        key,
        modifiers.join(","),
        window_id,
        encrypted ? 1 : 0
      )
    end

    def insert_mouse_event(type : String, x : Int32, y : Int32, button : String?, window_id : Int64?)
      ensure_connection

      db.not_nil!.exec(
        "INSERT INTO mouse_events (timestamp, event_type, x, y, button, window_id) VALUES (?, ?, ?, ?, ?, ?)",
        Time.utc.to_unix_ms,
        type,
        x,
        y,
        button,
        window_id
      )
    end

    def insert_window_event(title : String, app_name : String, bundle_id : String?, pid : Int32) : Int64
      ensure_connection

      # Check if window already exists
      existing = db.not_nil!.query_one?(
        "SELECT id FROM windows WHERE title = ? AND app_name = ? AND pid = ?",
        title, app_name, pid, as: Int64
      )

      if existing
        # Update last seen timestamp
        db.not_nil!.exec(
          "UPDATE windows SET last_seen = ? WHERE id = ?",
          Time.utc.to_unix_ms,
          existing
        )
        return existing
      else
        # Insert new window
        db.not_nil!.exec(
          "INSERT INTO windows (title, app_name, bundle_id, pid, first_seen, last_seen) VALUES (?, ?, ?, ?, ?, ?)",
          title, app_name, bundle_id, pid, Time.utc.to_unix_ms, Time.utc.to_unix_ms
        )
        return db.not_nil!.scalar("SELECT last_insert_rowid()").as(Int64)
      end
    end

    def insert_session_start
      ensure_connection

      db.not_nil!.exec(
        "INSERT INTO sessions (start_time, end_time) VALUES (?, NULL)",
        Time.utc.to_unix_ms
      )
      db.not_nil!.scalar("SELECT last_insert_rowid()").as(Int64)
    end

    def update_session_end(session_id : Int64)
      ensure_connection

      db.not_nil!.exec(
        "UPDATE sessions SET end_time = ? WHERE id = ?",
        Time.utc.to_unix_ms,
        session_id
      )
    end

    def get_stats(days : Int32) : ActivityStats
      ensure_connection

      since = Time.utc - days.days
      since_ms = since.to_unix_ms

      # Count keystrokes
      keystrokes = db.not_nil!.scalar(
        "SELECT COUNT(*) FROM keystrokes WHERE timestamp > ?",
        since_ms
      ).as(Int64)

      # Count mouse clicks
      clicks = db.not_nil!.scalar(
        "SELECT COUNT(*) FROM mouse_events WHERE timestamp > ? AND event_type = 'click'",
        since_ms
      ).as(Int64)

      # Count window changes
      window_changes = db.not_nil!.scalar(
        "SELECT COUNT(*) FROM windows WHERE first_seen > ?",
        since_ms
      ).as(Int64)

      # Calculate active time (sessions)
      active_time = db.not_nil!.scalar(
        "SELECT COALESCE(SUM(COALESCE(end_time, ?) - start_time), 0) FROM sessions WHERE start_time > ?",
        Time.utc.to_unix_ms,
        since_ms
      ).as(Int64) // 1000  # Convert to seconds

      # Get top applications
      top_apps = get_top_applications(days)

      ActivityStats.new(
        days: days,
        keystrokes: keystrokes,
        clicks: clicks,
        window_changes: window_changes,
        active_time: active_time,
        top_apps: top_apps
      )
    end

    def get_top_applications(days : Int32, limit : Int32 = 10) : Array(AppUsage)
      ensure_connection

      since = Time.utc - days.days
      since_ms = since.to_unix_ms

      apps = [] of AppUsage

      db.not_nil!.query(
        "SELECT app_name, COUNT(*) as usage_count,
         SUM(last_seen - first_seen) as total_time
         FROM windows
         WHERE first_seen > ?
         GROUP BY app_name
         ORDER BY usage_count DESC
         LIMIT ?",
        since_ms, limit
      ) do |rs|
        rs.each do
          app_name = rs.read(String)
          usage_count = rs.read(Int64)
          total_time = rs.read(Int64)

          # Calculate percentage (simplified)
          percentage = usage_count.to_f64 / 100.0  # This would need proper calculation

          apps << AppUsage.new(
            name: app_name,
            usage_count: usage_count,
            total_time: total_time,
            percentage: percentage
          )
        end
      end

      apps
    end

    def export_json(days : Int32) : String
      ensure_connection

      since = Time.utc - days.days
      since_ms = since.to_unix_ms

      data = {
        "export_timestamp" => Time.utc.to_rfc3339,
        "days" => days,
        "stats" => get_stats(days),
        "keystrokes" => get_keystroke_data(since_ms),
        "mouse_events" => get_mouse_data(since_ms),
        "windows" => get_window_data(since_ms),
        "sessions" => get_session_data(since_ms)
      }

      data.to_json
    end

    def export_csv(days : Int32) : String
      ensure_connection

      since = Time.utc - days.days
      since_ms = since.to_unix_ms

      csv_data = String::Builder.new

      # Export keystrokes
      csv_data << "# Keystrokes\n"
      csv_data << "timestamp,key_data,modifiers,window_id\n"

      db.not_nil!.query(
        "SELECT timestamp, key_data, modifiers, window_id FROM keystrokes WHERE timestamp > ? ORDER BY timestamp",
        since_ms
      ) do |rs|
        rs.each do
          timestamp = rs.read(Int64)
          key_data = rs.read(String)
          modifiers = rs.read(String)
          window_id = rs.read(Int64?)

          csv_data << "#{timestamp},\"#{key_data}\",\"#{modifiers}\",#{window_id}\n"
        end
      end

      csv_data << "\n# Mouse Events\n"
      csv_data << "timestamp,event_type,x,y,button,window_id\n"

      db.not_nil!.query(
        "SELECT timestamp, event_type, x, y, button, window_id FROM mouse_events WHERE timestamp > ? ORDER BY timestamp",
        since_ms
      ) do |rs|
        rs.each do
          timestamp = rs.read(Int64)
          event_type = rs.read(String)
          x = rs.read(Int32)
          y = rs.read(Int32)
          button = rs.read(String?)
          window_id = rs.read(Int64?)

          csv_data << "#{timestamp},#{event_type},#{x},#{y},#{button},#{window_id}\n"
        end
      end

      csv_data.to_s
    end

    def export_sql(days : Int32) : String
      ensure_connection

      since = Time.utc - days.days
      since_ms = since.to_unix_ms

      sql_data = String::Builder.new
      sql_data << "-- Selfspy Export SQL\n"
      sql_data << "-- Generated: #{Time.utc.to_rfc3339}\n"
      sql_data << "-- Days: #{days}\n\n"

      # Include table definitions
      sql_data << get_table_definitions
      sql_data << "\n"

      # Export data
      export_table_data(sql_data, "keystrokes", since_ms)
      export_table_data(sql_data, "mouse_events", since_ms)
      export_table_data(sql_data, "windows", since_ms)
      export_table_data(sql_data, "sessions", since_ms)

      sql_data.to_s
    end

    def cleanup_old_data(days : Int32)
      ensure_connection

      cutoff = Time.utc - days.days
      cutoff_ms = cutoff.to_unix_ms

      deleted_keystrokes = db.not_nil!.exec(
        "DELETE FROM keystrokes WHERE timestamp < ?",
        cutoff_ms
      ).rows_affected

      deleted_mouse = db.not_nil!.exec(
        "DELETE FROM mouse_events WHERE timestamp < ?",
        cutoff_ms
      ).rows_affected

      deleted_windows = db.not_nil!.exec(
        "DELETE FROM windows WHERE last_seen < ?",
        cutoff_ms
      ).rows_affected

      deleted_sessions = db.not_nil!.exec(
        "DELETE FROM sessions WHERE start_time < ?",
        cutoff_ms
      ).rows_affected

      Log.info { "Cleaned up old data: #{deleted_keystrokes} keystrokes, #{deleted_mouse} mouse events, #{deleted_windows} windows, #{deleted_sessions} sessions" }

      # Vacuum database to reclaim space
      db.not_nil!.exec("VACUUM")
    end

    private def setup_database
      Dir.mkdir_p(File.dirname(@db_path))
      @db = DB.open("sqlite3://#{@db_path}")

      # Set pragmas for performance and reliability
      db.not_nil!.exec("PRAGMA journal_mode = WAL")
      db.not_nil!.exec("PRAGMA synchronous = NORMAL")
      db.not_nil!.exec("PRAGMA cache_size = 10000")
      db.not_nil!.exec("PRAGMA temp_store = MEMORY")
      db.not_nil!.exec("PRAGMA foreign_keys = ON")
    end

    private def create_tables
      ensure_connection

      # Sessions table
      db.not_nil!.exec <<-SQL
        CREATE TABLE IF NOT EXISTS sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          start_time INTEGER NOT NULL,
          end_time INTEGER
        )
      SQL

      # Windows table
      db.not_nil!.exec <<-SQL
        CREATE TABLE IF NOT EXISTS windows (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          app_name TEXT NOT NULL,
          bundle_id TEXT,
          pid INTEGER NOT NULL,
          first_seen INTEGER NOT NULL,
          last_seen INTEGER NOT NULL
        )
      SQL

      # Keystrokes table
      db.not_nil!.exec <<-SQL
        CREATE TABLE IF NOT EXISTS keystrokes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp INTEGER NOT NULL,
          key_data TEXT NOT NULL,
          modifiers TEXT,
          window_id INTEGER,
          encrypted INTEGER DEFAULT 0,
          FOREIGN KEY (window_id) REFERENCES windows (id)
        )
      SQL

      # Mouse events table
      db.not_nil!.exec <<-SQL
        CREATE TABLE IF NOT EXISTS mouse_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp INTEGER NOT NULL,
          event_type TEXT NOT NULL,
          x INTEGER NOT NULL,
          y INTEGER NOT NULL,
          button TEXT,
          window_id INTEGER,
          FOREIGN KEY (window_id) REFERENCES windows (id)
        )
      SQL

      # Create indexes for performance
      create_indexes
    end

    private def create_indexes
      ensure_connection

      db.not_nil!.exec("CREATE INDEX IF NOT EXISTS idx_keystrokes_timestamp ON keystrokes (timestamp)")
      db.not_nil!.exec("CREATE INDEX IF NOT EXISTS idx_keystrokes_window_id ON keystrokes (window_id)")
      db.not_nil!.exec("CREATE INDEX IF NOT EXISTS idx_mouse_events_timestamp ON mouse_events (timestamp)")
      db.not_nil!.exec("CREATE INDEX IF NOT EXISTS idx_mouse_events_window_id ON mouse_events (window_id)")
      db.not_nil!.exec("CREATE INDEX IF NOT EXISTS idx_windows_app_name ON windows (app_name)")
      db.not_nil!.exec("CREATE INDEX IF NOT EXISTS idx_windows_first_seen ON windows (first_seen)")
      db.not_nil!.exec("CREATE INDEX IF NOT EXISTS idx_sessions_start_time ON sessions (start_time)")
    end

    private def ensure_connection
      unless @db
        raise "Database not initialized. Call initialize first."
      end
    end

    private def db
      @db.not_nil!
    end

    private def get_keystroke_data(since_ms : Int64)
      data = [] of Hash(String, String | Int64 | Nil)

      db.not_nil!.query(
        "SELECT timestamp, key_data, modifiers, window_id FROM keystrokes WHERE timestamp > ? ORDER BY timestamp",
        since_ms
      ) do |rs|
        rs.each do
          data << {
            "timestamp" => rs.read(Int64),
            "key_data" => rs.read(String),
            "modifiers" => rs.read(String),
            "window_id" => rs.read(Int64?)
          }
        end
      end

      data
    end

    private def get_mouse_data(since_ms : Int64)
      data = [] of Hash(String, String | Int32 | Int64 | Nil)

      db.not_nil!.query(
        "SELECT timestamp, event_type, x, y, button, window_id FROM mouse_events WHERE timestamp > ? ORDER BY timestamp",
        since_ms
      ) do |rs|
        rs.each do
          data << {
            "timestamp" => rs.read(Int64),
            "event_type" => rs.read(String),
            "x" => rs.read(Int32),
            "y" => rs.read(Int32),
            "button" => rs.read(String?),
            "window_id" => rs.read(Int64?)
          }
        end
      end

      data
    end

    private def get_window_data(since_ms : Int64)
      data = [] of Hash(String, String | Int32 | Int64 | Nil)

      db.not_nil!.query(
        "SELECT id, title, app_name, bundle_id, pid, first_seen, last_seen FROM windows WHERE first_seen > ? ORDER BY first_seen",
        since_ms
      ) do |rs|
        rs.each do
          data << {
            "id" => rs.read(Int64),
            "title" => rs.read(String),
            "app_name" => rs.read(String),
            "bundle_id" => rs.read(String?),
            "pid" => rs.read(Int32),
            "first_seen" => rs.read(Int64),
            "last_seen" => rs.read(Int64)
          }
        end
      end

      data
    end

    private def get_session_data(since_ms : Int64)
      data = [] of Hash(String, Int64 | Nil)

      db.not_nil!.query(
        "SELECT id, start_time, end_time FROM sessions WHERE start_time > ? ORDER BY start_time",
        since_ms
      ) do |rs|
        rs.each do
          data << {
            "id" => rs.read(Int64),
            "start_time" => rs.read(Int64),
            "end_time" => rs.read(Int64?)
          }
        end
      end

      data
    end

    private def get_table_definitions : String
      sql = String::Builder.new

      # Get CREATE TABLE statements from sqlite_master
      db.not_nil!.query("SELECT sql FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'") do |rs|
        rs.each do
          sql << rs.read(String) << ";\n"
        end
      end

      sql.to_s
    end

    private def export_table_data(sql_data : String::Builder, table_name : String, since_ms : Int64)
      sql_data << "-- #{table_name} data\n"

      if table_name == "windows"
        condition = "WHERE first_seen > #{since_ms}"
      else
        condition = "WHERE timestamp > #{since_ms}"
      end

      begin
        db.not_nil!.query("SELECT * FROM #{table_name} #{condition}") do |rs|
          while rs.move_next
            values = [] of String
            rs.column_count.times do |i|
              value = rs.read
              case value
              when String
                values << "'#{value.gsub("'", "''")}'"
              when Nil
                values << "NULL"
              else
                values << value.to_s
              end
            end

            sql_data << "INSERT INTO #{table_name} VALUES (#{values.join(", ")});\n"
          end
        end
      rescue ex : Exception
        Log.warn { "Failed to export #{table_name}: #{ex.message}" }
      end

      sql_data << "\n"
    end
  end

  # Statistics data structures
  struct ActivityStats
    include JSON::Serializable

    getter days : Int32
    getter keystrokes : Int64
    getter clicks : Int64
    getter window_changes : Int64
    getter active_time : Int64
    getter top_apps : Array(AppUsage)

    def initialize(@days : Int32, @keystrokes : Int64, @clicks : Int64, @window_changes : Int64, @active_time : Int64, @top_apps : Array(AppUsage))
    end
  end

  struct AppUsage
    include JSON::Serializable

    getter name : String
    getter usage_count : Int64
    getter total_time : Int64
    getter percentage : Float64

    def initialize(@name : String, @usage_count : Int64, @total_time : Int64, @percentage : Float64)
    end
  end
end