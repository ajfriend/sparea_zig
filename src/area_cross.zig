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
const adder = @import("adder.zig");

const Vec3 = vec3.Vec3;

/// Triangle area in steradians.
pub fn triangle_area(x: Vec3, y: Vec3, z: Vec3) f64 {
    const yx = y.sub(x);
    const zx = z.sub(x);

    const num = x.dot(yx.cross(zx));
    const den = 1.0 + x.dot(y) + y.dot(z) + z.dot(x);

    return 2.0 * std.math.atan2(num, den);
}

/// Signed area in steradians of a polygon, fan-triangulated
/// around the spherical centroid (renormalized vertex sum).
///
/// **Warning for external callers:** silently returns `0` on
/// great-circle rings and other polygons whose vertex sum
/// cancels (the centroid is undefined and every fan-triangle
/// from a `(0,0,0)` apex evaluates to `2·atan2(0, 1+y·z) = 0`).
/// The dispatcher in `area.zig` checks for this case via
/// `is_hemisphere_contained` and routes such polygons to the
/// angle formula instead. If you call `signed_area` directly
/// on a global / non-hemispheric polygon, check that the
/// vertex sum is nonzero first. No antipodal-edge validation
/// either — caller is responsible.
pub fn signed_area(verts: []const Vec3) f64 {
    const c = Vec3.centroid(verts);
    var sum = adder.Adder.init();
    for (0..verts.len) |i| {
        const j = (i + 1) % verts.len;
        sum.add(triangle_area(c, verts[i], verts[j]));
    }
    return sum.value();
}
