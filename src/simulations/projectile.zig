const std = @import("std");
const Vec3 = @import("../vec3.zig").Vec3;

pub const Projectile = struct {
    pos: Vec3,
    vel: Vec3,
    radius: f32,
    active: bool,
};

pub const ProjectileSimulation = struct {
    projectiles: [20]Projectile,
    projectile_count: usize,
    launch_angle: f32,
    launch_speed: f32,
    ground_y: f32,

    pub fn init() ProjectileSimulation {
        var sim = ProjectileSimulation{
            .projectiles = undefined,
            .projectile_count = 0,
            .launch_angle = 45.0,
            .launch_speed = 15.0,
            .ground_y = -3.0,
        };

        for (0..20) |i| {
            sim.projectiles[i] = Projectile{
                .pos = Vec3.zero(),
                .vel = Vec3.zero(),
                .radius = 0.2,
                .active = false,
            };
        }

        return sim;
    }

    pub fn launch(self: *ProjectileSimulation) void {
        //find inactive projectile
        for (0..20) |i| {
            if (!self.projectiles[i].active) {
                const angle_rad = self.launch_angle * std.math.pi / 180.0;
                self.projectiles[i] = Projectile{
                    .pos = Vec3{ .x = -5, .y = self.ground_y + 0.5, .z = 0 },
                    .vel = Vec3{
                        .x = @cos(angle_rad) * self.launch_speed,
                        .y = @sin(angle_rad) * self.launch_speed,
                        .z = 0,
                    },
                    .radius = 0.2,
                    .active = true,
                };
                if (self.projectile_count < 20) {
                    self.projectile_count += 1;
                }
                break;
            }
        }
    }

    pub fn update(self: *ProjectileSimulation, dt: f32, gravity_val: f32) void {
        const gravity = Vec3{ .x = 0, .y = -gravity_val, .z = 0 };

        for (0..20) |i| {
            if (self.projectiles[i].active) {
                self.projectiles[i].vel = self.projectiles[i].vel.add(gravity.scale(dt));
                self.projectiles[i].pos = self.projectiles[i].pos.add(self.projectiles[i].vel.scale(dt));

                if (self.projectiles[i].pos.y < self.ground_y) {
                    self.projectiles[i].pos.y = self.ground_y;
                    self.projectiles[i].vel = Vec3.zero();
                }

                //deactivate if too far
                if (self.projectiles[i].pos.x > 20) {
                    self.projectiles[i].active = false;
                }
            }
        }
    }

    pub fn reset(self: *ProjectileSimulation) void {
        self.* = ProjectileSimulation.init();
    }
};