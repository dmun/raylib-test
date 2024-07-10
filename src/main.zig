const std = @import("std");
const rl = @import("raylib");
const Vector2 = rl.Vector2;
const Vector3 = rl.Vector3;
const Color = rl.Color;
const Quaternion = rl.Quaternion;
const Ray = rl.Ray;

const Player = struct {
    speed: f32,
    pos: Vector3,
    force: Vector3,
    orientation: Vector3,

    pub fn update(self: *Player, frametime: f32) void {
        const dir = getDirection();
        self.pos = Vector3
            .init(dir.x, 0, dir.y)
            .scale(self.speed)
            .scale(frametime)
            .add(self.force)
            .add(self.pos);

        if (self.force.distance(Vector3.zero()) > 0.1) {
            self.force = self.force.scale(0.8);
        } else {
            self.force = Vector3.zero();
        }

        if (rl.isKeyPressed(.key_left_shift)) {
            self.force = Vector3
                .init(dir.x, 0, dir.y)
                .scale(100);
        }
    }

    pub fn draw(self: *Player) void {
        rl.drawCubeV(self.pos, Vector3.one().scale(10), Color.red);
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

const Particle = struct {
    position: Vector3,
    direction: Vector3,
    color: Color = Color.red,

    pub fn update(self: *Particle, frametime: f32) void {
        _ = frametime; // autofix
        _ = self; // autofix
        // self.position = self.direction
        //     .scale(frametime)
        //     .scale(100)
        //     .add(self.position);
    }

    pub fn draw(self: *Particle) void {
        // rl.drawCubeV(self.position, Vector3.one().scale(10), Color.white);
        rl.drawRay(
            .{
                .position = self.position,
                .direction = self.direction,
            },
            self.color,
        );
    }
};

const FpCamera = struct {
    position: Vector3,
    direction: Vector3,
    fov: f32,
};

pub fn main() !void {
    rl.setConfigFlags(.{
        .msaa_4x_hint = true,
    });

    rl.initWindow(1280, 720, "Test");
    rl.setTargetFPS(240);

    const fpCamera = FpCamera{
        .position = Vector3.init(0, 1, 1),
        .direction = Vector3.one(),
        .fov = 90,
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

    var particles = std.ArrayList(Particle).init(allocator);

    const crossW = @divTrunc(rl.getScreenWidth(), 2);
    const crossH = @divTrunc(rl.getScreenHeight(), 2);

    const testShader = rl.loadShader("src/test_vert.glsl", "src/test_frag.glsl");
    defer rl.unloadShader(testShader);

    const target = rl.loadRenderTexture(rl.getScreenWidth(), rl.getScreenHeight());
    defer target.unload();

    var player = Player{
        .pos = Vector3.one(),
        .force = Vector3.zero(),
        .speed = 800,
        .orientation = Vector3.init(1, 0, 0),
    };

    var camera = rl.Camera3D{
        .position = Vector3.one(),
        .target = player.orientation,
        .up = Vector3.init(0, 1, 0),
        .fovy = fpCamera.fov,
        .projection = .camera_perspective,
    };

    var shake: f32 = 0;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(Color.black.brightness(0.1));

        {
            testShader.activate();
            defer testShader.deactivate();

            rl.drawTextureRec(
                target.texture,
                .{
                    .x = 0,
                    .y = 0,
                    .width = @floatFromInt(target.texture.width),
                    .height = @floatFromInt(-target.texture.height),
                },
                Vector2.zero(),
                Color.white,
            );
        }

        // Camera
        const mouseDelta = rl.getMouseDelta().scale(0.05);
        player.orientation = player.orientation.rotateByAxisAngle(Vector3.init(0, 1, 0), -mouseDelta.x);

        camera.position = player.pos;
        camera.target = player.pos.add(player.orientation).multiply(Vector3.init(1, 1, 1));

        defer rl.drawText(rl.textFormat("x: %f", .{player.orientation.x}), 150, 0, 18, Color.white);
        defer rl.drawText(rl.textFormat("y: %f", .{player.orientation.y}), 150, 18, 18, Color.white);
        defer rl.drawText(rl.textFormat("z: %f", .{player.orientation.z}), 150, 36, 18, Color.white);

        // camera.update(.camera_custom);

        rl.disableCursor();

        // camera.target = camera.target.add(.{ .x = 0, .y = shake, .z = 0 });
        // shake = shake * 0.9;

        // UI
        defer rl.drawFPS(0, 0);
        defer crosshair.draw(crossW, crossH);

        // Scene
        camera.begin();
        defer camera.end();

        rl.drawSphere(player.pos.add(player.orientation.scale(10)), 3, Color.blue);

        const frametime = rl.getFrameTime();
        player.update(frametime);
        player.draw();

        rl.drawGrid(100, 10);
        rl.drawPlane(Vector3.zero(), Vector2.one().scale(1000), Color.black.brightness(0.2));
        for (cubes.items) |cube| {
            rl.drawCube(cube, 30, 30, 30, Color.white);
            rl.drawCubeWiresV(cube, Vector3.one().scale(30), Color.blue);
        }

        for (particles.items) |*particle| {
            particle.update(frametime);
            particle.draw();
        }

        if (rl.isMouseButtonPressed(.mouse_button_left)) {
            shake = 1;
            var hit = false;

            const ray = Ray{
                .position = camera.target,
                .direction = camera.target.subtract(camera.position),
            };

            for (cubes.items) |*cube| {
                const col = rl.getRayCollisionBox(ray, .{
                    .min = cube.subtract(Vector3.one().scale(15)),
                    .max = cube.add(Vector3.one().scale(15)),
                });
                if (col.hit) hit = true;
            }

            try particles.append(.{
                .position = camera.target,
                .direction = camera.target.subtract(camera.position),
                .color = if (hit) Color.green else Color.red,
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
