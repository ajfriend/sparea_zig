const std = @import("std");
const vec3 = @import("../vec3.zig");

const Vec3 = vec3.Vec3;
const testing = std.testing;

test "LatLng round-trip for a basket of unit vectors" {
    const samples = [_]Vec3{
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(0, 0, 1),
        .init(0, 0, -1),
        Vec3.init(1, 1, 1).normalized(),
        Vec3.init(-1, 0.5, -0.3).normalized(),
        Vec3.init(0.001, 0.001, 1).normalized(),
    };
    for (samples) |v| {
        const back = v.to_lat_lng().to_vec3();
        try testing.expectApproxEqAbs(v.x, back.x, 1e-15);
        try testing.expectApproxEqAbs(v.y, back.y, 1e-15);
        try testing.expectApproxEqAbs(v.z, back.z, 1e-15);
    }
}
