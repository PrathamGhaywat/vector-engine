const std = @import("std");
const Vec2 = @import("vec2.zig").Vec2;
const Body = @import("body.zig").Body;
const collision = @import("collision.zig");

pub const World = struct {
    bodies: std.ArrayListUnmanaged(Body),
    gravity: Vec2,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) World {
        return World{
            .bodies = .{},
            .gravity = Vec2{ .x = 0, .y = 500 },
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *World) void {
        self.bodies.deinit(self.allocator);
    }

    pub fn addBody(self: *World, body: Body) !void {
        try self.bodies.append(self.allocator, body);
    }

    pub fn clear(self: *World) void {
        self.bodies.clearRetainingCapacity();
    }

    pub fn update(self: *World, dt: f32, screen_width: f32, screen_height: f32) void {
        //update all bodies
        for (self.bodies.items) |*body| {
            body.update(self.gravity, dt);
            self.constrainToScreen(body, screen_width, screen_height);
        }

        //collision detection + resolution
        for (self.bodies.items, 0..) |*body_a, i| {
            for (self.bodies.items[i + 1 ..]) |*body_b| {
                var manifold = collision.detectCollision(body_a, body_b);
                collision.resolveCollision(&manifold);
            }
        }
    }

    fn constrainToScreen(self: *World, body: *Body, width: f32, height: f32) void {
        _ = self;
        if (body.is_static) return;

        switch (body.shape) {
            .circle => |circle| {
                if (body.pos.y + circle.radius > height) {
                    body.pos.y = height - circle.radius;
                    body.vel.y = -body.vel.y * body.restitution;
                }
                if (body.pos.x - circle.radius < 0) {
                    body.pos.x = circle.radius;
                    body.vel.x = -body.vel.x * body.restitution;
                }
                if (body.pos.x + circle.radius > width) {
                    body.pos.x = width - circle.radius;
                    body.vel.x = -body.vel.x * body.restitution;
                }
            },
            .rectangle => |rect| {
                const half_w = rect.width / 2;
                const half_h = rect.height / 2;
                if (body.pos.y + half_h > height) {
                    body.pos.y = height - half_h;
                    body.vel.y = -body.vel.y * body.restitution;
                }
                if (body.pos.x - half_w < 0) {
                    body.pos.x = half_w;
                    body.vel.x = -body.vel.x * body.restitution;
                }
                if (body.pos.x + half_w > width) {
                    body.pos.x = width - half_w;
                    body.vel.x = -body.vel.x * body.restitution;
                }
            },
            .polygon => {},
        }
    }
};
