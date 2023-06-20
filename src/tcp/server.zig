const std = @import("std");

pub const Server = struct {
    stream_server: std.net.StreamServer,

    pub fn init() !Server {
        const addr = std.net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, 9876);

        var server = std.net.StreamServer.init(.{ .reuse_address = true });
        try server.listen(addr);

        std.debug.print("start server at {}", .{server.listen_address});
        return Server{ .stream_server = server };
    }

    pub fn deinit(self: *Server) void {
        self.stream_server.deinit();
    }

    pub fn accept(self: *Server) !void {
        const conn = try self.stream_server.accept();
        defer conn.stream.close();

        var buf: [1024]u8 = undefined;
        const msg_size = try conn.stream.read(buf[0..]);

        std.debug.print(">> {s}\n", .{buf[0..msg_size]});

        const server_msg = "GoodBye";
        _ = try conn.stream.write(server_msg);
    }
};
