const Vec3 = @import("vec3.zig").Vec3;
const Shape3D = @import("shape3d.zig").Shape3D;

pub const Body3D = struct {
    pos: Vec3,
    vel: Vec3,
    rotation: Vec3, //euler angles
    angular_vel: Vec3,
    mass: f32,
    restitution: f32,
    shape: Shape3D,
    is_static: bool,

    pub fn init(pos: Vec3, mass: f32, shape: Shape3D) Body3D {
        return Body3D{
            .pos = pos,
            .vel = Vec3.zero(),
            .rotation = Vec3.zero(),
            .angular_vel = Vec3.zero(),
            .mass = mass,
            .restitution = 0.8,
            .shape = shape,
            .is_static = false,
        };
    }

    pub fn initStatic(pos: Vec3, shape: Shape3D) Body3D {
        var body = init(pos, 0, shape);
        body.is_static = true;
        return body;
    }

    pub fn update(self: *Body3D, gravity: Vec3, dt: f32) void {
        if (self.is_static) return;

        self.vel = self.vel.add(gravity.scale(dt));
        self.pos = self.pos.add(self.vel.scale(dt));
        self.rotation = self.rotation.add(self.angular_vel.scale(dt));
    }

    pub fn getInverseMass(self: Body3D) f32 {
        if (self.is_static or self.mass == 0) return 0;
        return 1.0 / self.mass;
    }

    pub fn applyForce(self: *Body3D, force: Vec3) void {
        if (self.is_static) return;
        const accel = force.scale(1.0 / self.mass);
        self.vel = self.vel.add(accel);
    }
};