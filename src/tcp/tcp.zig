const std = @import("std");
const server = @import("server.zig");

pub fn main() anyerror!void {
    var svr = try server.Server.init();
    defer svr.deinit();

    while (true) {
        try svr.accept();
    }
}

fn sendMessageToServer(server_addr: std.net.Address) !void {
    const conn = try std.net.tcpConnectToAddress(server_addr);
    defer conn.close();

    const client_msg = "Hello";
    _ = try conn.write(client_msg);

    var buf: [1024]u8 = undefined;
    const resp_size = try conn.read(buf[0..]);

    const server_msg = "GoodBye";
    try std.testing.expectEqualStrings(server_msg, buf[0..resp_size]);
}
