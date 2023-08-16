const std = @import("std");
const Allocator = std.mem.Allocator;

const multihash = @import("multihash.zig");
const crypto = @import("crypto");

test "generate id from public key" {
    var kp = try crypto.generateEd25519KeyPair();

    const mh = try multihash.multihashFromPublicKey(kp.public_key, std.testing.allocator);
    defer mh.deinit();

    std.debug.print("0x{}\n", .{std.fmt.fmtSliceHexLower(mh.bytes)});
    std.debug.print("encoded val: {s}", .{mh.encoded});
}
