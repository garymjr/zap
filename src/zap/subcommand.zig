pub const Spec = struct {
    name: []const u8,
    ty: type,
};

pub fn subcommand(comptime name: []const u8, comptime T: type) Spec {
    return .{ .name = name, .ty = T };
}
