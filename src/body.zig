const Vec2 = @import("vec2.zig").Vec2;
const Shape = @import("shape.zig").Shape;
const ShapeType = @import("shape.zig").ShapeType;

pub const Body = struct {
    pos: Vec2,
    vel: Vec2,
    rotation: f32, //angle in radians
    angular_vel: f32,
    mass: f32,
    restitution: f32,
    shape: Shape,
    is_static: bool, //for immovable obj (eg ground)

    pub fn init(pos: Vec2, mass: f32, shape: Shape) Body {
        return Body{
            .pos = pos,
            .vel = Vec2{ .x = 0, .y = 0 },
            .rotation = 0,
            .angular_vel = 0,
            .mass = mass,
            .restitution = 0.8,
            .shape = shape,
            .is_static = false,
        };
    }

    pub fn applyForce(self: *Body, force: Vec2) void {
        if (self.is_static) return;
        const accel = force.scale(1.0 / self.mass);
        self.vel = self.vel.add(accel);
    }

    pub fn update(self: *Body, gravity: Vec2, dt: f32) void {
        if (self.is_static) return;

        //apply gravity
        self.vel = self.vel.add(gravity.scale(dt));

        //update position
        self.pos = self.pos.add(self.vel.scale(dt));

        //update rotation
        self.rotation += self.angular_vel * dt;
    }

    pub fn getInverseMass(self: Body) f32 {
        if (self.is_static or self.mass == 0) return 0;
        return 1.0 / self.mass;
    }
};
