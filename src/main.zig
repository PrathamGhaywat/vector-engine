const rl = @import("raylib");
const std = @import("std");
const ui = @import("ui.zig");
const NewtonsCradle = @import("simulations/newtons_cradle.zig").NewtonsCradle;
const BouncingBalls = @import("simulations/bouncing_balls.zig").BouncingBalls;
const SolarSystem = @import("simulations/solar_system.zig").SolarSystem;
const SpringPendulum = @import("simulations/spring_pendulum.zig").SpringPendulum;
const ProjectileSimulation = @import("simulations/projectile.zig").ProjectileSimulation;
const Vec3 = @import("vec3.zig").Vec3;
const Vec2 = @import("vec2.zig").Vec2;
const Body = @import("body.zig").Body;
const Shape = @import("shape.zig").Shape;
const World = @import("world.zig").World;

const SimMode = enum {
    mode_2d,
    mode_3d,
};

const Simulation3D = enum {
    newtons_cradle,
    bouncing_balls,
    solar_system,
    spring_pendulum,
    projectile,
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
        .position = .{ .x = 15, .y = 10, .z = 15 },
        .target = .{ .x = 0, .y = 0, .z = 0 },
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = 45,
        .projection = .perspective,
    };

    //UI Elements
    const panel = ui.Panel{
        .x = 10,
        .y = 10,
        .width = 200,
        .height = 320,
        .title = "Controls",
    };

    var btn_reset = ui.Button.init(20, 40, 180, 30, "Reset");
    var btn_2d = ui.Button.init(20, 80, 85, 30, "2D Mode");
    var btn_3d = ui.Button.init(115, 80, 85, 30, "3D Mode");

    const sim_options = [_][:0]const u8{
        "Newton's Cradle",
        "Bouncing Balls",
        "Solar System",
        "Spring Pendulum",
        "Projectile",
    };
    var dropdown_sim = ui.Dropdown.init(20, 120, 180, &sim_options);

    var slider_gravity = ui.Slider.init(20, 200, 180, "Gravity", 0, 20, 9.81);
    var slider_speed = ui.Slider.init(20, 250, 180, "Speed", 0.1, 3.0, 1.0);

    var btn_launch = ui.Button.init(20, 280, 180, 30, "Launch");

    //3D Simulations
    var cradle = NewtonsCradle.init();
    var bouncing = BouncingBalls.init();
    var solar = SolarSystem.init();
    var spring = SpringPendulum.init();
    var projectile = ProjectileSimulation.init();

    var world = World.init(allocator);
    defer world.deinit();

    //state
    var current_mode = SimMode.mode_3d;
    var current_3d_sim = Simulation3D.newtons_cradle;

    //2D drag state
    var isDragging = false;
    var dragStart = Vec2{ .x = 0, .y = 0 };
    var currentShape: u8 = 0;

    const dt: f32 = 1.0 / 60.0;

    while (!rl.windowShouldClose()) {
        const currentWidth: f32 = @floatFromInt(rl.getScreenWidth());
        const currentHeight: f32 = @floatFromInt(rl.getScreenHeight());
        const mousePos = rl.getMousePosition();
        const mouseVec = Vec2{ .x = mousePos.x, .y = mousePos.y };

        const mouseOverUI = panel.contains(mousePos.x, mousePos.y);

        //UI updates
        if (btn_reset.update()) {
            if (current_mode == .mode_3d) {
                switch (current_3d_sim) {
                    .newtons_cradle => cradle.reset(),
                    .bouncing_balls => bouncing.reset(),
                    .solar_system => solar.reset(),
                    .spring_pendulum => spring.reset(),
                    .projectile => projectile.reset(),
                }
            } else {
                world.clear();
            }
        }

        if (btn_2d.update()) {
            current_mode = .mode_2d;
        }
        if (btn_3d.update()) {
            current_mode = .mode_3d;
        }

        if (dropdown_sim.update()) {
            current_3d_sim = @enumFromInt(dropdown_sim.selected);
        }

        slider_gravity.update();
        slider_speed.update();

        if (current_3d_sim == .projectile and btn_launch.update()) {
            projectile.launch();
        }

        const gravity_val = slider_gravity.value;
        const speed_mult = slider_speed.value;

        world.gravity = Vec2{ .x = 0, .y = gravity_val * 50 };

        if (current_mode == .mode_3d) {
            rl.updateCamera(&camera, .orbital);

            switch (current_3d_sim) {
                .newtons_cradle => cradle.update(dt * speed_mult),
                .bouncing_balls => bouncing.update(dt * speed_mult, true),
                .solar_system => solar.update(dt * speed_mult),
                .spring_pendulum => spring.update(dt * speed_mult, gravity_val),
                .projectile => projectile.update(dt * speed_mult, gravity_val),
            }
        } else {
            if (!mouseOverUI) {
                if (rl.isKeyPressed(.tab)) {
                    currentShape = (currentShape + 1) % 2;
                }
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

        if (current_mode == .mode_3d) {
            rl.beginMode3D(camera);
            defer rl.endMode3D();

            rl.drawGrid(20, 1.0);

            switch (current_3d_sim) {
                .newtons_cradle => {
                    for (cradle.pendulums) |p| {
                        rl.drawLine3D(
                            .{ .x = p.anchor.x, .y = p.anchor.y, .z = p.anchor.z },
                            .{ .x = p.ball.pos.x, .y = p.ball.pos.y, .z = p.ball.pos.z },
                            .dark_gray,
                        );
                        rl.drawSphere(.{ .x = p.ball.pos.x, .y = p.ball.pos.y, .z = p.ball.pos.z }, cradle.ball_radius, .maroon);
                    }
                    rl.drawCubeWires(.{ .x = 0, .y = 0.5, .z = 0 }, 8, 1, 0.2, .dark_gray);
                },
                .bouncing_balls => {
                    rl.drawCubeWires(.{ .x = 0, .y = 0, .z = 0 }, bouncing.box_size, bouncing.box_size, bouncing.box_size, .dark_gray);
                    for (0..bouncing.ball_count) |i| {
                        const ball = bouncing.balls[i];
                        rl.drawSphere(.{ .x = ball.pos.x, .y = ball.pos.y, .z = ball.pos.z }, 0.3, .red);
                    }
                },
                .solar_system => {
                    for (0..solar.body_count) |i| {
                        const body = solar.bodies[i];
                        rl.drawSphere(
                            .{ .x = body.pos.x, .y = body.pos.y, .z = body.pos.z },
                            body.radius,
                            .{ .r = body.color_r, .g = body.color_g, .b = body.color_b, .a = 255 },
                        );
                    }
                },
                .spring_pendulum => {
                    rl.drawLine3D(
                        .{ .x = spring.anchor.x, .y = spring.anchor.y, .z = spring.anchor.z },
                        .{ .x = spring.ball_pos.x, .y = spring.ball_pos.y, .z = spring.ball_pos.z },
                        .green,
                    );
                    rl.drawSphere(.{ .x = spring.anchor.x, .y = spring.anchor.y, .z = spring.anchor.z }, 0.15, .dark_gray);
                    rl.drawSphere(.{ .x = spring.ball_pos.x, .y = spring.ball_pos.y, .z = spring.ball_pos.z }, spring.ball_radius, .blue);
                },
                .projectile => {
                    rl.drawCube(.{ .x = 0, .y = projectile.ground_y - 0.1, .z = 0 }, 30, 0.2, 10, .dark_gray);
                    rl.drawCube(.{ .x = -5, .y = projectile.ground_y + 0.5, .z = 0 }, 0.5, 1, 0.5, .gray);
                    for (0..20) |i| {
                        if (projectile.projectiles[i].active) {
                            const p = projectile.projectiles[i];
                            rl.drawSphere(.{ .x = p.pos.x, .y = p.pos.y, .z = p.pos.z }, p.radius, .orange);
                        }
                    }
                },
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

        //UI overlay
        panel.draw();
        btn_reset.draw();
        btn_2d.draw();
        btn_3d.draw();
        dropdown_sim.draw();
        slider_gravity.draw();
        slider_speed.draw();

        if (current_3d_sim == .projectile and current_mode == .mode_3d) {
            btn_launch.draw();
        }

        const modeText: [:0]const u8 = if (current_mode == .mode_3d) "Mode: 3D" else "Mode: 2D";
        rl.drawText(modeText, 20, 290, 14, .dark_gray);

        rl.drawFPS(@intFromFloat(currentWidth - 100), 10);
    }
}
