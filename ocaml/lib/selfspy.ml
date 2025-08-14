(** Selfspy - OCaml Implementation
    
    Core modules for industrial-strength functional activity monitoring *)

(** Configuration management with strong types *)
module Config = struct
  type t = {
    data_dir : string;
    database_path : string;
    capture_text : bool;
    capture_mouse : bool;
    capture_windows : bool;
    update_interval_ms : int;
    encryption_enabled : bool;
    debug : bool;
    privacy_mode : bool;
    exclude_applications : string list;
    max_database_size_mb : int;
  }

  let default_config () =
    let home_dir = try Sys.getenv "HOME" with Not_found -> "/tmp" in
    let data_dir = match Sys.os_type with
      | "Win32" -> Filename.concat (Sys.getenv "APPDATA") "selfspy"
      | "Unix" -> 
        if Sys.file_exists "/System/Library" then
          Filename.concat home_dir "Library/Application Support/selfspy"
        else
          Filename.concat home_dir ".local/share/selfspy"
      | _ -> Filename.concat home_dir ".selfspy"
    in
    {
      data_dir;
      database_path = Filename.concat data_dir "selfspy.db";
      capture_text = true;
      capture_mouse = true;
      capture_windows = true;
      update_interval_ms = 100;
      encryption_enabled = true;
      debug = false;
      privacy_mode = false;
      exclude_applications = [];
      max_database_size_mb = 500;
    }

  let load () =
    let open Lwt.Syntax in
    let config = default_config () in
    (* Create data directory if it doesn't exist *)
    let%lwt () = 
      if not (Sys.file_exists config.data_dir) then
        Lwt_unix.mkdir config.data_dir 0o755
      else
        Lwt.return_unit
    in
    Lwt.return config
end

(** Core data types with algebraic data types *)
module Types = struct
  type window_info = {
    title : string;
    application : string;
    bundle_id : string;
    process_id : int;
    x : int;
    y : int;
    width : int;
    height : int;
    timestamp : float;
  }

  type key_event = {
    key : string;
    application : string;
    process_id : int;
    count : int;
    encrypted : bool;
    timestamp : float;
  }

  type mouse_event = {
    x : int;
    y : int;
    button : int;
    event_type : string;
    process_id : int;
    timestamp : float;
  }

  type permissions = {
    accessibility : bool;
    input_monitoring : bool;
    screen_recording : bool;
  }

  type system_info = {
    platform : string;
    architecture : string;
    ocaml_version : string;
    hostname : string;
    username : string;
  }

  type app_usage = {
    name : string;
    percentage : float;
    duration : int;
    events : int;
  }

  type activity_stats = {
    keystrokes : int;
    clicks : int;
    window_changes : int;
    active_time_seconds : int;
    top_apps : app_usage list;
  }
end

(** Platform abstraction with pattern matching *)
module Platform = struct
  open Types

  let get_os () = match Sys.os_type with
    | "Win32" -> "windows"
    | "Unix" ->
      if Sys.file_exists "/System/Library" then "darwin"
      else if Sys.file_exists "/proc" then "linux"
      else "unix"
    | _ -> "unknown"

  let check_permissions () =
    let open Lwt.Syntax in
    match get_os () with
    | "darwin" ->
      (* Check macOS permissions via external commands *)
      let%lwt accessibility = Lwt.return true in (* Placeholder *)
      let%lwt input_monitoring = Lwt.return true in (* Placeholder *)
      Lwt.return { accessibility; input_monitoring; screen_recording = false }
    | "linux" ->
      (* Check for display server *)
      let has_display = 
        try 
          ignore (Sys.getenv "DISPLAY");
          true
        with Not_found -> 
          try
            ignore (Sys.getenv "WAYLAND_DISPLAY");
            true
          with Not_found -> false
      in
      Lwt.return { accessibility = has_display; input_monitoring = has_display; screen_recording = has_display }
    | "windows" ->
      Lwt.return { accessibility = true; input_monitoring = true; screen_recording = true }
    | _ ->
      Lwt.return { accessibility = true; input_monitoring = true; screen_recording = false }

  let has_all_permissions permissions =
    permissions.accessibility && permissions.input_monitoring

  let request_permissions () =
    let open Lwt.Syntax in
    match get_os () with
    | "darwin" ->
      let%lwt () = Lwt_io.printl "Please grant accessibility permissions in System Preferences" in
      let%lwt () = Lwt_io.printl "Security & Privacy > Privacy > Accessibility" in
      Lwt.return true
    | _ ->
      Lwt.return true

  let get_system_info () =
    let hostname = try Unix.gethostname () with _ -> "localhost" in
    let username = try Sys.getenv "USER" with Not_found -> 
      try Sys.getenv "USERNAME" with Not_found -> "unknown" in
    {
      platform = get_os ();
      architecture = "x64"; (* Placeholder *)
      ocaml_version = Sys.ocaml_version;
      hostname;
      username;
    }

  let get_current_window () =
    (* Placeholder implementation *)
    {
      title = "Sample Window";
      application = "Sample Application";
      bundle_id = "";
      process_id = 0;
      x = 0;
      y = 0;
      width = 1920;
      height = 1080;
      timestamp = Unix.time ();
    }
end

(** Storage layer with functional error handling *)
module Storage = struct
  open Types

  type t = {
    db_path : string;
    mutable connection : Sqlite3.db option;
  }

  let create db_path = Lwt.return { db_path; connection = None }

  let initialize storage =
    let open Lwt.Syntax in
    let%lwt () = Lwt_io.printl ("Initializing database: " ^ storage.db_path) in
    let db = Sqlite3.db_open storage.db_path in
    storage.connection <- Some db;
    
    (* Create tables *)
    let create_tables = [
      "CREATE TABLE IF NOT EXISTS processes (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         name TEXT NOT NULL,
         bundle_id TEXT,
         created_at DATETIME DEFAULT CURRENT_TIMESTAMP
       )";
      "CREATE TABLE IF NOT EXISTS windows (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         process_id INTEGER,
         title TEXT,
         x INTEGER, y INTEGER,
         width INTEGER, height INTEGER,
         created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
         FOREIGN KEY (process_id) REFERENCES processes (id)
       )";
      "CREATE TABLE IF NOT EXISTS keys (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         process_id INTEGER,
         keys TEXT,
         count INTEGER DEFAULT 1,
         created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
         FOREIGN KEY (process_id) REFERENCES processes (id)
       )";
      "CREATE TABLE IF NOT EXISTS clicks (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         process_id INTEGER,
         x INTEGER, y INTEGER,
         button INTEGER,
         event_type TEXT,
         created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
         FOREIGN KEY (process_id) REFERENCES processes (id)
       )";
    ] in
    
    List.iter (fun sql ->
      match Sqlite3.exec db sql with
      | Sqlite3.Rc.OK -> ()
      | rc -> failwith ("Failed to create table: " ^ Sqlite3.Rc.to_string rc)
    ) create_tables;
    
    Lwt.return_unit

  let close storage =
    let open Lwt.Syntax in
    match storage.connection with
    | Some db ->
      let%lwt () = Lwt_io.printl "Closing database connection" in
      ignore (Sqlite3.db_close db);
      storage.connection <- None;
      Lwt.return_unit
    | None ->
      Lwt.return_unit

  let get_stats storage days =
    let open Lwt.Syntax in
    match storage.connection with
    | Some db ->
      (* Placeholder: Would execute actual SQL queries *)
      let top_apps = [
        { name = "Code Editor"; percentage = 45.2; duration = 6683; events = 5234 };
        { name = "Web Browser"; percentage = 32.1; duration = 4736; events = 3892 };
        { name = "Terminal"; percentage = 15.7; duration = 2318; events = 2156 };
      ] in
      Lwt.return {
        keystrokes = 12547;
        clicks = 3821;
        window_changes = 342;
        active_time_seconds = 14760;
        top_apps;
      }
    | None ->
      Lwt.fail_with "Database not initialized"

  let export_json storage days =
    let open Lwt.Syntax in
    let%lwt stats = get_stats storage days in
    let json = `Assoc [
      ("keystrokes", `Int stats.keystrokes);
      ("clicks", `Int stats.clicks);
      ("window_changes", `Int stats.window_changes);
      ("active_time_seconds", `Int stats.active_time_seconds);
    ] in
    Lwt.return (Yojson.Basic.pretty_to_string json)

  let export_csv storage days =
    let open Lwt.Syntax in
    let%lwt stats = get_stats storage days in
    let csv = Printf.sprintf "metric,value\nkeystrokes,%d\nclicks,%d\nwindow_changes,%d\nactive_time_seconds,%d"
      stats.keystrokes stats.clicks stats.window_changes stats.active_time_seconds in
    Lwt.return csv

  let export_sql storage days =
    let open Lwt.Syntax in
    let%lwt stats = get_stats storage days in
    let sql = Printf.sprintf {|-- Selfspy Activity Export
CREATE TABLE stats (metric TEXT, value INTEGER);
INSERT INTO stats VALUES ('keystrokes', %d);
INSERT INTO stats VALUES ('clicks', %d);
INSERT INTO stats VALUES ('window_changes', %d);
INSERT INTO stats VALUES ('active_time_seconds', %d);|}
      stats.keystrokes stats.clicks stats.window_changes stats.active_time_seconds in
    Lwt.return sql
end

(** Statistics and visualization *)
module Stats = struct
  open Types

  let format_number num =
    if num >= 1_000_000 then
      Printf.sprintf "%.1fM" (float_of_int num /. 1_000_000.0)
    else if num >= 1_000 then
      Printf.sprintf "%.1fK" (float_of_int num /. 1_000.0)
    else
      string_of_int num

  let format_duration seconds =
    let hours = seconds / 3600 in
    let minutes = (seconds mod 3600) / 60 in
    if hours > 0 then
      Printf.sprintf "%dh %dm" hours minutes
    else
      Printf.sprintf "%dm" minutes

  let print_formatted stats days =
    Printf.printf "\n";
    Printf.printf "📊 Selfspy Activity Statistics (Last %d days)\n" days;
    Printf.printf "==================================================\n";
    Printf.printf "\n";
    Printf.printf "⌨️  Keystrokes: %s\n" (format_number stats.keystrokes);
    Printf.printf "🖱️  Mouse clicks: %s\n" (format_number stats.clicks);
    Printf.printf "🪟  Window changes: %s\n" (format_number stats.window_changes);
    Printf.printf "⏰ Active time: %s\n" (format_duration stats.active_time_seconds);
    
    if List.length stats.top_apps > 0 then (
      Printf.printf "📱 Most used applications:\n";
      List.iteri (fun i app ->
        Printf.printf "   %d. %s (%.1f%%)\n" (i + 1) app.name app.percentage
      ) stats.top_apps
    );
    Printf.printf "\n"

  let to_json stats =
    let app_to_json app = `Assoc [
      ("name", `String app.name);
      ("percentage", `Float app.percentage);
      ("duration", `Int app.duration);
      ("events", `Int app.events);
    ] in
    let json = `Assoc [
      ("keystrokes", `Int stats.keystrokes);
      ("clicks", `Int stats.clicks);
      ("window_changes", `Int stats.window_changes);
      ("active_time_seconds", `Int stats.active_time_seconds);
      ("top_apps", `List (List.map app_to_json stats.top_apps));
    ] in
    Yojson.Basic.pretty_to_string json
end

(** Activity Monitor with cooperative concurrency *)
module Monitor = struct
  open Types

  type t = {
    config : Config.t;
    storage : Storage.t;
    mutable running : bool;
    mutable events_processed : int;
  }

  let create config storage = {
    config;
    storage;
    running = false;
    events_processed = 0;
  }

  let start monitor =
    let open Lwt.Syntax in
    monitor.running <- true;
    
    (* Start monitoring loop with cooperative concurrency *)
    let rec monitoring_loop () =
      if monitor.running then
        let%lwt () = Lwt_unix.sleep (float_of_int monitor.config.update_interval_ms /. 1000.0) in
        
        (* Collect events *)
        let window = Platform.get_current_window () in
        monitor.events_processed <- monitor.events_processed + 1;
        
        (* Continue loop *)
        monitoring_loop ()
      else
        Lwt.return_unit
    in
    
    (* Start monitoring in background *)
    Lwt.async monitoring_loop;
    Lwt.return_unit

  let stop monitor =
    let open Lwt.Syntax in
    monitor.running <- false;
    let%lwt () = Lwt_io.printl "Monitor stopped gracefully" in
    Lwt.return_unit
end