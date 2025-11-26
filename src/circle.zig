const Vec2 = @import("vec2.zig").Vec2;

pub const Circle = struct {
    pos: Vec2,
    vel: Vec2,
    radius: f32,
    mass: f32,

    pub fn update(self: *Circle, gravity: Vec2, dt: f32, screenWidth: f32, screenHeight: f32) void {
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
        if (self.pos.x + self.radius > screenWidth) {
            self.pos.x = screenWidth - self.radius;
            self.vel.x = -self.vel.x * 0.8;
        }
    }

    pub fn collidesWith(self: Circle, other: Circle) bool {
        const dist = self.pos.distance(other.pos);
        return dist < self.radius + other.radius;
    }

    pub fn resolveCollision(self: *Circle, other: *Circle) void {
        const delta = self.pos.sub(other.pos);
        const dist = delta.length();
        if (dist == 0) return;

        const normal = delta.normalize();
        const overlap = (self.radius + other.radius) - dist;

        // Separate circles
        self.pos = self.pos.add(normal.scale(overlap * 0.5));
        other.pos = other.pos.sub(normal.scale(overlap * 0.5));

        // Elastic collision response
        const relVel = self.vel.sub(other.vel);
        const velAlongNormal = relVel.dot(normal);

        if (velAlongNormal > 0) return; // Moving apart

        const restitution: f32 = 0.8;
        const totalMass = self.mass + other.mass;

        const impulse = -(1 + restitution) * velAlongNormal / totalMass;

        self.vel = self.vel.add(normal.scale(impulse * other.mass));
        other.vel = other.vel.sub(normal.scale(impulse * self.mass));
    }
};
