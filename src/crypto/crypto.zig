const std = @import("std");
const Allocator = std.mem.Allocator;
const RndGen = std.rand.DefaultPrng;
const ed25519 = std.crypto.sign.Ed25519;
const secp256k1 = std.crypto.ecc.Secp256k1;

const protobuf = @import("protobuf");
const keyPair = @import("generated/crypto/pb.pb.zig");

const testing = std.testing;

const Type = enum {
    RSA,
    Ed25519,
    Secp256k1,
    ECDSA,
};

const PeerIDKey = struct { encoded_public_key: []u8 };

const TypeNotSupported = error.TypeNotSupported;

fn generateEd25519KeyPair() !ed25519.KeyPair {
    return try ed25519.KeyPair.create(undefined);
}

pub fn marshalEd25519PublicKey(pub_key: ed25519.PublicKey, allocator: Allocator) ![]u8 {
    var publickKeyPB = keyPair.PublicKey.init(allocator);
    defer publickKeyPB.deinit();

    var allocatedPubKeyBytes = try allocator.dupe(u8, &pub_key.bytes);

    publickKeyPB.Type = keyPair.KeyType.ECDSA;
    publickKeyPB.Data = try protobuf.ManagedString.copy(allocatedPubKeyBytes, allocator);

    allocator.free(allocatedPubKeyBytes);

    return try publickKeyPB.encode(allocator);
}

fn unmarshalEd25519PublicKey(encoded: []u8, allocator: Allocator) !keyPair.PublicKey {
    return try keyPair.PublicKey.decode(encoded, allocator);
}

test "test basic sign and verify" {
    var kp = try generateEd25519KeyPair();

    var data = "hello! and welcome to some awesome crypto primitives";
    var signatue = try kp.sign(data, undefined);
    try signatue.verify(data, kp.public_key);

    var diffData = "abcdefg";
    var verification = signatue.verify(diffData, kp.public_key);

    try std.testing.expectError(std.crypto.errors.SignatureVerificationError.SignatureVerificationFailed, verification);
}

test "encode/decode protobuf public key" {
    var kp = try generateEd25519KeyPair();
    var enc = try marshalEd25519PublicKey(kp.public_key, testing.allocator);
    defer testing.allocator.free(enc);

    var decoded = try unmarshalEd25519PublicKey(enc, testing.allocator);
    defer decoded.deinit();

    try testing.expectEqualSlices(u8, &kp.public_key.bytes, decoded.Data.getSlice());
    try testing.expectEqual(keyPair.KeyType.ECDSA, decoded.Type);
}
