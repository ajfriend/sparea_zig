/// Compensated-summation accumulator (Kahan-Babuška-Neumaier). Tracks
/// a running sum `s` and a compensation term `c` capturing the rounding
/// error so the final total `s + c` is correct to ~1 ulp regardless of
/// summation order, even when intermediate values dominate the running
/// sum.
pub fn AdderT(comptime T: type) type {
    return struct {
        const Self = @This();

        s: T = 0.0,
        c: T = 0.0,

        pub fn init() Self {
            return .{};
        }

        pub fn add(self: *Self, x: T) void {
            const t = self.s + x;
            if (@abs(self.s) >= @abs(x)) {
                self.c += (self.s - t) + x;
            } else {
                self.c += (x - t) + self.s;
            }
            self.s = t;
        }

        pub fn value(self: Self) T {
            return self.s + self.c;
        }
    };
}

pub const Adder = AdderT(f64);
