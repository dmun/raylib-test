const std = @import("std");
const rl = @import("raylib");
const Vector2 = rl.Vector2;
const Color = rl.Color;

const Player = struct {
    speed: f32,
    pos: Vector2,
    force: Vector2 = .{ .x = 0, .y = 0 },

    pub fn update(self: *Player, frametime: f32) void {
        self.pos = getDirection()
            .scale(self.speed)
            .scale(frametime)
            .add(self.force)
            .add(self.pos);

        if (self.force.distance(Vector2.zero()) > 0.1) {
            self.force = self.force.scale(0.8);
        } else {
            self.force = Vector2.zero();
        }

        if (rl.isKeyPressed(.key_space)) {
            self.force = getDirection().scale(100);
        }
    }

    pub fn draw(self: *Player) void {
        rl.drawRectangleV(
            self.pos.subtractValue(50),
            Vector2.init(100, 100),
            Color.ray_white,
        );
    }
};

pub fn randomColor() Color {
    return .{
        .r = @intCast(rl.getRandomValue(0, 255)),
        .g = @intCast(rl.getRandomValue(0, 255)),
        .b = @intCast(rl.getRandomValue(0, 255)),
        .a = 255,
    };
}

const Projectile = struct {
    speed: f32,
    size: f32,
    rotation: f32 = 0,
    pos: Vector2,
    dir: Vector2,

    pub fn update(self: *Projectile, frametime: f32) void {
        self.pos = self.dir
            .scale(self.speed)
            .scale(frametime)
            .add(self.pos);
    }

    var rng = std.rand.DefaultPrng.init(0);

    pub fn draw(self: *Projectile) void {
        const spawnPoint = self.pos
            .subtractValue(25)
            .add(Vector2.init(
            rng.random().float(f32) * 50,
            rng.random().float(f32) * 50,
        ));

        const rect = rl.Rectangle.init(spawnPoint.x, spawnPoint.y, self.size, self.size);

        rl.drawRectanglePro(
            rect,
            .{
                .x = rect.width / 2,
                .y = rect.height / 2,
            },
            self.rotation,
            randomColor(),
        );
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

pub fn drawGrid() void {
    const width = 100;
    const height = 100;
    const size = 100;
    const spacing = 2;

    for (0..width) |x| {
        for (0..height) |y| {
            rl.drawRectangle(
                @intCast(x * (size + spacing)),
                @intCast(y * (size + spacing)),
                size,
                size,
                .{
                    .r = @intCast(@divTrunc(x * 255, width)),
                    .g = @intCast(@divTrunc(y * 255, height)),
                    .b = 255,
                    .a = 69,
                },
            );
        }
    }
}

pub fn main() !void {
    rl.initWindow(1280, 720, "Test");
    rl.setTargetFPS(144);

    var player = Player{
        .speed = 800,
        .pos = Vector2.init(3600, 3600),
    };

    const screenScaling = @as(f32, @floatFromInt(rl.getScreenHeight())) / 1080;
    var camera = rl.Camera2D{
        .target = Vector2.zero(),
        .offset = Vector2.init(
            @as(f32, @floatFromInt(rl.getScreenWidth())) / 2,
            @as(f32, @floatFromInt(rl.getScreenHeight())) / 2,
        ),
        .rotation = 0,
        .zoom = screenScaling,
    };

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var projectiles = std.ArrayList(Projectile).init(allocator);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(Color.black.brightness(0.1));
        // defer rl.drawCircleV(rl.getMousePosition(), 10, Color.green);
        defer rl.drawText(rl.textFormat("%d", .{rl.getFPS()}), 0, 0, 18, Color.green);

        const frametime = rl.getFrameTime();

        player.update(frametime);
        camera.target = player.pos;

        camera.begin();
        defer camera.end();

        drawGrid();

        player.draw();

        for (projectiles.items) |*projectile| {
            projectile.update(frametime);
            projectile.draw();
        }

        if (rl.isMouseButtonDown(.mouse_button_left)) {
            try projectiles.append(.{
                .speed = 1600,
                .size = @floatFromInt(rl.getRandomValue(5, 30)),
                .pos = player.pos,
                .dir = rl
                    .getMousePosition()
                    .add(camera.target)
                    .subtract(player.pos)
                    .subtract(camera.offset)
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
