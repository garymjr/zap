//! zap: a Zig-first CLI parser inspired by clap.

pub const meta = @import("zap/meta.zig").meta;
pub const arg = @import("zap/arg.zig");
pub const help = @import("zap/help.zig");
pub const subcommand = @import("zap/subcommand.zig").subcommand;

pub const ParseError = @import("zap/parse.zig").ParseError;
pub const ParseResult = @import("zap/parse.zig").ParseResult;
pub const parse = @import("zap/parse.zig").parse;
pub const parseFrom = @import("zap/parse.zig").parseFrom;
