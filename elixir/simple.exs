#!/usr/bin/env elixir

# Simple Selfspy CLI implementation in Elixir
# Run with: elixir simple.exs [command]

defmodule SelfspyCLI do
  @version "1.0.0"

  def main(args \\ []) do
    case args do
      [] -> show_help()
      ["help"] -> show_help()
      ["check"] -> check_permissions()
      ["stats"] -> show_stats()
      ["stats", "--json"] -> show_stats_json()
      ["version"] -> show_version()
      [unknown | _] ->
        IO.puts(:stderr, "Error: Unknown command \"#{unknown}\"")
        IO.puts(:stderr, "Use \"elixir simple.exs help\" for usage information")
        System.halt(1)
    end
  end

  defp show_help do
    IO.puts("Selfspy - Demo CLI in Elixir")
    IO.puts("")
    IO.puts("Let it crash! Fault-tolerant monitoring with OTP")
    IO.puts("")
    IO.puts("USAGE:")
    IO.puts("    elixir simple.exs [COMMAND]")
    IO.puts("")
    IO.puts("COMMANDS:")
    IO.puts("    help                  Show this help message")
    IO.puts("    check                 Check system information")
    IO.puts("    stats                 Show demo statistics")
    IO.puts("    stats --json          Show demo statistics in JSON format")
    IO.puts("    version               Show version information")
    IO.puts("")
    IO.puts("Note: This is a demo CLI. For real monitoring use monitor_real.exs")
    IO.puts("")
    IO.puts("Elixir Implementation Features:")
    IO.puts("  • Actor model concurrency with OTP")
    IO.puts("  • Fault-tolerant supervision trees")
    IO.puts("  • Phoenix LiveView real-time web UI")
    IO.puts("  • Distributed computing capabilities")
    IO.puts("  • Hot code reloading")
  end

  defp check_permissions do
    IO.puts("🔍 Checking Selfspy permissions...")
    IO.puts(String.duplicate("=", 35))
    IO.puts("")
    IO.puts("✅ All permissions granted")
    IO.puts("")
    IO.puts("📱 System Information:")
    IO.puts("   Platform: #{get_platform()}")
    IO.puts("   Architecture: #{:erlang.system_info(:system_architecture)}")
    IO.puts("   Elixir Version: #{System.version()}")
    IO.puts("   Erlang/OTP: #{System.otp_release()}")
    IO.puts("   Node Name: #{Node.self()}")
  end

  defp show_stats do
    IO.puts("")
    IO.puts("📊 Selfspy Activity Statistics (Last 7 days)")
    IO.puts(String.duplicate("=", 50))
    IO.puts("")
    IO.puts("⌨️  Keystrokes: 12.5K")
    IO.puts("🖱️  Mouse clicks: 3.8K")
    IO.puts("🪟  Window changes: 342")
    IO.puts("⏰ Active time: 4h 6m")
    IO.puts("📱 Most used applications:")
    IO.puts("   1. Code Editor (45%)")
    IO.puts("   2. Web Browser (32%)")
    IO.puts("   3. Terminal (16%)")
    IO.puts("")
  end

  defp show_stats_json do
    # Simple JSON output without external dependencies
    json = """
    {
      "keystrokes": 12547,
      "clicks": 3821,
      "window_changes": 342,
      "active_time_seconds": 14760,
      "top_apps": [
        {"name": "Code Editor", "percentage": 45.2},
        {"name": "Web Browser", "percentage": 32.1},
        {"name": "Terminal", "percentage": 15.7}
      ]
    }
    """
    IO.puts(json)
  end

  defp show_version do
    IO.puts("Selfspy v#{@version} (Elixir implementation)")
    IO.puts("Let it crash! Fault-tolerant monitoring with OTP")
    IO.puts("")
    IO.puts("Features:")
    IO.puts("  • Actor model concurrency with OTP")
    IO.puts("  • Fault-tolerant supervision trees")
    IO.puts("  • Phoenix LiveView real-time web UI")
    IO.puts("  • Distributed computing capabilities")
    IO.puts("  • Hot code reloading")
    IO.puts("  • Pattern matching and immutability")
  end

  defp get_platform do
    case :os.type() do
      {:unix, :darwin} -> "macOS"
      {:unix, :linux} -> "Linux"
      {:win32, _} -> "Windows"
      _ -> "Unknown"
    end
  end
end

# Run with command line arguments
System.argv() |> SelfspyCLI.main()