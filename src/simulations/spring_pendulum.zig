const Vec3 = @import("../vec3.zig").Vec3;

pub const SpringPendulum = struct {
    anchor: Vec3,
    ball_pos: Vec3,
    ball_vel: Vec3,
    rest_length: f32,
    spring_constant: f32,
    damping: f32,
    ball_mass: f32,
    ball_radius: f32,

    pub fn init() SpringPendulum {
        return SpringPendulum{
            .anchor = Vec3{ .x = 0, .y = 3, .z = 0 },
            .ball_pos = Vec3{ .x = 3, .y = 0, .z = 0 },
            .ball_vel = Vec3.zero(),
            .rest_length = 2.0,
            .spring_constant = 15.0,
            .damping = 0.5,
            .ball_mass = 1.0,
            .ball_radius = 0.4,
        };
    }

    pub fn update(self: *SpringPendulum, dt: f32, gravity_val: f32) void {
        const gravity = Vec3{ .x = 0, .y = -gravity_val, .z = 0 };

        //Hooke's law
        const delta = self.ball_pos.sub(self.anchor);
        const dist = delta.length();
        const stretch = dist - self.rest_length;

        var spring_force = Vec3.zero();
        if (dist > 0) {
            spring_force = delta.normalize().scale(-self.spring_constant * stretch);
        }
        
        const damping_force = self.ball_vel.scale(-self.damping);

        const total_force = spring_force.add(damping_force).add(gravity.scale(self.ball_mass));

        const accel = total_force.scale(1.0 / self.ball_mass);
        self.ball_vel = self.ball_vel.add(accel.scale(dt));
        self.ball_pos = self.ball_pos.add(self.ball_vel.scale(dt));
    }

    pub fn reset(self: *SpringPendulum) void {
        self.* = SpringPendulum.init();
    }

    pub fn pull(self: *SpringPendulum, direction: Vec3) void {
        self.ball_pos = self.ball_pos.add(direction);
    }
};