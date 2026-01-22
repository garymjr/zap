const std = @import("std");
const arg = @import("arg.zig");

pub const ParseError = error{
    UnknownArgument,
    MissingValue,
    MissingRequired,
    InvalidFieldType,
    UnsupportedPositional,
};

pub fn ParseResult(comptime T: type) type {
    return struct {
        args: T,
        argv: ?[][:0]u8 = null,
        allocator: ?std.mem.Allocator = null,

        pub fn deinit(self: *@This()) void {
            if (self.argv) |argv| {
                if (self.allocator) |allocator| {
                    std.process.argsFree(allocator, argv);
                }
            }
        }
    };
}

pub fn parse(comptime T: type, allocator: std.mem.Allocator) !ParseResult(T) {
    const argv = try std.process.argsAlloc(allocator);
    const parsed = try parseArgs(T, argv);
    return .{ .args = parsed, .argv = argv, .allocator = allocator };
}

pub fn parseFrom(comptime T: type, args: []const []const u8) !ParseResult(T) {
    const parsed = try parseArgs(T, args);
    return .{ .args = parsed };
}

fn parseArgs(comptime T: type, args: anytype) !T {
    comptime {
        const info = @typeInfo(@TypeOf(args));
        switch (info) {
            .pointer => |ptr| {
                if (ptr.size != .slice) {
                    @compileError("zap: parseArgs expects a slice of argument strings");
                }
            },
            else => @compileError("zap: parseArgs expects a slice of argument strings"),
        }
    }

    const config = if (@hasDecl(T, "zap"))
        T.zap.config
    else if (@hasDecl(T, "zap_meta"))
        T.zap_meta.config
    else
        @compileError("zap: missing `pub const zap = zap.meta(...)` on argument struct");
    const specs = if (@hasField(@TypeOf(config), "args")) config.args else .{};

    var out: T = .{};
    var seen = std.StaticBitSet(std.meta.fields(T).len).initEmpty();

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const token: []const u8 = args[i];
        if (std.mem.eql(u8, token, "--")) {
            i += 1;
            break;
        }

        if (std.mem.startsWith(u8, token, "--")) {
            const long = token[2..];
            var matched = false;
            inline for (specs) |spec| {
                if (spec.long) |lname| {
                    if (std.mem.eql(u8, lname, long)) {
                        matched = true;
                        const idx = fieldIndex(T, spec.name);
                        seen.set(idx);
                        switch (spec.kind) {
                            .flag => try setBoolField(T, &out, spec.name, true),
                            .option => {
                                if (i + 1 >= args.len) return ParseError.MissingValue;
                                i += 1;
                                try setValueField(T, &out, spec.name, args[i]);
                            },
                            .positional => return ParseError.UnsupportedPositional,
                        }
                    }
                }
            }
            if (!matched) return ParseError.UnknownArgument;
            continue;
        }

        if (std.mem.startsWith(u8, token, "-") and token.len > 1) {
            if (token.len != 2) return ParseError.UnknownArgument;
            const short = token[1];
            var matched = false;
            inline for (specs) |spec| {
                if (spec.short) |s| {
                    if (s == short) {
                        matched = true;
                        const idx = fieldIndex(T, spec.name);
                        seen.set(idx);
                        switch (spec.kind) {
                            .flag => try setBoolField(T, &out, spec.name, true),
                            .option => {
                                if (i + 1 >= args.len) return ParseError.MissingValue;
                                i += 1;
                                try setValueField(T, &out, spec.name, args[i]);
                            },
                            .positional => return ParseError.UnsupportedPositional,
                        }
                    }
                }
            }
            if (!matched) return ParseError.UnknownArgument;
            continue;
        }

        return ParseError.UnsupportedPositional;
    }

    inline for (specs) |spec| {
        if (spec.required) {
            const idx = fieldIndex(T, spec.name);
            if (!seen.isSet(idx)) return ParseError.MissingRequired;
        }
    }

    return out;
}

fn setBoolField(comptime T: type, out: *T, comptime name: []const u8, value: bool) !void {
    if (@TypeOf(@field(out.*, name)) != bool) return ParseError.InvalidFieldType;
    @field(out.*, name) = value;
}

fn setValueField(comptime T: type, out: *T, comptime name: []const u8, value: []const u8) !void {
    const FieldType = @TypeOf(@field(out.*, name));
    switch (@typeInfo(FieldType)) {
        .pointer => {
            if (FieldType == []const u8 or FieldType == []u8) {
                @field(out.*, name) = value;
                return;
            }
            return ParseError.InvalidFieldType;
        },
        .int => {
            const parsed = try std.fmt.parseInt(FieldType, value, 10);
            @field(out.*, name) = parsed;
            return;
        },
        .optional => |opt| {
            const Child = opt.child;
            switch (@typeInfo(Child)) {
                .pointer => {
                    if (Child == []const u8 or Child == []u8) {
                        @field(out.*, name) = value;
                        return;
                    }
                    return ParseError.InvalidFieldType;
                },
                .int => {
                    const parsed = try std.fmt.parseInt(Child, value, 10);
                    @field(out.*, name) = parsed;
                    return;
                },
                else => return ParseError.InvalidFieldType,
            }
        },
        else => return ParseError.InvalidFieldType,
    }
}

fn fieldIndex(comptime T: type, comptime name: []const u8) usize {
    if (std.meta.fieldIndex(T, name)) |idx| return idx;
    @compileError("zap: arg name does not match any struct field: " ++ name);
}

test "parse flag and option" {
    const Options = struct {
        verbose: bool = false,
        name: []const u8 = "default",
        count: u8 = 0,

        const zaplib = @import("zap");
        pub const zap = zaplib.meta(.{
            .args = .{
                zaplib.arg.flag("verbose", .{ .short = 'v' }),
                zaplib.arg.option("name", .{ .long = "name" }),
                zaplib.arg.option("count", .{ .short = 'c' }),
            },
        });
    };

    const args = &[_][]const u8{ "app", "-v", "--name", "zig", "-c", "3" };
    var res = try parseFrom(Options, args);
    defer res.deinit();

    try std.testing.expect(res.args.verbose);
    try std.testing.expectEqualStrings("zig", res.args.name);
    try std.testing.expectEqual(@as(u8, 3), res.args.count);
}
