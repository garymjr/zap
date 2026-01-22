# zap (WIP)

Zig-first CLI parsing library inspired by clap.

## API sketch (typed struct + comptime metadata)

```zig
const std = @import("std");
const zaplib = @import("zap");

const Init = struct {
    path: []const u8 = "./",

    pub const zap = zaplib.meta(.{
        .about = "Initialize a repo",
        .args = .{
            zaplib.arg.positional("path", .{ .required = true }),
        },
    });
};

const Options = struct {
    verbose: bool = false,
    count: u32 = 1,
    name: []const u8 = "world",

    pub const zap = zaplib.meta(.{
        .name = "zap",
        .version = @import("build_options").version,
        .about = "Zig CLI parsing",
        .args = .{
            zaplib.arg.flag("verbose", .{ .short = 'v' }),
            zaplib.arg.option("count", .{ .short = 'c' }),
            zaplib.arg.option("name", .{ .long = "name", .required = true }),
        },
        .subcommands = .{
            zaplib.subcommand("init", Init),
        },
        .help = .minimal,
    });
};

pub fn main() !void {
    const arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var res = try zaplib.parse(Options, arena.allocator());
    defer res.deinit();

    const opts = res.args;
    if (res.subcommand) |sc| {
        switch (sc) {
            .init => |init_opts| {
                _ = init_opts;
            },
        }
    }
}
```

## build.zig version injection (sketch)

```zig
const version = b.option([]const u8, "version", "Override package version") orelse "0.0.0";
const options = b.addOptions();
options.addOption([]const u8, "version", version);

const mod = b.addModule("zap", .{
    .root_source_file = b.path("src/root.zig"),
    .target = target,
});

mod.addOptions("build_options", options);
```

Notes:
- `zap.meta` is a compile-time descriptor attached to the struct.
- `zap.parse` returns a typed `args` payload.
- Minimal help output for MVP.
