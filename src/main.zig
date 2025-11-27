const rl = @import("raylib");
const std = @import("std");
const Vec2 = @import("vec2.zig").Vec2;
const Body = @import("body.zig").Body;
const Shape = @import("shape.zig").Shape;
const World = @import("world.zig").World;

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(screenWidth, screenHeight, "VectorEngine");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var world = World.init(allocator);
    defer world.deinit();

    const dt: f32 = 1.0 / 60.0;

    //drag and throw state
    var isDragging = false;
    var dragStart = Vec2{ .x = 0, .y = 0 };
    var currentShape: u8 = 0; // 0 = circle, 1 = rectangle

    while (!rl.windowShouldClose()) {
        const currentWidth: f32 = @floatFromInt(rl.getScreenWidth());
        const currentHeight: f32 = @floatFromInt(rl.getScreenHeight());

        const mousePos = rl.getMousePosition();
        const mouseVec = Vec2{ .x = mousePos.x, .y = mousePos.y };

        //toggle shape with TAB
        if (rl.isKeyPressed(.tab)) {
            currentShape = (currentShape + 1) % 2;
        }

        //start drag
        if (rl.isMouseButtonPressed(.left)) {
            isDragging = true;
            dragStart = mouseVec;
        }

        //release and throw
        if (rl.isMouseButtonReleased(.left) and isDragging) {
            isDragging = false;
            const throwVel = dragStart.sub(mouseVec).scale(5.0);

            const shape: Shape = if (currentShape == 0)
                Shape{ .circle = .{ .radius = 20.0 } }
            else
                Shape{ .rectangle = .{ .width = 40.0, .height = 40.0 } };

            var body = Body.init(dragStart, 1.0, shape);
            body.vel = throwVel;
            try world.addBody(body);
        }

        //gravity controls
        if (rl.isKeyDown(.up)) world.gravity.y -= 10;
        if (rl.isKeyDown(.down)) world.gravity.y += 10;
        if (rl.isKeyPressed(.space)) world.gravity.y = 0;
        if (rl.isKeyPressed(.r)) world.gravity.y = 500;

        //clear
        if (rl.isKeyPressed(.c)) {
            world.clear();
        }

        //update physics
        world.update(dt, currentWidth, currentHeight);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        //drag preview
        if (isDragging) {
            if (currentShape == 0) {
                rl.drawCircle(@intFromFloat(dragStart.x), @intFromFloat(dragStart.y), 20.0, .{ .r = 255, .g = 0, .b = 0, .a = 100 });
            } else {
                rl.drawRectangle(@intFromFloat(dragStart.x - 20), @intFromFloat(dragStart.y - 20), 40, 40, .{ .r = 0, .g = 0, .b = 255, .a = 100 });
            }
            rl.drawLine(@intFromFloat(dragStart.x), @intFromFloat(dragStart.y), @intFromFloat(mousePos.x), @intFromFloat(mousePos.y), .blue);
        }

        
        for (world.bodies.items) |body| {
            switch (body.shape) {
                .circle => |circle| {
                    rl.drawCircle(@intFromFloat(body.pos.x), @intFromFloat(body.pos.y), circle.radius, .red);
                },
                .rectangle => |rect| {
                    rl.drawRectangle(@intFromFloat(body.pos.x - rect.width / 2), @intFromFloat(body.pos.y - rect.height / 2), @intFromFloat(rect.width), @intFromFloat(rect.height), .blue);
                },
                .polygon => {},
            }
        }

        // UI
        const shapeText = if (currentShape == 0) "Circle" else "Rectangle";
        rl.drawText("Drag to throw | TAB: Switch shape | C: Clear", 10, 10, 18, .dark_gray);
        rl.drawText(@ptrCast(shapeText), 10, 35, 20, .green);
    }
}
