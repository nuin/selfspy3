require "log"

module Selfspy
  # Cross-platform abstraction layer for system monitoring
  module Platform
    Log = ::Log.for(self)

    # Permission checking result
    struct PermissionStatus
      getter accessibility : Bool
      getter input_monitoring : Bool
      getter screen_recording : Bool

      def initialize(@accessibility : Bool, @input_monitoring : Bool, @screen_recording : Bool)
      end

      def all_granted? : Bool
        @accessibility && @input_monitoring
      end

      def accessibility? : Bool
        @accessibility
      end

      def input_monitoring? : Bool
        @input_monitoring
      end

      def screen_recording? : Bool
        @screen_recording
      end
    end

    # Platform-specific system information
    def self.system_info : Hash(String, String)
      info = Hash(String, String).new

      {% if flag?(:darwin) %}
        info["Platform"] = "macOS"
        info["Architecture"] = {{ `uname -m`.stringify.chomp }}
        info["Kernel"] = {{ `uname -r`.stringify.chomp }}
        info["Crystal"] = Crystal::VERSION
      {% elsif flag?(:linux) %}
        info["Platform"] = "Linux"
        info["Distribution"] = get_linux_distribution
        info["Architecture"] = {{ `uname -m`.stringify.chomp }}
        info["Kernel"] = {{ `uname -r`.stringify.chomp }}
        info["Crystal"] = Crystal::VERSION
      {% elsif flag?(:win32) %}
        info["Platform"] = "Windows"
        info["Architecture"] = ENV["PROCESSOR_ARCHITECTURE"]? || "Unknown"
        info["Crystal"] = Crystal::VERSION
      {% else %}
        info["Platform"] = "Unknown"
        info["Crystal"] = Crystal::VERSION
      {% end %}

      info
    end

    # Check current permission status
    def self.check_permissions : PermissionStatus
      {% if flag?(:darwin) %}
        check_macos_permissions
      {% elsif flag?(:linux) %}
        check_linux_permissions
      {% elsif flag?(:win32) %}
        check_windows_permissions
      {% else %}
        # Assume permissions are granted on other platforms
        PermissionStatus.new(true, true, true)
      {% end %}
    end

    # Request necessary permissions (interactive)
    def self.request_permissions : Bool
      {% if flag?(:darwin) %}
        request_macos_permissions
      {% elsif flag?(:linux) %}
        request_linux_permissions
      {% elsif flag?(:win32) %}
        request_windows_permissions
      {% else %}
        true
      {% end %}
    end

    # Platform-specific keyboard monitoring
    module Keyboard
      def self.start_monitoring(&callback : KeyEvent ->)
        {% if flag?(:darwin) %}
          Log.warn { "macOS keyboard monitoring not fully implemented" }
        {% elsif flag?(:linux) %}
          Log.warn { "Linux keyboard monitoring not fully implemented" }
        {% elsif flag?(:win32) %}
          Log.warn { "Windows keyboard monitoring not fully implemented" }
        {% else %}
          Log.warn { "Keyboard monitoring not implemented for this platform" }
        {% end %}
      end

      def self.stop_monitoring
        # Placeholder - monitoring will stop when fibers exit
        Log.info { "Keyboard monitoring stopped" }
      end
    end

    # Platform-specific mouse monitoring
    module Mouse
      def self.start_monitoring(&callback : MouseEvent ->)
        {% if flag?(:darwin) %}
          Log.warn { "macOS mouse monitoring not fully implemented" }
        {% elsif flag?(:linux) %}
          Log.warn { "Linux mouse monitoring not fully implemented" }
        {% elsif flag?(:win32) %}
          Log.warn { "Windows mouse monitoring not fully implemented" }
        {% else %}
          Log.warn { "Mouse monitoring not implemented for this platform" }
        {% end %}
      end

      def self.stop_monitoring
        # Placeholder - monitoring will stop when fibers exit
        Log.info { "Mouse monitoring stopped" }
      end
    end

    # Platform-specific window monitoring
    module Window
      def self.start_monitoring(&callback : WindowEvent ->)
        {% if flag?(:darwin) %}
          Log.warn { "macOS window monitoring not fully implemented" }
        {% elsif flag?(:linux) %}
          Log.warn { "Linux window monitoring not fully implemented" }
        {% elsif flag?(:win32) %}
          Log.warn { "Windows window monitoring not fully implemented" }
        {% else %}
          Log.warn { "Window monitoring not implemented for this platform" }
        {% end %}
      end

      def self.stop_monitoring
        # Placeholder - monitoring will stop when fibers exit
        Log.info { "Window monitoring stopped" }
      end

      def self.get_active_window : WindowInfo?
        {% if flag?(:darwin) %}
          # Placeholder for macOS - would use Accessibility APIs
          nil
        {% elsif flag?(:linux) %}
          # Placeholder for Linux - would use X11/Wayland APIs
          nil
        {% elsif flag?(:win32) %}
          # Placeholder for Windows - would use Windows API
          nil
        {% else %}
          nil
        {% end %}
      end
    end

    # Event structures
    struct KeyEvent
      getter key : String
      getter modifiers : Array(String)
      getter timestamp : Time

      def initialize(@key : String, @modifiers : Array(String), @timestamp : Time = Time.utc)
      end
    end

    struct MouseEvent
      enum Type
        Click
        Move
        Scroll
      end

      getter type : Type
      getter x : Int32
      getter y : Int32
      getter button : String?
      getter timestamp : Time

      def initialize(@type : Type, @x : Int32, @y : Int32, @button : String? = nil, @timestamp : Time = Time.utc)
      end
    end

    struct WindowEvent
      getter title : String
      getter app_name : String
      getter bundle_id : String?
      getter pid : Int32
      getter timestamp : Time

      def initialize(@title : String, @app_name : String, @bundle_id : String?, @pid : Int32, @timestamp : Time = Time.utc)
      end
    end

    struct WindowInfo
      getter title : String
      getter app_name : String
      getter bundle_id : String?
      getter pid : Int32
      getter x : Int32
      getter y : Int32
      getter width : Int32
      getter height : Int32

      def initialize(@title : String, @app_name : String, @bundle_id : String?, @pid : Int32, @x : Int32, @y : Int32, @width : Int32, @height : Int32)
      end
    end

    # macOS-specific implementations
    {% if flag?(:darwin) %}
    private def self.check_macos_permissions : PermissionStatus
      # For now, we'll use basic checks
      # In a real implementation, you'd use Objective-C/Swift bindings
      accessibility = system("which osascript > /dev/null 2>&1")
      input_monitoring = true  # Assume granted for now
      screen_recording = true  # Optional

      PermissionStatus.new(accessibility, input_monitoring, screen_recording)
    end

    private def self.request_macos_permissions : Bool
      puts "Please grant accessibility permissions in System Preferences:"
      puts "1. Open System Preferences > Security & Privacy > Privacy"
      puts "2. Select 'Accessibility' from the left panel"
      puts "3. Click the lock and enter your password"
      puts "4. Add this application to the list"
      puts
      print "Press Enter when permissions are granted..."
      gets
      true
    end

    private def self.start_macos_keyboard_monitoring(callback)
      # Placeholder - would implement using Carbon/Cocoa APIs
      Log.warn { "macOS keyboard monitoring not fully implemented" }
    end

    private def self.stop_macos_keyboard_monitoring
      # Placeholder
    end

    private def self.start_macos_mouse_monitoring(callback)
      # Placeholder - would implement using Carbon/Cocoa APIs
      Log.warn { "macOS mouse monitoring not fully implemented" }
    end

    private def self.stop_macos_mouse_monitoring
      # Placeholder
    end

    private def self.start_macos_window_monitoring(callback)
      # Placeholder - would implement using Accessibility APIs
      Log.warn { "macOS window monitoring not fully implemented" }
    end

    private def self.stop_macos_window_monitoring
      # Placeholder
    end

    def self.get_macos_active_window : WindowInfo?
      # Placeholder - would use Accessibility APIs
      nil
    end
    {% end %}

    # Linux-specific implementations
    {% if flag?(:linux) %}
    private def self.get_linux_distribution : String
      if File.exists?("/etc/os-release")
        File.read("/etc/os-release").lines.each do |line|
          if line.starts_with?("PRETTY_NAME=")
            return line.split("=", 2)[1].strip('"')
          end
        end
      end
      "Unknown Linux"
    end

    private def self.check_linux_permissions : PermissionStatus
      # Check if we can access /dev/input for keyboard/mouse
      can_access_input = File.readable?("/dev/input/") rescue false

      # Check if we're running in X11 or Wayland
      has_display = !ENV["DISPLAY"]?.nil? || !ENV["WAYLAND_DISPLAY"]?.nil?

      PermissionStatus.new(has_display, can_access_input, true)
    end

    private def self.request_linux_permissions : Bool
      puts "For full functionality on Linux, you may need to:"
      puts "1. Add your user to the 'input' group: sudo usermod -a -G input $USER"
      puts "2. Restart your session or run: newgrp input"
      puts "3. Ensure you're running in X11 or Wayland environment"
      puts
      true
    end

    private def self.start_linux_keyboard_monitoring(callback)
      # Placeholder - would implement using X11/Wayland APIs or evdev
      Log.warn { "Linux keyboard monitoring not fully implemented" }
    end

    private def self.stop_linux_keyboard_monitoring
      # Placeholder
    end

    private def self.start_linux_mouse_monitoring(callback)
      # Placeholder - would implement using X11/Wayland APIs or evdev
      Log.warn { "Linux mouse monitoring not fully implemented" }
    end

    private def self.stop_linux_mouse_monitoring
      # Placeholder
    end

    private def self.start_linux_window_monitoring(callback)
      # Placeholder - would implement using X11/Wayland APIs
      Log.warn { "Linux window monitoring not fully implemented" }
    end

    private def self.stop_linux_window_monitoring
      # Placeholder
    end

    def self.get_linux_active_window : WindowInfo?
      # Placeholder - would use X11/Wayland APIs
      nil
    end
    {% end %}

    # Windows-specific implementations
    {% if flag?(:win32) %}
    private def self.check_windows_permissions : PermissionStatus
      # On Windows, most monitoring capabilities don't require special permissions
      PermissionStatus.new(true, true, true)
    end

    private def self.request_windows_permissions : Bool
      puts "Windows monitoring should work without additional permissions."
      puts "If you encounter issues, try running as Administrator."
      true
    end

    private def self.start_windows_keyboard_monitoring(callback)
      # Placeholder - would implement using Windows API
      Log.warn { "Windows keyboard monitoring not fully implemented" }
    end

    private def self.stop_windows_keyboard_monitoring
      # Placeholder
    end

    private def self.start_windows_mouse_monitoring(callback)
      # Placeholder - would implement using Windows API
      Log.warn { "Windows mouse monitoring not fully implemented" }
    end

    private def self.stop_windows_mouse_monitoring
      # Placeholder
    end

    private def self.start_windows_window_monitoring(callback)
      # Placeholder - would implement using Windows API
      Log.warn { "Windows window monitoring not fully implemented" }
    end

    private def self.stop_windows_window_monitoring
      # Placeholder
    end

    def self.get_windows_active_window : WindowInfo?
      # Placeholder - would use Windows API
      nil
    end
    {% end %}
  end
end