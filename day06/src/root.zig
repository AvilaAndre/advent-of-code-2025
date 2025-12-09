const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const testing = std.testing;

pub const Part = enum {
    partOne,
    partTwo,
};

const Operator = enum {
    add,
    mul,
};

const OperatorWithIdx = struct {
    op: Operator,
    idx: usize,
};

fn SimpleArray(T: type) type {
    return struct {
        items: []T,
        length: usize,
        allocator: std.mem.Allocator,

        const Self = @This();
        pub fn init(allocator: std.mem.Allocator, capacity: usize) !Self {
            return .{
                .items = try allocator.alloc(T, capacity),
                .length = 0,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.items);
        }

        pub fn add(self: *Self, value: T) !void {
            if (self.length == self.items.len) {
                self.items = try self.allocator.realloc(self.items, self.items.len + 16);
            }

            self.items[self.length] = value;
            self.length += 1;
        }
    };
}

fn extract_operators_from_line(
    allocator: std.mem.Allocator,
    row: []const u8,
) !SimpleArray(OperatorWithIdx) {
    var operators = try SimpleArray(OperatorWithIdx).init(allocator, 16);

    for (0..row.len) |i| {
        if (row[i] == ' ') {
            continue;
        }

        try operators.add(.{
            .idx = i,
            .op = if (row[i] == '+') .add else .mul,
        });
    }

    return operators;
}

fn answerPartTwo(input: []const u8) !i64 {
    const allocator = std.heap.smp_allocator;

    var backward_splits = std.mem.splitBackwardsScalar(u8, input, '\n');
    var forward_splits = std.mem.splitScalar(u8, input, '\n');

    _ = backward_splits.next();
    var operators: SimpleArray(OperatorWithIdx) = try extract_operators_from_line(
        allocator,
        backward_splits.next().?,
    );
    defer operators.deinit();

    var arr = try SimpleArray(i64).init(allocator, 16);
    defer arr.deinit();

    var line_idx: usize = 0;
    while (forward_splits.next()) |line| {
        if (line[0] == '*' or line[0] == '+') {
            break;
        }

        var actual_i: usize = 0;
        var next_op_idx: usize = 0;
        var next_op: ?OperatorWithIdx = operators.items[0];
        for (0..line.len) |i| {
            if (next_op != null) {
                if (next_op.?.idx == i) {
                    next_op_idx += 1;
                    if (next_op_idx == operators.length) {
                        next_op = null;
                    } else {
                        next_op = operators.items[next_op_idx];
                    }
                } else if (next_op.?.idx - 1 == i) {
                    continue;
                }
            }

            if (line_idx == 0) {
                if (line[i] == ' ') {
                    try arr.add(0);
                } else {
                    try arr.add(line[i] - '0');
                }
            } else {
                if (line[i] != ' ') {
                    const parsed_num: i64 = @as(i64, @intCast(line[i] - '0'));
                    arr.items[actual_i] = arr.items[actual_i] * 10 + parsed_num;
                }
            }
            actual_i += 1;
        }

        line_idx += 1;
    }

    var total: i64 = 0;
    var cur_idx: usize = 0;
    for (0..operators.length) |i| {
        const op = operators.items[i];
        var st = cur_idx;
        var fi = arr.length;

        // if there are still operators to iterate
        // get the next one and use it as diff
        if (i != operators.length - 1) {
            st = op.idx;
            fi = operators.items[i+1].idx - 1;
        }

        const diff: usize = fi - st;

        var val: i64 = switch (op.op) {
            .add => 0,
            .mul => 1,
        };
        for (0..diff) |j| {
            assert(j < arr.length);
            val = switch (op.op) {
                .add => val + arr.items[cur_idx + j],
                .mul => val * arr.items[cur_idx + j],
            };
        }

        total += val;
        cur_idx += diff;
    }

    return total;
}

fn answerPartOne(input: []const u8) !i64 {
    const allocator = std.heap.smp_allocator;

    var splits = std.mem.splitBackwardsScalar(u8, input, '\n');
    _ = splits.next();
    const first_row = splits.next() orelse return 0;

    const operators = try extract_operators_from_line(allocator, first_row);
    defer operators.deinit();

    var nums = try allocator.alloc(i64, operators.length);
    defer allocator.free(nums);

    for (0..operators.length) |i| {
        nums[i] = switch (operators.items[i].op) {
            .add => 0,
            .mul => 1,
        };
    }

    while (splits.next()) |row| {
        var row_split = std.mem.splitScalar(u8, row, ' ');
        var i: usize = 0;
        while (row_split.next()) |line| {
            if (line.len == 0) continue;

            const parsed_num = try std.fmt.parseInt(i64, line, 10);

            nums[i] = switch (operators.items[i].op) {
                .add => nums[i] + parsed_num,
                .mul => nums[i] * parsed_num,
            };
            i += 1;
        }
    }

    var res: i64 = 0;
    for (0..operators.length) |i| {
        res += nums[i];
    }

    return res;
}

pub fn solution(input: []const u8, comptime part: Part) !i64 {
    return switch (part) {
        .partOne => answerPartOne(input),
        .partTwo => answerPartTwo(input),
    };
}
