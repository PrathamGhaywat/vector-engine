const std = @import("std");
const Vec3 = @import("../vec3.zig").Vec3;

pub const CelestialBody = struct {
    pos: Vec3,
    vel: Vec3,
    mass: f32,
    radius: f32,
    color_r: u8,
    color_g: u8,
    color_b: u8,
};

pub const SolarSystem = struct {
    bodies: [6]CelestialBody,
    body_count: usize,
    time_scale: f32,

    pub fn init() SolarSystem {
        var sys = SolarSystem{
            .bodies = undefined,
            .body_count = 6,
            .time_scale = 1.0,
        };

        // Sun
        sys.bodies[0] = CelestialBody{
            .pos = Vec3.zero(),
            .vel = Vec3.zero(),
            .mass = 1000.0,
            .radius = 1.0,
            .color_r = 255,
            .color_g = 200,
            .color_b = 0,
        };

        // Mercury
        sys.bodies[1] = CelestialBody{
            .pos = Vec3{ .x = 2.5, .y = 0, .z = 0 },
            .vel = Vec3{ .x = 0, .y = 0, .z = 12.0 },
            .mass = 1.0,
            .radius = 0.15,
            .color_r = 150,
            .color_g = 150,
            .color_b = 150,
        };

        // Venus
        sys.bodies[2] = CelestialBody{
            .pos = Vec3{ .x = 4.0, .y = 0, .z = 0 },
            .vel = Vec3{ .x = 0, .y = 0, .z = 9.5 },
            .mass = 2.0,
            .radius = 0.2,
            .color_r = 255,
            .color_g = 180,
            .color_b = 100,
        };

        // Earth
        sys.bodies[3] = CelestialBody{
            .pos = Vec3{ .x = 5.5, .y = 0, .z = 0 },
            .vel = Vec3{ .x = 0, .y = 0, .z = 8.0 },
            .mass = 2.5,
            .radius = 0.25,
            .color_r = 50,
            .color_g = 100,
            .color_b = 255,
        };

        // Mars
        sys.bodies[4] = CelestialBody{
            .pos = Vec3{ .x = 7.0, .y = 0, .z = 0 },
            .vel = Vec3{ .x = 0, .y = 0, .z = 7.0 },
            .mass = 1.5,
            .radius = 0.18,
            .color_r = 200,
            .color_g = 80,
            .color_b = 50,
        };

        // Jupiter
        sys.bodies[5] = CelestialBody{
            .pos = Vec3{ .x = 10.0, .y = 0, .z = 0 },
            .vel = Vec3{ .x = 0, .y = 0, .z = 6.0 },
            .mass = 50.0,
            .radius = 0.5,
            .color_r = 200,
            .color_g = 150,
            .color_b = 100,
        };

        return sys;
    }

    pub fn update(self: *SolarSystem, dt: f32) void {
        const G: f32 = 1.0; 

        //calc forces
        for (0..self.body_count) |i| {
            var force = Vec3.zero();

            for (0..self.body_count) |j| {
                if (i == j) continue;

                const delta = self.bodies[j].pos.sub(self.bodies[i].pos);
                const dist = delta.length();
                if (dist < 0.1) continue;

                const strength = G * self.bodies[i].mass * self.bodies[j].mass / (dist * dist);
                force = force.add(delta.normalize().scale(strength));
            }

            //F = ma, so a = F/m
            const accel = force.scale(1.0 / self.bodies[i].mass);
            self.bodies[i].vel = self.bodies[i].vel.add(accel.scale(dt * self.time_scale));
        }

        for (0..self.body_count) |i| {
            self.bodies[i].pos = self.bodies[i].pos.add(self.bodies[i].vel.scale(dt * self.time_scale));
        }
    }

    pub fn reset(self: *SolarSystem) void {
        self.* = SolarSystem.init();
    }
};
