const std = @import("std");
const day05 = @import("day05");

const print = std.debug.print;
const testing = std.testing;

const INPUT_FILE = "res/input.txt";
const EXAMPLE_FILE = "res/example.txt";

fn read_file(allocator: std.mem.Allocator, comptime filepath: []const u8) ![]const u8 {
    const input_file = try std.fs.cwd().openFile(filepath, .{});
    defer input_file.close();

    const file_stat = try input_file.stat();

    return try input_file.readToEndAlloc(allocator, file_stat.size);
}

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const input = try read_file(alloc, INPUT_FILE);
    defer alloc.free(input);

    const answer1 = try day05.solution(input, .partOne);
    const answer2 = try day05.solution(input, .partTwo);

    print("Answer 1 is {d}\n", .{answer1});
    print("Answer 2 is {d}\n", .{answer2});
}

test "part1" {
    const alloc = testing.allocator;
    const input = try read_file(alloc, EXAMPLE_FILE);
    defer alloc.free(input);

    try testing.expectEqual(4277556, day05.solution(input, .partOne));
}

test "part2" {
    const alloc = testing.allocator;
    const input = try read_file(alloc, EXAMPLE_FILE);
    defer alloc.free(input);

    try testing.expectEqual(3263827, day05.solution(input, .partTwo));
}
