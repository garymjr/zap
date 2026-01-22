const std = @import("std");

pub const Kind = enum {
    flag,
    option,
    positional,
};

pub const Spec = struct {
    name: []const u8,
    kind: Kind,
    short: ?u8 = null,
    long: ?[]const u8 = null,
    required: bool = false,
};

pub fn flag(comptime name: []const u8, comptime opts: anytype) Spec {
    return make(.flag, name, opts);
}

pub fn option(comptime name: []const u8, comptime opts: anytype) Spec {
    return make(.option, name, opts);
}

pub fn positional(comptime name: []const u8, comptime opts: anytype) Spec {
    return make(.positional, name, opts);
}

fn make(comptime kind: Kind, comptime name: []const u8, comptime opts: anytype) Spec {
    const short_value: ?u8 = if (@hasField(@TypeOf(opts), "short")) @field(opts, "short") else null;
    const long_value: ?[]const u8 = if (@hasField(@TypeOf(opts), "long")) @field(opts, "long") else name;
    const required_value: bool = if (@hasField(@TypeOf(opts), "required")) @field(opts, "required") else false;

    return .{
        .name = name,
        .kind = kind,
        .short = short_value,
        .long = long_value,
        .required = required_value,
    };
}
