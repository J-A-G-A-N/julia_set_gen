const std = @import("std");
const stdout = std.io.getStdOut().writer();
const cwd = std.fs.cwd();
const max_iter: u8 = 255;
const julia_type = std.math.Complex(f32);
const screenwidth: usize = 800;
const screenheight: usize = 600;
const inv_width = 1.0 / @as(f32, @floatFromInt(screenwidth));
const inv_height = 1.0 / @as(f32, @floatFromInt(screenheight));

pub fn main() !void {
    const buf_len: usize = screenwidth * screenheight;
    try cwd.makePath("frames");
    var juila_arr: [buf_len]u8 = undefined;
    const juila_buf = juila_arr[0..];
    var image_arr: [buf_len][3]u8 = undefined;
    const image_buf = image_arr[0..];
    const fps: usize = 60;
    const seconds: usize = 30;
    const total_seconds: usize = seconds * fps;
    var i: usize = 0;
    var time: f32 = 0;
    const dt: f32 = 1.0 / @as(f32, @floatFromInt(fps));

    var path_buf_arr: [1024]u8 = undefined;
    const path_buf = path_buf_arr[0..];
    const start_time = @as(u64, @intCast(std.time.nanoTimestamp()));

    while (i < total_seconds) : (i += 1) {
        const c = julia_type.init(
            @cos(time),
            @sin(time),
        );
        calculateJulia(juila_buf, screenwidth, screenheight, c, max_iter, 2.0);
        time += dt;
        var idx: usize = 0;
        while (idx < buf_len) : (idx += 1) {
            const r = juila_buf[idx];
            const g = juila_buf[idx];
            const b = juila_buf[idx];
            image_buf[idx] = .{ r, g, b };
        }
        const path = try std.fmt.bufPrint(path_buf, "frames/frame_{d:0>4}.ppm", .{i});
        try writePPm6(path, image_buf, screenwidth, screenheight);
        try printProgressBar(i, total_seconds, start_time);
    }
}
fn printProgressBar(current: usize, total: usize, start_time: u64) !void {
    const bar_width = 40;

    const now = std.time.nanoTimestamp();
    const elapsed_ns = now - start_time;
    const elapsed_sec = @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000_000.0;

    const percent = (current * 100) / total;
    const filled = (current * bar_width) / total;

    const speed = if (elapsed_sec > 0.0) @as(f64, @floatFromInt(current)) / elapsed_sec else 0.0;
    const remaining = if (current > 0 and speed > 0.0)
        @as(f64, @floatFromInt(total - current)) / speed
    else
        0.0;

    try stdout.print("\r[", .{});
    var j: usize = 0;
    while (j < bar_width) : (j += 1) {
        if (j < filled) {
            try stdout.print("=", .{});
        } else if (j == filled) {
            try stdout.print(">", .{});
        } else {
            try stdout.print(" ", .{});
        }
    }
    try stdout.print("] {d:>3}% | {d:.2} s elapsed | ETA: {d:.2} s | {d:.2} it/s", .{
        percent,
        elapsed_sec,
        remaining,
        speed,
    });
}

fn writePPm6(file_name: []const u8, buf: []const [3]u8, width: usize, height: usize) !void {
    const file = try cwd.createFile(file_name, .{ .truncate = true });
    defer file.close();
    const writer = file.writer();

    // Write File Header
    try writer.print("P6\n{} {}\n{}\n", .{ width, height, max_iter });
    for (buf) |pixel| {
        try writer.writeAll(&pixel);
    }
}

fn calculateJulia(buf: []u8, width: usize, height: usize, c: julia_type, max_iterations: usize, max_value: f32) void {
    for (0..height) |y| {
        for (0..width) |x| {
            const index = y * width + x;
            const julia_iterations = calculateJuliaAtIndex(x, y, width, height, c, max_iterations, max_value);
            buf[index] = julia_iterations;
        }
    }
}
fn calculateJuliaAtIndex(x: usize, y: usize, width: usize, height: usize, c: julia_type, max_iterations: usize, max_val: f32) u8 {
    const aspect = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
    const real = 2.0 * (@as(f32, @floatFromInt(x)) * inv_width - 0.5) * aspect;
    const img = 2.0 * (@as(f32, @floatFromInt(y)) * inv_height - 0.5);

    var z = std.math.Complex(f32).init(real, img);
    var i: usize = 0;
    while (z.magnitude() < max_val and i < max_iterations) : (i += 1) {
        z = z.mul(z).add(c);
    }
    return @intCast(i);
}
