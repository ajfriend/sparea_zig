//! Vertex polymorphism + Vec3 ↔ LatLng conversion math.
//!
//! `as(comptime To, v)` is the single conversion entry point —
//! caller writes the target type, and the function picks the
//! right path at compile time. Each call site lowers to exactly
//! the conversion needed (identity move, `@floatCast`, or an
//! atan2/sin/cos evaluation), with no runtime branch.
//!
//! Kept in its own module so neither `vec3.zig` nor `latlng.zig`
//! has to know about the other.

const std = @import("std");
const vec3 = @import("vec3.zig");
const latlng = @import("latlng.zig");

const Vec3 = vec3.Vec3;
const Vec3T = vec3.Vec3T;
const LatLng = latlng.LatLng;

/// Convert `v` to type `To`. Supported pairs:
///   - identity (any T → T)
///   - Vec3T(S) → Vec3T(T)   (`@floatCast` per field)
///   - Vec3T(S) → LatLng     (atan2-based, S coerced through f64)
///   - LatLng   → Vec3T(T)   (cos/sin evaluated at precision T)
///
/// Vec3→LatLng uses `atan2(z, √(x²+y²))` for latitude rather than
/// `asin(z)` — the former is correctly rounded at the poles where
/// `asin` flattens out.
pub inline fn as(comptime To: type, v: anytype) To {
    const From = @TypeOf(v);
    if (From == To) return v;

    if (To == LatLng) {
        // From must be a Vec3T(S) — fields x/y/z. The result is f64.
        const x: f64 = @floatCast(v.x);
        const y: f64 = @floatCast(v.y);
        const z: f64 = @floatCast(v.z);
        return .{
            .lat = std.math.atan2(z, @sqrt(x * x + y * y)),
            .lng = std.math.atan2(y, x),
        };
    }

    // To is a Vec3T(T).
    const T = @FieldType(To, "x");

    if (From == LatLng) {
        const lat: T = @floatCast(v.lat);
        const lng: T = @floatCast(v.lng);
        const cl = @cos(lat);
        return To.init(cl * @cos(lng), cl * @sin(lng), @sin(lat));
    }

    // From is a Vec3T(S), S ≠ T — widen or narrow per field.
    return To.init(@floatCast(v.x), @floatCast(v.y), @floatCast(v.z));
}

/// Spherical centroid at precision T: renormalized vector sum of
/// the polygon's vertices, computed in `Vec3T(T)`. Accepts a slice
/// of `Vec3` or `LatLng`. Returns `(0,0,0)` if the vertex sum
/// cancels (great-circle ring etc.) — callers must check for that
/// and handle the degenerate case.
pub fn centroid(comptime T: type, verts: anytype) Vec3T(T) {
    var c = Vec3T(T).init(0, 0, 0);
    for (verts) |v| c = c.add(as(Vec3T(T), v));
    return c.normalized();
}
