const std = @import("std");
const vec3 = @import("../vec3.zig");
const area_angle = @import("../area_angle.zig");

const Vec3 = vec3.Vec3;
const signed_area = area_angle.signed_area;
const testing = std.testing;
const expectApproxEqAbs = testing.expectApproxEqAbs;
const pi = std.math.pi;

test "angle formula handles a polygon with a pole vertex" {
    // Octant traced CCW from outside: (1,0,0) → (0,1,0) → (0,0,1) → close.
    // Includes a north-pole vertex (lng undefined). area = pi/2.
    const verts = [_]Vec3{
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(0, 0, 1),
    };
    try expectApproxEqAbs(pi / 2.0, signed_area(&verts), 1e-13);
}

test "angle formula orientation flip negates result" {
    const fwd = [_]Vec3{
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(-1, 0, 0),
        .init(0, -1, 0),
    };
    const rev = [_]Vec3{
        .init(0, -1, 0),
        .init(-1, 0, 0),
        .init(0, 1, 0),
        .init(1, 0, 0),
    };
    try expectApproxEqAbs(signed_area(&fwd), -(signed_area(&rev)), 1e-13);
}
