const std = @import("std");

test "basic uvarint encoding/decoding" {
    const numbers: [6]u64 = [6]u64{ 1, 127, 128, 255, 300, 16384 };

    for (numbers) |n| {
        std.debug.print("{}", .{n});
    }
}
