/// Compensated-summation accumulator (Kahan-Babuška-Neumaier). Tracks
/// a running sum `s` and a compensation term `c` capturing the rounding
/// error so the final total `s + c` is correct to ~1 ulp regardless of
/// summation order, even when intermediate values dominate the running
/// sum.
pub const Adder = struct {
    s: f64 = 0.0,
    c: f64 = 0.0,

    pub fn init() Adder {
        return .{};
    }

    pub fn add(self: *Adder, x: f64) void {
        const t = self.s + x;
        if (@abs(self.s) >= @abs(x)) {
            self.c += (self.s - t) + x;
        } else {
            self.c += (x - t) + self.s;
        }
        self.s = t;
    }

    pub fn value(self: Adder) f64 {
        return self.s + self.c;
    }
};
