const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ed25519 = std.crypto.sign.Ed25519;
const sha2_256 = std.crypto.hash.sha2.Sha256;
const varint = @import("varint");
const crypto = @import("crypto");
const base58 = @import("base58");

const maxInlineKeyLength = 42;
const HashFunctionCode = enum(u8) {
    IdentityCode = 0x00,
    SHA2_256Code = 0x12,
};

// Multihash is a byte slice with the following form:
// <hash function code><digest size><hash function output>
pub const Multihash = struct {
    bytes: []u8,

    // only allocated once bas58Encode
    // is called
    encoded: []u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator, cap: usize) !*Multihash {
        var instance = try allocator.create(Multihash);
        instance.bytes = try allocator.alloc(u8, cap);
        instance.encoded = try allocator.alloc(u8, cap * 2);
        instance.allocator = allocator;
        return instance;
    }

    pub fn deinit(self: *Multihash) void {
        self.allocator.free(self.bytes);
        self.allocator.free(self.encoded);
        self.allocator.destroy(self);
    }

    pub fn bas58Encode(self: *Multihash) !void {
        const bas58Encoder = base58.Encoder.init(.{});
        var size = try bas58Encoder.encode(self.bytes, self.encoded);
        if (self.encoded.len != size) {
            self.encoded = try self.allocator.realloc(self.encoded, size);
        }
    }
};

pub fn identitySum(buff: []u8, allocator: Allocator) !*Multihash {
    var encodedCode: [10]u8 = undefined;
    const amountCode = varint.PutUvarint(@as(u64, @intFromEnum(HashFunctionCode.IdentityCode)), &encodedCode);

    var encodedBuffSize: [10]u8 = undefined;
    const amountBuffSize = varint.PutUvarint(@as(u64, buff.len), &encodedBuffSize);

    var mh = try Multihash.init(allocator, amountCode + amountBuffSize + buff.len);

    @memcpy(mh.bytes[0..amountCode], encodedCode[0..amountCode]);
    @memcpy(mh.bytes[amountCode .. amountCode + amountBuffSize], encodedBuffSize[0..amountBuffSize]);
    @memcpy(mh.bytes[amountCode + amountBuffSize ..], buff[0..buff.len]);

    return mh;
}

pub fn sha2_256Sum(buff: []u8, allocator: Allocator) !*Multihash {
    var hashed_data: [32]u8 = undefined;
    sha2_256.hash(buff, &hashed_data, .{});

    var encodedCode: [10]u8 = undefined;
    const amountCode = varint.PutUvarint(@as(u64, @intFromEnum(HashFunctionCode.SHA2_256Code)), &encodedCode);

    var encodedBuffSize: [10]u8 = undefined;
    const amountBuffSize = varint.PutUvarint(@as(u64, 32), &encodedBuffSize);

    var mh = try Multihash.init(allocator, amountCode + amountBuffSize + 32);

    @memcpy(mh.bytes[0..amountCode], encodedCode[0..amountCode]);
    @memcpy(mh.bytes[amountCode .. amountCode + amountBuffSize], encodedBuffSize[0..amountBuffSize]);
    @memcpy(mh.bytes[amountCode + amountBuffSize ..], hashed_data[0..32]);

    return mh;
}

pub fn multihashFromPublicKey(pub_key: ed25519.PublicKey, allocator: Allocator) !*Multihash {
    const encodedPubKey = try crypto.marshalEd25519PublicKey(pub_key, allocator);
    defer allocator.free(encodedPubKey);

    var mh: *Multihash = undefined;
    if (encodedPubKey.len <= maxInlineKeyLength) {
        mh = try identitySum(encodedPubKey, allocator);
    } else {
        mh = try sha2_256Sum(encodedPubKey, allocator);
    }

    try mh.bas58Encode();
    return mh;
}

pub fn decodeFromB58(encoded: []const u8) !*Multihash {
    _ = encoded;
}

test "identity sum" {
    var buff = try std.testing.allocator.alloc(u8, 32);
    defer std.testing.allocator.free(buff);

    const mh = try identitySum(buff, std.testing.allocator);
    defer mh.deinit();

    try std.testing.expect(mh.bytes[0] == @intFromEnum(HashFunctionCode.IdentityCode));
    try std.testing.expect(mh.bytes[1] == 32);
    try std.testing.expect(std.mem.eql(u8, mh.bytes[2..], buff[0..]));
}

test "SHA2_256 sum" {
    var buff = try std.testing.allocator.alloc(u8, 32);
    defer std.testing.allocator.free(buff);

    // hash the allocated bytes beforehand
    var hashed_data: [32]u8 = undefined;
    sha2_256.hash(buff, &hashed_data, .{});

    const mh = try sha2_256Sum(buff, std.testing.allocator);
    defer mh.deinit();

    try std.testing.expect(mh.bytes[0] == @intFromEnum(HashFunctionCode.SHA2_256Code));
    try std.testing.expect(mh.bytes[1] == 32);
    try std.testing.expect(std.mem.eql(u8, mh.bytes[2..], hashed_data[0..]));
}
