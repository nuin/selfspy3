const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    // Create the main selfspy executable
    const exe = b.addExecutable(.{
        .name = "selfspy",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add platform-specific libraries
    switch (target.result.os.tag) {
        .macos => {
            exe.linkFramework("ApplicationServices");
            exe.linkFramework("Carbon");
            exe.linkFramework("CoreGraphics");
            exe.linkFramework("Foundation");
        },
        .linux => {
            exe.linkSystemLibrary("X11");
            exe.linkSystemLibrary("Xtst");
            exe.linkSystemLibrary("Xext");
        },
        .windows => {
            exe.linkSystemLibrary("user32");
            exe.linkSystemLibrary("kernel32");
            exe.linkSystemLibrary("shell32");
        },
        else => {},
    }

    // Link SQLite
    exe.linkSystemLibrary("sqlite3");
    exe.linkLibC();

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, which can be invoked with the
    // `zig build run` command. This will start the selfspy program.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be built before
    // running if necessary.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- start --debug`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the selfspy application");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit tests. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    // Create benchmark executable
    const bench = b.addExecutable(.{
        .name = "selfspy-bench",
        .root_source_file = .{ .path = "src/bench.zig" },
        .target = target,
        .optimize = .ReleaseFast,
    });

    bench.linkLibC();
    b.installArtifact(bench);

    const run_bench = b.addRunArtifact(bench);
    const bench_step = b.step("bench", "Run performance benchmarks");
    bench_step.dependOn(&run_bench.step);
}