const std = @import("std");
const ed25519 = std.crypto.sign.Ed25519;
const Allocator = std.mem.Allocator;

const crypto = @import("../crypto/crypto.zig");
const multihash = @import("multihash.zig");

const maxInlineKeyLength = 42;
const ID = []u8;

fn IDFromPublicKey(pub_key: ed25519.PublicKey, allocator: Allocator) !ID {
    const encodedPubKey = try crypto.marshalEd25519PublicKey(pub_key, allocator);

    if (encodedPubKey.len <= maxInlineKeyLength) {
        multihash.identitySum(encodedPubKey);
    } else {
        multihash.SHA2_256Sum(encodedPubKey, -1);
    }
}
