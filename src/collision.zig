const Vec2 = @import("vec2.zig").Vec2;
const Body = @import("body.zig").Body;
const Shape = @import("shape.zig").Shape;
const ShapeType = @import("shape.zig").ShapeType;

pub const Manifold = struct {
    body_a: *Body,
    body_b: *Body,
    normal: Vec2,
    penetration: f32,
    has_collision: bool,
};

pub fn detectCollision(a: *Body, b: *Body) Manifold {
    var manifold = Manifold{
        .body_a = a,
        .body_b = b,
        .normal = Vec2{ .x = 0, .y = 0 },
        .penetration = 0,
        .has_collision = false,
    };

    switch (a.shape) {
        .circle => |circle_a| {
            switch (b.shape) {
                .circle => |circle_b| {
                    manifold = circleVsCircle(a, b, circle_a.radius, circle_b.radius);
                },
                .rectangle => |rect_b| {
                    manifold = circleVsRect(a, b, circle_a.radius, rect_b.width, rect_b.height);
                },
                .polygon => {},
            }
        },
        .rectangle => |rect_a| {
            switch (b.shape) {
                .circle => |circle_b| {
                    manifold = circleVsRect(b, a, circle_b.radius, rect_a.width, rect_a.height);
                    manifold.normal = manifold.normal.scale(-1); //flip normal
                },
                .rectangle => |rect_b| {
                    manifold = rectVsRect(a, b, rect_a.width, rect_a.height, rect_b.width, rect_b.height);
                },
                .polygon => {},
            }
        },
        .polygon => {},
    }

    return manifold;
}

fn circleVsCircle(a: *Body, b: *Body, radius_a: f32, radius_b: f32) Manifold {
    var manifold = Manifold{
        .body_a = a,
        .body_b = b,
        .normal = Vec2{ .x = 0, .y = 0 },
        .penetration = 0,
        .has_collision = false,
    };

    const delta = b.pos.sub(a.pos);
    const dist = delta.length();
    const sum_radii = radius_a + radius_b;

    if (dist >= sum_radii) return manifold;

    manifold.has_collision = true;
    if (dist == 0) {
        manifold.penetration = radius_a;
        manifold.normal = Vec2{ .x = 1, .y = 0 };
    } else {
        manifold.penetration = sum_radii - dist;
        manifold.normal = delta.normalize();
    }

    return manifold;
}

fn circleVsRect(circle_body: *Body, rect_body: *Body, radius: f32, width: f32, height: f32) Manifold {
    var manifold = Manifold{
        .body_a = circle_body,
        .body_b = rect_body,
        .normal = Vec2{ .x = 0, .y = 0 },
        .penetration = 0,
        .has_collision = false,
    };

    const half_w = width / 2;
    const half_h = height / 2;

    //fFind closest point on rect to circle middle
    const delta = circle_body.pos.sub(rect_body.pos);
    var closest = Vec2{
        .x = @max(-half_w, @min(half_w, delta.x)),
        .y = @max(-half_h, @min(half_h, delta.y)),
    };

    const inside = delta.x == closest.x and delta.y == closest.y;

    if (inside) {
        //circle middle is inside rect
        const dist_x = half_w - @abs(delta.x);
        const dist_y = half_h - @abs(delta.y);

        if (dist_x < dist_y) {
            closest.x = if (delta.x > 0) half_w else -half_w;
        } else {
            closest.y = if (delta.y > 0) half_h else -half_h;
        }
    }

    const normal = delta.sub(closest);
    const dist = normal.length();

    if (dist > radius and !inside) return manifold;

    manifold.has_collision = true;
    manifold.normal = if (dist == 0) Vec2{ .x = 1, .y = 0 } else normal.normalize();
    manifold.penetration = radius - dist;

    if (inside) {
        manifold.normal = manifold.normal.scale(-1);
    }

    return manifold;
}

fn rectVsRect(a: *Body, b: *Body, w_a: f32, h_a: f32, w_b: f32, h_b: f32) Manifold {
    var manifold = Manifold{
        .body_a = a,
        .body_b = b,
        .normal = Vec2{ .x = 0, .y = 0 },
        .penetration = 0,
        .has_collision = false,
    };

    const delta = b.pos.sub(a.pos);

    const overlap_x = (w_a / 2 + w_b / 2) - @abs(delta.x);
    if (overlap_x <= 0) return manifold;

    const overlap_y = (h_a / 2 + h_b / 2) - @abs(delta.y);
    if (overlap_y <= 0) return manifold;

    manifold.has_collision = true;

    if (overlap_x < overlap_y) {
        manifold.normal = Vec2{ .x = if (delta.x < 0) -1 else 1, .y = 0 };
        manifold.penetration = overlap_x;
    } else {
        manifold.normal = Vec2{ .x = 0, .y = if (delta.y < 0) -1 else 1 };
        manifold.penetration = overlap_y;
    }

    return manifold;
}

pub fn resolveCollision(manifold: *Manifold) void {
    if (!manifold.has_collision) return;

    const a = manifold.body_a;
    const b = manifold.body_b;

    const inv_mass_a = a.getInverseMass();
    const inv_mass_b = b.getInverseMass();
    const total_inv_mass = inv_mass_a + inv_mass_b;

    if (total_inv_mass == 0) return; //both static

    //separate bodies
    const correction = manifold.normal.scale(manifold.penetration / total_inv_mass);
    a.pos = a.pos.sub(correction.scale(inv_mass_a));
    b.pos = b.pos.add(correction.scale(inv_mass_b));

    //calc relative vel
    const rel_vel = b.vel.sub(a.vel);
    const vel_along_normal = rel_vel.dot(manifold.normal);

    if (vel_along_normal > 0) return; 

    const restitution = @min(a.restitution, b.restitution);
    const impulse_scalar = -(1 + restitution) * vel_along_normal / total_inv_mass;

    const impulse = manifold.normal.scale(impulse_scalar);
    a.vel = a.vel.sub(impulse.scale(inv_mass_a));
    b.vel = b.vel.add(impulse.scale(inv_mass_b));
}
