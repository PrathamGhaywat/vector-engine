const rl = @import("raylib");
const std = @import("std");

const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn sub(self: Vec2, other: Vec2) Vec2 {
        return .{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn scale(self: Vec2, scalar: f32) Vec2 {
        return .{ .x = self.x * scalar, .y = self.y * scalar };
    }
};

const Circle = struct {
    pos: Vec2,
    vel: Vec2,
    radius: f32,
    mass: f32,
};

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "VectorEngine");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var circle = Circle{
        .pos = Vec2{ .x = 400.0, .y = 100.0 },
        .vel = Vec2{ .x = 0.0, .y = 0.0 },
        .radius = 20.0,
        .mass = 1.0,
    };

    const gravity = Vec2{ .x = 0, .y = 500 };
    const dt: f32 = 1.0 / 60.0;

    while (!rl.windowShouldClose()) {
        //apply gravity
        circle.vel = circle.vel.add(gravity.scale(dt));

        //position updat
        circle.pos = circle.pos.add(circle.vel.scale(dt));

        //floor collision
        if (circle.pos.y + circle.radius > screenHeight) {
            circle.pos.y = screenHeight - circle.radius;
            circle.vel.y = -circle.vel.y * 0.8; //bounce w damping
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        rl.drawCircle(@intFromFloat(circle.pos.x), @intFromFloat(circle.pos.y), circle.radius, .red);
        rl.drawText("VectorEngine", 10, 10, 20, .black);
    }
}
