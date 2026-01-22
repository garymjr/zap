const std = @import("std");
const zaplib = @import("zap");

const Options = struct {
    verbose: bool = false,
    name: []const u8 = "world",

    pub const zap = zaplib.meta(.{
        .name = "zap-basic",
        .version = @import("build_options").version,
        .about = "Minimal zap example",
        .args = .{
            zaplib.arg.flag("verbose", .{ .short = 'v' }),
            zaplib.arg.option("name", .{ .long = "name" }),
        },
        .help = .minimal,
    });
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var res = try zaplib.parse(Options, arena.allocator());
    defer res.deinit();

    const opts = res.args;
    if (opts.verbose) {
        std.debug.print("verbose on\n", .{});
    }
    std.debug.print("hello {s}\n", .{opts.name});
}
