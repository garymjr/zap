# Notes

Last update: 2026-01-22

Where we left off:
- Core zap skeleton exists under `src/zap/` with `arg`, `meta`, `parse`, `help`, and `subcommand` modules.
- `zap.parse` supports flags and options into a typed struct; minimal test added.
- Examples live in `examples/` and `zig build examples` compiles them.

What’s next:
- Add positional argument support + `--` passthrough.
- Implement subcommand parsing with typed payloads.
- Add minimal help output for `-h/--help`.
- Expand tests for missing required args, type errors, and unknown flags.
