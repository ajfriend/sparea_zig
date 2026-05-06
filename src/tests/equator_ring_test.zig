//! Equator ring through the four cardinal points: a great-circle
//! polygon whose vertices are (lat=0, lng ∈ {0, π/2, π, -π/2}).
//!
//! Vertex sum is zero (each unit vector cancels its antipode), so
//! the dispatcher sends this through the angle-formula path. The
//! polygon traces a great circle, so the enclosed region is exactly
//! one hemisphere — area = 2π sr.

const std = @import("std");
const _vec3 = @import("../vec3.zig");
const _angle = @import("../area_angle.zig");
const _cross = @import("../area_cross.zig");
const _area = @import("../area.zig");

const Vec3 = _vec3.Vec3;
const normalize_positive = _area.normalize_positive;
const pi = std.math.pi;

const testing = std.testing;

test "equator ring (CCW from above): signed = -2pi, |area| = 2pi" {
    // CCW as viewed from the north pole = CW as viewed from outside
    // the sphere on the northern side, so the signed result is
    // negative. `normalize_positive` adds 4π to recover the magnitude.
    const verts = [_]Vec3{
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(-1, 0, 0),
        .init(0, -1, 0),
    };
    const signed = _angle.signed_area(&verts);
    try testing.expectApproxEqAbs(-2.0 * pi, signed, 1e-13);
}

test "bigger ring: angle and cross agree after normalize_positive" {
    // Square ring at lat = +9°. The angle formula returns its raw
    // signed sum, which differs from the centroid-fan result by 4π
    // for hemispheric polygons whose orientation places the cap
    // opposite the angle formula's natural sign convention.
    // `normalize_positive` collapses the [−2π, 2π] and [2π, 4π) (or
    // [−4π, −2π]) representations into a single value in [0, 4π).
    const lat = 0.1 * pi / 2.0;
    const cl = @cos(lat);
    const sl = @sin(lat);
    const ccw = [_]Vec3{
        .init(cl, 0, sl),
        .init(0, cl, sl),
        .init(-cl, 0, sl),
        .init(0, -cl, sl),
    };
    const cw = [_]Vec3{
        .init(cl, 0, sl),
        .init(0, -cl, sl),
        .init(-cl, 0, sl),
        .init(0, cl, sl),
    };

    const a_ccw = _angle.signed_area(&ccw);
    const c_ccw = _cross.signed_area(&ccw);
    try testing.expectApproxEqAbs(
        normalize_positive(c_ccw),
        normalize_positive(a_ccw),
        1e-13,
    );

    const a_cw = _angle.signed_area(&cw);
    const c_cw = _cross.signed_area(&cw);
    try testing.expectApproxEqAbs(
        normalize_positive(c_cw),
        normalize_positive(a_cw),
        1e-13,
    );
}

test "equator ring reversed: signed = +2pi" {
    const verts = [_]Vec3{
        .init(1, 0, 0),
        .init(0, -1, 0),
        .init(-1, 0, 0),
        .init(0, 1, 0),
    };
    const signed = _angle.signed_area(&verts);
    try testing.expectApproxEqAbs(2.0 * pi, signed, 1e-13);
}
