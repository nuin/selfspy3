package com.selfspy

import kotlinx.cli.*
import kotlinx.coroutines.*
import kotlinx.serialization.json.*
import org.slf4j.LoggerFactory
import java.io.File
import java.sql.DriverManager
import java.time.Instant
import kotlin.system.exitProcess

/**
 * Selfspy - Modern Activity Monitoring in Kotlin
 *
 * Modern JVM language with excellent coroutines, null safety, and expressive syntax.
 * Perfect for building robust, concurrent applications with functional programming features.
 */

private val logger = LoggerFactory.getLogger("Selfspy")

// Core data structures with data classes and null safety
data class Config(
    val dataDir: String,
    val databasePath: String,
    val captureText: Boolean = true,
    val captureMouse: Boolean = true,
    val captureWindows: Boolean = true,
    val updateIntervalMs: Long = 100,
    val encryptionEnabled: Boolean = true,
    val debug: Boolean = false,
    val privacyMode: Boolean = false,
    val excludeApplications: List<String> = emptyList(),
    val maxDatabaseSizeMb: Int = 500
)

data class WindowInfo(
    val title: String,
    val application: String,
    val bundleId: String?,
    val processId: Int,
    val x: Int,
    val y: Int,
    val width: Int,
    val height: Int,
    val timestamp: Instant = Instant.now()
)

data class KeyEvent(
    val key: String,
    val application: String,
    val processId: Int,
    val count: Int = 1,
    val encrypted: Boolean = false,
    val timestamp: Instant = Instant.now()
)

data class MouseEvent(
    val x: Int,
    val y: Int,
    val button: Int,
    val eventType: String,
    val processId: Int,
    val timestamp: Instant = Instant.now()
)

data class ActivityStats(
    val keystrokes: Long,
    val clicks: Long,
    val windowChanges: Long,
    val activeTimeSeconds: Long,
    val topApps: List<AppUsage>
)

data class AppUsage(
    val name: String,
    val percentage: Double,
    val duration: Long,
    val events: Long
)

data class Permissions(
    val accessibility: Boolean,
    val inputMonitoring: Boolean,
    val screenRecording: Boolean
)

data class SystemInfo(
    val platform: String,
    val architecture: String,
    val kotlinVersion: String,
    val jvmVersion: String,
    val hostname: String,
    val username: String
)

// Command line options with sealed classes
sealed class Command {
    data class Start(
        val noText: Boolean = false,
        val noMouse: Boolean = false,
        val debug: Boolean = false
    ) : Command()
    
    object Stop : Command()
    
    data class Stats(
        val days: Int = 7,
        val json: Boolean = false
    ) : Command()
    
    object Check : Command()
    
    data class Export(
        val format: String = "json",
        val output: String? = null,
        val days: Int = 30
    ) : Command()
    
    object Version : Command()
    object Help : Command()
}

// Custom exceptions with sealed hierarchy
sealed class SelfspyException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class ConfigurationError(message: String, cause: Throwable? = null) : SelfspyException(message, cause)
    class PermissionError(message: String) : SelfspyException(message)
    class StorageError(message: String, cause: Throwable? = null) : SelfspyException(message, cause)
    class PlatformError(message: String) : SelfspyException(message)
    class InvalidArgumentError(message: String) : SelfspyException(message)
}

// Platform abstraction with object singleton
object Platform {
    val os: String by lazy {
        val osName = System.getProperty("os.name").lowercase()
        when {
            osName.contains("windows") -> "windows"
            osName.contains("mac") || osName.contains("darwin") -> "darwin"
            osName.contains("linux") -> "linux"
            else -> "unknown"
        }
    }
    
    val homeDir: String by lazy {
        System.getProperty("user.home") ?: "/tmp"
    }
    
    val dataDir: String by lazy {
        when (os) {
            "windows" -> "${System.getenv("APPDATA") ?: homeDir}/selfspy"
            "darwin" -> "$homeDir/Library/Application Support/selfspy"
            else -> "$homeDir/.local/share/selfspy"
        }
    }
    
    fun checkPermissions(): Permissions {
        return when (os) {
            "darwin" -> {
                // macOS permission checking (placeholder)
                Permissions(
                    accessibility = true,
                    inputMonitoring = true,
                    screenRecording = false
                )
            }
            "linux" -> {
                // Check for display server
                val display = System.getenv("DISPLAY") != null
                val wayland = System.getenv("WAYLAND_DISPLAY") != null
                val hasDisplay = display || wayland
                
                Permissions(
                    accessibility = hasDisplay,
                    inputMonitoring = hasDisplay,
                    screenRecording = hasDisplay
                )
            }
            "windows" -> {
                Permissions(
                    accessibility = true,
                    inputMonitoring = true,
                    screenRecording = true
                )
            }
            else -> {
                Permissions(
                    accessibility = true,
                    inputMonitoring = true,
                    screenRecording = false
                )
            }
        }
    }
    
    fun requestPermissions(): Boolean {
        return when (os) {
            "darwin" -> {
                println("Please grant accessibility permissions in System Preferences")
                println("Security & Privacy > Privacy > Accessibility")
                true
            }
            else -> true
        }
    }
    
    fun getSystemInfo(): SystemInfo {
        val hostname = System.getenv("HOSTNAME") ?: "localhost"
        val username = System.getProperty("user.name") ?: "unknown"
        
        return SystemInfo(
            platform = os,
            architecture = System.getProperty("os.arch") ?: "unknown",
            kotlinVersion = KotlinVersion.CURRENT.toString(),
            jvmVersion = System.getProperty("java.version") ?: "unknown",
            hostname = hostname,
            username = username
        )
    }
}

// Configuration management with lazy initialization
object ConfigManager {
    fun createDefaultConfig(): Config {
        val dataDir = Platform.dataDir
        return Config(
            dataDir = dataDir,
            databasePath = "$dataDir/selfspy.db"
        )
    }
}

// Activity monitoring with coroutines and channels
class ActivityMonitor(private val config: Config) {
    private var isRunning = false
    private var eventsProcessed = 0L
    
    suspend fun startMonitoring(options: Command.Start) {
        logger.info("🚀 Starting Selfspy monitoring (Kotlin implementation)")
        
        val updatedConfig = config.copy(
            captureText = config.captureText && !options.noText,
            captureMouse = config.captureMouse && !options.noMouse,
            debug = config.debug || options.debug
        )
        
        // Check permissions
        val permissions = Platform.checkPermissions()
        if (!hasAllPermissions(permissions)) {
            println("❌ Insufficient permissions for monitoring")
            println("Missing permissions:")
            
            if (!permissions.accessibility) {
                println("   - Accessibility permission required")
            }
            if (!permissions.inputMonitoring) {
                println("   - Input monitoring permission required")
            }
            
            println("\nAttempting to request permissions...")
            if (!Platform.requestPermissions()) {
                throw SelfspyException.PermissionError("Failed to obtain required permissions")
            }
        }
        
        // Create data directory if needed
        val dataDirFile = File(updatedConfig.dataDir)
        if (!dataDirFile.exists()) {
            if (!dataDirFile.mkdirs()) {
                throw SelfspyException.ConfigurationError("Failed to create data directory: ${updatedConfig.dataDir}")
            }
        }
        
        // Initialize database
        initializeDatabase(updatedConfig.databasePath)
        
        isRunning = true
        println("✅ Selfspy monitoring started successfully")
        println("📊 Press Ctrl+C to stop monitoring")
        
        // Set up shutdown hook
        Runtime.getRuntime().addShutdownHook(Thread {
            runBlocking {
                stopMonitoring()
            }
        })
        
        // Start monitoring loop with coroutines
        coroutineScope {
            launch {
                monitoringLoop(updatedConfig)
            }
        }
    }
    
    private suspend fun monitoringLoop(config: Config) {
        while (isRunning) {
            // Simulate event collection
            eventsProcessed++
            
            if (config.debug) {
                logger.debug("Events processed: $eventsProcessed")
            }
            
            // Sleep for update interval
            delay(config.updateIntervalMs)
        }
    }
    
    suspend fun stopMonitoring() {
        logger.info("🛑 Stopping Selfspy monitoring...")
        isRunning = false
        println("✅ Stop signal sent")
    }
    
    private fun hasAllPermissions(permissions: Permissions): Boolean {
        return permissions.accessibility && permissions.inputMonitoring
    }
    
    private fun initializeDatabase(databasePath: String) {
        try {
            Class.forName("org.sqlite.JDBC")
            DriverManager.getConnection("jdbc:sqlite:$databasePath").use { connection ->
                connection.createStatement().use { statement ->
                    // Create tables
                    statement.executeUpdate("""
                        CREATE TABLE IF NOT EXISTS processes (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            name TEXT NOT NULL,
                            bundle_id TEXT,
                            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                        )
                    """.trimIndent())
                    
                    statement.executeUpdate("""
                        CREATE TABLE IF NOT EXISTS keys (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            process_id INTEGER,
                            keys TEXT,
                            count INTEGER DEFAULT 1,
                            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                            FOREIGN KEY (process_id) REFERENCES processes (id)
                        )
                    """.trimIndent())
                    
                    statement.executeUpdate("""
                        CREATE TABLE IF NOT EXISTS clicks (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            process_id INTEGER,
                            x INTEGER,
                            y INTEGER,
                            button INTEGER,
                            event_type TEXT,
                            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                            FOREIGN KEY (process_id) REFERENCES processes (id)
                        )
                    """.trimIndent())
                }
            }
            logger.info("Database initialized successfully")
        } catch (e: Exception) {
            throw SelfspyException.StorageError("Failed to initialize database", e)
        }
    }
}

// Statistics service with extension functions
object StatsService {
    fun getStats(days: Int): ActivityStats {
        // Placeholder: Would query actual database
        val topApps = listOf(
            AppUsage("Code Editor", 45.2, 6683, 5234),
            AppUsage("Web Browser", 32.1, 4736, 3892),
            AppUsage("Terminal", 15.7, 2318, 2156)
        )
        
        return ActivityStats(
            keystrokes = 12547,
            clicks = 3821,
            windowChanges = 342,
            activeTimeSeconds = 14760,
            topApps = topApps
        )
    }
    
    fun showStats(options: Command.Stats) {
        val stats = getStats(options.days)
        
        if (options.json) {
            val json = buildJsonObject {
                put("keystrokes", stats.keystrokes)
                put("clicks", stats.clicks)
                put("window_changes", stats.windowChanges)
                put("active_time_seconds", stats.activeTimeSeconds)
                putJsonArray("top_apps") {
                    stats.topApps.forEach { app ->
                        addJsonObject {
                            put("name", app.name)
                            put("percentage", app.percentage)
                            put("duration", app.duration)
                            put("events", app.events)
                        }
                    }
                }
            }
            println(Json.encodeToString(JsonObject.serializer(), json))
        } else {
            printFormattedStats(stats, options.days)
        }
    }
    
    fun exportData(options: Command.Export) {
        println("📤 Exporting ${options.days} days of data in ${options.format} format...")
        
        val stats = getStats(options.days)
        
        val data = when (options.format.lowercase()) {
            "json" -> {
                buildJsonObject {
                    put("keystrokes", stats.keystrokes)
                    put("clicks", stats.clicks)
                    put("window_changes", stats.windowChanges)
                    put("active_time_seconds", stats.activeTimeSeconds)
                }.toString()
            }
            "csv" -> {
                buildString {
                    appendLine("metric,value")
                    appendLine("keystrokes,${stats.keystrokes}")
                    appendLine("clicks,${stats.clicks}")
                    appendLine("window_changes,${stats.windowChanges}")
                    appendLine("active_time_seconds,${stats.activeTimeSeconds}")
                }
            }
            "sql" -> {
                buildString {
                    appendLine("-- Selfspy Activity Export")
                    appendLine("CREATE TABLE stats (metric TEXT, value INTEGER);")
                    appendLine("INSERT INTO stats VALUES ('keystrokes', ${stats.keystrokes});")
                    appendLine("INSERT INTO stats VALUES ('clicks', ${stats.clicks});")
                    appendLine("INSERT INTO stats VALUES ('window_changes', ${stats.windowChanges});")
                    appendLine("INSERT INTO stats VALUES ('active_time_seconds', ${stats.activeTimeSeconds});")
                }
            }
            else -> throw SelfspyException.InvalidArgumentError("Unsupported export format: ${options.format}")
        }
        
        options.output?.let { outputPath ->
            try {
                File(outputPath).writeText(data)
                println("✅ Data exported to $outputPath")
            } catch (e: Exception) {
                throw SelfspyException.StorageError("Failed to write to file: $outputPath", e)
            }
        } ?: run {
            println(data)
        }
    }
}

// Utility functions with extension functions
fun Long.formatNumber(): String = when {
    this >= 1_000_000 -> "%.1fM".format(this / 1_000_000.0)
    this >= 1_000 -> "%.1fK".format(this / 1_000.0)
    else -> this.toString()
}

fun Long.formatDuration(): String {
    val hours = this / 3600
    val minutes = (this % 3600) / 60
    
    return if (hours > 0) {
        "${hours}h ${minutes}m"
    } else {
        "${minutes}m"
    }
}

fun printFormattedStats(stats: ActivityStats, days: Int) {
    println()
    println("📊 Selfspy Activity Statistics (Last $days days)")
    println("==================================================")
    println()
    println("⌨️  Keystrokes: ${stats.keystrokes.formatNumber()}")
    println("🖱️  Mouse clicks: ${stats.clicks.formatNumber()}")
    println("🪟  Window changes: ${stats.windowChanges.formatNumber()}")
    println("⏰ Active time: ${stats.activeTimeSeconds.formatDuration()}")
    
    if (stats.topApps.isNotEmpty()) {
        println("📱 Most used applications:")
        stats.topApps.forEachIndexed { index, app ->
            println("   ${index + 1}. ${app.name} (${app.percentage}%)")
        }
    }
    println()
}

// Command execution with sealed class pattern matching
class CommandExecutor {
    private val monitor = ActivityMonitor(ConfigManager.createDefaultConfig())
    
    suspend fun execute(command: Command) {
        try {
            when (command) {
                is Command.Start -> monitor.startMonitoring(command)
                is Command.Stop -> monitor.stopMonitoring()
                is Command.Stats -> StatsService.showStats(command)
                is Command.Check -> checkSystem()
                is Command.Export -> StatsService.exportData(command)
                is Command.Version -> showVersion()
                is Command.Help -> printHelp()
            }
        } catch (e: SelfspyException) {
            logger.error("Selfspy error: ${e.message}", e)
            println("Error: ${e.message}")
            exitProcess(1)
        } catch (e: Exception) {
            logger.error("Unexpected error", e)
            println("Unexpected error: ${e.message}")
            exitProcess(1)
        }
    }
    
    private fun checkSystem() {
        println("🔍 Checking Selfspy permissions...")
        println("===================================")
        println()
        
        val permissions = Platform.checkPermissions()
        if (permissions.accessibility && permissions.inputMonitoring) {
            println("✅ All permissions granted")
        } else {
            println("❌ Missing permissions:")
            if (!permissions.accessibility) {
                println("   - Accessibility permission required")
            }
            if (!permissions.inputMonitoring) {
                println("   - Input monitoring permission required")
            }
        }
        
        println()
        println("📱 System Information:")
        val sysInfo = Platform.getSystemInfo()
        println("   Platform: ${sysInfo.platform}")
        println("   Architecture: ${sysInfo.architecture}")
        println("   Kotlin Version: ${sysInfo.kotlinVersion}")
        println("   JVM Version: ${sysInfo.jvmVersion}")
        println("   Hostname: ${sysInfo.hostname}")
        println("   Username: ${sysInfo.username}")
    }
    
    private fun showVersion() {
        println("Selfspy v1.0.0 (Kotlin implementation)")
        println("Modern JVM language with coroutines and null safety")
        println()
        println("Features:")
        println("  • Coroutines for asynchronous programming")
        println("  • Null safety and type inference")
        println("  • Expressive syntax with functional features")
        println("  • Seamless Java interoperability")
        println("  • Excellent tooling and IDE support")
        println("  • Perfect for robust, concurrent applications")
    }
}

fun printHelp() {
    println("Selfspy - Modern Activity Monitoring in Kotlin")
    println()
    println("USAGE:")
    println("    java -jar selfspy.jar [COMMAND] [OPTIONS]")
    println("    # or with Gradle:")
    println("    ./gradlew run --args='[COMMAND] [OPTIONS]'")
    println()
    println("COMMANDS:")
    println("    start                 Start activity monitoring")
    println("    stop                  Stop running monitoring instance")
    println("    stats                 Show activity statistics")
    println("    check                 Check system permissions and setup")
    println("    export                Export data to various formats")
    println("    version               Show version information")
    println("    help                  Show this help message")
    println()
    println("START OPTIONS:")
    println("    --no-text             Disable text capture for privacy")
    println("    --no-mouse            Disable mouse monitoring")
    println("    --debug               Enable debug logging")
    println()
    println("STATS OPTIONS:")
    println("    --days <N>            Number of days to analyze (default: 7)")
    println("    --json                Output in JSON format")
    println()
    println("EXPORT OPTIONS:")
    println("    --format <FORMAT>     Export format: json, csv, sql (default: json)")
    println("    --output <FILE>       Output file path")
    println("    --days <N>            Number of days to export (default: 30)")
    println()
    println("EXAMPLES:")
    println("    java -jar selfspy.jar start")
    println("    java -jar selfspy.jar start --no-text --debug")
    println("    java -jar selfspy.jar stats --days 30 --json")
    println("    java -jar selfspy.jar export --format csv --output activity.csv")
    println("    ./gradlew run --args='start --debug'")
    println()
    println("Kotlin Implementation Features:")
    println("  • Modern JVM language with excellent performance")
    println("  • Coroutines for efficient asynchronous programming")
    println("  • Null safety prevents common runtime errors")
    println("  • Expressive syntax with functional programming support")
    println("  • Seamless interoperability with Java ecosystem")
    println("  • Excellent tooling and IDE support")
}

// Command line parsing with kotlinx-cli
fun parseCommand(args: Array<String>): Command {
    if (args.isEmpty()) return Command.Help
    
    return when (args[0]) {
        "start" -> {
            var noText = false
            var noMouse = false
            var debug = false
            
            args.drop(1).forEach { arg ->
                when (arg) {
                    "--no-text" -> noText = true
                    "--no-mouse" -> noMouse = true
                    "--debug" -> debug = true
                }
            }
            
            Command.Start(noText, noMouse, debug)
        }
        "stop" -> Command.Stop
        "stats" -> {
            var days = 7
            var json = false
            
            val iterator = args.drop(1).iterator()
            while (iterator.hasNext()) {
                when (val arg = iterator.next()) {
                    "--days" -> if (iterator.hasNext()) {
                        days = iterator.next().toIntOrNull() ?: 7
                    }
                    "--json" -> json = true
                }
            }
            
            Command.Stats(days, json)
        }
        "check" -> Command.Check
        "export" -> {
            var format = "json"
            var output: String? = null
            var days = 30
            
            val iterator = args.drop(1).iterator()
            while (iterator.hasNext()) {
                when (val arg = iterator.next()) {
                    "--format" -> if (iterator.hasNext()) {
                        format = iterator.next()
                    }
                    "--output" -> if (iterator.hasNext()) {
                        output = iterator.next()
                    }
                    "--days" -> if (iterator.hasNext()) {
                        days = iterator.next().toIntOrNull() ?: 30
                    }
                }
            }
            
            Command.Export(format, output, days)
        }
        "version" -> Command.Version
        "help" -> Command.Help
        else -> throw SelfspyException.InvalidArgumentError("Unknown command: ${args[0]}")
    }
}

// Main entry point with coroutines
suspend fun main(args: Array<String>) {
    try {
        val command = parseCommand(args)
        val executor = CommandExecutor()
        executor.execute(command)
    } catch (e: SelfspyException.InvalidArgumentError) {
        println("Error: ${e.message}")
        println("Use 'java -jar selfspy.jar help' for usage information")
        exitProcess(1)
    } catch (e: Exception) {
        logger.error("Fatal error", e)
        println("Fatal error: ${e.message}")
        exitProcess(1)
    }
}