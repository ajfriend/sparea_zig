//! Shared helpers for the test files in this directory.

const std = @import("std");
const vec3 = @import("../vec3.zig");
const area_cross = @import("../area_cross.zig");
const adder = @import("../adder.zig");

const Vec3 = vec3.Vec3;

pub fn random_unit_vec3(r: std.Random) Vec3 {
    // Three independent standard normals → sum of squares is chi²(3);
    // P(magnitude ≈ 0) is astronomically small, so we don't bother
    // with rejection. Tests use seeded RNGs and never hit it.
    return Vec3.init(r.floatNorm(f64), r.floatNorm(f64), r.floatNorm(f64)).normalized();
}

/// Compute polygon area by fan-triangulating around `verts[apex_idx]`
/// — the v_k-fan, generalizing the original "v0-fan" approach. Used by
/// the centroid-fan-vs-v0-fan comparison tests.
pub fn vertex_fan_area(verts: []const Vec3, apex_idx: usize) f64 {
    const apex = verts[apex_idx];
    var sum = adder.Adder.init();
    var i: usize = 1;
    while (i + 1 < verts.len) : (i += 1) {
        const a = (apex_idx + i) % verts.len;
        const b = (apex_idx + i + 1) % verts.len;
        sum.add(area_cross.triangle_area(f64, apex, verts[a], verts[b]));
    }
    return sum.value();
}
