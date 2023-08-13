const std = @import("std");
const Allocator = std.mem.Allocator;

const base58 = @import("base58");
const multihash = @import("multihash.zig");
const crypto = @import("crypto");

test "generate id from public key" {
    var kp = try crypto.generateEd25519KeyPair();

    const mh = try multihash.multihashFromPublicKey(kp.public_key, std.testing.allocator);
    defer mh.deinit();

    const bas58Encoder = base58.Encoder.init(.{});
    var dest = try std.testing.allocator.alloc(u8, mh.bytes.len * 2);
    var size = try bas58Encoder.encode(mh.bytes, dest);
    if (dest.len != size) {
        dest = try std.testing.allocator.realloc(dest, size);
    }

    defer std.testing.allocator.free(dest);

    std.debug.print("0x{}\n", .{std.fmt.fmtSliceHexLower(mh.bytes)});
    std.debug.print("encoded val: {s}", .{dest});
}
