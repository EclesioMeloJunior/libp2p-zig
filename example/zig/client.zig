const std = @import("std");
const os = @import("os");
const varint = @import("varint");
const peer = @import("peer");
const crypto = @import("crypto");
const Allocator = std.mem.Allocator;

const multistreamProtocol = "/multistream/1.0.0";

pub const Server = struct {
    mh: *peer.Multihash,
    alloc: Allocator,
    p2p_addr: []const u8,
    stream_server: std.net.StreamServer,

    pub fn init() !Server {
        const addr = std.net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, 9876);
        var stream_server = std.net.StreamServer.init(.{ .reuse_address = true });
        try stream_server.listen(addr);

        var kp = try crypto.generateEd25519KeyPair();
        var mh = try peer.multihashFromPublicKey(kp.public_key, std.heap.page_allocator);

        var p2p_addr = try std
            .fmt
            .allocPrint(std.heap.page_allocator, "/ip4/127.0.0.1/tcp/9876/p2p/{s}", .{mh.encoded});

        var server: Server = .{ .stream_server = stream_server, .alloc = std.heap.page_allocator, .mh = mh, .p2p_addr = p2p_addr };
        std.debug.print("listening on addr: {s}\n", .{p2p_addr});
        return server;
    }

    pub fn deinit(self: *Server) void {
        self.alloc.free(self.p2p_addr);
        self.stream_server.deinit();
        self.mh.deinit();
    }

    pub fn accept(self: *Server) !void {
        const conn = try self.stream_server.accept();
        defer conn.stream.close();

        var buf: [1024]u8 = undefined;
        const msg_size = try conn.stream.read(buf[0..]);

        std.debug.print(">> {s}\n", .{buf[0..msg_size]});

        std.time.sleep(5000000000);

        var alloc = std.heap.page_allocator;
        var messageBuf = std.ArrayList(u8).init(alloc);
        defer messageBuf.deinit();

        var lenBuf: [10]u8 = undefined;
        var multistreamLen: u64 = multistreamProtocol.*.len;
        const write_bytes = varint.PutUvarint(multistreamLen, &lenBuf);

        try messageBuf.appendSlice(lenBuf[0..write_bytes]);
        try messageBuf.appendSlice(multistreamProtocol);
        try messageBuf.append('\n');

        var slice: []u8 = try messageBuf.toOwnedSlice();
        _ = try conn.stream.write(slice);
    }
};

pub fn main() anyerror!void {
    var svr = try Server.init();
    defer svr.deinit();

    while (true) {
        try svr.accept();
    }
}
