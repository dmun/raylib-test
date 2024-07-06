const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const Player = struct {
    speed: f32,
    pos: rl.Vector2,

    pub fn move(self: *Player, direction: rl.Vector2, frametime: f32) void {
        self.pos = rl.Vector2Add(self.pos, rl.Vector2{
            .x = self.speed * direction.x * frametime,
            .y = self.speed * direction.y * frametime,
        });
    }
};

const Projectile = struct {
    speed: f32,
    pos: rl.Vector2,
    dir: rl.Vector2,

    pub fn move(self: *Projectile, frametime: f32) void {
        self.pos = rl.Vector2Add(self.pos, rl.Vector2{
            .x = self.speed * self.dir.x * frametime,
            .y = self.speed * self.dir.y * frametime,
        });
    }
};

pub fn main() !void {
    std.debug.print("Hello World!", .{});
    rl.InitWindow(1280, 720, "Test");
    rl.SetTargetFPS(120);

    var player = Player{
        .speed = 800,
        .pos = .{ .x = 300, .y = 300 },
    };

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var projectiles = std.ArrayList(Projectile).init(allocator);

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.BLACK);

        const fps = try std.fmt.allocPrint(allocator, "{}", .{rl.GetFPS()});
        rl.DrawText(@ptrCast(fps), 0, 0, 12, rl.GREEN);

        var direction = rl.Vector2{ .x = 0, .y = 0 };
        if (rl.IsKeyDown(rl.KEY_W)) {
            direction.y = direction.y - 1;
        }
        if (rl.IsKeyDown(rl.KEY_A)) {
            direction.x = direction.x - 1;
        }
        if (rl.IsKeyDown(rl.KEY_S)) {
            direction.y = direction.y + 1;
        }
        if (rl.IsKeyDown(rl.KEY_D)) {
            direction.x = direction.x + 1;
        }

        player.move(direction, rl.GetFrameTime());

        rl.DrawRectangleV(player.pos, rl.Vector2{ .x = 100, .y = 100 }, rl.BLUE);

        for (projectiles.items) |*item| {
            item.move(rl.GetFrameTime());
            rl.DrawCircleV(item.pos, 30, rl.RED);
        }

        if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
            try projectiles.append(.{
                .speed = 1600,
                .pos = player.pos,
                .dir = rl.Vector2Normalize(rl.Vector2Subtract(
                    rl.GetMousePosition(),
                    player.pos,
                )),
            });
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
