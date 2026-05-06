const std = @import("std");
const vec3 = @import("../vec3.zig");
const area_cross = @import("../area_cross.zig");

const Vec3 = vec3.Vec3;
const triangle_area = area_cross.triangle_area;
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

test "equator ring defeats every fan-of-vertex cross strategy; only angle gets it right" {
    // Two independent failure modes pile up on this single polygon,
    // and together they're the structural reason the angle formula
    // can't be replaced by a smarter fan choice:
    //
    //   - centroid-fan: vertex sum is exactly (0,0,0), so the
    //     centroid is (0,0,0); every fan triangle reduces to
    //     2·atan2(0, 1+v_i·v_j) = 0. This failure depends only on
    //     vertex-sum cancellation — not on great-circle or antipodal
    //     structure (the 3-vertex equilateral on the equator has the
    //     same vertex-sum cancellation and centroid-fan also returns
    //     0 there, even though it has no antipodal pairs).
    //
    //   - v_k-fan: every choice of apex v_k has its antipode at
    //     v_{k+2}, so each fan triangle (v_k, v_{k+1}, v_{k+2}) and
    //     (v_k, v_{k+2}, v_{k+3}) has num=0 (coplanar) AND den=0
    //     (antipodal pair), giving 2·atan2(0, 0) = 0. This is
    //     antipodal-specific, not great-circle-generic — the 3-
    //     equilateral lives on a great circle but has no antipodal
    //     pairs, and v0-fan recovers 2π there.
    //
    // The angle formula returns -2π (= 2π after normalize_positive),
    // independent of either failure mode.
    const helpers = @import("helpers.zig");
    const area_angle = @import("../area_angle.zig");
    const verts = [_]Vec3{
        Vec3.init(1, 0, 0),
        Vec3.init(0, 1, 0),
        Vec3.init(-1, 0, 0),
        Vec3.init(0, -1, 0),
    };
    try testing.expectEqual(@as(f64, 0.0), area_cross.signed_area(&verts));
    for (0..verts.len) |k| {
        try testing.expectEqual(@as(f64, 0.0), helpers.vertex_fan_area(&verts, k));
    }
    try expectApproxEqAbs(-2.0 * pi, area_angle.signed_area(&verts), 1e-13);
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


test "tiny pole-enclosing triangle: cross gets ε² area; angle winds by 4π" {
    // Equilateral triangle around the north pole, side ~eps. Each
    // edge crosses an antimeridian-equivalent (the lng jump is ~120°
    // → 360° as eps → 0), and the angle formula's atan2 collapses
    // each edge's contribution toward 0, summing to -4π — a full
    // sign-loss winding. The cross formula works in 3-space and
    // never sees the lng singularity, so it returns the correct
    // tiny area to ulp. This is the failure mode that justifies
    // dispatching hemisphere-contained polygons (and especially
    // pole-enclosing ones) to the cross path.
    const area_angle = @import("../area_angle.zig");
    const eps: f64 = 1e-8;
    const verts = [_]Vec3{
        Vec3.init(eps, 0, 1).normalized(),
        Vec3.init(-eps / 2.0, eps * 0.8660254037844387, 1).normalized(),
        Vec3.init(-eps / 2.0, -eps * 0.8660254037844387, 1).normalized(),
    };
    const expected = (3.0 * @sqrt(3.0) / 4.0) * eps * eps;

    const cross_a = area_cross.signed_area(&verts);
    try testing.expect(@abs(cross_a - expected) < 1e-17);

    const angle_a = area_angle.signed_area(&verts);
    try expectApproxEqAbs(-4.0 * pi, angle_a, 1e-13);
}
