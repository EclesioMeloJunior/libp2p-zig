const std = @import("std");
const RndGen = std.rand.DefaultPrng;
const crypto = std.crypto;
const ed25519 = crypto.sign.Ed25519;
const secp256k1 = crypto.ecc.Secp256k1;

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

fn UnmarshalPrivateKeu(privateKeyBytes: []u8) !void {
    _ = privateKeyBytes;
}

test "test basic sign and verify" {
    var kp = try generateEd25519KeyPair();

    var data = "hello! and welcome to some awesome crypto primitives";
    var signatue = try kp.sign(data, undefined);
    try signatue.verify(data, kp.public_key);

    var diffData = "abcdefg";
    var verification = signatue.verify(diffData, kp.public_key);

    try std.testing.expectError(crypto.errors.SignatureVerificationError.SignatureVerificationFailed, verification);
}
