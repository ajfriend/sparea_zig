const std = @import("std");
const vec3 = @import("vec3.zig");

const Vec3 = vec3.Vec3;

/// Geographic coordinates in radians. Latitude is measured from the
/// equator (-π/2 at south pole, +π/2 at north pole); longitude is
/// unbounded but the formulas only depend on differences of longitudes
/// mod 2π.
pub const LatLng = struct {
    lat: f64,
    lng: f64,

    pub fn init(lat: f64, lng: f64) LatLng {
        return .{ .lat = lat, .lng = lng };
    }

    /// Convert lat/lng (radians) to a unit vector.
    pub fn to_vec3(self: LatLng) Vec3 {
        const cl = @cos(self.lat);
        return Vec3.init(cl * @cos(self.lng), cl * @sin(self.lng), @sin(self.lat));
    }
};
