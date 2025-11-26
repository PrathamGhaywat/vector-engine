const Vec2 = @import("vec2.zig").Vec2;

pub const Circle = struct {
    pos: Vec2,
    vel: Vec2,
    radius: f32,
    mass: f32,

    pub fn update(self: *Circle, gravity: Vec2, dt: f32,screenHeight: f32) void {
        //apply gravity
        self.vel = self.vel.add(gravity.scale(dt));

        //update position
        self.pos = self.pos.add(self.vel.scale(dt));

        //Floor collision
        if (self.pos.y + self.radius > screenHeight) {
            self.pos.y = screenHeight - self.radius;
            self.vel.y = -self.vel.y * 0.8;
        }

        //wall collisions
        if (self.pos.x - self.radius < 0) {
            self.pos.x = self.radius;
            self.vel.x = -self.vel.x * 0.8;
        }
        if (self.pos.x + self.radius > 800) {
            self.pos.x = 800 - self.radius;
            self.vel.x = -self.vel.x * 0.8;
        }


    }
};