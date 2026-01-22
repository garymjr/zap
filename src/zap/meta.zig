pub fn Meta(comptime C: type) type {
    return struct {
        config: C,
    };
}

pub fn meta(comptime config: anytype) Meta(@TypeOf(config)) {
    return .{ .config = config };
}
