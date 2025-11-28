const rl = @import("raylib");
const std = @import("std");
const ui = @import("ui.zig");
const NewtonsCradle = @import("simulations/newtons_cradle.zig").NewtonsCradle;
const Vec3 = @import("vec3.zig").Vec3;

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

    //3D Camera
    var camera = rl.Camera3D{
        .position = .{ .x = 10, .y = 5, .z = 10 },
        .target = .{ .x = 0, .y = -2, .z = 0 },
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = 45,
        .projection = .perspective,
    };

    //ui
    var panel = ui.Panel{
        .x = 10,
        .y = 10,
        .width = 200,
        .height = 300,
        .title = "Controls",
    };

    var btn_reset = ui.Button.init(20, 40, 180, 30, "Reset");
    var btn_2d = ui.Button.init(20, 80, 85, 30, "2D Mode");
    var btn_3d = ui.Button.init(115, 80, 85, 30, "3D Mode");
    var slider_gravity = ui.Slider.init(20, 140, 180, "Gravity", 0, 20, 9.81);
    var slider_speed = ui.Slider.init(20, 190, 180, "Speed", 0.1, 3.0, 1.0);

    //simulations
    var cradle = NewtonsCradle.init();
    const current_sim = SimulationType.newtons_cradle;
    _ = current_sim;

    const dt: f32 = 1.0 / 60.0;

    while (!rl.windowShouldClose()) {
        //ui updates
        if (btn_reset.update()) {
            cradle.reset();
        }
        if (btn_2d.update()) {
            //to 2D sandbox
        }
        if (btn_3d.update()) {
            //to 3D Newton's cradle
        }
        slider_gravity.update();
        slider_speed.update();

        //update camera (orbit)
        rl.updateCamera(&camera, .orbital);

        //update physics
        const speed_mult = slider_speed.value;
        cradle.update(dt * speed_mult);

        //drawing
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.ray_white);

        //3D Scene
        {
            rl.beginMode3D(camera);
            defer rl.endMode3D();

            //draw ground
            rl.drawGrid(20, 1.0);

            //draw newton's cradle
            for (cradle.pendulums) |p| {
                // Draw rope
                rl.drawLine3D(
                    .{ .x = p.anchor.x, .y = p.anchor.y, .z = p.anchor.z },
                    .{ .x = p.ball.pos.x, .y = p.ball.pos.y, .z = p.ball.pos.z },
                    .dark_gray,
                );

                //draw ball
                rl.drawSphere(
                    .{ .x = p.ball.pos.x, .y = p.ball.pos.y, .z = p.ball.pos.z },
                    cradle.ball_radius,
                    .maroon,
                );
            }

            //draw frame
            rl.drawCubeWires(.{ .x = 0, .y = 0.5, .z = 0 }, 8, 1, 0.2, .dark_gray);
        }

        //ui (2D overlay)
        panel.draw();
        btn_reset.draw();
        btn_2d.draw();
        btn_3d.draw();
        slider_gravity.draw();
        slider_speed.draw();

        rl.drawFPS(screenWidth - 100, 10);
    }
}