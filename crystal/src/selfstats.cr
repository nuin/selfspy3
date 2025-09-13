require "option_parser"
require "log"
require "json"
require "./config"
require "./storage"

# Selfstats - Activity Statistics for Crystal Selfspy
module Selfstats
  VERSION = "1.0.0"

  class StatsApplication
    Log = ::Log.for(self)

    getter config : Selfspy::Config
    getter storage : Selfspy::Storage

    def initialize
      @config = Selfspy::Config.load
      @storage = Selfspy::Storage.new(@config.database.path)
    end

    def run_stats(days : Int32, format : String, detailed : Bool, apps : Bool, export_file : String?)
      Log.info { "Generating statistics for #{days} days" }

      @storage.initialize! unless @storage.initialized?
      stats = @storage.get_stats(days)

      case format.downcase
      when "json"
        output = generate_json_stats(stats, detailed, apps)
      when "table"
        output = generate_table_stats(stats, detailed, apps)
      when "summary"
        output = generate_summary_stats(stats)
      else
        raise "Unsupported format: #{format}. Use: json, table, summary"
      end

      if export_file
        File.write(export_file, output)
        Log.info { "Statistics exported to #{export_file}" }
      else
        puts output
      end
    end

    def run_apps(days : Int32, limit : Int32, format : String)
      Log.info { "Generating application usage statistics for #{days} days" }

      @storage.initialize! unless @storage.initialized?
      apps = @storage.get_top_applications(days, limit)

      case format.downcase
      when "json"
        puts apps.to_json
      when "table"
        print_apps_table(apps)
      else
        raise "Unsupported format: #{format}. Use: json, table"
      end
    end

    def run_live_stats
      Log.info { "Starting live statistics monitor" }

      @storage.initialize! unless @storage.initialized?

      puts "📊 Live Selfspy Statistics"
      puts "Press Ctrl+C to stop"
      puts "=" * 40

      last_stats = @storage.get_stats(1)

      loop do
        sleep(5.seconds)

        current_stats = @storage.get_stats(1)

        # Calculate deltas
        delta_keystrokes = current_stats.keystrokes - last_stats.keystrokes
        delta_clicks = current_stats.clicks - last_stats.clicks
        delta_windows = current_stats.window_changes - last_stats.window_changes

        if delta_keystrokes > 0 || delta_clicks > 0 || delta_windows > 0
          timestamp = Time.utc.to_s("%H:%M:%S")
          puts "[#{timestamp}] ⌨️ +#{delta_keystrokes} 🖱️ +#{delta_clicks} 🪟 +#{delta_windows}"
        end

        last_stats = current_stats
      end
    end

    private def generate_json_stats(stats : Selfspy::ActivityStats, detailed : Bool, apps : Bool) : String
      data = {
        "period" => "#{stats.days} days",
        "summary" => {
          "keystrokes" => stats.keystrokes,
          "mouse_clicks" => stats.clicks,
          "window_changes" => stats.window_changes,
          "active_time_seconds" => stats.active_time,
          "active_time_formatted" => format_duration(stats.active_time)
        }
      }

      if apps
        data = data.merge({"top_applications" => stats.top_apps})
      end

      if detailed
        data = data.merge({
          "averages" => {
            "keystrokes_per_day" => stats.keystrokes / stats.days,
            "clicks_per_day" => stats.clicks / stats.days,
            "window_changes_per_day" => stats.window_changes / stats.days,
            "active_hours_per_day" => (stats.active_time / stats.days) / 3600.0
          }
        })
      end

      data.to_json
    end

    private def generate_table_stats(stats : Selfspy::ActivityStats, detailed : Bool, apps : Bool) : String
      output = String::Builder.new

      output << "\n📊 Selfspy Activity Statistics (Last #{stats.days} days)\n"
      output << "=" * 60 << "\n\n"

      # Basic stats
      output << "📈 Activity Summary:\n"
      output << "  ⌨️  Keystrokes:     #{stats.keystrokes.format}\n"
      output << "  🖱️  Mouse clicks:   #{stats.clicks.format}\n"
      output << "  🪟  Window changes: #{stats.window_changes.format}\n"
      output << "  ⏰ Active time:    #{format_duration(stats.active_time)}\n\n"

      if detailed
        output << "📊 Daily Averages:\n"
        output << "  ⌨️  Keystrokes/day:     #{(stats.keystrokes / stats.days).format}\n"
        output << "  🖱️  Mouse clicks/day:   #{(stats.clicks / stats.days).format}\n"
        output << "  🪟  Window changes/day: #{(stats.window_changes / stats.days).format}\n"
        output << "  ⏰ Active hours/day:   #{((stats.active_time / stats.days) / 3600.0).round(1)}h\n\n"
      end

      if apps && !stats.top_apps.empty?
        output << "🏆 Most Used Applications:\n"
        stats.top_apps.each_with_index do |app, index|
          percentage = app.percentage.round(1)
          time_formatted = format_duration((app.total_time / 1000).to_i64)  # Convert from ms
          output << "  #{index + 1}. #{app.name.ljust(20)} #{percentage.to_s.rjust(5)}% (#{time_formatted})\n"
        end
        output << "\n"
      end

      output.to_s
    end

    private def generate_summary_stats(stats : Selfspy::ActivityStats) : String
      output = String::Builder.new

      total_events = stats.keystrokes + stats.clicks + stats.window_changes
      activity_score = calculate_activity_score(stats)

      output << "📊 Quick Summary (#{stats.days} days)\n"
      output << "━" * 35 << "\n"
      output << "🎯 Activity Score: #{activity_score}/10\n"
      output << "📝 Total Events:  #{total_events.format}\n"
      output << "⏰ Active Time:   #{format_duration(stats.active_time)}\n"

      if !stats.top_apps.empty?
        top_app = stats.top_apps.first
        output << "🏆 Top App:       #{top_app.name} (#{top_app.percentage.round(1)}%)\n"
      end

      output.to_s
    end

    private def print_apps_table(apps : Array(Selfspy::AppUsage))
      puts "\n🏆 Application Usage Statistics"
      puts "=" * 50

      if apps.empty?
        puts "No application data found."
        return
      end

      puts
      puts "#{"Rank".ljust(6)}#{"Application".ljust(25)}#{"Usage".ljust(10)}#{"Time".ljust(15)}"
      puts "-" * 56

      apps.each_with_index do |app, index|
        rank = (index + 1).to_s.ljust(6)
        name = app.name.ljust(25)
        usage = "#{app.percentage.round(1)}%".ljust(10)
        time = format_duration((app.total_time / 1000).to_i64).ljust(15)  # Convert from ms

        puts "#{rank}#{name}#{usage}#{time}"
      end

      puts
    end

    private def format_duration(seconds : Int64) : String
      return "0s" if seconds <= 0

      hours = seconds // 3600
      minutes = (seconds % 3600) // 60
      secs = seconds % 60

      parts = [] of String
      parts << "#{hours}h" if hours > 0
      parts << "#{minutes}m" if minutes > 0
      parts << "#{secs}s" if secs > 0 && hours == 0

      parts.empty? ? "0s" : parts.join(" ")
    end

    private def calculate_activity_score(stats : Selfspy::ActivityStats) : Int32
      # Simple activity scoring algorithm (0-10)
      # Based on keystrokes, clicks, and active time relative to expectations

      daily_keystrokes = stats.keystrokes.to_f64 / stats.days
      daily_clicks = stats.clicks.to_f64 / stats.days
      daily_active_hours = (stats.active_time.to_f64 / stats.days) / 3600.0

      # Scoring thresholds (typical usage patterns)
      keystroke_score = Math.min(10, (daily_keystrokes / 2000.0) * 4).to_i32
      click_score = Math.min(10, (daily_clicks / 500.0) * 3).to_i32
      time_score = Math.min(10, (daily_active_hours / 8.0) * 3).to_i32

      # Weighted average
      total_score = (keystroke_score * 0.4 + click_score * 0.3 + time_score * 0.3)
      Math.min(10, total_score.round.to_i32)
    end
  end
end

# Command line interface
def main
  days = 7
  format = "table"
  detailed = false
  apps = false
  export_file = nil
  command = "stats"
  app_limit = 10

  OptionParser.parse do |parser|
    parser.banner = "Selfstats - Crystal Selfspy Statistics\n\nUsage: selfstats [command] [options]"

    parser.on("stats", "Show activity statistics (default)") do
      command = "stats"

      parser.on("--days DAYS", "Number of days to analyze (default: 7)") { |d| days = d.to_i }
      parser.on("--format FORMAT", "Output format: table, json, summary (default: table)") { |f| format = f }
      parser.on("--detailed", "Show detailed statistics") { detailed = true }
      parser.on("--apps", "Include application usage") { apps = true }
      parser.on("--export FILE", "Export to file") { |f| export_file = f }
    end

    parser.on("apps", "Show application usage statistics") do
      command = "apps"

      parser.on("--days DAYS", "Number of days to analyze (default: 7)") { |d| days = d.to_i }
      parser.on("--limit LIMIT", "Number of apps to show (default: 10)") { |l| app_limit = l.to_i }
      parser.on("--format FORMAT", "Output format: table, json (default: table)") { |f| format = f }
    end

    parser.on("live", "Show live statistics") do
      command = "live"
    end

    parser.on("-h", "--help", "Show help") do
      puts parser
      exit
    end

    parser.on("-v", "--version", "Show version") do
      puts "Selfstats v#{Selfstats::VERSION}"
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

  Log.setup(:info)

  begin
    app = Selfstats::StatsApplication.new

    case command
    when "stats"
      app.run_stats(days, format, detailed, apps, export_file)
    when "apps"
      app.run_apps(days, app_limit, format)
    when "live"
      app.run_live_stats
    else
      puts "Unknown command: #{command}"
      puts "Use --help for usage information"
      exit(1)
    end
  rescue ex : Exception
    STDERR.puts "Error: #{ex.message}"
    exit(1)
  end
end

main if PROGRAM_NAME.includes?("selfstats")