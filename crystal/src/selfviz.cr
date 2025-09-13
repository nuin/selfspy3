require "option_parser"
require "log"
require "json"
require "./config"
require "./storage"

# Selfviz - Enhanced Activity Visualizations for Crystal Selfspy
module Selfviz
  VERSION = "1.0.0"

  class VizApplication
    Log = ::Log.for(self)

    getter config : Selfspy::Config
    getter storage : Selfspy::Storage

    def initialize
      @config = Selfspy::Config.load
      @storage = Selfspy::Storage.new(@config.database.path)
    end

    def run_enhanced(days : Int32, include_charts : Bool)
      Log.info { "Generating enhanced statistics for #{days} days" }

      @storage.initialize! unless @storage.initialized?
      stats = @storage.get_stats(days)

      print_enhanced_header(days)
      print_activity_overview(stats)
      print_productivity_metrics(stats)
      print_application_analysis(stats)

      if include_charts
        print_ascii_charts(stats)
      end

      print_insights_and_tips(stats)
    end

    def run_timeline(days : Int32, granularity : String)
      Log.info { "Generating timeline for #{days} days with #{granularity} granularity" }

      @storage.initialize! unless @storage.initialized?

      print_timeline_header(days, granularity)

      case granularity.downcase
      when "hour"
        print_hourly_timeline(days)
      when "day"
        print_daily_timeline(days)
      when "week"
        print_weekly_timeline(days)
      else
        raise "Unsupported granularity: #{granularity}. Use: hour, day, week"
      end
    end

    def run_heatmap(days : Int32, type : String)
      Log.info { "Generating #{type} heatmap for #{days} days" }

      @storage.initialize! unless @storage.initialized?

      case type.downcase
      when "activity"
        print_activity_heatmap(days)
      when "keyboard"
        print_keyboard_heatmap(days)
      when "mouse"
        print_mouse_heatmap(days)
      else
        raise "Unsupported heatmap type: #{type}. Use: activity, keyboard, mouse"
      end
    end

    def run_dashboard
      Log.info { "Starting live dashboard" }

      @storage.initialize! unless @storage.initialized?

      puts "\033[2J\033[H"  # Clear screen and move cursor to top
      puts "🚀 Live Selfspy Dashboard"
      puts "Press Ctrl+C to exit"
      puts "=" * 60

      loop do
        print_live_dashboard
        sleep(2.seconds)
        puts "\033[2J\033[H"  # Clear screen and move cursor to top
      end
    end

    private def print_enhanced_header(days : Int32)
      puts
      puts "🎨 Enhanced Activity Analysis"
      puts "━" * 50
      puts "📅 Period: Last #{days} days"
      puts "⏰ Generated: #{Time.utc.to_s("%Y-%m-%d %H:%M:%S UTC")}"
      puts "💎 Crystal Selfspy v#{VERSION}"
      puts
    end

    private def print_activity_overview(stats : Selfspy::ActivityStats)
      puts "📊 Activity Overview"
      puts "─" * 30

      # Create activity bars
      max_value = [stats.keystrokes, stats.clicks, stats.window_changes].max
      keystroke_bar = create_bar(stats.keystrokes, max_value, 30)
      click_bar = create_bar(stats.clicks, max_value, 30)
      window_bar = create_bar(stats.window_changes, max_value, 30)

      puts "⌨️  Keystrokes     │#{keystroke_bar}│ #{stats.keystrokes.format}"
      puts "🖱️  Mouse Clicks   │#{click_bar}│ #{stats.clicks.format}"
      puts "🪟  Window Changes │#{window_bar}│ #{stats.window_changes.format}"
      puts
    end

    private def print_productivity_metrics(stats : Selfspy::ActivityStats)
      puts "📈 Productivity Metrics"
      puts "─" * 30

      daily_keystrokes = stats.keystrokes / stats.days
      daily_active_hours = (stats.active_time / stats.days) / 3600.0
      productivity_score = calculate_productivity_score(stats)

      puts "📝 Keystrokes/day:   #{daily_keystrokes.format}"
      puts "⏰ Active hours/day: #{daily_active_hours.round(1)}h"
      puts "🎯 Productivity:     #{create_score_bar(productivity_score)} #{productivity_score}/10"
      puts "💪 Activity level:   #{get_activity_level(productivity_score)}"
      puts
    end

    private def print_application_analysis(stats : Selfspy::ActivityStats)
      return if stats.top_apps.empty?

      puts "🏆 Application Usage Analysis"
      puts "─" * 35

      stats.top_apps.first(5).each_with_index do |app, index|
        emoji = ["🥇", "🥈", "🥉", "4️⃣", "5️⃣"][index]
        percentage_bar = create_percentage_bar(app.percentage, 20)
        time_str = format_duration((app.total_time / 1000).to_i64)  # Convert from ms

        puts "#{emoji} #{app.name.ljust(20)} │#{percentage_bar}│ #{app.percentage.round(1)}% (#{time_str})"
      end
      puts
    end

    private def print_ascii_charts(stats : Selfspy::ActivityStats)
      puts "📊 Activity Distribution Charts"
      puts "─" * 40

      # Simple text-based pie chart for applications
      if !stats.top_apps.empty?
        puts "Application Usage:"
        total_usage = stats.top_apps.sum(&.percentage)

        stats.top_apps.first(3).each do |app|
          slice_size = (app.percentage / total_usage * 20).to_i
          chart_slice = "█" * slice_size + "░" * (20 - slice_size)
          puts "  #{app.name.ljust(15)} │#{chart_slice}│ #{app.percentage.round(1)}%"
        end
        puts
      end

      # Activity intensity chart
      puts "Daily Activity Pattern (simulated):"
      24.times do |hour|
        intensity = simulate_hourly_activity(hour)
        bar = "█" * (intensity / 5).to_i + "░" * (20 - intensity / 5).to_i
        puts "  #{hour.to_s.rjust(2)}:00 │#{bar}│"
      end
      puts
    end

    private def print_insights_and_tips(stats : Selfspy::ActivityStats)
      puts "💡 Insights & Recommendations"
      puts "─" * 35

      insights = generate_insights(stats)
      insights.each_with_index do |insight, index|
        puts "#{index + 1}. #{insight}"
      end
      puts
    end

    private def print_timeline_header(days : Int32, granularity : String)
      puts
      puts "📅 Activity Timeline"
      puts "━" * 30
      puts "📊 Period: #{days} days"
      puts "🔍 Granularity: #{granularity}"
      puts
    end

    private def print_hourly_timeline(days : Int32)
      # Simplified hourly timeline
      puts "Hourly Activity (last 24 hours):"
      puts

      24.times do |hour|
        activity = simulate_hourly_activity(hour)
        bar = create_bar(activity, 100, 30)
        timestamp = Time.utc.at_beginning_of_day + hour.hours
        puts "#{timestamp.to_s("%H:00")} │#{bar}│ #{activity}%"
      end
      puts
    end

    private def print_daily_timeline(days : Int32)
      puts "Daily Activity Summary:"
      puts

      days.times do |day_offset|
        date = Time.utc - day_offset.days
        activity = simulate_daily_activity(day_offset)
        bar = create_bar(activity, 100, 25)
        puts "#{date.to_s("%m-%d")} │#{bar}│ #{activity}% active"
      end
      puts
    end

    private def print_weekly_timeline(days : Int32)
      weeks = (days / 7.0).ceil.to_i

      puts "Weekly Activity Summary:"
      puts

      weeks.times do |week_offset|
        start_date = Time.utc - (week_offset * 7).days
        end_date = start_date - 6.days
        activity = simulate_weekly_activity(week_offset)
        bar = create_bar(activity, 100, 20)
        puts "#{end_date.to_s("%m-%d")} - #{start_date.to_s("%m-%d")} │#{bar}│ #{activity}% avg"
      end
      puts
    end

    private def print_activity_heatmap(days : Int32)
      puts "🔥 Activity Heatmap (7-day week view)"
      puts "─" * 40
      puts

      days_of_week = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
      hours = (0..23).to_a

      # Print hour headers
      print "     "
      hours.each do |hour|
        print "#{hour.to_s.rjust(2)} "
      end
      puts

      # Print heatmap rows
      days_of_week.each do |day|
        print "#{day} │"
        hours.each do |hour|
          intensity = simulate_heatmap_activity(day, hour)
          print " #{get_heatmap_char(intensity)} "
        end
        puts "│"
      end

      puts
      puts "Legend: ░ (low) ▓ (medium) █ (high)"
      puts
    end

    private def print_keyboard_heatmap(days : Int32)
      puts "⌨️ Keyboard Activity Heatmap"
      puts "─" * 35
      puts

      # Simulate keyboard layout heatmap
      keyboard_rows = [
        "Q W E R T Y U I O P",
        " A S D F G H J K L",
        "  Z X C V B N M"
      ]

      keyboard_rows.each do |row|
        row.chars.each do |char|
          if char == ' '
            print " "
          elsif char.alphanumeric?
            intensity = simulate_key_intensity(char)
            print get_heatmap_char(intensity)
          else
            print char
          end
        end
        puts
      end

      puts
      puts "Legend: ░ (rarely used) ▓ (moderate) █ (frequent)"
      puts
    end

    private def print_mouse_heatmap(days : Int32)
      puts "🖱️ Mouse Activity Heatmap"
      puts "─" * 30
      puts

      # Simulate screen quadrant heatmap
      puts "Screen Activity (by quadrant):"
      puts
      puts "┌─────────────┬─────────────┐"

      2.times do |row|
        2.times do |quad_row|
          print "│"
          2.times do |col|
            quadrant = row * 2 + col
            activity = simulate_mouse_quadrant_activity(quadrant)
            intensity_bar = get_heatmap_char(activity) * 12
            print " #{intensity_bar} "
            print "│" if col == 1
          end
          puts
        end
        puts "├─────────────┼─────────────┤" if row == 0
      end

      puts "└─────────────┴─────────────┘"
      puts
    end

    private def print_live_dashboard
      current_time = Time.utc.to_s("%H:%M:%S")
      stats = @storage.get_stats(1)

      puts "🚀 Live Selfspy Dashboard - #{current_time}"
      puts "=" * 60
      puts

      # Current session info
      puts "📊 Today's Activity:"
      puts "  ⌨️  Keystrokes: #{stats.keystrokes.format}"
      puts "  🖱️  Clicks:     #{stats.clicks.format}"
      puts "  🪟  Windows:    #{stats.window_changes.format}"
      puts "  ⏰ Active:     #{format_duration(stats.active_time)}"
      puts

      # Real-time activity indicator
      activity_level = calculate_current_activity_level
      activity_bar = "█" * activity_level + "░" * (10 - activity_level)
      puts "📈 Current Activity: │#{activity_bar}│ #{activity_level}/10"
      puts

      # Recent activity
      puts "📝 Recent Activity:"
      puts "  • Last keystroke: #{simulate_last_activity("keystroke")}"
      puts "  • Last click:     #{simulate_last_activity("click")}"
      puts "  • Last window:    #{simulate_last_activity("window")}"
      puts

      puts "Press Ctrl+C to exit..."
    end

    # Helper methods for visualization

    private def create_bar(value : Int64, max_value : Int64, width : Int32) : String
      return "░" * width if max_value == 0

      filled = ((value.to_f64 / max_value) * width).to_i
      "█" * filled + "░" * (width - filled)
    end

    private def create_percentage_bar(percentage : Float64, width : Int32) : String
      filled = ((percentage / 100.0) * width).to_i
      "█" * filled + "░" * (width - filled)
    end

    private def create_score_bar(score : Int32) : String
      filled = score
      "█" * filled + "░" * (10 - filled)
    end

    private def get_heatmap_char(intensity : Int32) : String
      case intensity
      when 0..30
        "░"
      when 31..70
        "▓"
      else
        "█"
      end
    end

    private def format_duration(seconds : Int64) : String
      return "0s" if seconds <= 0

      hours = seconds // 3600
      minutes = (seconds % 3600) // 60

      parts = [] of String
      parts << "#{hours}h" if hours > 0
      parts << "#{minutes}m" if minutes > 0

      parts.empty? ? "0s" : parts.join(" ")
    end

    private def calculate_productivity_score(stats : Selfspy::ActivityStats) : Int32
      daily_keystrokes = stats.keystrokes.to_f64 / stats.days
      daily_active_hours = (stats.active_time.to_f64 / stats.days) / 3600.0

      # Simple scoring algorithm
      keystroke_factor = Math.min(5, daily_keystrokes / 1000.0)
      time_factor = Math.min(5, daily_active_hours / 4.0)

      ((keystroke_factor + time_factor) * 1.0).round.to_i32
    end

    private def get_activity_level(score : Int32) : String
      case score
      when 0..2
        "🐌 Low"
      when 3..5
        "🚶 Moderate"
      when 6..8
        "🏃 High"
      else
        "🚀 Very High"
      end
    end

    private def generate_insights(stats : Selfspy::ActivityStats) : Array(String)
      insights = [] of String

      daily_active_hours = (stats.active_time.to_f64 / stats.days) / 3600.0

      if daily_active_hours > 8
        insights << "You're very active! Consider taking regular breaks."
      elsif daily_active_hours < 2
        insights << "Low activity detected. Consider setting activity goals."
      end

      if stats.keystrokes > stats.clicks * 10
        insights << "High keyboard-to-mouse ratio suggests good keyboard efficiency."
      end

      if !stats.top_apps.empty? && stats.top_apps.first.percentage > 50
        insights << "#{stats.top_apps.first.name} dominates your time. Consider diversifying."
      end

      insights << "Consistent monitoring helps track productivity trends."

      insights
    end

    # Simulation methods (replace with real data in production)

    private def simulate_hourly_activity(hour : Int32) : Int32
      # Simulate typical work day pattern
      case hour
      when 9..11, 14..16
        80 + Random.rand(20)
      when 8, 12, 13, 17
        60 + Random.rand(20)
      when 7, 18, 19
        30 + Random.rand(20)
      else
        Random.rand(10)
      end
    end

    private def simulate_daily_activity(day_offset : Int32) : Int32
      # Simulate weekday vs weekend pattern
      day_of_week = (Time.utc - day_offset.days).day_of_week.value
      if day_of_week <= 5  # Monday to Friday
        70 + Random.rand(30)
      else
        30 + Random.rand(40)
      end
    end

    private def simulate_weekly_activity(week_offset : Int32) : Int32
      50 + Random.rand(40)
    end

    private def simulate_heatmap_activity(day : String, hour : Int32) : Int32
      # Weekday vs weekend patterns
      if ["Sat", "Sun"].includes?(day)
        Random.rand(50)
      else
        simulate_hourly_activity(hour)
      end
    end

    private def simulate_key_intensity(key : Char) : Int32
      # Common keys have higher intensity
      common_keys = ['E', 'T', 'A', 'O', 'I', 'N', 'S', 'H', 'R']
      if common_keys.includes?(key.upcase)
        70 + Random.rand(30)
      else
        Random.rand(50)
      end
    end

    private def simulate_mouse_quadrant_activity(quadrant : Int32) : Int32
      # Top-right quadrant (UI elements) typically more active
      case quadrant
      when 1  # Top-right
        80 + Random.rand(20)
      when 0  # Top-left
        60 + Random.rand(20)
      else    # Bottom quadrants
        30 + Random.rand(30)
      end
    end

    private def calculate_current_activity_level : Int32
      # Simulate current activity level
      Random.rand(1..10)
    end

    private def simulate_last_activity(type : String) : String
      seconds_ago = Random.rand(1..300)
      "#{seconds_ago}s ago"
    end
  end
end

# Command line interface
def main
  days = 7
  command = "enhanced"
  granularity = "day"
  include_charts = false
  heatmap_type = "activity"

  OptionParser.parse do |parser|
    parser.banner = "Selfviz - Crystal Selfspy Enhanced Visualizations\n\nUsage: selfviz [command] [options]"

    parser.on("enhanced", "Show enhanced statistics (default)") do
      command = "enhanced"

      parser.on("--days DAYS", "Number of days to analyze (default: 7)") { |d| days = d.to_i }
      parser.on("--charts", "Include ASCII charts") { include_charts = true }
    end

    parser.on("timeline", "Show activity timeline") do
      command = "timeline"

      parser.on("--days DAYS", "Number of days to analyze (default: 7)") { |d| days = d.to_i }
      parser.on("--granularity GRAN", "Time granularity: hour, day, week (default: day)") { |g| granularity = g }
    end

    parser.on("heatmap", "Show activity heatmap") do
      command = "heatmap"

      parser.on("--days DAYS", "Number of days to analyze (default: 7)") { |d| days = d.to_i }
      parser.on("--type TYPE", "Heatmap type: activity, keyboard, mouse (default: activity)") { |t| heatmap_type = t }
    end

    parser.on("dashboard", "Show live dashboard") do
      command = "dashboard"
    end

    parser.on("-h", "--help", "Show help") do
      puts parser
      exit
    end

    parser.on("-v", "--version", "Show version") do
      puts "Selfviz v#{Selfviz::VERSION}"
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
    app = Selfviz::VizApplication.new

    case command
    when "enhanced"
      app.run_enhanced(days, include_charts)
    when "timeline"
      app.run_timeline(days, granularity)
    when "heatmap"
      app.run_heatmap(days, heatmap_type)
    when "dashboard"
      app.run_dashboard
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

main if PROGRAM_NAME.includes?("selfviz")