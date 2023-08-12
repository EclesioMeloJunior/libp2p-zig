const std = @import("std");
const ed25519 = std.crypto.sign.Ed25519;
const Allocator = std.mem.Allocator;

const base58 = @import("base58");
const crypto = @import("crypto");
const multihash = @import("multihash.zig");

const maxInlineKeyLength = 42;

fn multihashFromPublicKey(pub_key: ed25519.PublicKey, allocator: Allocator) !*multihash.Multihash {
    const encodedPubKey = try crypto.marshalEd25519PublicKey(pub_key, allocator);
    defer allocator.free(encodedPubKey);

    var mh: *multihash.Multihash = undefined;
    if (encodedPubKey.len <= maxInlineKeyLength) {
        mh = try multihash.identitySum(encodedPubKey, allocator);
    } else {
        mh = try multihash.sha2_256Sum(encodedPubKey, allocator);
    }

    return mh;
}

test "generate id from public key" {
    var kp = try crypto.generateEd25519KeyPair();

    const mh = try multihashFromPublicKey(kp.public_key, std.testing.allocator);
    defer mh.deinit();

    std.debug.print("{any}", .{mh.bytes});
}
