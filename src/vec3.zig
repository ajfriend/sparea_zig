pub fn Vec3T(comptime T: type) type {
    return struct {
        const Self = @This();

        x: T,
        y: T,
        z: T,

        pub fn init(x: T, y: T, z: T) Self {
            return .{ .x = x, .y = y, .z = z };
        }

        pub fn add(a: Self, b: Self) Self {
            return .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
        }

        pub fn sub(a: Self, b: Self) Self {
            return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
        }

        pub fn dot(a: Self, b: Self) T {
            var t = a.x * b.x;
            t = @mulAdd(T, a.y, b.y, t);
            t = @mulAdd(T, a.z, b.z, t);
            return t;
        }

        pub fn cross(a: Self, b: Self) Self {
            return .{
                .x = diff_of_products(T, a.y, b.z, a.z, b.y),
                .y = diff_of_products(T, a.z, b.x, a.x, b.z),
                .z = diff_of_products(T, a.x, b.y, a.y, b.x),
            };
        }

        pub fn norm(self: Self) T {
            return @sqrt(self.dot(self));
        }

        pub fn div(self: Self, v: T) Self {
            return .init(self.x / v, self.y / v, self.z / v);
        }

        pub fn normalized(self: Self) Self {
            const n = self.norm();
            if (n == 0) {
                return .init(0, 0, 0);
            } else {
                return self.div(n);
            }
        }
    };
}

pub const Vec3 = Vec3T(f64);

/// Returns a*b - c*d, computed via Kahan's compensated FMA scheme so the
/// result is correct to ~2 ulp even when the two products nearly cancel.
pub inline fn diff_of_products(comptime T: type, a: T, b: T, c: T, d: T) T {
    const cd = c * d;
    const err = @mulAdd(T, -c, d, cd);
    const dop = @mulAdd(T, a, b, -cd);
    return dop + err;
}
