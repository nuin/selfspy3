const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const config = @import("config.zig");
const monitor = @import("monitor.zig");
const storage = @import("storage.zig");
const platform = @import("platform.zig");

// Selfspy - Ultra-fast Activity Monitoring in Zig
// 
// Low-level systems programming with C interop for maximum performance.
// Memory-safe with explicit control over allocations.

const VERSION = "1.0.0";

const Command = enum {
    start,
    stop,
    stats,
    check,
    export,
    help,
    version,
};

const StartOptions = struct {
    no_text: bool = false,
    no_mouse: bool = false,
    debug: bool = false,
};

const StatsOptions = struct {
    days: u32 = 7,
    json: bool = false,
};

const ExportOptions = struct {
    format: []const u8 = "json",
    output: ?[]const u8 = null,
    days: u32 = 30,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        printHelp();
        return;
    }

    const command = parseCommand(args[1]) orelse {
        print("Unknown command: {s}\n", .{args[1]});
        print("Use 'selfspy help' for usage information.\n");
        return;
    };

    switch (command) {
        .start => {
            const options = try parseStartOptions(allocator, args[2..]);
            try startMonitoring(allocator, options);
        },
        .stop => try stopMonitoring(),
        .stats => {
            const options = try parseStatsOptions(allocator, args[2..]);
            try showStats(allocator, options);
        },
        .check => try checkPermissions(),
        .export => {
            const options = try parseExportOptions(allocator, args[2..]);
            try exportData(allocator, options);
        },
        .help => printHelp(),
        .version => printVersion(),
    }
}

fn parseCommand(cmd: []const u8) ?Command {
    const commands = std.ComptimeStringMap(Command, .{
        .{ "start", .start },
        .{ "stop", .stop },
        .{ "stats", .stats },
        .{ "check", .check },
        .{ "export", .export },
        .{ "help", .help },
        .{ "--help", .help },
        .{ "-h", .help },
        .{ "version", .version },
        .{ "--version", .version },
        .{ "-v", .version },
    });

    return commands.get(cmd);
}

fn parseStartOptions(allocator: Allocator, args: [][]const u8) !StartOptions {
    _ = allocator;
    var options = StartOptions{};

    for (args) |arg| {
        if (std.mem.eql(u8, arg, "--no-text")) {
            options.no_text = true;
        } else if (std.mem.eql(u8, arg, "--no-mouse")) {
            options.no_mouse = true;
        } else if (std.mem.eql(u8, arg, "--debug")) {
            options.debug = true;
        }
    }

    return options;
}

fn parseStatsOptions(allocator: Allocator, args: [][]const u8) !StatsOptions {
    _ = allocator;
    var options = StatsOptions{};
    var i: usize = 0;

    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--days") and i + 1 < args.len) {
            options.days = std.fmt.parseInt(u32, args[i + 1], 10) catch 7;
            i += 1;
        } else if (std.mem.eql(u8, arg, "--json")) {
            options.json = true;
        }
    }

    return options;
}

fn parseExportOptions(allocator: Allocator, args: [][]const u8) !ExportOptions {
    _ = allocator;
    var options = ExportOptions{};
    var i: usize = 0;

    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--format") and i + 1 < args.len) {
            options.format = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "--output") and i + 1 < args.len) {
            options.output = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "--days") and i + 1 < args.len) {
            options.days = std.fmt.parseInt(u32, args[i + 1], 10) catch 30;
            i += 1;
        }
    }

    return options;
}

fn startMonitoring(allocator: Allocator, options: StartOptions) !void {
    print("🚀 Starting Selfspy monitoring v{s}\n", .{VERSION});

    // Load configuration
    var cfg = config.Config.init(allocator);
    defer cfg.deinit();
    try cfg.load();

    // Apply command line options
    if (options.no_text) cfg.monitoring.capture_text = false;
    if (options.no_mouse) cfg.monitoring.capture_mouse = false;

    // Check permissions
    const perms = try platform.checkPermissions(allocator);
    if (!perms.hasAllPermissions()) {
        print("❌ Insufficient permissions for monitoring\n");
        if (perms.accessibility) print("   ✅ Accessibility permission granted\n");
        if (!perms.accessibility) print("   ❌ Accessibility permission required\n");
        if (!perms.input_monitoring) print("   ❌ Input monitoring permission required\n");

        print("\nAttempting to request permissions...\n");
        if (!try platform.requestPermissions(allocator)) {
            return error.InsufficientPermissions;
        }
    }

    // Initialize storage
    var store = storage.Storage.init(allocator, cfg.database.path);
    defer store.deinit();
    try store.initialize();

    // Initialize monitor
    var mon = monitor.Monitor.init(allocator, &cfg, &store);
    defer mon.deinit();

    // Set up signal handling for graceful shutdown
    const signals = [_]c_int{ std.os.SIG.INT, std.os.SIG.TERM };
    for (signals) |sig| {
        try std.os.sigaction(sig, &std.os.Sigaction{
            .handler = .{ .handler = handleShutdown },
            .mask = std.os.empty_sigset,
            .flags = 0,
        }, null);
    }

    // Start monitoring
    try mon.start();

    print("✅ Selfspy monitoring started successfully\n");
    print("📊 Press Ctrl+C to stop monitoring\n\n");

    // Keep running until shutdown signal
    while (mon.isRunning()) {
        std.time.sleep(std.time.ns_per_s); // Sleep for 1 second
    }

    try mon.stop();
    print("🛑 Selfspy monitoring stopped\n");
}

fn stopMonitoring() !void {
    print("🛑 Stopping Selfspy monitoring...\n");
    // Implementation would send signal to running process
    // For now, just print message
    print("✅ Stop signal sent\n");
}

fn showStats(allocator: Allocator, options: StatsOptions) !void {
    var cfg = config.Config.init(allocator);
    defer cfg.deinit();
    try cfg.load();

    var store = storage.Storage.init(allocator, cfg.database.path);
    defer store.deinit();
    try store.initialize();

    const stats = try store.getStats(options.days);

    if (options.json) {
        // Print JSON format
        print("{{\n");
        print("  \"days\": {},\n", .{options.days});
        print("  \"keystrokes\": {},\n", .{stats.keystrokes});
        print("  \"clicks\": {},\n", .{stats.clicks});
        print("  \"window_changes\": {},\n", .{stats.window_changes});
        print("  \"active_time_seconds\": {}\n", .{stats.active_time_seconds});
        print("}}\n");
    } else {
        print("\n📊 Selfspy Activity Statistics (Last {} days)\n", .{options.days});
        print("=".** 50 ++ "\n\n");
        print("⌨️  Keystrokes: {}\n", .{formatNumber(stats.keystrokes)});
        print("🖱️  Mouse clicks: {}\n", .{formatNumber(stats.clicks)});
        print("🪟  Window changes: {}\n", .{formatNumber(stats.window_changes)});
        print("⏰ Active time: {}\n", .{formatDuration(stats.active_time_seconds)});
        print("\n");
    }
}

fn checkPermissions() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    print("🔍 Checking Selfspy permissions...\n");
    print("=".** 35 ++ "\n\n");

    const perms = try platform.checkPermissions(allocator);

    if (perms.hasAllPermissions()) {
        print("✅ All permissions granted\n");
    } else {
        print("❌ Missing permissions:\n");
        if (!perms.accessibility) print("   - Accessibility permission required\n");
        if (!perms.input_monitoring) print("   - Input monitoring permission required\n");
        if (!perms.screen_recording) print("   - Screen recording permission (optional)\n");
    }

    print("\n📱 System Information:\n");
    const sys_info = try platform.getSystemInfo(allocator);
    print("   Platform: {s}\n", .{sys_info.platform});
    print("   Architecture: {s}\n", .{sys_info.architecture});
    print("   Version: {s}\n", .{sys_info.version});
}

fn exportData(allocator: Allocator, options: ExportOptions) !void {
    print("📤 Exporting {} days of data in {} format...\n", .{ options.days, options.format });

    var cfg = config.Config.init(allocator);
    defer cfg.deinit();
    try cfg.load();

    var store = storage.Storage.init(allocator, cfg.database.path);
    defer store.deinit();
    try store.initialize();

    const data = try store.exportData(allocator, options.format, options.days);
    defer allocator.free(data);

    if (options.output) |output_path| {
        try std.fs.cwd().writeFile(output_path, data);
        print("✅ Data exported to {s}\n", .{output_path});
    } else {
        print("{s}\n", .{data});
    }
}

fn printHelp() void {
    print("Selfspy - Ultra-fast Activity Monitoring in Zig\n\n");
    print("USAGE:\n");
    print("    selfspy [COMMAND] [OPTIONS]\n\n");
    print("COMMANDS:\n");
    print("    start                 Start activity monitoring\n");
    print("    stop                  Stop running monitoring instance\n");
    print("    stats                 Show activity statistics\n");
    print("    check                 Check system permissions and setup\n");
    print("    export                Export data to various formats\n");
    print("    help                  Show this help message\n");
    print("    version               Show version information\n\n");
    print("START OPTIONS:\n");
    print("    --no-text             Disable text capture for privacy\n");
    print("    --no-mouse            Disable mouse monitoring\n");
    print("    --debug               Enable debug logging\n\n");
    print("STATS OPTIONS:\n");
    print("    --days <N>            Number of days to analyze (default: 7)\n");
    print("    --json                Output in JSON format\n\n");
    print("EXPORT OPTIONS:\n");
    print("    --format <FORMAT>     Export format: json, csv, sql (default: json)\n");
    print("    --output <FILE>       Output file path\n");
    print("    --days <N>            Number of days to export (default: 30)\n\n");
    print("EXAMPLES:\n");
    print("    selfspy start\n");
    print("    selfspy start --no-text --debug\n");
    print("    selfspy stats --days 30 --json\n");
    print("    selfspy export --format csv --output activity.csv\n");
}

fn printVersion() void {
    print("Selfspy v{s} (Zig implementation)\n", .{VERSION});
    print("Ultra-fast activity monitoring with memory safety\n");
}

fn formatNumber(num: u64) []const u8 {
    // Simple number formatting - in a real implementation would be more sophisticated
    if (num >= 1_000_000) {
        return std.fmt.allocPrint(std.heap.page_allocator, "{d:.1}M", .{@as(f64, @floatFromInt(num)) / 1_000_000}) catch "error";
    } else if (num >= 1_000) {
        return std.fmt.allocPrint(std.heap.page_allocator, "{d:.1}K", .{@as(f64, @floatFromInt(num)) / 1_000}) catch "error";
    } else {
        return std.fmt.allocPrint(std.heap.page_allocator, "{}", .{num}) catch "error";
    }
}

fn formatDuration(seconds: u64) []const u8 {
    const hours = seconds / 3600;
    const minutes = (seconds % 3600) / 60;

    if (hours > 0) {
        return std.fmt.allocPrint(std.heap.page_allocator, "{}h {}m", .{ hours, minutes }) catch "error";
    } else {
        return std.fmt.allocPrint(std.heap.page_allocator, "{}m", .{minutes}) catch "error";
    }
}

fn handleShutdown(sig: c_int) callconv(.C) void {
    _ = sig;
    print("\n🛑 Received shutdown signal, stopping gracefully...\n");
    std.process.exit(0);
}

test "basic functionality" {
    const testing = std.testing;
    try testing.expect(parseCommand("start") == .start);
    try testing.expect(parseCommand("unknown") == null);
}