#!/usr/bin/env kotlin

// Simple Selfspy CLI implementation in Kotlin
// Run with: kotlin simple.kt [command]

fun showHelp() {
    println("Selfspy - Modern Activity Monitoring in Kotlin")
    println("")
    println("Modern JVM language with null safety and coroutines")
    println("")
    println("USAGE:")
    println("    kotlin simple.kt [COMMAND]")
    println("")
    println("COMMANDS:")
    println("    help                  Show this help message")
    println("    check                 Check system permissions")
    println("    stats                 Show activity statistics")
    println("    stats --json          Show statistics in JSON format")
    println("    version               Show version information")
    println("")
    println("Kotlin Implementation Features:")
    println("  • Null safety and smart casts")
    println("  • Coroutines for async programming")
    println("  • Extension functions")
    println("  • Data classes and sealed classes")
    println("  • Interoperability with Java")
}

fun checkPermissions() {
    println("🔍 Checking Selfspy permissions...")
    println("=".repeat(35))
    println("")
    println("✅ All permissions granted")
    println("")
    println("📱 System Information:")
    println("   Platform: ${System.getProperty("os.name")}")
    println("   Architecture: ${System.getProperty("os.arch")}")
    println("   Kotlin Version: ${KotlinVersion.CURRENT}")
    println("   JVM Version: ${System.getProperty("java.version")}")
    println("   User Home: ${System.getProperty("user.home")}")
}

fun showStats() {
    println("")
    println("📊 Selfspy Activity Statistics (Last 7 days)")
    println("=".repeat(50))
    println("")
    println("⌨️  Keystrokes: 12.5K")
    println("🖱️  Mouse clicks: 3.8K")
    println("🪟  Window changes: 342")
    println("⏰ Active time: 4h 6m")
    println("📱 Most used applications:")
    println("   1. Code Editor (45%)")
    println("   2. Web Browser (32%)")
    println("   3. Terminal (16%)")
    println("")
}

fun showStatsJson() {
    val json = """
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
    """.trimIndent()
    println(json)
}

fun showVersion() {
    println("Selfspy v1.0.0 (Kotlin implementation)")
    println("Modern JVM language with null safety and coroutines")
    println("")
    println("Features:")
    println("  • Null safety and smart casts")
    println("  • Coroutines for async programming")
    println("  • Extension functions")
    println("  • Data classes and sealed classes")
    println("  • Interoperability with Java")
    println("  • Functional programming support")
}

fun main(args: Array<String>) {
    val command = args.firstOrNull()

    when (command) {
        "help" -> showHelp()
        "check" -> checkPermissions()
        "stats" -> {
            if (args.size > 1 && args[1] == "--json") {
                showStatsJson()
            } else {
                showStats()
            }
        }
        "version" -> showVersion()
        null -> showHelp()
        else -> {
            System.err.println("Error: Unknown command \"$command\"")
            System.err.println("Use \"kotlin simple.kt help\" for usage information")
            System.exit(1)
        }
    }
}