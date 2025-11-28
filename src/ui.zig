const rl = @import("raylib");

pub const Button = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    text: [:0]const u8,
    is_hovered: bool = false,
    is_pressed: bool = false,

    pub fn init(x: f32, y: f32, width: f32, height: f32, text: [:0]const u8) Button {
        return Button{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
            .text = text,
        };
    }

    pub fn update(self: *Button) bool {
        const mouse = rl.getMousePosition();
        self.is_hovered = mouse.x >= self.x and
            mouse.x <= self.x + self.width and
            mouse.y >= self.y and
            mouse.y <= self.y + self.height;

        self.is_pressed = self.is_hovered and rl.isMouseButtonPressed(.left);
        return self.is_pressed;
    }

    pub fn draw(self: Button) void {
        const color: rl.Color = if (self.is_hovered) .light_gray else .gray;
        rl.drawRectangle(
            @intFromFloat(self.x),
            @intFromFloat(self.y),
            @intFromFloat(self.width),
            @intFromFloat(self.height),
            color,
        );
        rl.drawRectangleLines(
            @intFromFloat(self.x),
            @intFromFloat(self.y),
            @intFromFloat(self.width),
            @intFromFloat(self.height),
            .dark_gray,
        );

        const text_width = rl.measureText(self.text, 16);
        rl.drawText(
            self.text,
            @intFromFloat(self.x + (self.width - @as(f32, @floatFromInt(text_width))) / 2),
            @intFromFloat(self.y + (self.height - 16) / 2),
            16,
            .black,
        );
    }
};

pub const Slider = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    min_val: f32,
    max_val: f32,
    value: f32,
    label: [:0]const u8,
    is_dragging: bool = false,

    pub fn init(x: f32, y: f32, width: f32, label: [:0]const u8, min_val: f32, max_val: f32, default: f32) Slider {
        return Slider{
            .x = x,
            .y = y,
            .width = width,
            .height = 20,
            .min_val = min_val,
            .max_val = max_val,
            .value = default,
            .label = label,
        };
    }

    pub fn update(self: *Slider) void {
        const mouse = rl.getMousePosition();
        const in_bounds = mouse.x >= self.x and
            mouse.x <= self.x + self.width and
            mouse.y >= self.y and
            mouse.y <= self.y + self.height;

        if (in_bounds and rl.isMouseButtonPressed(.left)) {
            self.is_dragging = true;
        }
        if (rl.isMouseButtonReleased(.left)) {
            self.is_dragging = false;
        }

        if (self.is_dragging) {
            const t = (mouse.x - self.x) / self.width;
            const clamped = @max(0.0, @min(1.0, t));
            self.value = self.min_val + clamped * (self.max_val - self.min_val);
        }
    }

    pub fn draw(self: Slider) void {
        //track
        rl.drawRectangle(
            @intFromFloat(self.x),
            @intFromFloat(self.y + 8),
            @intFromFloat(self.width),
            4,
            .gray,
        );

        //knob position
        const t = (self.value - self.min_val) / (self.max_val - self.min_val);
        const knob_x = self.x + t * self.width;

        rl.drawCircle(@intFromFloat(knob_x), @intFromFloat(self.y + 10), 8, .dark_gray);

        //label
        rl.drawText(self.label, @intFromFloat(self.x), @intFromFloat(self.y - 18), 14, .black);
    }
};

pub const Panel = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    title: [:0]const u8,

    pub fn draw(self: Panel) void {
        rl.drawRectangle(
            @intFromFloat(self.x),
            @intFromFloat(self.y),
            @intFromFloat(self.width),
            @intFromFloat(self.height),
            .{ .r = 240, .g = 240, .b = 240, .a = 230 },
        );
        rl.drawRectangleLines(
            @intFromFloat(self.x),
            @intFromFloat(self.y),
            @intFromFloat(self.width),
            @intFromFloat(self.height),
            .dark_gray,
        );
        rl.drawText(self.title, @intFromFloat(self.x + 10), @intFromFloat(self.y + 5), 18, .black);
    }

    pub fn contains(self: Panel, x: f32, y: f32) bool {
        return x >= self.x and x <= self.x + self.width and
            y >= self.y and y <= self.y + self.height;
    }
};