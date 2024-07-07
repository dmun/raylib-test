const std = @import("std");
const rl = @import("raylib");
const Vector2 = rl.Vector2;
const Vector3 = rl.Vector3;
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

const Crosshair = struct {
    length: i32,
    thickness: i32,
    gap: i32,
    color: Color,

    pub fn draw(self: Crosshair, posX: i32, posY: i32) void {
        rl.drawRectangle(
            posX - @divTrunc(self.thickness, 2),
            posY + self.gap,
            self.thickness,
            self.length,
            self.color,
        );
        rl.drawRectangle(
            posX - @divTrunc(self.thickness, 2),
            posY - self.gap - self.length,
            self.thickness,
            self.length,
            self.color,
        );
        rl.drawRectangle(
            posX + self.gap + @mod(self.thickness, 2),
            posY - @divTrunc(self.thickness, 2),
            self.length,
            self.thickness,
            self.color,
        );
        rl.drawRectangle(
            posX - self.gap - self.length,
            posY - @divTrunc(self.thickness, 2),
            self.length,
            self.thickness,
            self.color,
        );
    }
};

pub fn main() !void {
    rl.initWindow(1280, 720, "Test");
    rl.setTargetFPS(144);

    var player = Player{
        .speed = 800,
        .pos = Vector2.init(3600, 3600),
    };

    var camera = rl.Camera3D{
        .position = Vector3.init(0, 1, 1),
        .target = Vector3.zero(),
        .up = Vector3.init(0, 1, 0),
        .fovy = 90,
        .projection = .camera_perspective,
    };

    const crosshair = Crosshair{
        .length = 8,
        .thickness = 3,
        .gap = 4,
        .color = Color.green,
    };

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var projectiles = std.ArrayList(Projectile).init(allocator);

    var cubes = std.ArrayList(Vector3).init(allocator);
    for (0..100) |_| {
        try cubes.append(
            Vector3.init(
                @floatFromInt(rl.getRandomValue(-500, 500)),
                @floatFromInt(rl.getRandomValue(0, 500)),
                @floatFromInt(rl.getRandomValue(-500, 500)),
            ),
        );
    }

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(Color.black.brightness(0.1));
        // defer rl.drawCircleV(rl.getMousePosition(), 10, Color.green);
        defer rl.drawText(rl.textFormat("%d", .{rl.getFPS()}), 0, 0, 18, Color.green);
        const crossW = @divTrunc(rl.getScreenWidth(), 2);
        const crossH = @divTrunc(rl.getScreenHeight(), 2);

        defer crosshair.draw(crossW, crossH);

        const frametime = rl.getFrameTime();

        player.update(frametime);

        const mouseDelta = rl.getMouseDelta().scale(0.5);

        const direction = getDirection();
        camera.update(.camera_custom);
        rl.updateCameraPro(
            &camera,
            Vector3.init(-direction.y, direction.x, 0),
            Vector3.init(mouseDelta.x, mouseDelta.y, 0),
            0,
        );
        defer rl.disableCursor();

        camera.begin();
        defer camera.end();

        rl.drawGrid(100, 10);
        rl.drawPlane(Vector3.zero(), Vector2.one().scale(1000), Color.black.brightness(0.2));
        for (cubes.items) |cube| {
            rl.drawCube(cube, 30, 30, 30, Color.white);
        }

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
                // .add(camera.target)
                    .subtract(player.pos)
                // .subtract(camera.offset)
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
