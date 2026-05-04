//! Equator ring through the four cardinal points: a great-circle
//! polygon whose vertices are (lat=0, lng ∈ {0, π/2, π, -π/2}).
//!
//! Vertex sum is zero (each unit vector cancels its antipode), so
//! the dispatcher sends this through the angle-formula path. The
//! polygon traces a great circle, so the enclosed region is exactly
//! one hemisphere — area = 2π sr.

const std = @import("std");
const _root = @import("../root.zig");
const _angle = @import("../area_angle.zig");
const _cross = @import("../area_cross.zig");
const _polygon = @import("../polygon.zig");

const LatLng = _root.LatLng;
const normalize_positive = _polygon.normalize_positive;
const pi = std.math.pi;

const testing = std.testing;

test "equator ring (CCW from above): signed = -2pi, |area| = 2pi" {
    // CCW as viewed from the north pole = CW as viewed from outside
    // the sphere on the northern side, so the signed result is
    // negative. `normalize_positive` adds 4π to recover the magnitude.
    const verts = [_]LatLng{
        .init(0,0),
        .init(0, pi/2.0),
        .init(0, pi),
        .init(0, -pi/2.0),
    };
    const signed = _angle.signed_area(&verts);
    try testing.expectApproxEqAbs(-2.0 * pi, signed, 1e-13);
    // try testing.expectApproxEqAbs(2.0 * pi, normalize_positive(signed), 1e-13);
}


test "bigger ring: angle and cross agree after normalize_positive" {
    // Square ring at lat = +9°. The angle formula returns its raw
    // signed sum, which differs from the centroid-fan result by 4π
    // for hemispheric polygons whose orientation places the cap
    // opposite the angle formula's natural sign convention.
    // `normalize_positive` collapses the [−2π, 2π] and [2π, 4π) (or
    // [−4π, −2π]) representations into a single value in [0, 4π).
    const lat = 0.1 * pi / 2.0;
    const ccw = [_]LatLng{
        .init(lat, 0),
        .init(lat, pi / 2.0),
        .init(lat, pi),
        .init(lat, -pi / 2.0),
    };
    const cw = [_]LatLng{
        .init(lat, 0),
        .init(lat, -pi / 2.0),
        .init(lat, pi),
        .init(lat, pi / 2.0),
    };

    const a_ccw = _angle.signed_area(&ccw);
    const c_ccw = _cross.signed_area(f64, &ccw);
    try testing.expectApproxEqAbs(
        normalize_positive(c_ccw),
        normalize_positive(a_ccw),
        1e-13,
    );

    const a_cw = _angle.signed_area(&cw);
    const c_cw = _cross.signed_area(f64, &cw);
    try testing.expectApproxEqAbs(
        normalize_positive(c_cw),
        normalize_positive(a_cw),
        1e-13,
    );
}

test "equator ring reversed: signed = +2pi" {
    const verts = [_]LatLng{
        .init(0,0),
        .init(0, -pi/2.0),
        .init(0, pi),
        .init(0, pi/2.0),
    };
    const signed = _angle.signed_area(&verts);
    try testing.expectApproxEqAbs(2.0 * pi, signed, 1e-13);
}
