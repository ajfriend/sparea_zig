/// Geographic coordinates in radians. Latitude is measured from the
/// equator (-π/2 at south pole, +π/2 at north pole); longitude is
/// unbounded but the formulas only depend on differences of longitudes
/// mod 2π.
///
/// Pure data type; the Vec3 ↔ LatLng conversions live in
/// `vertex.zig` to avoid an import cycle with `vec3.zig`.
pub const LatLng = struct {
    lat: f64,
    lng: f64,

    pub fn init(lat: f64, lng: f64) LatLng {
        return .{ .lat = lat, .lng = lng };
    }
};
