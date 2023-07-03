const server = @import("tcp.zig");

pub fn main() anyerror!void {
    var svr = try server.Server.init();
    defer svr.deinit();

    while (true) {
        try svr.accept();
    }
}
