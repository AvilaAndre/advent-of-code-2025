const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

pub const Part = enum {
    partOne,
    partTwo,
};

pub fn part1_validator(num: i64) bool {
    var numStr = std.mem.zeroes([19]u8);
    const len = parsei64ToStr(&numStr, num);

    if (len % 2 != 0) return true;

    const half = len / 2;
    for (0..half) |i| {
        // NOTE: does not consider odd lengths
        if (numStr[i] != numStr[i + half]) return true;
    }
    return false;
}

pub fn part2_validator(num: i64) bool {
    var numStr = std.mem.zeroes([19]u8);
    const len = parsei64ToStr(&numStr, num);

    const half = len / 2;

    outer: for (1..half + 1) |groupsize| {
        if (@mod(len, groupsize) != 0) continue;

        const checks = len / groupsize;

        for (1..checks) |j| {
            for (0..groupsize) |k| {
                if (numStr[k] != numStr[j * groupsize + k]) {
                    continue :outer;
                }
            }
        }

        return false;
    }

    return true;
}

fn explore_range(left: i64, right: i64, comptime validator: anytype) i64 {
    assert(left < right);

    var res: i64 = 0;
    var num = left;

    while (num <= right) {
        if (!validator(num)) {
            res += num;
        }
        num += 1;
    }

    return res;
}

pub fn solution(input: []const u8, comptime part: Part) !i64 {
    const validator = switch (part) {
        .partOne => part1_validator,
        .partTwo => part2_validator,
    };

    var str1 = std.mem.zeroes([19]u8);
    var str2 = std.mem.zeroes([19]u8);

    var res: i64 = 0;

    var i: usize = 0;
    var j: usize = 0;
    var first = true;

    for (input) |c| {
        switch (c) {
            '0'...'9' => {
                if (first) {
                    str1[i] = c - 48;
                    i += 1;
                } else {
                    str2[j] = c - 48;
                    j += 1;
                }
            },
            '-' => first = false,
            ',' => {
                const left: i64 = parseStrToi64(str1, i);
                const right: i64 = parseStrToi64(str2, j);
                i = 0;
                j = 0;
                first = true;

                res += explore_range(left, right, validator);
            },
            else => {
                std.process.exit(1);
            },
        }
    }

    const left: i64 = parseStrToi64(str1, i);
    const right: i64 = parseStrToi64(str2, j);

    res += explore_range(left, right, validator);

    return res;
}

fn parseStrToi64(arr: [19]u8, len: usize) i64 {
    assert(len < 19);
    var num: i64 = 0;
    var mul: i64 = 1;

    for (0..len) |i| {
        num += arr[len - i - 1] * mul;
        mul = mul * 10;
    }

    return num;
}

test "parseStrToi64_0" {
    const num = std.mem.zeroes([19]u8);

    try std.testing.expectEqual(0, parseStrToi64(num, 18));
}

test "parseStrToi64_9898" {
    var num = std.mem.zeroes([19]u8);
    num[0] = 9;
    num[1] = 8;
    num[2] = 9;
    num[3] = 8;

    try std.testing.expectEqual(9898, parseStrToi64(num, 4));
}

fn parsei64ToStr(arr: *[19]u8, num: i64) usize {
    var len: usize = 0;

    var rem = num;

    var stop = false;

    while (!stop) {
        if (rem < 10) stop = true;
        const remmod = @mod(rem, 10);
        rem = @divTrunc(rem - remmod, 10);

        arr[len] = @as(u8, @intCast(remmod)) + 48;
        len += 1;
    }

    for (0..len / 2) |i| {
        const temp = arr[i];
        arr[i] = arr[len - i - 1];
        arr[len - i - 1] = temp;
    }

    return len;
}

test "parsei64ToStr_1" {
    var num = std.mem.zeroes([19]u8);

    const len = parsei64ToStr(&num, 54321);
    try std.testing.expectEqual(5, len);
    try std.testing.expectEqualStrings("54321", num[0..5]);
}

test "parsei64ToStr_2" {
    var num = std.mem.zeroes([19]u8);

    const len = parsei64ToStr(&num, 1);
    try std.testing.expectEqual(1, len);
    try std.testing.expectEqualStrings("1", num[0..1]);
}

test "part1_validator" {
    try std.testing.expectEqual(false, part1_validator(22));
    try std.testing.expectEqual(false, part1_validator(5252));
    try std.testing.expectEqual(false, part1_validator(9999));
}

test "part2_validator" {
    try std.testing.expectEqual(false, part2_validator(22));
    try std.testing.expectEqual(false, part2_validator(111));
    try std.testing.expectEqual(false, part2_validator(5252));
    try std.testing.expectEqual(false, part2_validator(9999));
}
