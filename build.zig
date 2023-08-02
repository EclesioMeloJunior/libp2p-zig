const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const clientExec = b.addExecutable(.{
        .name = "client-libp2p",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/client.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(clientExec);

    const protobuf = b.createModule(.{ .source_file = .{ .path = "zig-protobuf/src/protobuf.zig" } });

    var tests = [_]*std.build.LibExeObjStep{ b.addTest(
        .{
            .name = "varint",
            .root_source_file = .{ .path = "src/varint.zig" },
            .target = target,
            .optimize = optimize,
        },
    ), b.addTest(.{
        .name = "crypto",
        .root_source_file = .{ .path = "src/crypto/crypto.zig" },
        .target = target,
        .optimize = optimize,
    }) };

    const test_step = b.step("test", "Run library tests");

    for (tests) |test_item| {
        test_item.addModule("protobuf", protobuf);

        // This creates a build step. It will be visible in the `zig build --help` menu,
        // and can be selected like this: `zig build test`
        // This will evaluate the `test` step rather than the default, which is "install".
        const run_main_tests = b.addRunArtifact(test_item);
        test_step.dependOn(&run_main_tests.step);
    }
}
