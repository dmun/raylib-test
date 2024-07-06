const std = @import("std");
const rl = @import("raylib");
const Vector2 = rl.Vector2;
const Color = rl.Color;

const Player = struct {
    speed: f32,
    pos: Vector2,

    pub fn move(self: *Player, direction: Vector2, frametime: f32) void {
        self.pos = self.pos.add(.{
            .x = self.speed * direction.x * frametime,
            .y = self.speed * direction.y * frametime,
        });
    }
};

const Projectile = struct {
    speed: f32,
    pos: Vector2,
    dir: Vector2,

    pub fn move(self: *Projectile, frametime: f32) void {
        self.pos = self.pos.add(.{
            .x = self.speed * self.dir.x * frametime,
            .y = self.speed * self.dir.y * frametime,
        });
    }
};

pub fn getDirection() Vector2 {
    var v = Vector2.zero();
    if (rl.isKeyDown(.key_w)) v.y = v.y - 1;
    if (rl.isKeyDown(.key_a)) v.x = v.x - 1;
    if (rl.isKeyDown(.key_s)) v.y = v.y + 1;
    if (rl.isKeyDown(.key_d)) v.x = v.x + 1;
    return v;
}

pub fn main() !void {
    std.debug.print("Hello World!", .{});
    rl.initWindow(1280, 720, "Test");
    rl.setTargetFPS(120);

    var player = Player{
        .speed = 800,
        .pos = .{ .x = 300, .y = 300 },
    };

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var projectiles = std.ArrayList(Projectile).init(allocator);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);

        const fps = try std.fmt.allocPrint(allocator, "{}", .{rl.getFPS()});
        rl.drawText(@ptrCast(fps), 0, 0, 18, Color.green);

        const direction = getDirection();

        player.move(direction, rl.getFrameTime());

        rl.drawRectangleV(
            player.pos,
            Vector2.init(100, 100),
            Color.blue,
        );

        for (projectiles.items) |*item| {
            item.move(rl.getFrameTime());
            rl.drawCircleV(item.pos, 30, Color.red);
        }

        if (rl.isMouseButtonDown(.mouse_button_left)) {
            try projectiles.append(.{
                .speed = 1600,
                .pos = player.pos,
                .dir = rl
                    .getMousePosition()
                    .subtract(player.pos)
                    .normalize(),
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
