const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const example_client_exe = b.addExecutable(.{
        .name = "client-libp2p",
        .root_source_file = .{ .path = "example/zig/client.zig" },
        .target = target,
        .optimize = optimize,
    });

    addModules(b, example_client_exe);
    b.installArtifact(example_client_exe);

    var tests = [_]*std.build.LibExeObjStep{ b.addTest(
        .{
            .name = "varint",
            .root_source_file = .{ .path = "src/varint/varint.zig" },
            .target = target,
            .optimize = optimize,
        },
    ), b.addTest(
        .{
            .name = "crypto",
            .root_source_file = .{ .path = "src/crypto/crypto.zig" },
            .target = target,
            .optimize = optimize,
        },
    ), b.addTest(
        .{
            .name = "peer",
            .root_source_file = .{ .path = "src/peer/peer.zig" },
            .target = target,
            .optimize = optimize,
        },
    ) };

    const test_step = b.step("test", "Run library tests");

    for (tests) |test_item| {
        addModules(b, test_item);
        const run_main_tests = b.addRunArtifact(test_item);
        test_step.dependOn(&run_main_tests.step);
    }
}

fn addModules(b: *std.Build, sc: *std.Build.Step.Compile) void {
    const protobuf = b.createModule(.{
        .source_file = std.build.LazyPath.relative("zig-protobuf/src/protobuf.zig"),
        .dependencies = &[_]std.build.ModuleDependency{},
    });

    sc.addModule("protobuf", protobuf);

    const base58 = b.createModule(.{
        .source_file = std.build.LazyPath.relative("base58-zig/src/lib.zig"),
        .dependencies = &[_]std.build.ModuleDependency{},
    });

    sc.addModule("base58", base58);

    const varint = b.createModule(.{
        .source_file = std.build.LazyPath.relative("src/varint/varint.zig"),
        .dependencies = &[_]std.build.ModuleDependency{},
    });

    sc.addModule(
        "varint",
        varint,
    );

    const crypto = b.createModule(.{
        .source_file = std.build.LazyPath.relative("src/crypto/crypto.zig"),
        .dependencies = &[_]std.build.ModuleDependency{std.build.ModuleDependency{ .module = protobuf, .name = "protobuf" }},
    });

    sc.addModule(
        "crypto",
        crypto,
    );

    sc.addModule("peer", b.createModule(.{
        .source_file = std.build.LazyPath.relative("src/peer/peer.zig"),
        .dependencies = &[_]std.build.ModuleDependency{
            std.build.ModuleDependency{ .module = crypto, .name = "crypto" },
            std.build.ModuleDependency{ .module = varint, .name = "varint" },
            std.build.ModuleDependency{ .module = base58, .name = "base58" },
        },
    }));
}
