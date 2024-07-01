const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    std.debug.print("Hello World!", .{});
    rl.InitWindow(1280, 720, "Test");
    rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.BLACK);

        const a = rl.Vector2{ .x = 10, .y = 10 };
        const b = rl.Vector2{ .x = 100, .y = 100 };
        rl.DrawLineEx(a, b, 3.0, rl.WHITE);
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
