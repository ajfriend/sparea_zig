const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("sparea", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const mod_tests = b.addTest(.{
        .name = "sparea-test",
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

    // `zig build install-test` produces `zig-out/bin/sparea-test`, the
    // test binary built without running. Used by the kcov-based
    // coverage recipe in the justfile.
    const install_test = b.addInstallArtifact(mod_tests, .{});
    const install_test_step = b.step("install-test", "Install the test binary at zig-out/bin/sparea-test");
    install_test_step.dependOn(&install_test.step);
}
