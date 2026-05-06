const std = @import("std");
const latlng = @import("latlng.zig");

pub const Vec3 = struct {
    x: f64,
    y: f64,
    z: f64,

    pub fn init(x: f64, y: f64, z: f64) Vec3 {
        return .{ .x = x, .y = y, .z = z };
    }

    /// Convert a unit vector to lat/lng (radians).
    ///
    /// Uses `atan2(z, √(x²+y²))` for latitude rather than `asin(z)`
    /// — the former is correctly rounded at the poles where `asin`
    /// flattens out.
    pub fn to_lat_lng(self: Vec3) latlng.LatLng {
        return .{
            .lat = std.math.atan2(self.z, @sqrt(self.x * self.x + self.y * self.y)),
            .lng = std.math.atan2(self.y, self.x),
        };
    }

    pub fn add(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
    }

    pub fn sub(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
    }

    pub fn dot(a: Vec3, b: Vec3) f64 {
        var t = a.x * b.x;
        t = @mulAdd(f64, a.y, b.y, t);
        t = @mulAdd(f64, a.z, b.z, t);
        return t;
    }

    pub fn cross(a: Vec3, b: Vec3) Vec3 {
        return .{
            .x = diff_of_products(a.y, b.z, a.z, b.y),
            .y = diff_of_products(a.z, b.x, a.x, b.z),
            .z = diff_of_products(a.x, b.y, a.y, b.x),
        };
    }

    pub fn norm(self: Vec3) f64 {
        return @sqrt(self.dot(self));
    }

    pub fn div(self: Vec3, v: f64) Vec3 {
        return .init(self.x / v, self.y / v, self.z / v);
    }

    pub fn normalized(self: Vec3) Vec3 {
        const n = self.norm();
        if (n == 0) {
            return .init(0, 0, 0);
        } else {
            return self.div(n);
        }
    }

    /// Spherical centroid: renormalized vector sum of the polygon's
    /// vertices. Returns `(0,0,0)` if the vertex sum cancels (great-
    /// circle ring etc.) — callers must check for that and handle
    /// the degenerate case.
    pub fn centroid(verts: []const Vec3) Vec3 {
        var c = Vec3.init(0, 0, 0);
        for (verts) |v| c = c.add(v);
        return c.normalized();
    }
};

/// Returns a*b - c*d, computed via Kahan's compensated FMA scheme so the
/// result is correct to ~2 ulp even when the two products nearly cancel.
pub inline fn diff_of_products(a: f64, b: f64, c: f64, d: f64) f64 {
    const cd = c * d;
    const err = @mulAdd(f64, -c, d, cd);
    const dop = @mulAdd(f64, a, b, -cd);
    return dop + err;
}
