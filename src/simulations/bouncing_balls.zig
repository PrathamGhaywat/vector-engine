const std = @import("std");
const Vec3 = @import("../vec3.zig").Vec3;
const Body3D = @import("../body3d.zig").Body3D;
const Shape3D = @import("../shape3d.zig").Shape3D;

pub const BouncingBalls = struct {
    balls: [10]Body3D,
    ball_count: usize,
    box_size: f32,

    pub fn init() BouncingBalls {
        var sim = BouncingBalls{
            .balls = undefined,
            .ball_count = 10,
            .box_size = 5.0,
        };


        var prng = std.Random.DefaultPrng.init(12345);
        const random = prng.random();

        for (0..sim.ball_count) |i| {
            const x = (random.float(f32) - 0.5) * 4.0;
            const y = (random.float(f32) - 0.5) * 4.0;
            const z = (random.float(f32) - 0.5) * 4.0;

            sim.balls[i] = Body3D.init(
                Vec3{ .x = x, .y = y, .z = z },
                1.0,
                Shape3D{ .sphere = .{ .radius = 0.3 } },
            );

            sim.balls[i].vel = Vec3{
                .x = (random.float(f32) - 0.5) * 5.0,
                .y = (random.float(f32) - 0.5) * 5.0,
                .z = (random.float(f32) - 0.5) * 5.0,
            };
            sim.balls[i].restitution = 0.9;
        }

        return sim;
    }

    pub fn update(self: *BouncingBalls, dt: f32, gravity_enabled: bool) void {
        const gravity = if (gravity_enabled) Vec3{ .x = 0, .y = -9.81, .z = 0 } else Vec3.zero();
        const half = self.box_size / 2.0;
        const radius: f32 = 0.3;

        for (0..self.ball_count) |i| {
            var ball = &self.balls[i];

            //apply gravity
            ball.vel = ball.vel.add(gravity.scale(dt));
            ball.pos = ball.pos.add(ball.vel.scale(dt));

            //box collisions
            if (ball.pos.x - radius < -half) {
                ball.pos.x = -half + radius;
                ball.vel.x = -ball.vel.x * ball.restitution;
            }
            if (ball.pos.x + radius > half) {
                ball.pos.x = half - radius;
                ball.vel.x = -ball.vel.x * ball.restitution;
            }
            if (ball.pos.y - radius < -half) {
                ball.pos.y = -half + radius;
                ball.vel.y = -ball.vel.y * ball.restitution;
            }
            if (ball.pos.y + radius > half) {
                ball.pos.y = half - radius;
                ball.vel.y = -ball.vel.y * ball.restitution;
            }
            if (ball.pos.z - radius < -half) {
                ball.pos.z = -half + radius;
                ball.vel.z = -ball.vel.z * ball.restitution;
            }
            if (ball.pos.z + radius > half) {
                ball.pos.z = half - radius;
                ball.vel.z = -ball.vel.z * ball.restitution;
            }
        }

        for (0..self.ball_count) |i| {
            for (i + 1..self.ball_count) |j| {
                self.resolveBallCollision(i, j);
            }
        }
    }

    fn resolveBallCollision(self: *BouncingBalls, i: usize, j: usize) void {
        const a = &self.balls[i];
        const b = &self.balls[j];

        const delta = b.pos.sub(a.pos);
        const dist = delta.length();
        const min_dist: f32 = 0.6; // 2 * radius

        if (dist >= min_dist or dist == 0) return;

        const normal = delta.normalize();
        const overlap = min_dist - dist;

        a.pos = a.pos.sub(normal.scale(overlap * 0.5));
        b.pos = b.pos.add(normal.scale(overlap * 0.5));

        const rel_vel = a.vel.sub(b.vel);
        const vel_along_normal = rel_vel.dot(normal);

        if (vel_along_normal < 0) return;

        const restitution: f32 = 0.9;
        const impulse = normal.scale(vel_along_normal * restitution);

        a.vel = a.vel.sub(impulse);
        b.vel = b.vel.add(impulse);
    }

    pub fn reset(self: *BouncingBalls) void {
        self.* = BouncingBalls.init();
    }
};
