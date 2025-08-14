/// Storage layer for Selfspy F# implementation
namespace Selfspy.Storage

open System
open System.Data.SQLite
open System.Threading.Tasks
open Newtonsoft.Json
open Selfspy.Types

type Storage = {
    ConnectionString: string
    mutable IsInitialized: bool
}

let createStorage (databasePath: string) : Async<Storage> =
    async {
        let connectionString = $"Data Source={databasePath};Version=3;"
        return { ConnectionString = connectionString; IsInitialized = false }
    }

let initializeStorage (storage: Storage) : Async<unit> =
    async {
        use connection = new SQLiteConnection(storage.ConnectionString)
        do! connection.OpenAsync() |> Async.AwaitTask
        
        let createTables = [
            """CREATE TABLE IF NOT EXISTS processes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                bundle_id TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )"""
            """CREATE TABLE IF NOT EXISTS windows (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                process_id INTEGER,
                title TEXT,
                x INTEGER, y INTEGER,
                width INTEGER, height INTEGER,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (process_id) REFERENCES processes (id)
            )"""
            """CREATE TABLE IF NOT EXISTS keys (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                process_id INTEGER,
                keys TEXT,
                count INTEGER DEFAULT 1,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (process_id) REFERENCES processes (id)
            )"""
        ]
        
        for sql in createTables do
            use command = new SQLiteCommand(sql, connection)
            do! command.ExecuteNonQueryAsync() |> Async.AwaitTask |> Async.Ignore
        
        storage.IsInitialized <- true
    }

let closeStorage (storage: Storage) : Async<unit> =
    async {
        // Connection cleanup handled by using statements
        storage.IsInitialized <- false
    }

let getStats (storage: Storage) (days: int) : Async<ActivityStats> =
    async {
        // Placeholder implementation
        let topApps = [
            { Name = "Code Editor"; Percentage = 45.2; Duration = 6683L; Events = 5234L }
            { Name = "Web Browser"; Percentage = 32.1; Duration = 4736L; Events = 3892L }
            { Name = "Terminal"; Percentage = 15.7; Duration = 2318L; Events = 2156L }
        ]
        
        return {
            Keystrokes = 12547L
            Clicks = 3821L
            WindowChanges = 342L
            ActiveTimeSeconds = 14760L
            TopApps = topApps
            DateRange = (DateTime.UtcNow.AddDays(-float days), DateTime.UtcNow)
        }
    }

let exportJson (storage: Storage) (days: int) : Async<string> =
    async {
        let! stats = getStats storage days
        return JsonConvert.SerializeObject(stats, Formatting.Indented)
    }

let exportCsv (storage: Storage) (days: int) : Async<string> =
    async {
        let! stats = getStats storage days
        return $"metric,value\nkeystrokes,{stats.Keystrokes}\nclicks,{stats.Clicks}\nwindow_changes,{stats.WindowChanges}\nactive_time_seconds,{stats.ActiveTimeSeconds}"
    }

let exportSql (storage: Storage) (days: int) : Async<string> =
    async {
        let! stats = getStats storage days
        return $"""-- Selfspy Activity Export
CREATE TABLE stats (metric TEXT, value INTEGER);
INSERT INTO stats VALUES ('keystrokes', {stats.Keystrokes});
INSERT INTO stats VALUES ('clicks', {stats.Clicks});
INSERT INTO stats VALUES ('window_changes', {stats.WindowChanges});
INSERT INTO stats VALUES ('active_time_seconds', {stats.ActiveTimeSeconds});"""
    }