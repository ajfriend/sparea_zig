//! Concrete polygons that defeat the v0-fan cross-product
//! triangulation but compute correctly via the angle formula (and
//! via centroid-fan cross-product, since the centroid avoids putting
//! an antipodal pair into any single fan triangle). These are the
//! geometric reason the dispatcher in `polygon.zig` prefers the
//! centroid-fan cross-product path and falls back to the angle
//! formula for non-hemispheric polygons.
//!
//! When a polygon has a non-adjacent antipodal vertex pair (a, ā)
//! and you triangulate with v0 = a as the apex, every fan triangle
//! that includes ā has the form (a, ?, ā) — and the cross-product
//! formula on such a triangle evaluates `2 · atan2(0, 0) = 0`,
//! contributing nothing. The resulting "area" silently understates
//! the true value.

const std = @import("std");
const area_angle = @import("../area_angle.zig");
const vec3 = @import("../vec3.zig");
const helpers = @import("helpers.zig");

const Vec3 = vec3.Vec3;
const angle_area = area_angle.signed_area;
const vertex_fan_area = helpers.vertex_fan_area;
const testing = std.testing;
const pi = std.math.pi;

test "pole-to-pole lune: v0-fan cross-product returns 0; angle formula returns pi" {
    // Two octants glued along edge (E0, E1), forming a lune from
    // north pole to south pole. With v0 = NP, the v0-fan produces
    // triangles (NP, E0, SP) and (NP, SP, E1) — both contain the
    // antipodal pair NP/SP, so each evaluates to 0.
    const verts = [_]Vec3{
        .init(0, 0, 1), // NP
        .init(1, 0, 0), // E0
        .init(0, 0, -1), // SP
        .init(0, 1, 0), // E1
    };

    try testing.expectEqual(@as(f64, 0.0), vertex_fan_area(&verts, 0));

    const angle = angle_area(&verts);
    try testing.expectApproxEqAbs(pi, @abs(angle), 1e-13);
}

test "equator-cornered quad: v0-fan cross-product returns 0; angle formula returns pi" {
    // Two adjacent north-cap octants glued along edge (NP, E1),
    // forming a quad with antipodal corners E0 and E2 on the
    // equator. With v0 = E0, the v0-fan produces (E0, E1, E2) and
    // (E0, E2, NP) — both contain the antipodal pair E0/E2.
    const verts = [_]Vec3{
        .init(1, 0, 0), // E0
        .init(0, 1, 0), // E1
        .init(-1, 0, 0), // E2
        .init(0, 0, 1), // NP
    };

    try testing.expectEqual(@as(f64, 0.0), vertex_fan_area(&verts, 0));

    const angle = angle_area(&verts);
    try testing.expectApproxEqAbs(pi, @abs(angle), 1e-13);
}
