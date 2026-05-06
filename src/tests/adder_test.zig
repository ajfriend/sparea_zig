const std = @import("std");
const adder = @import("../adder.zig");

const Adder = adder.Adder;
const testing = std.testing;

test "Adder recovers cancelled small term" {
    var s = Adder.init();
    s.add(1.0e16);
    s.add(1.0);
    s.add(-1.0e16);
    try testing.expectEqual(@as(f64, 1.0), s.value());
}

test "Adder of many 0.1s is exact to high precision" {
    var s = Adder.init();
    var i: usize = 0;
    while (i < 10_000) : (i += 1) s.add(0.1);
    try testing.expectApproxEqAbs(1000.0, s.value(), 1e-12);
}

test "Adder on empty input is zero" {
    const s = Adder.init();
    try testing.expectEqual(@as(f64, 0.0), s.value());
}
