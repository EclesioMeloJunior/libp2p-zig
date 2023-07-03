const std = @import("std");

pub fn PutUvarint(v: u64, buf: []u8) usize {
    var valueToEncode = v;
    var i: usize = 0;
    while (valueToEncode >= 0x80) : (i += 1) {
        const u8_value: u8 = @truncate(u8, valueToEncode);
        buf[i] = u8_value | 0x80;
        valueToEncode >>= 7;
    }

    buf[i] = @truncate(u8, valueToEncode);
    return i + 1;
}

pub fn Uvarint(buf: []u8) !u64 {
    const maxVarintLen: usize = 10;
    var decoded_value: u64 = 0;
    var s: u6 = 0;

    for (buf, 0..) |b, idx| {
        if (idx == maxVarintLen) {
            return error.VarintOverflow;
        }

        if (b < 0x80) {
            if (idx == (maxVarintLen - 1) and b > 0x01) {
                return error.VarintOverflow;
            }

            return decoded_value | @as(u64, b) << s;
        }

        decoded_value |= @as(u64, b & 0x7f) << s;
        s += 7;
    }

    return 0;
}

test "basic uvarint encoding/decoding" {
    const case = struct {
        number: u64,
        expected: []const u8,
    };

    var zeroU64: u64 = 0;
    var zeroU32: u32 = 0;
    const cases = [_]case{ case{
        .number = 1,
        .expected = &(&[_]u8{0x01}).*,
    }, case{
        .number = 127,
        .expected = &(&[_]u8{0x7f}).*,
    }, case{
        .number = 128,
        .expected = &(&[_]u8{ 0x80, 0x01 }).*,
    }, case{
        .number = 300,
        .expected = &(&[_]u8{ 0xac, 0x02 }).*,
    }, case{
        .number = 16384,
        .expected = &(&[_]u8{ 0x80, 0x80, 0x01 }).*,
    }, case{
        .number = @as(u64, ~zeroU32),
        .expected = &(&[_]u8{ 0xff, 0xff, 0xff, 0xff, 0x0f }).*,
    }, case{
        .number = ~zeroU64,
        .expected = &(&[_]u8{ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01 }).*,
    } };

    for (cases) |c| {
        var buf: [10]u8 = undefined;
        const write_bytes = PutUvarint(c.number, &buf);
        var output_buf = buf[0..write_bytes];
        try std.testing.expect(std.mem.eql(u8, output_buf, c.expected));

        var decoded = try Uvarint(output_buf);
        try std.testing.expectEqual(c.number, decoded);
    }
}
