const microzig = @import("microzig");
const util = @import("util.zig");
const sio = @import("sio.zig");
const VectorTable = microzig.chip.regs.VectorTable;
const PSM = microzig.chip.registers.PSM;
const cpu = microzig.cpu;
const nvic = cpu.nvic;

pub fn reset() void {
    const power_off = PSM.FRCE_OFF;
    const power_off_set = util.setAlias(PSM.FRCE_OFF);
    const power_off_clear = util.clearAlias(PSM.FRCE_OFF);

    const mask = .{
        .rosc = 0,
        .xosc = 0,
        .clocks = 0,
        .resets = 0,
        .busfabric = 0,
        .rom = 0,
        .sram0 = 0,
        .sram1 = 0,
        .sram2 = 0,
        .sram3 = 0,
        .sram4 = 0,
        .sram5 = 0,
        .xip = 0,
        .vreg_and_chip_reset = 0,
        .sio = 0,
        .proc0 = 0,
        .proc1 = 1,
    };

    power_off_set.write(mask);
    while (power_off.read().proc1 == 0) {}
    power_off_clear.write(mask);
}

fn wrapper(entry: fn () callconv(.C) c_int, stack_base: ?*anyopaque) callconv(.C) c_int {
    _ = stack_base;
    // TODO: irq_init_properties
    return entry();
}

fn trampoline() callconv(.Naked) void {
    asm volatile ("pop {r0, r1, pc}");
}

// TODO: does entry need to have a C calling convention, does the convention
// even matter since there's no return or arguments?
//
// TODO: stack protector?
// TODO: can I use async frames to determine stack size?
pub fn launch(
    entry: fn () callconv(.C) void,
    stack: []u32,
    args: struct {
        vector_table: ?*VectorTable = null,
    },
) void {
    const stack_ptr = &stack[stack.len - 3];
    stack[stack.len - 3] = @ptrToInt(entry);
    stack[stack.len - 2] = @ptrToInt(&stack);
    stack[stack.len - 1] = @ptrToInt(wrapper);

    const enabled = nvic.irqIsEnabled(.SIO_IRQ_PROC0);
    nvic.irqSetEnabled(.SIO_IRQ_PROC0, false);
    defer nvic.irqSetEnabled(.SIO_IRQ_PROC0, enabled);

    const vector_table = if (args.vector_table) |vt|
        vt
    else
        @extern(VectorTable, .{ .name = "vector_table" });

    const sequence = [_]u32{
        0,
        0,
        1,
        @ptrToInt(vector_table),
        @ptrToInt(stack_ptr),
        @ptrToInt(trampoline),
    };

    var i: u32 = 0;
    while (i < sequence.len) {
        const cmd = sequence[i];
        if (cmd == 0) {
            sio.fifo.drain();
            cpu.sev();
        }

        sio.fifo.push(cmd);
        const resp = sio.fifo.pop();
        i = if (cmd == resp) i + 1 else 0;
    }
}
