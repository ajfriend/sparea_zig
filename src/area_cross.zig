//! Cross-product / atan2 spherical area formulas. Triangle area uses
//! Van Oosterom–Strackee (1983):
//!     2 · atan2(x · ((y−x) × (z−x)),  1 + x·y + y·z + z·x)
//! and the polygon-level routine fan-triangulates around the
//! renormalized vertex sum (the spherical "centroid"), summing the
//! signed triangle areas with Kahan-Babuška-Neumaier compensation.
//! Caller is responsible for any precondition checks (e.g.,
//! antipodal edges).

const std = @import("std");
const vec3 = @import("vec3.zig");
const vertex = @import("vertex.zig");
const adder = @import("adder.zig");

const Vec3T = vec3.Vec3T;

/// Generic triangle kernel — computes num/den at precision T and
/// casts to f64 for the smooth atan2 step. Result is f64 regardless
/// of T, since std.math.atan2 supports only f32/f64. Each vertex
/// argument is passed through `vertex.as` so callers can supply
/// `Vec3`, `LatLng`, or an already-typed `Vec3T(T)` value.
pub fn triangle_area(comptime T: type, x: anytype, y: anytype, z: anytype) f64 {
    const xt = vertex.as(Vec3T(T), x);
    const yt = vertex.as(Vec3T(T), y);
    const zt = vertex.as(Vec3T(T), z);

    const yx = yt.sub(xt);
    const zx = zt.sub(xt);

    const num: T = xt.dot(yx.cross(zx));
    const den: T = 1.0 + xt.dot(yt) + yt.dot(zt) + zt.dot(xt);

    const num64: f64 = @floatCast(num);
    const den64: f64 = @floatCast(den);

    return 2.0 * std.math.atan2(num64, den64);
}

/// Signed area in steradians of a polygon, fan-triangulated
/// around the spherical centroid (renormalized vertex sum).
/// Accepts a slice of `Vec3` *or* `LatLng` (always f64 inputs);
/// the comptime `T` parameter sets the precision of the centroid
/// sum and the per-triangle num/den computation. Result is f64
/// regardless (the final atan2 is f64).
///
/// **Warning for external callers:** silently returns `0` on
/// great-circle rings and other polygons whose vertex sum
/// cancels (the centroid is undefined and every fan-triangle
/// from a `(0,0,0)` apex evaluates to `2·atan2(0, 1+y·z) = 0`).
/// The dispatcher in `polygon.zig` checks for this case via
/// `is_hemisphere_contained` and routes such polygons to the
/// angle formula instead. If you call `signed_area` directly
/// on a global / non-hemispheric polygon, check that the
/// vertex sum is nonzero first. No antipodal-edge validation
/// either — caller is responsible.
pub fn signed_area(comptime T: type, verts: anytype) f64 {
    const c = vertex.centroid(T, verts);
    // Accumulator at precision T to keep the pipeline uniform.
    // triangle_area returns f64 regardless of T (atan2 is f64-only),
    // so the per-term @floatCast is a no-op for T=f64, a lossless
    // widen for T=f128, and a narrow for T=f32. f64 is the only
    // production case; f128 / f32 exist as testing/reference knobs.
    var sum = adder.AdderT(T).init();
    for (0..verts.len) |i| {
        const j = (i + 1) % verts.len;
        sum.add(@floatCast(triangle_area(T, c, verts[i], verts[j])));
    }
    return @floatCast(sum.value());
}
