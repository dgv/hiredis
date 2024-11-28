const std = @import("std");
const hiredis = @import("hiredis");

pub fn main() !void {
    const context = hiredis.redisConnect("127.0.0.1", 0);

    if (context == null or context.*.err != 0) {
        std.debug.print("Connection error: {?s}\n", .{context.*.errstr});
    }

    defer hiredis.redisFree(context);
}
