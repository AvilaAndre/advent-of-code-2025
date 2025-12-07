const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const testing = std.testing;

pub const Part = enum {
    partOne,
    partTwo,
};

fn printRanges(ranges: *MyArray([2]usize)) void {
    var it = ranges.iterator();

    while (it.next()) |range| {
        print("{d} - {d}\n", .{ range[0], range[1] });
    }
}

const ParseRangeError = error{
    FailedToFindTwoValues,
    FailedToParseValue,
};

fn parseRange(line: []const u8) ![2]usize {
    var range_split = std.mem.splitScalar(u8, line, '-');

    const start = range_split.next() orelse return error.FailedToFindTwoValues;
    const end = range_split.next() orelse return error.FailedToFindTwoValues;

    const parsed_start = std.fmt.parseInt(usize, start, 10) catch return error.FailedToParseValue;
    const parsed_end = std.fmt.parseInt(usize, end, 10) catch return error.FailedToParseValue;

    return [2]usize{ parsed_start, parsed_end };
}

fn cmpRanges(a: [2]usize, b: [2]usize) bool {
    if (a[0] < b[0]) {
        return true;
    } else if (a[0] == b[0]) {
        return a[1] < b[1];
    } else {
        return false;
    }
}

fn shortenRanges(ranges: *MyArray([2]usize)) !void {
    ranges.quicksort();

    var ranges_it = ranges.iterator();
    const first = ranges_it.next() orelse return;
    var mini = first[0];
    var maxi = first[1];

    var short_ranges = try MyArray([2]usize).init(std.heap.smp_allocator, .{ .cmp = cmpRanges });
    defer short_ranges.deinit();

    while (ranges_it.next()) |range| {
        if (maxi < range[0]) {
            try short_ranges.add([2]usize{ mini, maxi });
            mini = range[0];
            maxi = range[1];
        } else {
            maxi = @max(range[1], maxi);
        }
    }

    try short_ranges.add([2]usize{ mini, maxi });

    try ranges.resize(short_ranges.len);
    ranges.len = short_ranges.len;
    for (0..short_ranges.len) |i| {
        try ranges.set(i, try short_ranges.get(i));
    }
}

fn countFreshIngredientsFromRange(ranges: *MyArray([2]usize)) !i64 {
    var fresh_ingredients: usize = 0;

    try shortenRanges(ranges);

    var ranges_it = ranges.iterator();
    while (ranges_it.next()) |range| {
        fresh_ingredients += range[1] - range[0] + 1;
    }

    return @as(i64, @intCast(fresh_ingredients));
}

fn countFreshIngredientsFromIngredients(
    ranges: *MyArray([2]usize),
    ingredients: *MyArray(usize),
) !i64 {
    var fresh_ingredients: i64 = 0;

    try shortenRanges(ranges);
    ingredients.quicksort();

    var ingredients_it = ingredients.iterator();
    var ranges_it = ranges.iterator();
    var cur_range = ranges_it.next() orelse return 0;

    outer: while (ingredients_it.next()) |ingredient| {
        while (ingredient > cur_range[1]) {
            cur_range = ranges_it.next() orelse break :outer;
        }

        if (ingredient >= cur_range[0] and ingredient <= cur_range[1]) {
            fresh_ingredients += 1;
        }
    }

    return fresh_ingredients;
}

pub fn solution(input: []const u8, comptime part: Part) !i64 {
    const allocator = std.heap.smp_allocator;
    var ranges = try MyArray([2]usize).init(allocator, .{ .cmp = cmpRanges });
    var ingredients = try MyArray(usize).init(allocator, .{});

    var nranges_lookup = true;
    var splits = std.mem.splitScalar(u8, input, '\n');
    while (splits.next()) |line| {
        if (line.len > 0) {
            if (nranges_lookup) {
                const parsed_range = parseRange(line) catch continue;
                try ranges.add(parsed_range);
            } else {
                const parsed_ingredient = std.fmt.parseInt(usize, line, 10) catch continue;
                try ingredients.add(parsed_ingredient);
            }
        } else {
            if (part == .partTwo) break;
            nranges_lookup = false;
        }
    }

    // catching errors to 0 just becuase I'm too lazy to deal with them lol
    return switch (part) {
        .partOne => countFreshIngredientsFromIngredients(&ranges, &ingredients),
        .partTwo => countFreshIngredientsFromRange(&ranges),
    } catch 0;
}

fn is_comparable(T: type) bool {
    return switch (@typeInfo(T)) {
        .int => true,
        .float => true,
        .comptime_float => true,
        .comptime_int => true,
        else => false,
    };
}

fn generic_cmp(T: type) fn (T, T) bool {
    return struct {
        fn cmp(a: T, b: T) bool {
            return a < b;
        }
    }.cmp;
}

fn default_cmp(T: type) fn (T, T) bool {
    return struct {
        fn cmp(_: T, _: T) bool {
            return false;
        }
    }.cmp;
}

fn MyArrayOptions(T: type) type {
    return struct {
        capacity: usize = 128,
        step: usize = 16,
        cmp: *const (fn (a: T, b: T) bool) = if (is_comparable(T))
            &generic_cmp(T)
        else
            &default_cmp(T),
    };
}

fn MyArray(comptime T: type) type {
    return struct {
        len: usize,
        items: []T,
        allocator: std.mem.Allocator,
        step: usize,
        cmp: *const (fn (a: T, b: T) bool),

        const Self = @This();
        const MyArrayErrors = error{IndexOutOfBounds};

        pub fn init(allocator: std.mem.Allocator, comptime options: MyArrayOptions(T)) !Self {
            const capacity = options.capacity;

            return .{
                .len = 0,
                .items = try allocator.alloc(T, capacity),
                .allocator = allocator,
                .step = options.step,
                .cmp = options.cmp,
            };
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.items);
        }

        pub fn resize(self: *Self, target: usize) !void {
            self.items = try self.allocator.realloc(self.items, target);
        }

        pub fn add(self: *Self, new_item: T) !void {
            if (self.items.len == self.len) {
                try self.resize(self.items.len + self.step);
            }
            self.items[self.len] = new_item;
            self.len += 1;
        }

        pub fn extend(self: *Self, new_items: []const T) !void {
            if (self.len + new_items.len <= self.items.len) {
                try self.resize(self.items.len + new_items.len);
            }
            for (new_items) |item| {
                self.items[self.len] = item;
                self.len += 1;
            }
        }

        pub fn get(self: Self, index: usize) !T {
            if (index >= self.len) {
                return error.IndexOutOfBounds;
            }
            return self.items[index];
        }

        pub fn set(self: *Self, index: usize, value: T) !void {
            if (index >= self.len) {
                return error.IndexOutOfBounds;
            }
            self.items[index] = value;
        }

        pub fn sort(self: *Self) !void {
            try self.resize(self.len);

            std.mem.sort(T, self.items, {}, struct {
                fn cmp(_: void, a: [2]usize, b: [2]usize) bool {
                    return cmpRanges(a, b);
                }
            }.cmp);
        }

        pub fn quicksort(self: *Self) void {
            if (self.len < 2) return;

            _quicksort_partition(self, 0, self.len - 1);
        }

        fn _quicksort_partition(self: *Self, low: usize, high: usize) void {
            if (high == low) return;
            if (high - low == 1) {
                if (self.cmp(self.items[high], self.items[low])) {
                    self.swp(low, high);
                }
                return;
            }

            const pivot = @divFloor(high - low, 2) + low;
            self.swp(pivot, high);

            var le: usize = 0;
            var ri: usize = high - 1;

            while (ri > le) {
                while (ri > le and self.cmp(self.items[le], self.items[high])) {
                    le += 1;
                }
                while (ri > le and self.cmp(self.items[high], self.items[ri])) {
                    ri -= 1;
                }

                self.swp(le, ri);
            }

            if (self.cmp(self.items[high], self.items[ri])) {
                self.swp(ri, high);
            }

            if (le > 0 and low < le) {
                _quicksort_partition(self, low, le);
            }
            if (ri < high) {
                _quicksort_partition(self, ri, high);
            }
        }

        fn swp(self: *Self, first: usize, second: usize) void {
            assert(first >= 0 and first < self.len and second >= 0 and second < self.len);
            if (first == second) return;

            const tmp = self.items[first];
            self.items[first] = self.items[second];
            self.items[second] = tmp;
        }

        const MyArrayIterator = struct {
            array: Self,
            index: usize,

            pub fn next(it: *MyArrayIterator) ?T {
                if (it.index == it.array.len) {
                    return null;
                }
                it.index += 1;
                return it.array.items[it.index - 1];
            }

            pub fn peek(it: *MyArrayIterator) ?T {
                if (it.index == it.array.len) {
                    return null;
                }
                return it.array.items[it.index];
            }

            pub fn reset(it: *MyArrayIterator) void {
                it.index = 0;
            }
        };

        pub fn iterator(self: Self) MyArrayIterator {
            return .{
                .array = self,
                .index = 0,
            };
        }
    };
}

test "MyArrayInit" {
    const array = try MyArray(i64).init(testing.allocator, .{});
    defer array.deinit();
    try testing.expectEqual(0, array.len);
}

test "MyArrayAdd" {
    var array = try MyArray(i64).init(testing.allocator, .{});
    defer array.deinit();
    try array.add(5);
    try testing.expectEqual(1, array.len);
}

test "MyArrayAddRequireAllocate" {
    var array = try MyArray(usize).init(testing.allocator, .{});
    defer array.deinit();

    for (0..20) |i| {
        try array.add(i);
    }

    try testing.expectEqual(20, array.len);

    for (0..20) |i| {
        try testing.expectEqual(i, try array.get(i));
    }
}

test "MyArrayInvalidSet" {
    var array = try MyArray(i64).init(testing.allocator, .{});
    defer array.deinit();
    try testing.expectError(MyArray(i64).MyArrayErrors.IndexOutOfBounds, array.set(0, 5));
}

test "MyArrayInvalidGet" {
    const array = try MyArray(i64).init(testing.allocator, .{});
    defer array.deinit();
    try testing.expectError(MyArray(i64).MyArrayErrors.IndexOutOfBounds, array.get(0));
}

test "MyArraySet" {
    var array = try MyArray(i64).init(testing.allocator, .{});
    defer array.deinit();

    try array.add(1);
    const val: i64 = 4;
    try array.set(0, val);
    try testing.expectEqual(val, try array.get(0));
}

test "MyArraySwap" {
    var array = try MyArray(i64).init(testing.allocator, .{});
    defer array.deinit();

    const first = 1;
    const second = 2;

    try array.add(first);
    try array.add(second);

    try testing.expectEqual(first, try array.get(0));
    try testing.expectEqual(second, try array.get(1));

    array.swp(0, 1);

    try testing.expectEqual(first, try array.get(1));
    try testing.expectEqual(second, try array.get(0));
}

test "MyArray_extend" {
    var array = try MyArray(i64).init(testing.allocator, .{});
    defer array.deinit();

    const to_extend = [9]i64{ -1, -10, 6, 2, 5, 7, 5, 9, 0 };

    try array.extend(&to_extend);

    for (0..to_extend.len) |i| {
        try testing.expectEqual(to_extend[i], try array.get(i));
    }
}

test "MyArray_quicksort" {
    var array = try MyArray(i64).init(testing.allocator, .{});
    defer array.deinit();

    const arr = [9]i64{ -1, -10, 6, 2, 5, 7, 5, 9, 0 };
    try array.extend(&arr);
    const sorted_arr = [9]i64{ -10, -1, 0, 2, 5, 5, 6, 7, 9 };

    array.quicksort();

    try testing.expectEqualSlices(i64, &sorted_arr, array.items[0..array.len]);
}

test "MyArray_quicksort_from_input" {
    const alloc = std.heap.smp_allocator;

    const input_file = try std.fs.cwd().openFile("res/input.txt", .{});
    defer input_file.close();
    const file_stat = try input_file.stat();
    const input = try input_file.readToEndAlloc(alloc, file_stat.size);

    var rangesQuicksort = try MyArray([2]usize).init(alloc, .{ .cmp = cmpRanges });
    var rangesSort = try MyArray([2]usize).init(alloc, .{ .cmp = cmpRanges });

    var splits = std.mem.splitScalar(u8, input, '\n');

    while (splits.next()) |line| {
        if (line.len > 0) {
            const parsed_range = parseRange(line) catch continue;
            try rangesQuicksort.add(parsed_range);
            try rangesSort.add(parsed_range);
        } else {
            break;
        }
    }

    rangesQuicksort.quicksort();
    try rangesQuicksort.resize(rangesQuicksort.len);
    try rangesSort.sort();

    try testing.expectEqualSlices([2]usize, rangesSort.items, rangesQuicksort.items);
}

test "parseRange" {
    try testing.expectEqual([2]usize{ 10, 4 }, parseRange("10-4"));
}

test "parseRangeFail1" {
    try testing.expectError(ParseRangeError.FailedToParseValue, parseRange("a-4"));
    try testing.expectError(ParseRangeError.FailedToParseValue, parseRange("10 -4"));
}

test "parseRangeFail2" {
    try testing.expectError(ParseRangeError.FailedToParseValue, parseRange("10-a"));
    try testing.expectError(ParseRangeError.FailedToParseValue, parseRange("10- 4"));
}

test "parseRangeFailTwoValues" {
    try testing.expectError(ParseRangeError.FailedToFindTwoValues, parseRange("104"));
}
