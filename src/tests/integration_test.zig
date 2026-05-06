//! Integration tests for the public dispatch / validation API in root.zig.

const std = @import("std");
const sa = @import("../root.zig");
const polygon = @import("../polygon.zig");
const area_cross = @import("../area_cross.zig");
const area_angle = @import("../area_angle.zig");
const helpers = @import("helpers.zig");

const Vec3 = sa.Vec3;
const LatLng = sa.LatLng;
const polygon_area = sa.polygon_area;
const angle_area = area_angle.signed_area;

const cross_area = area_cross.signed_area;
const triangle_area = area_cross.triangle_area;
const normalize_positive = polygon.normalize_positive;

const testing = std.testing;
const expectApproxEqAbs = testing.expectApproxEqAbs;
const pi = std.math.pi;

const random_unit_vec3 = helpers.random_unit_vec3;
const vertex_fan_area = helpers.vertex_fan_area;

test "4-vertex polygon = two adjacent octants" {
    const verts = [_]Vec3{
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(0, 0, 1),
        .init(0, -1, 0),
    };
    try expectApproxEqAbs(pi, try polygon_area(&verts), 1e-13);
}

test "4-vertex polygon with non-adjacent antipodal vertices" {
    const verts = [_]Vec3{
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(-1, 0, 0),
        .init(0, 0, 1),
    };
    try expectApproxEqAbs(pi, try polygon_area(&verts), 1e-13);
}

test "tight polygon dispatches to centroid-fan path" {
    const verts = [_]Vec3{
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(0, 0, 1),
    };
    try testing.expectEqual(
        cross_area(&verts),
        try polygon_area(&verts),
    );
    try expectApproxEqAbs(pi / 2.0, try polygon_area(&verts), 1e-14);
}

test "angle formula matches centroid-fan on a non-degenerate hemispheric polygon" {
    const verts = [_]Vec3{
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(0, 0, 1),
    };
    try expectApproxEqAbs(
        angle_area(&verts),
        cross_area(&verts),
        1e-13,
    );
}

test "great-circle polygon (vertex sum = 0) dispatches to angle formula" {
    const ccw_from_above = [_]Vec3{
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(-1, 0, 0),
        .init(0, -1, 0),
    };
    try expectApproxEqAbs(2.0 * pi, try polygon_area(&ccw_from_above), 1e-13);

    const cw_from_above = [_]Vec3{
        .init(1, 0, 0),
        .init(0, -1, 0),
        .init(-1, 0, 0),
        .init(0, 1, 0),
    };
    try expectApproxEqAbs(2.0 * pi, try polygon_area(&cw_from_above), 1e-13);

    // Same equator ring constructed from LatLng input then converted
    // at the call site — the recommended pattern for LatLng-shaped data.
    const ll_ccw = [_]LatLng{
        .init(0, 0),
        .init(0, pi / 2.0),
        .init(0, pi),
        .init(0, -pi / 2.0),
    };
    var verts_v: [ll_ccw.len]Vec3 = undefined;
    for (ll_ccw, &verts_v) |ll, *v| v.* = ll.to_vec3();
    try expectApproxEqAbs(2.0 * pi, try polygon_area(&verts_v), 1e-13);
}

test "orientation flip yields complementary region (small/centroid-fan polygon)" {
    const fwd = [_]Vec3{
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(0, 0, 1),
    };
    const rev = [_]Vec3{
        .init(0, 0, 1),
        .init(0, 1, 0),
        .init(1, 0, 0),
    };
    // The two orientations enclose complementary regions, so the
    // magnitudes sum to 4π.
    try expectApproxEqAbs(
        4.0 * pi,
        (try polygon_area(&fwd)) + (try polygon_area(&rev)),
        1e-13,
    );
}

test "orientation flip yields complementary region (global/angle-formula polygon)" {
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
    // Equator ring: each orientation encloses one hemisphere (2π).
    try expectApproxEqAbs(
        4.0 * pi,
        (try polygon_area(&fwd)) + (try polygon_area(&rev)),
        1e-13,
    );
}

test "LatLng-derived Vec3 input matches direct Vec3 input on a hemispheric polygon" {
    // Octant traced as lat/lng (then converted) vs as Vec3 directly —
    // both should land on pi/2.
    const verts_v = [_]Vec3{
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(0, 0, 1),
    };
    const verts_ll = [_]LatLng{
        .{ .lat = 0.0, .lng = 0.0 },
        .{ .lat = 0.0, .lng = pi / 2.0 },
        .{ .lat = pi / 2.0, .lng = 0.0 },
    };
    var verts_ll_as_v: [verts_ll.len]Vec3 = undefined;
    for (verts_ll, &verts_ll_as_v) |ll, *v| v.* = ll.to_vec3();
    try expectApproxEqAbs(
        try polygon_area(&verts_v),
        try polygon_area(&verts_ll_as_v),
        1e-13,
    );
    try expectApproxEqAbs(pi / 2.0, try polygon_area(&verts_ll_as_v), 1e-14);
}

test "all 8 CCW octants give +π/2 from both kernels" {
    // Same construction as the next test, but goes through the
    // signed kernels directly to lock in the sign convention:
    //   - cross_area returns +π/2 directly for CCW-from-outside.
    //   - angle_area returns the raw "winding" sum, which lands
    //     on +π/2 OR (+π/2 − 4π) depending on whether the edges
    //     cross the antimeridian (the atan2(0, −x) = π flip).
    //     normalize_positive folds the latter back to +π/2.
    const eq = [_]Vec3{
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(-1, 0, 0),
        .init(0, -1, 0),
    };
    const np = Vec3.init(0, 0, 1);
    const sp = Vec3.init(0, 0, -1);

    for (0..4) |i| {
        const j = (i + 1) % 4;

        const north = [_]Vec3{ np, eq[i], eq[j] };
        try expectApproxEqAbs(pi / 2.0, cross_area(&north), 1e-14);
        try expectApproxEqAbs(pi / 2.0, normalize_positive(angle_area(&north)), 1e-13);

        const south = [_]Vec3{ sp, eq[j], eq[i] };
        try expectApproxEqAbs(pi / 2.0, cross_area(&south), 1e-14);
        try expectApproxEqAbs(pi / 2.0, normalize_positive(angle_area(&south)), 1e-13);
    }
}

test "all 8 octants have area pi/2" {
    // Equator at the four cardinal longitudes, plus both poles. Any
    // pair of adjacent equator vertices closes with a pole into one of
    // the 8 octants of the sphere; each octant is 4π/8 = π/2 sr.
    const eq_v = [_]Vec3{
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(-1, 0, 0),
        .init(0, -1, 0),
    };
    const np_v = Vec3.init(0, 0, 1);
    const sp_v = Vec3.init(0, 0, -1);

    var total: f64 = 0;
    for (0..4) |i| {
        const j = (i + 1) % 4;

        const north_v = [_]Vec3{ np_v, eq_v[i], eq_v[j] };
        try expectApproxEqAbs(pi / 2.0, @abs(try polygon_area(&north_v)), 1e-14);

        const south_v = [_]Vec3{ sp_v, eq_v[j], eq_v[i] };
        try expectApproxEqAbs(pi / 2.0, @abs(try polygon_area(&south_v)), 1e-14);

        total += @abs(try polygon_area(&north_v));
        total += @abs(try polygon_area(&south_v));
    }
    try expectApproxEqAbs(4.0 * pi, total, 1e-13);
}

test "polygon_area rejects an exactly-antipodal edge" {
    const verts = [_]Vec3{
        .init(1, 0, 0),
        .init(-1, 0, 0),
        .init(0, 0, 1),
    };
    try testing.expectError(error.AntipodalEdge, polygon_area(&verts));
}

test "polygon_area rejects a near-antipodal edge within tolerance" {
    const verts = [_]Vec3{
        .init(1, 0, 0),
        Vec3.init(-1, 1e-7, 0).normalized(),
        .init(0, 0, 1),
    };
    try testing.expectError(error.AntipodalEdge, polygon_area(&verts));
}

test "polygon_area accepts edge just outside the antipodal tolerance" {
    const verts = [_]Vec3{
        .init(1, 0, 0),
        Vec3.init(-1, 1e-2, 0).normalized(),
        .init(0, 0, 1),
    };
    _ = try polygon_area(&verts);
}

test "polygon_area rejects polygons with fewer than 3 vertices" {
    const empty = [_]Vec3{};
    try testing.expectError(error.TooFewVertices, polygon_area(&empty));

    const one = [_]Vec3{.init(1, 0, 0)};
    try testing.expectError(error.TooFewVertices, polygon_area(&one));

    const two = [_]Vec3{ .init(1, 0, 0), .init(0, 1, 0) };
    try testing.expectError(error.TooFewVertices, polygon_area(&two));
}

test "centroid-fan beats v0-fan on a strict-hemisphere polygon with non-adjacent near-antipodal vertices" {
    // Square just above the equator: well-conditioned for both the
    // angle formula (no edge crosses the antimeridian, no pole
    // vertex) and the centroid-fan (apex sits over the +z pole, far
    // from every vertex). The v0-fan fails because the (1,0,eps) /
    // (-1,0,eps) pair is near-antipodal across a single fan
    // triangle. The angle formula serves as the independent oracle.
    const eps: f64 = 1e-4;
    const verts = [_]Vec3{
        Vec3.init(1.0, 0.0, eps).normalized(),
        Vec3.init(0.0, 1.0, eps).normalized(),
        Vec3.init(-1.0, 0.0, eps).normalized(),
        Vec3.init(0.0, -1.0, eps).normalized(),
    };

    const ref = normalize_positive(angle_area(&verts));
    const cfan = normalize_positive(cross_area(&verts));
    const v0fan = normalize_positive(vertex_fan_area(&verts, 0));

    const cfan_err = @abs(cfan - ref);
    const v0fan_err = @abs(v0fan - ref);

    try testing.expect(cfan_err < 1e-13);
    try testing.expect(v0fan_err > 1e-13);
    try testing.expect(v0fan_err > 100.0 * cfan_err);
}

test "centroid-fan and v0-fan agree to ulp on well-conditioned polygons" {
    var rng = std.Random.DefaultPrng.init(0xFEEDFACE);
    const r = rng.random();
    const n: usize = 6;
    var verts: [n]Vec3 = undefined;
    var max_diff: f64 = 0;
    var i: usize = 0;
    while (i < 200) : (i += 1) {
        const center = random_unit_vec3(r);
        for (0..n) |k| {
            const noise = Vec3.init(
                r.floatNorm(f64) * 0.05,
                r.floatNorm(f64) * 0.05,
                r.floatNorm(f64) * 0.05,
            );
            verts[k] = center.add(noise).normalized();
        }
        const cfan = cross_area(&verts);
        const v0fan = vertex_fan_area(&verts, 0);
        const d = @abs(cfan - v0fan);
        if (d > max_diff) max_diff = d;
    }
    try testing.expect(max_diff < 1e-13);
}

