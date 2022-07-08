const microzig = @import("microzig");
const time = @import("time.zig");
const SIO = microzig.chip.registers.SIO;
const cpu = microzig.cpu;

pub const fifo = struct {
    const TimeoutError = error{Timeout};

    pub fn push(data: u32) void {
        while (!ready()) {}

        SIO.FIFO_WR.* = data;
        cpu.sev();
    }

    pub fn pushTimeoutUs(data: u32, timeout_us: u64) TimeoutError!void {
        const end_time = time.makeTimeoutUs(timeout_us);
        while (!ready())
            if (time.reached(end_time))
                return error.Timeout;

        SIO.FIFO_WR.* = data;
        cpu.sev();
    }

    pub fn pop() u32 {
        while (!hasData())
            cpu.wfe();

        return SIO.FIFO_RD.*;
    }

    pub fn popTimeoutUs(timeout_us: u64) TimeoutError!u32 {
        const end_time = time.makeTimeoutUs(timeout_us);
        while (!hasData()) {
            cpu.wfe();

            if (time.reached(end_time))
                return error.Timeout;
        }

        return SIO.FIFO_RD.*;
    }

    pub inline fn hasData() bool {
        return (1 == SIO.FIFO_ST.read().VLD);
    }

    pub inline fn ready() bool {
        return (1 == SIO.FIFO_ST.read().RDY);
    }

    // TODO: ensure the codegen is correct for this one, might need to use
    // `std.mem.doNotOptimizeAway()`
    pub fn drain() void {
        while (hasData())
            _ = SIO.FIFO_RD.*;
    }

    pub fn clearIrq() void {
        SIO.FIFO_ST.raw = 0xff;
    }
};

// TODO: spinlocks
// TODO: integer divider
// TODO: interpolator 0
// TODO: interpolator 1
