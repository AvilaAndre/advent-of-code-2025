const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const testing = std.testing;

pub const Part = enum {
    partOne,
    partTwo,
};

fn get_accessible_rolls(grid: Grid, comptime remove_rolls: bool) !i64 {
    var accessible_rolls: i64 = 0;
    for (0..grid.rows) |r| {
        for (0..grid.cols) |c| {
            if (try grid.at(r, c) != '@') continue;
            var neighbour_rolls: i64 = 0;

            for (0..9) |offset| {
                const r_offset = @mod(offset, 3);
                const c_offset = @divFloor(offset, 3);

                if (r_offset == c_offset and r_offset == 1) continue;
                if (r + r_offset < 1 or c + c_offset < 1) continue;

                const val = grid.at(r + r_offset - 1, c + c_offset - 1) catch continue;
                if (val == '@' or val == 'x') neighbour_rolls += 1;
            }

            if (neighbour_rolls < 4) {
                accessible_rolls += 1;
                if (remove_rolls) {
                    try grid.set(r, c, 'x');
                }
            }
        }
    }

    if (remove_rolls) {
        for (0..grid.rows) |r| {
            for (0..grid.cols) |c| {
                const val = try grid.at(r, c);
                if (val == 'x') try grid.set(r, c, '.');
            }
        }
    }

    return accessible_rolls;
}

pub fn solution(input: []const u8, comptime part: Part) !i64 {
    var splits = std.mem.splitScalar(u8, input, '\n');

    var lines: usize = 0;
    const width = splits.peek().?.len;

    while (splits.next()) |line| {
        if (line.len > 0) lines += 1;
    }

    const grid = try Grid.create(lines, width);
    defer grid.free();

    splits.reset();

    for (0..grid.rows) |i| {
        const line = splits.next().?;
        try grid.populateRow(i, line);
    }

    const accessible_rolls: i64 = switch (part) {
        .partOne => try get_accessible_rolls(grid, false),
        .partTwo => |_| total: {
            var total_rolls: i64 = 0;

            while (get_accessible_rolls(grid, true) catch null) |rolls| {
                if (rolls == 0) break :total total_rolls;
                total_rolls += rolls;
            }

            break :total total_rolls;
        },
    };

    return accessible_rolls;
}

fn charToi64(c: u8) i64 {
    return @as(i64, c) - 48;
}

test "charToi64" {
    try testing.expectEqual(0, charToi64('0'));
    try testing.expectEqual(5, charToi64('5'));
    try testing.expectEqual(9, charToi64('9'));
}

const Grid = struct {
    items: [][]u8,
    allocator: std.mem.Allocator,
    rows: usize,
    cols: usize,

    const GridError = error{
        OutOfBoundsAccess,
        WrongSizedRow,
    };

    fn create_with_default(rows: usize, cols: usize, default_val: u8) !Grid {
        const allocator = std.heap.smp_allocator;

        var grid = try allocator.alloc([]u8, rows);

        for (0..rows) |i| {
            const row = try allocator.alloc(u8, cols);
            for (0..cols) |j| {
                row[j] = default_val;
            }
            grid[i] = row;
        }

        return .{
            .allocator = allocator,
            .items = grid,
            .rows = rows,
            .cols = cols,
        };
    }

    fn create(rows: usize, cols: usize) !Grid {
        return create_with_default(rows, cols, 0);
    }

    fn free(self: *const Grid) void {
        for (0..self.rows) |i| {
            self.allocator.free(self.items[i]);
        }
        self.allocator.free(self.items);
    }

    fn inBounds(self: *const Grid, row: usize, col: usize) bool {
        return row >= 0 and row < self.rows and col >= 0 and col < self.cols;
    }

    fn at(self: *const Grid, row: usize, col: usize) GridError!u8 {
        if (!self.inBounds(row, col)) return error.OutOfBoundsAccess;

        return self.items[row][col];
    }

    fn set(self: *const Grid, row: usize, col: usize, value: u8) GridError!void {
        if (!self.inBounds(row, col)) return error.OutOfBoundsAccess;

        self.items[row][col] = value;
    }

    fn populateRow(self: *const Grid, row: usize, value: []const u8) GridError!void {
        if (row < 0 or row >= self.rows) {
            return error.OutOfBoundsAccess;
        }

        const rowLen = @max(value.len, self.cols);
        for (0..rowLen) |i| {
            self.items[row][i] = value[i];
        }
    }

    fn debugPrint(self: *const Grid) void {
        for (0..self.rows) |i| {
            print("{s}\n", .{self.items[i]});
        }
    }
};

test "Grid_create" {
    var grid = try Grid.create(6, 100);
    try testing.expectEqual(0, try grid.at(0, 6));
    defer grid.free();
}

test "Grid_create_with_default" {
    var grid = try Grid.create_with_default(6, 100, '0');
    try testing.expectEqual('0', try grid.at(0, 6));
    defer grid.free();
}

test "Grid_set_get" {
    var grid = try Grid.create(6, 100);
    try grid.set(0, 6, 9);
    try testing.expectEqual(9, try grid.at(0, 6));
    defer grid.free();
}

test "Grid_setOutOfBounds" {
    var grid = try Grid.create(6, 100);
    try testing.expectError(Grid.GridError.OutOfBoundsAccess, grid.set(10, 6, 9));
    defer grid.free();
}

test "Grid_getOutOfBounds" {
    var grid = try Grid.create(6, 100);
    try testing.expectError(Grid.GridError.OutOfBoundsAccess, grid.at(10, 6));
    defer grid.free();
}
