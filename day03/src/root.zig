const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

pub const Part = enum {
    partOne,
    partTwo,
};

fn bankJoltageCalculator(bank: []const u8, comptime batteries: usize) i64 {
    if (bank.len < batteries) return 0;

    var nums: [batteries]u8 = std.mem.zeroes([batteries]u8);
    inline for (0..batteries) |i| nums[i] = bank[i];

    var index: usize = 0;

    // select the biggest from the possible numbers
    for (0..batteries) |i| {
        var big: u8 = bank[index];
        for (index..bank.len - (batteries - 1 - i)) |j| {
            if (bank[j] > big) {
                big = bank[j];
                index = j;
            }
        }
        index += 1;
        nums[i] = big;
    }

    var joltage: i64 = 0;
    var mul: i64 = 1;
    inline for (0..batteries) |i| {
        joltage += mul * charToi64(nums[batteries - 1 - i]);
        mul *= 10;
    }

    return joltage;
}

pub fn solution(input: []const u8, comptime part: Part) !i64 {
    const batteries = switch (part) {
        .partOne => 2,
        .partTwo => 12,
    };
    var total_joltage: i64 = 0;

    var splits = std.mem.splitScalar(u8, input, '\n');
    while (splits.next()) |line| {
        total_joltage += bankJoltageCalculator(line, batteries);
    }

    return total_joltage;
}

fn charToi64(c: u8) i64 {
    return @as(i64, c) - 48;
}

test "charToi64" {
    try std.testing.expectEqual(0, charToi64('0'));
    try std.testing.expectEqual(5, charToi64('5'));
    try std.testing.expectEqual(9, charToi64('9'));
}
