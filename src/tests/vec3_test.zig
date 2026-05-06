const std = @import("std");
const vec3 = @import("../vec3.zig");

const Vec3 = vec3.Vec3;
const testing = std.testing;

test "Vec3 dot and cross on basis vectors" {
    const ex = Vec3.init(1, 0, 0);
    const ey = Vec3.init(0, 1, 0);
    const ez = Vec3.init(0, 0, 1);

    try testing.expectEqual(@as(f64, 1.0), ex.dot(ex));
    try testing.expectEqual(@as(f64, 0.0), ex.dot(ey));

    const cxy = ex.cross(ey);
    try testing.expectEqual(ez.x, cxy.x);
    try testing.expectEqual(ez.y, cxy.y);
    try testing.expectEqual(ez.z, cxy.z);
}

test "diff_of_products agrees with naive on well-separated operands" {
    const got = vec3.diff_of_products(3.0, 5.0, 2.0, 7.0); // 15 - 14 = 1
    try testing.expectEqual(@as(f64, 1.0), got);
}

test "Vec3.norm" {
    try testing.expectEqual(@as(f64, 0.0), Vec3.init(0, 0, 0).norm());
    try testing.expectEqual(@as(f64, 1.0), Vec3.init(1, 0, 0).norm());
    try testing.expectEqual(@as(f64, 5.0), Vec3.init(3, 0, 4).norm());
}

test "Vec3.normalized" {
    const v = Vec3.init(3, 0, 4).normalized();
    try testing.expectApproxEqAbs(0.6, v.x, 1e-15);
    try testing.expectApproxEqAbs(0.0, v.y, 1e-15);
    try testing.expectApproxEqAbs(0.8, v.z, 1e-15);
    try testing.expectApproxEqAbs(1.0, v.norm(), 1e-15);
}

test "Vec3.normalized of (0,0,0) returns (0,0,0)" {
    const z = Vec3.init(0, 0, 0).normalized();
    try testing.expectEqual(@as(f64, 0.0), z.x);
    try testing.expectEqual(@as(f64, 0.0), z.y);
    try testing.expectEqual(@as(f64, 0.0), z.z);
}

