require "log"
require "fiber"
require "./platform"
require "./storage"
require "./config"

module Selfspy
  # Main monitoring coordinator
  class Monitor
    Log = ::Log.for(self)

    getter config : Config
    getter storage : Storage
    private getter running : Bool = false
    private getter session_id : Int64?
    private getter keyboard_fiber : Fiber?
    private getter mouse_fiber : Fiber?
    private getter window_fiber : Fiber?
    private getter stats_fiber : Fiber?

    def initialize(@config : Config, @storage : Storage)
      @session_id = nil
      @keyboard_fiber = nil
      @mouse_fiber = nil
      @window_fiber = nil
      @stats_fiber = nil
    end

    def start
      return if @running

      Log.info { "Starting activity monitoring..." }

      # Start monitoring session
      @session_id = @storage.insert_session_start
      @running = true

      # Start monitoring threads
      start_keyboard_monitoring if @config.monitoring.capture_text
      start_mouse_monitoring if @config.monitoring.capture_mouse
      start_window_monitoring if @config.monitoring.capture_windows

      # Start stats reporting
      start_stats_reporting

      Log.info { "All monitoring services started successfully" }
    end

    def stop
      return unless @running

      Log.info { "Stopping activity monitoring..." }

      @running = false

      # Note: Crystal fibers will stop when @running becomes false
      # Fibers will exit naturally when their loops check @running

      # Stop platform monitoring
      Platform::Keyboard.stop_monitoring
      Platform::Mouse.stop_monitoring
      Platform::Window.stop_monitoring

      # End monitoring session
      if session_id = @session_id
        @storage.update_session_end(session_id)
      end

      Log.info { "Activity monitoring stopped" }
    end

    def running?
      @running
    end

    def get_current_stats : ActivityStats
      @storage.get_stats(1)  # Current day stats
    end

    private def start_keyboard_monitoring
      @keyboard_fiber = spawn do
        Log.info { "Starting keyboard monitoring" }

        Platform::Keyboard.start_monitoring do |event|
          next unless @running

          begin
            # Get current window context
            window_id = get_current_window_id

            # Process keystroke
            process_keystroke(event, window_id)
          rescue ex : Exception
            Log.error { "Error processing keystroke: #{ex.message}" }
          end
        end
      end
    end

    private def start_mouse_monitoring
      @mouse_fiber = spawn do
        Log.info { "Starting mouse monitoring" }

        Platform::Mouse.start_monitoring do |event|
          next unless @running

          begin
            # Get current window context
            window_id = get_current_window_id

            # Process mouse event
            process_mouse_event(event, window_id)
          rescue ex : Exception
            Log.error { "Error processing mouse event: #{ex.message}" }
          end
        end
      end
    end

    private def start_window_monitoring
      @window_fiber = spawn do
        Log.info { "Starting window monitoring" }

        last_window_id = nil

        Platform::Window.start_monitoring do |event|
          next unless @running

          begin
            # Process window change
            window_id = process_window_event(event)

            # Update current window reference
            last_window_id = window_id
          rescue ex : Exception
            Log.error { "Error processing window event: #{ex.message}" }
          end
        end
      end
    end

    private def start_stats_reporting
      @stats_fiber = spawn do
        Log.info { "Starting periodic stats reporting" }

        while @running
          sleep(60.seconds)  # Report every minute

          begin
            if @running
              stats = get_current_stats
              Log.debug { "Current stats: #{stats.keystrokes} keystrokes, #{stats.clicks} clicks" }
            end
          rescue ex : Exception
            Log.error { "Error reporting stats: #{ex.message}" }
          end
        end
      end
    end

    private def process_keystroke(event : Platform::KeyEvent, window_id : Int64?)
      # Filter based on privacy settings
      return if should_exclude_keystroke(event)

      # Encrypt if enabled
      key_data = event.key
      encrypted = false

      if @config.encryption.enabled
        key_data = encrypt_keystroke(key_data)
        encrypted = true
      end

      # Store in database
      @storage.insert_keystroke(
        key: key_data,
        modifiers: event.modifiers,
        window_id: window_id,
        encrypted: encrypted
      )

      Log.debug { "Recorded keystroke: #{event.key} with modifiers: #{event.modifiers}" }
    end

    private def process_mouse_event(event : Platform::MouseEvent, window_id : Int64?)
      # Convert event type to string
      type_str = case event.type
                 when Platform::MouseEvent::Type::Click
                   "click"
                 when Platform::MouseEvent::Type::Move
                   "move"
                 when Platform::MouseEvent::Type::Scroll
                   "scroll"
                 else
                   "unknown"
                 end

      # Store in database
      @storage.insert_mouse_event(
        type: type_str,
        x: event.x,
        y: event.y,
        button: event.button,
        window_id: window_id
      )

      Log.debug { "Recorded mouse #{type_str} at (#{event.x}, #{event.y})" }
    end

    private def process_window_event(event : Platform::WindowEvent) : Int64
      # Store window information
      window_id = @storage.insert_window_event(
        title: event.title,
        app_name: event.app_name,
        bundle_id: event.bundle_id,
        pid: event.pid
      )

      Log.debug { "Recorded window change: #{event.app_name} - #{event.title}" }
      window_id
    end

    private def get_current_window_id : Int64?
      return nil unless @config.monitoring.capture_windows

      begin
        if window_info = Platform::Window.get_active_window
          return @storage.insert_window_event(
            title: window_info.title,
            app_name: window_info.app_name,
            bundle_id: window_info.bundle_id,
            pid: window_info.pid
          )
        end
      rescue ex : Exception
        Log.debug { "Could not get current window: #{ex.message}" }
      end

      nil
    end

    private def should_exclude_keystroke(event : Platform::KeyEvent) : Bool
      # Check if we're in private mode
      return true if @config.privacy.private_mode

      # Check for privacy-sensitive keys
      privacy_keys = ["password", "pass", "pwd", "secret", "key", "token"]
      return true if privacy_keys.any? { |key| event.key.downcase.includes?(key) }

      false
    end

    private def encrypt_keystroke(key_data : String) : String
      # Simple base64 encoding for now
      # In a real implementation, you'd use proper encryption
      case @config.encryption.algorithm
      when "AES-256-GCM"
        # Would implement AES encryption here
        Base64.encode(key_data)
      else
        # Fallback to base64
        Base64.encode(key_data)
      end
    end

    # Real-time monitoring status
    def monitoring_status : MonitoringStatus
      MonitoringStatus.new(
        running: @running,
        session_id: @session_id,
        keyboard_active: @keyboard_fiber ? @keyboard_fiber.not_nil!.resumable? : false,
        mouse_active: @mouse_fiber ? @mouse_fiber.not_nil!.resumable? : false,
        window_active: @window_fiber ? @window_fiber.not_nil!.resumable? : false,
        uptime: session_uptime
      )
    end

    private def session_uptime : Int64
      if session_id = @session_id
        # Calculate uptime in seconds
        (Time.utc.to_unix_ms - session_id) // 1000
      else
        0_i64
      end
    end

    # Background maintenance tasks
    def run_maintenance
      spawn do
        Log.info { "Starting maintenance tasks" }

        while @running
          sleep(1.hour)  # Run every hour

          begin
            if @running
              # Cleanup old data if configured
              if @config.database.backup_interval > 0
                cleanup_interval = @config.database.backup_interval * 24  # Convert hours to days
                @storage.cleanup_old_data(cleanup_interval * 7)  # Keep data for backup_interval weeks
              end

              Log.debug { "Maintenance tasks completed" }
            end
          rescue ex : Exception
            Log.error { "Error during maintenance: #{ex.message}" }
          end
        end
      end
    end

    # Performance monitoring
    def performance_stats : PerformanceStats
      fiber_count = 0
      fiber_count += 1 if @keyboard_fiber && @keyboard_fiber.not_nil!.resumable?
      fiber_count += 1 if @mouse_fiber && @mouse_fiber.not_nil!.resumable?
      fiber_count += 1 if @window_fiber && @window_fiber.not_nil!.resumable?
      fiber_count += 1 if @stats_fiber && @stats_fiber.not_nil!.resumable?

      PerformanceStats.new(
        active_fibers: fiber_count,
        memory_usage: GC.stats.heap_size,
        uptime: session_uptime,
        events_processed: estimate_events_processed
      )
    end

    private def estimate_events_processed : Int64
      # Estimate based on current session data
      stats = get_current_stats
      stats.keystrokes + stats.clicks + stats.window_changes
    end
  end

  # Monitoring status structures
  struct MonitoringStatus
    include JSON::Serializable

    getter running : Bool
    getter session_id : Int64?
    getter keyboard_active : Bool
    getter mouse_active : Bool
    getter window_active : Bool
    getter uptime : Int64

    def initialize(@running : Bool, @session_id : Int64?, @keyboard_active : Bool, @mouse_active : Bool, @window_active : Bool, @uptime : Int64)
    end
  end

  struct PerformanceStats
    include JSON::Serializable

    getter active_fibers : Int32
    getter memory_usage : UInt64
    getter uptime : Int64
    getter events_processed : Int64

    def initialize(@active_fibers : Int32, @memory_usage : UInt64, @uptime : Int64, @events_processed : Int64)
    end
  end
end