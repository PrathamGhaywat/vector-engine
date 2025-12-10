const Vec3 = @import("vec3.zig").Vec3;

pub const SimulationType3D = enum {
    newtons_cradle,
    bouncing_balls,
    projectile,
    spring_pendulum,
};

pub const SimulationInfo = struct {
    sim_type: SimulationType3D,
    name: [:0]const u8,
    description: [:0]const u8,
};

pub const simulations = [_]SimulationInfo{
    .{ .sim_type = .newtons_cradle, .name = "Newton's Cradle", .description = "Classic momentum demo"},
    .{ .sim_type = .bouncing_balls, .name = "Bouncing Balls", .description = "3D balls in a box"},
    .{ .sim_type = .solar_system, .name = "Solar System", .description = "Orbital mechanics"},
    .{ .sim_type = .bouncing_balls, .name = "Projectile", .description = "Launch projectiles"},
    .{ .sim_type = .newtons_cradle, .name = "Newton's Cradle", .description = "Hooke's law demo"},
};