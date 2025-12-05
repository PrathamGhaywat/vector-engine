const rl = @import("raylib");
const std = @import("std");
const ui = @import("ui.zig");
const NewtonsCradle = @import("simulations/newtons_cradle.zig").NewtonsCradle;
const Vec3 = @import("vec3.zig").Vec3;
const Vec2 = @import("vec2.zig").Vec2;
const Body = @import("body.zig").Body;
const Shape = @import("shape.zig").Shape;
const World = @import("world.zig").World;

const SimulationType = enum {
    sandbox_2d,
    newtons_cradle,
};

pub fn main() anyerror!void {
    const screenWidth = 1200;
    const screenHeight = 700;

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(screenWidth, screenHeight, "VectorEngine - Physics Simulator");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    //3D Camera
    var camera = rl.Camera3D{
        .position = .{ .x = 10, .y = 5, .z = 10 },
        .target = .{ .x = 0, .y = -2, .z = 0 },
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = 45,
        .projection = .perspective,
    };

    const panel = ui.Panel{
        .x = 10,
        .y = 10,
        .width = 200,
        .height = 250,
        .title = "Controls",
    };

    var btn_reset = ui.Button.init(20, 40, 180, 30, "Reset");
    var btn_2d = ui.Button.init(20, 80, 85, 30, "2D Mode");
    var btn_3d = ui.Button.init(115, 80, 85, 30, "3D Mode");
    var slider_gravity = ui.Slider.init(20, 140, 180, "Gravity", 0, 20, 9.81);
    var slider_speed = ui.Slider.init(20, 190, 180, "Speed", 0.1, 3.0, 1.0);

    var cradle = NewtonsCradle.init();

    var world = World.init(allocator);
    defer world.deinit();

    var current_sim = SimulationType.newtons_cradle;

    //2D drag state
    var isDragging = false;
    var dragStart = Vec2{ .x = 0, .y = 0 };
    var currentShape: u8 = 0; // 0 = circ, 1 = rect

    const dt: f32 = 1.0 / 60.0;

    while (!rl.windowShouldClose()) {
        const currentWidth: f32 = @floatFromInt(rl.getScreenWidth());
        const currentHeight: f32 = @floatFromInt(rl.getScreenHeight());
        const mousePos = rl.getMousePosition();
        const mouseVec = Vec2{ .x = mousePos.x, .y = mousePos.y };

        const mouseOverUI = panel.contains(mousePos.x, mousePos.y);

        //UI updates
        if (btn_reset.update()) {
            if (current_sim == .newtons_cradle) {
                cradle.reset();
            } else {
                world.clear();
            }
        }
        if (btn_2d.update()) {
            current_sim = .sandbox_2d;
        }
        if (btn_3d.update()) {
            current_sim = .newtons_cradle;
        }
        slider_gravity.update();
        slider_speed.update();

        //update gravity from slider
        const gravity_val = slider_gravity.value;
        world.gravity = Vec2{ .x = 0, .y = gravity_val * 50 };

        const speed_mult = slider_speed.value;

        if (current_sim == .newtons_cradle) {
            //3D Mode
            rl.updateCamera(&camera, .orbital);
            cradle.update(dt * speed_mult);
        } else {
            if (!mouseOverUI) {
                //toggle shape with Tab
                if (rl.isKeyPressed(.tab)) {
                    currentShape = (currentShape + 1) % 2;
                }

                //start drag
                if (rl.isMouseButtonPressed(.left)) {
                    isDragging = true;
                    dragStart = mouseVec;
                }
                if (rl.isMouseButtonReleased(.left) and isDragging) {
                    isDragging = false;
                    const throwVel = dragStart.sub(mouseVec).scale(5.0);

                    const shape: Shape = if (currentShape == 0)
                        Shape{ .circle = .{ .radius = 20.0 } }
                    else
                        Shape{ .rectangle = .{ .width = 40.0, .height = 40.0 } };

                    var body = Body.init(dragStart, 1.0, shape);
                    body.vel = throwVel;
                    world.addBody(body) catch {};
                }
            } else {
                isDragging = false;
            }

            world.update(dt * speed_mult, currentWidth, currentHeight);
        }

        // Drawing
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.ray_white);

        if (current_sim == .newtons_cradle) {
            {
                rl.beginMode3D(camera);
                defer rl.endMode3D();

                rl.drawGrid(20, 1.0);

                for (cradle.pendulums) |p| {
                    rl.drawLine3D(
                        .{ .x = p.anchor.x, .y = p.anchor.y, .z = p.anchor.z },
                        .{ .x = p.ball.pos.x, .y = p.ball.pos.y, .z = p.ball.pos.z },
                        .dark_gray,
                    );

                    rl.drawSphere(
                        .{ .x = p.ball.pos.x, .y = p.ball.pos.y, .z = p.ball.pos.z },
                        cradle.ball_radius,
                        .maroon,
                    );
                }

                rl.drawCubeWires(.{ .x = 0, .y = 0.5, .z = 0 }, 8, 1, 0.2, .dark_gray);
            }
        } else {
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

            rl.drawText("TAB: Switch shape | Drag to throw", 220, 10, 18, .dark_gray);
            const shapeText: [:0]const u8 = if (currentShape == 0) "Shape: Circle" else "Shape: Rectangle";
            rl.drawText(shapeText, 220, 35, 18, .green);
        }

        //2D overlay
        panel.draw();
        btn_reset.draw();
        btn_2d.draw();
        btn_3d.draw();
        slider_gravity.draw();
        slider_speed.draw();

        const modeText: [:0]const u8 = if (current_sim == .newtons_cradle) "Mode: 3D Newton's Cradle" else "Mode: 2D Sandbox";
        rl.drawText(modeText, 20, 220, 14, .dark_gray);

        rl.drawFPS(@intFromFloat(currentWidth - 100), 10);
    }
}
