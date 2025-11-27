const Vec2 = @import("vec2.zig").Vec2;

pub const ShapeType = enum {
    circle,
    rectangle,
    polygon,
};

pub const Shape = union(ShapeType) {
    circle: CircleShape,
    rectangle: RectangleShape,
    polygon: PolygonShape,
};


pub const CircleShape = struct {
    radius: f32,
};

pub const RectangleShape = struct {
    width: f32,
    height: f32
};

pub const PolygonShape = struct {
    vertices: [8]Vec2, //max 8 vertices. i want to keep it simple
    vertex_count: u8,
};