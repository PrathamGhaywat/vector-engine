const rl = @import("raylib");
const std = @import("std");
const Vec2 = @import("vec2.zig").Vec2;
const Circle = @import("circle.zig").Circle;

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.setConfigFlags(.{.window_resizable = true });
    rl.initWindow(screenWidth, screenHeight, "VectorEngine");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var circles = try std.ArrayList(Circle).initCapacity(allocator, 0);
    defer circles.deinit(allocator);

    var gravity = Vec2{ .x = 0, .y = 500 };
    const dt: f32 = 1.0 / 60.0;

    while (!rl.windowShouldClose()) {
        //win dimensions
        const currentWidth: f32 = @floatFromInt(rl.getScreenWidth());
        const currentHeight: f32 = @floatFromInt(rl.getScreenHeight());
        //spawn circle on mouse click
        if (rl.isMouseButtonPressed(.left)) {
            const mousePos = rl.getMousePosition();
            try circles.append(allocator, Circle{
                .pos = Vec2{ .x = mousePos.x, .y = mousePos.y },
                .vel = Vec2{ .x = 0.0, .y = 0.0 },
                .radius = 20.0,
                .mass = 1.0,
            });
        }

        //change gravity with arrow keys
        if (rl.isKeyDown(.up)) gravity.y -= 10;
        if (rl.isKeyDown(.down)) gravity.y += 10;
        if (rl.isKeyPressed(.space)) gravity.y = 0; //toggle gravity
        if (rl.isKeyPressed(.r)) gravity.y = 500; //reset gravity

        //update every circle
        for (circles.items) |*circle| {
            circle.update(gravity, dt, currentWidth, currentHeight);
        }

        //clear circles
        if (rl.isKeyPressed(.c)) {
            circles.clearRetainingCapacity();
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        //draw all circles
        for (circles.items) |circle| {
            rl.drawCircle(@intFromFloat(circle.pos.x), @intFromFloat(circle.pos.y), circle.radius, .red);
        }

        //ui
        var gravity_text_buf: [128]u8 = undefined;
        const gravity_text_remainder =
            try std.fmt.bufPrint(&gravity_text_buf,
                "Gravity: {d:.0} (UP/DOWN to adjust, SPACE to zero, R to reset.",
                .{gravity.y}
            );
        const gravity_text_len = gravity_text_buf.len - gravity_text_remainder.len;

        //add sentinel
        gravity_text_buf[gravity_text_len] = 0;

        const gravityText: [:0]const u8 = gravity_text_buf[0 .. gravity_text_len :0];

        rl.drawText("Click to spawn balls", 10, 10, 20, .green);
        rl.drawText(gravityText, 10, 35, 20, .black);
        rl.drawText("Press C to erase all balls", 10, 60, 20, .black);

    }
}
