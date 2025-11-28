const std = @import("std");
const Vec3 = @import("../vec3.zig").Vec3;
const Body3D = @import("../body3d.zig").Body3D;
const Shape3D = @import("../shape3d.zig").Shape3D;

pub const Pendulum = struct {
    ball: Body3D,
    anchor: Vec3,
    length: f32,
};

pub const NewtonsCradle = struct {
    pendulums: [5]Pendulum,
    ball_radius: f32,

    pub fn init() NewtonsCradle {
        var cradle = NewtonsCradle{
            .pendulums = undefined,
            .ball_radius = 0.5,
        };

        const spacing: f32 = 1.1;
        const length: f32 = 4.0;
        const start_x: f32 = -2.2;

        for (0..5) |i| {
            const x = start_x + @as(f32, @floatFromInt(i)) * spacing;
            cradle.pendulums[i] = Pendulum{
                .ball = Body3D.init(
                    Vec3{ .x = x, .y = -length, .z = 0 },
                    1.0,
                    Shape3D{ .sphere = .{ .radius = 0.5 } },
                ),
                .anchor = Vec3{ .x = x, .y = 0, .z = 0 },
                .length = length,
            };
        }

        //pull first ball back
        cradle.pendulums[0].ball.pos = Vec3{ .x = start_x - 2.0, .y = -length + 1.0, .z = 0 };

        return cradle;
    }

    pub fn update(self: *NewtonsCradle, dt: f32) void {
        const gravity = Vec3{ .x = 0, .y = -9.81, .z = 0 };

        //update each pendulum
        for (&self.pendulums) |*p| {
            //apply gravity
            p.ball.vel = p.ball.vel.add(gravity.scale(dt));

            //constraint to rope length
            const to_anchor = p.anchor.sub(p.ball.pos);
            const dist = to_anchor.length();
            if (dist > p.length) {
                const correction = to_anchor.normalize().scale(dist - p.length);
                p.ball.pos = p.ball.pos.add(correction);

                const rope_dir = to_anchor.normalize();
                const vel_along_rope = rope_dir.scale(p.ball.vel.dot(rope_dir));
                p.ball.vel = p.ball.vel.sub(vel_along_rope);
            }

            p.ball.pos = p.ball.pos.add(p.ball.vel.scale(dt));
        }

        for (0..5) |i| {
            for (i + 1..5) |j| {
                self.resolveBallCollision(i, j);
            }
        }
    }

    fn resolveBallCollision(self: *NewtonsCradle, i: usize, j: usize) void {
        const a = &self.pendulums[i].ball;
        const b = &self.pendulums[j].ball;

        const delta = b.pos.sub(a.pos);
        const dist = delta.length();
        const min_dist = self.ball_radius * 2;

        if (dist >= min_dist or dist == 0) return;

        const normal = delta.normalize();
        const overlap = min_dist - dist;

        //separate
        a.pos = a.pos.sub(normal.scale(overlap * 0.5));
        b.pos = b.pos.add(normal.scale(overlap * 0.5));

        //elastic collision (conservation of momentum)
        const rel_vel = a.vel.sub(b.vel);
        const vel_along_normal = rel_vel.dot(normal);

        if (vel_along_normal < 0) return;

        const restitution: f32 = 1.0;
        const impulse = normal.scale(vel_along_normal * restitution);

        a.vel = a.vel.sub(impulse);
        b.vel = b.vel.add(impulse);
    }

    pub fn reset(self: *NewtonsCradle) void {
        self.* = NewtonsCradle.init();
    }
};
