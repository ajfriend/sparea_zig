const std = @import("std");
const vec3 = @import("../vec3.zig");
const area_cross = @import("../area_cross.zig");

const Vec3 = vec3.Vec3;

inline fn triangle_area(a: Vec3, b: Vec3, c: Vec3) f64 {
    return area_cross.triangle_area(f64, a, b, c);
}
const testing = std.testing;
const expectApproxEqAbs = testing.expectApproxEqAbs;
const pi = std.math.pi;

test "octant triangle has area pi/2" {
    const a = Vec3.init(1, 0, 0);
    const b = Vec3.init(0, 1, 0);
    const c = Vec3.init(0, 0, 1);
    try expectApproxEqAbs(pi / 2.0, triangle_area(a, b, c), 1e-14);
}

test "degenerate triangle (repeated vertex) has zero area" {
    const a = Vec3.init(1, 0, 0);
    const b = Vec3.init(0, 1, 0);
    try expectApproxEqAbs(0.0, triangle_area(a, a, b), 1e-14);
}

test "triangle_area: orientation flip negates result" {
    const a = Vec3.init(1, 0, 0);
    const b = Vec3.init(0, 1, 0);
    const c = Vec3.init(0, 0, 1);
    try expectApproxEqAbs(triangle_area(a, b, c), -triangle_area(a, c, b), 1e-14);
}

test "tiny triangle stays well-behaved" {
    const eps: f64 = 1e-8;
    const a = Vec3.init(eps, 0, 1).normalized();
    const b = Vec3.init(-eps / 2.0, eps * 0.8660254037844387, 1).normalized();
    const c = Vec3.init(-eps / 2.0, -eps * 0.8660254037844387, 1).normalized();

    const area = triangle_area(a, b, c);
    const expected_order: f64 = (3.0 * @sqrt(3.0) / 4.0) * eps * eps;
    try testing.expect(area > 0.5 * expected_order);
    try testing.expect(area < 2.0 * expected_order);
    try testing.expect(!std.math.isNan(area));
}
