require "option_parser"
require "log"
require "json"
require "yaml"
require "./config"
require "./monitor"
require "./storage"
require "./platform"

# Selfspy - Modern Activity Monitoring in Crystal
# 
# Ruby-like syntax with compiled performance for efficient system monitoring.
# Tracks keystrokes, mouse activity, window changes, and terminal commands.

module Selfspy
  VERSION = "1.0.0"
  
  class Application
    Log = ::Log.for(self)
    
    getter config : Config
    getter storage : Storage
    getter monitor : Monitor
    
    def initialize
      @config = Config.load
      @storage = Storage.new(@config.database.path)
      @monitor = Monitor.new(@config, @storage)
    end
    
    def start(options = StartOptions.new)
      Log.info { "Starting Selfspy monitoring v#{VERSION}" }
      
      # Apply command line options
      @config.monitoring.capture_text = false if options.no_text
      @config.monitoring.capture_mouse = false if options.no_mouse
      
      # Check permissions first
      unless Platform.check_permissions.all_granted?
        Log.error { "Insufficient permissions for monitoring" }
        unless Platform.request_permissions
          raise "Failed to obtain required permissions"
        end
      end
      
      # Initialize storage
      @storage.initialize
      
      # Start monitoring
      @monitor.start
      
      # Set up signal handlers for graceful shutdown
      Signal::INT.trap { stop_gracefully }
      Signal::TERM.trap { stop_gracefully }
      
      Log.info { "Selfspy monitoring started successfully" }
      Log.info { "Press Ctrl+C to stop monitoring" }
      
      # Keep application running
      sleep
      
    rescue ex : Exception
      Log.error { "Failed to start monitoring: #{ex.message}" }
      exit(1)
    end
    
    def stop
      Log.info { "Stopping Selfspy monitoring..." }
      @monitor.stop
      @storage.close
      Log.info { "Selfspy stopped" }
    end
    
    def stats(days : Int32 = 7, json_format : Bool = false)
      Log.info { "Generating statistics for #{days} days" }
      
      @storage.initialize unless @storage.initialized?
      stats = @storage.get_stats(days)
      
      if json_format
        puts stats.to_json
      else
        print_formatted_stats(stats)
      end
    end
    
    def check_permissions
      Log.info { "Checking system permissions..." }
      
      perms = Platform.check_permissions
      
      puts "🔍 Selfspy Permission Check"
      puts "=" * 30
      puts
      
      if perms.all_granted?
        puts "✅ All permissions granted"
      else
        puts "❌ Missing permissions:"
        puts "   - Accessibility permission required" unless perms.accessibility?
        puts "   - Input monitoring permission required" unless perms.input_monitoring?
        puts "   - Screen recording permission (optional)" unless perms.screen_recording?
        puts
        puts "Run with elevated permissions or grant access in System Preferences"
      end
      
      puts
      puts "System Information:"
      Platform.system_info.each do |key, value|
        puts "   #{key}: #{value}"
      end
    end
    
    def export(format : String = "json", output : String? = nil, days : Int32 = 30)
      Log.info { "Exporting #{days} days of data in #{format} format" }
      
      @storage.initialize unless @storage.initialized?
      
      case format.downcase
      when "json"
        data = @storage.export_json(days)
      when "csv"
        data = @storage.export_csv(days)
      when "sql"
        data = @storage.export_sql(days)
      else
        raise "Unsupported export format: #{format}"
      end
      
      if output
        File.write(output, data)
        Log.info { "Data exported to #{output}" }
      else
        puts data
      end
    end
    
    private def stop_gracefully
      Log.info { "Received shutdown signal, stopping gracefully..." }
      stop
      exit(0)
    end
    
    private def print_formatted_stats(stats)
      puts
      puts "📊 Selfspy Activity Statistics (Last #{stats.days} days)"
      puts "=" * 50
      puts
      puts "⌨️  Keystrokes: #{stats.keystrokes.format}"
      puts "🖱️  Mouse clicks: #{stats.clicks.format}"
      puts "🪟  Window changes: #{stats.window_changes.format}" 
      puts "⏰ Active time: #{format_duration(stats.active_time)}"
      puts "📱 Most used applications:"
      
      stats.top_apps.each_with_index do |app, index|
        puts "   #{index + 1}. #{app.name} (#{app.percentage.round(1)}%)"
      end
      puts
    end
    
    private def format_duration(seconds : Int64) : String
      hours = seconds // 3600
      minutes = (seconds % 3600) // 60
      
      if hours > 0
        "#{hours}h #{minutes}m"
      else
        "#{minutes}m"
      end
    end
  end
  
  struct StartOptions
    property no_text : Bool = false
    property no_mouse : Bool = false
    property debug : Bool = false
  end
end

# Command line interface
def main
  options = Selfspy::StartOptions.new
  command = "help"
  days = 7
  json_format = false
  export_format = "json"
  export_output = nil
  
  OptionParser.parse do |parser|
    parser.banner = "Selfspy - Modern Activity Monitoring in Crystal\n\nUsage: selfspy [command] [options]"
    
    parser.on("start", "Start activity monitoring") do
      command = "start"
      
      parser.on("--no-text", "Disable text capture for privacy") { options.no_text = true }
      parser.on("--no-mouse", "Disable mouse monitoring") { options.no_mouse = true }
      parser.on("--debug", "Enable debug logging") { options.debug = true }
    end
    
    parser.on("stop", "Stop running monitoring instance") do
      command = "stop"
    end
    
    parser.on("stats", "Show activity statistics") do
      command = "stats"
      
      parser.on("--days DAYS", "Number of days to analyze (default: 7)") { |d| days = d.to_i }
      parser.on("--json", "Output in JSON format") { json_format = true }
    end
    
    parser.on("check", "Check system permissions and setup") do
      command = "check"
    end
    
    parser.on("export", "Export data to various formats") do
      command = "export"
      
      parser.on("--format FORMAT", "Export format: json, csv, sql (default: json)") { |f| export_format = f }
      parser.on("--output FILE", "Output file path") { |f| export_output = f }
      parser.on("--days DAYS", "Number of days to export (default: 30)") { |d| days = d.to_i }
    end
    
    parser.on("-h", "--help", "Show help") do
      puts parser
      exit
    end
    
    parser.on("-v", "--version", "Show version") do
      puts "Selfspy v#{Selfspy::VERSION}"
      exit
    end
    
    parser.missing_option do |flag|
      STDERR.puts "Missing argument for #{flag}"
      exit(1)
    end
    
    parser.invalid_option do |flag|
      STDERR.puts "Invalid option: #{flag}"
      exit(1)
    end
  end
  
  # Configure logging
  if options.debug
    Log.setup(:debug)
  else
    Log.setup(:info)
  end
  
  app = Selfspy::Application.new
  
  case command
  when "start"
    app.start(options)
  when "stop"
    app.stop
  when "stats"
    app.stats(days, json_format)
  when "check"
    app.check_permissions
  when "export"
    app.export(export_format, export_output, days)
  else
    puts "Unknown command: #{command}"
    puts "Use --help for usage information"
    exit(1)
  end
rescue ex : Exception
  STDERR.puts "Error: #{ex.message}"
  exit(1)
end

main if PROGRAM_NAME.includes?("selfspy")