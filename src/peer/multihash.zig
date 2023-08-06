const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const sha2_256 = std.crypto.hash.sha2.Sha256;
const varint = @import("varint");

const IdentityCode: u64 = 0x00;

// Multihash is a byte slice with the following form:
// <hash function code><digest size><hash function output>
pub const Multihash = struct {
    bytes: []u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator, cap: usize) !*Multihash {
        var instance = try allocator.create(Multihash);
        instance.bytes = try allocator.alloc(u8, cap);
        instance.allocator = allocator;
        return instance;
    }

    pub fn deinit(self: *Multihash) void {
        self.allocator.free(self.bytes);
        self.allocator.destroy(self);
    }
};

pub const Hasher = struct {};

pub fn identitySum(buff: []u8, allocator: Allocator) !*Multihash {
    var encodedCode: [10]u8 = undefined;
    const amountCode = varint.PutUvarint(IdentityCode, &encodedCode);

    var encodedBuffSize: [10]u8 = undefined;
    const amountBuffSize = varint.PutUvarint(@as(u64, buff.len), &encodedBuffSize);

    var mh = try Multihash.init(allocator, amountCode + amountBuffSize + buff.len);

    @memcpy(mh.bytes[0..amountCode], encodedCode[0..amountCode]);
    @memcpy(mh.bytes[amountCode .. amountCode + amountBuffSize], encodedBuffSize[0..amountBuffSize]);
    @memcpy(mh.bytes[amountCode + amountBuffSize ..], buff[0..buff.len]);

    return mh;
}

test "identity sum" {
    var buff = try std.testing.allocator.alloc(u8, 32);
    defer std.testing.allocator.free(buff);

    const mh = try identitySum(buff, std.testing.allocator);

    try std.testing.expect(mh.bytes[0] == 0x00);
    try std.testing.expect(mh.bytes[1] == 32);
    try std.testing.expect(std.mem.eql(u8, mh.bytes[2..], buff[0..]));

    mh.deinit();

    //std.debug.print("{any}", .{mh.bytes});
}
