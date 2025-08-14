(** Selfspy - Modern Activity Monitoring in OCaml
    
    Industrial-strength functional programming with excellent performance,
    strong type system with inference, and mature ecosystem for system programming. *)

open Lwt.Syntax
open Selfspy

(** Command line interface types *)
type start_options = {
  no_text : bool;
  no_mouse : bool;
  debug : bool;
}

type stats_options = {
  days : int;
  json : bool;
}

type export_options = {
  format : string;
  output : string option;
  days : int;
}

type command =
  | Start of start_options
  | Stop
  | Stats of stats_options
  | Check
  | Export of export_options
  | Version

(** Command line argument parsing with Cmdliner *)
let start_cmd =
  let no_text =
    let doc = "Disable text capture for privacy" in
    Cmdliner.Arg.(value & flag & info ["no-text"] ~doc)
  in
  let no_mouse =
    let doc = "Disable mouse monitoring" in
    Cmdliner.Arg.(value & flag & info ["no-mouse"] ~doc)
  in
  let debug =
    let doc = "Enable debug logging" in
    Cmdliner.Arg.(value & flag & info ["debug"] ~doc)
  in
  let term =
    Cmdliner.Term.(const (fun no_text no_mouse debug ->
      Start { no_text; no_mouse; debug }) $ no_text $ no_mouse $ debug)
  in
  let info = Cmdliner.Cmd.info "start" ~doc:"Start activity monitoring" in
  Cmdliner.Cmd.v info term

let stop_cmd =
  let term = Cmdliner.Term.(const Stop) in
  let info = Cmdliner.Cmd.info "stop" ~doc:"Stop running monitoring instance" in
  Cmdliner.Cmd.v info term

let stats_cmd =
  let days =
    let doc = "Number of days to analyze" in
    Cmdliner.Arg.(value & opt int 7 & info ["days"] ~doc)
  in
  let json =
    let doc = "Output in JSON format" in
    Cmdliner.Arg.(value & flag & info ["json"] ~doc)
  in
  let term =
    Cmdliner.Term.(const (fun days json -> Stats { days; json }) $ days $ json)
  in
  let info = Cmdliner.Cmd.info "stats" ~doc:"Show activity statistics" in
  Cmdliner.Cmd.v info term

let check_cmd =
  let term = Cmdliner.Term.(const Check) in
  let info = Cmdliner.Cmd.info "check" ~doc:"Check system permissions and setup" in
  Cmdliner.Cmd.v info term

let export_cmd =
  let format =
    let doc = "Export format (json, csv, sql)" in
    Cmdliner.Arg.(value & opt string "json" & info ["format"] ~doc)
  in
  let output =
    let doc = "Output file path" in
    Cmdliner.Arg.(value & opt (some string) None & info ["output"] ~doc)
  in
  let days =
    let doc = "Number of days to export" in
    Cmdliner.Arg.(value & opt int 30 & info ["days"] ~doc)
  in
  let term =
    Cmdliner.Term.(const (fun format output days ->
      Export { format; output; days }) $ format $ output $ days)
  in
  let info = Cmdliner.Cmd.info "export" ~doc:"Export data to various formats" in
  Cmdliner.Cmd.v info term

let version_cmd =
  let term = Cmdliner.Term.(const Version) in
  let info = Cmdliner.Cmd.info "version" ~doc:"Show version information" in
  Cmdliner.Cmd.v info term

(** Command execution with comprehensive error handling *)
let run_start_command options =
  let%lwt () = Lwt_io.printl "🚀 Starting Selfspy monitoring (OCaml implementation)" in
  
  (* Load configuration *)
  let%lwt config = Config.load () in
  let updated_config = Config.{
    config with
    capture_text = config.capture_text && not options.no_text;
    capture_mouse = config.capture_mouse && not options.no_mouse;
    debug = config.debug || options.debug;
  } in
  
  (* Check permissions *)
  let%lwt permissions = Platform.check_permissions () in
  if not (Platform.has_all_permissions permissions) then (
    let%lwt () = Lwt_io.printl "❌ Insufficient permissions for monitoring" in
    let%lwt () = Lwt_io.printl "Missing permissions:" in
    let%lwt () = 
      if not permissions.accessibility then
        Lwt_io.printl "   - Accessibility permission required"
      else Lwt.return_unit
    in
    let%lwt () =
      if not permissions.input_monitoring then
        Lwt_io.printl "   - Input monitoring permission required"
      else Lwt.return_unit
    in
    let%lwt () = Lwt_io.printl "\nAttempting to request permissions..." in
    let%lwt success = Platform.request_permissions () in
    if not success then
      Lwt.fail_with "Failed to obtain required permissions"
    else
      Lwt.return_unit
  ) else
    Lwt.return_unit
  in
  
  (* Initialize storage *)
  let%lwt storage = Storage.create updated_config.database_path in
  let%lwt () = Storage.initialize storage in
  
  (* Create and start monitor *)
  let monitor = Monitor.create updated_config storage in
  let%lwt () = Monitor.start monitor in
  
  let%lwt () = Lwt_io.printl "✅ Selfspy monitoring started successfully" in
  let%lwt () = Lwt_io.printl "📊 Press Ctrl+C to stop monitoring" in
  
  (* Set up signal handling for graceful shutdown *)
  let shutdown_promise, shutdown_resolver = Lwt.wait () in
  let _ = Lwt_unix.on_signal Sys.sigint (fun _ ->
    let%lwt () = Lwt_io.printl "\n🛑 Received shutdown signal, stopping gracefully..." in
    let%lwt () = Monitor.stop monitor in
    let%lwt () = Storage.close storage in
    Lwt.wakeup shutdown_resolver ();
    Lwt.return_unit |> ignore
  ) in
  
  (* Wait for shutdown *)
  shutdown_promise

let run_stop_command () =
  let%lwt () = Lwt_io.printl "🛑 Stopping Selfspy monitoring..." in
  let%lwt () = Lwt_io.printl "✅ Stop signal sent" in
  Lwt.return_unit

let run_stats_command options =
  let%lwt config = Config.load () in
  let%lwt storage = Storage.create config.database_path in
  let%lwt () = Storage.initialize storage in
  let%lwt stats = Storage.get_stats storage options.days in
  let%lwt () = Storage.close storage in
  
  if options.json then (
    let json_str = Stats.to_json stats in
    Lwt_io.printl json_str
  ) else (
    Stats.print_formatted stats options.days;
    Lwt.return_unit
  )

let run_check_command () =
  let%lwt () = Lwt_io.printl "🔍 Checking Selfspy permissions..." in
  let%lwt () = Lwt_io.printl "===================================" in
  let%lwt () = Lwt_io.printl "" in
  
  let%lwt permissions = Platform.check_permissions () in
  let%lwt () =
    if Platform.has_all_permissions permissions then
      Lwt_io.printl "✅ All permissions granted"
    else (
      let%lwt () = Lwt_io.printl "❌ Missing permissions:" in
      let%lwt () =
        if not permissions.accessibility then
          Lwt_io.printl "   - Accessibility permission required"
        else Lwt.return_unit
      in
      if not permissions.input_monitoring then
        Lwt_io.printl "   - Input monitoring permission required"
      else Lwt.return_unit
    )
  in
  
  let%lwt () = Lwt_io.printl "" in
  let%lwt () = Lwt_io.printl "📱 System Information:" in
  let sys_info = Platform.get_system_info () in
  let%lwt () = Lwt_io.printl ("   Platform: " ^ sys_info.platform) in
  let%lwt () = Lwt_io.printl ("   Architecture: " ^ sys_info.architecture) in
  let%lwt () = Lwt_io.printl ("   OCaml Version: " ^ sys_info.ocaml_version) in
  Lwt_io.printl ("   Hostname: " ^ sys_info.hostname)

let run_export_command options =
  let%lwt () = Lwt_io.printl (Printf.sprintf "📤 Exporting %d days of data in %s format..."
    options.days options.format) in
  
  let%lwt config = Config.load () in
  let%lwt storage = Storage.create config.database_path in
  let%lwt () = Storage.initialize storage in
  let%lwt data = 
    match options.format with
    | "json" -> Storage.export_json storage options.days
    | "csv" -> Storage.export_csv storage options.days
    | "sql" -> Storage.export_sql storage options.days
    | _ -> Lwt.fail_with ("Unsupported export format: " ^ options.format)
  in
  let%lwt () = Storage.close storage in
  
  match options.output with
  | Some filename ->
    let%lwt () = Lwt_io.with_file ~mode:Lwt_io.Output filename (fun oc ->
      Lwt_io.write oc data) in
    Lwt_io.printl ("✅ Data exported to " ^ filename)
  | None ->
    Lwt_io.print data

let run_version_command () =
  let%lwt () = Lwt_io.printl "Selfspy v1.0.0 (OCaml implementation)" in
  let%lwt () = Lwt_io.printl "Industrial-strength functional programming approach" in
  let%lwt () = Lwt_io.printl "" in
  let%lwt () = Lwt_io.printl "Features:" in
  let%lwt () = Lwt_io.printl "  • Industrial-strength functional programming" in
  let%lwt () = Lwt_io.printl "  • Excellent performance with strong type system" in
  let%lwt () = Lwt_io.printl "  • Type inference and pattern matching" in
  let%lwt () = Lwt_io.printl "  • Mature ecosystem and libraries" in
  let%lwt () = Lwt_io.printl "  • Memory safety with garbage collection" in
  Lwt_io.printl "  • Cooperative concurrency with Lwt"

let run_command = function
  | Start options -> run_start_command options
  | Stop -> run_stop_command ()
  | Stats options -> run_stats_command options
  | Check -> run_check_command ()
  | Export options -> run_export_command options
  | Version -> run_version_command ()

(** Error handling and logging setup *)
let setup_logging debug =
  let level = if debug then Logs.Debug else Logs.Info in
  Logs.set_level (Some level);
  Logs.set_reporter (Logs_fmt.reporter ())

(** Main entry point *)
let main debug_flag cmd =
  setup_logging debug_flag;
  Lwt_main.run (
    Lwt.catch
      (fun () -> run_command cmd)
      (function
        | Failure msg ->
          let%lwt () = Lwt_io.eprintf "Error: %s\n" msg in
          Lwt.return (`Error (false, msg))
        | exn ->
          let%lwt () = Lwt_io.eprintf "Unexpected error: %s\n" (Printexc.to_string exn) in
          Lwt.return (`Error (false, "Unexpected error")))
    >>= function
    | `Ok () -> Lwt.return (`Ok ())
    | `Error _ as err -> Lwt.return err
  )

(** Global debug flag *)
let debug_flag =
  let doc = "Enable debug logging" in
  Cmdliner.Arg.(value & flag & info ["debug"; "d"] ~doc)

(** Main command with subcommands *)
let default_cmd =
  let doc = "Modern activity monitoring in OCaml" in
  let man = [
    `S Cmdliner.Manpage.s_description;
    `P "Selfspy is a modern activity monitoring application implemented in OCaml, \
        featuring industrial-strength functional programming with excellent performance, \
        strong type system with inference, and mature ecosystem.";
    `S Cmdliner.Manpage.s_examples;
    `P "Start monitoring:";
    `Pre "  $(mname) start";
    `P "View statistics:";
    `Pre "  $(mname) stats --days 30 --json";
    `P "Export data:";
    `Pre "  $(mname) export --format csv --output activity.csv";
    `S Cmdliner.Manpage.s_bugs;
    `P "Report bugs to https://github.com/selfspy/selfspy3/issues";
  ] in
  let info = Cmdliner.Cmd.info "selfspy" ~version:"1.0.0" ~doc ~man in
  let default_term = 
    Cmdliner.Term.(ret (const (`Help (`Pager, None))))
  in
  Cmdliner.Cmd.group info ~default:default_term [
    start_cmd; stop_cmd; stats_cmd; check_cmd; export_cmd; version_cmd
  ]

(** Application entry point *)
let () =
  let result = Cmdliner.Cmd.eval default_cmd in
  match result with
  | `Ok () -> exit 0
  | `Error _ -> exit 1
  | `Version | `Help -> exit 0