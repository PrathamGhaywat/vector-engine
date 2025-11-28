const Vec3 = @import("vec3.zig").Vec3;

pub const ShapeType3D = enum {
    sphere,
    box,
};

pub const Shape3D = union(ShapeType3D) {
    sphere: SphereShape,
    box: BoxShape,
};

pub const SphereShape = struct {
    radius: f32,
};

pub const BoxShape = struct {
    width: f32,
    height: f32,
    depth: f32,
};