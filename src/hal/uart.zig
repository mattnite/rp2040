const std = @import("std");
const microzig = @import("microzig");
const gpio = @import("gpio.zig");
const clocks = @import("clocks.zig");
const assert = std.debug.assert;
const regs = microzig.chip.registers;

pub const uart0 = UART{
    .ibdf = @ptrCast(*volatile u32, regs.UART0.UARTIBRD),
    .fbdf = @ptrCast(*volatile u32, regs.UART0.UARTFBRD),
};

pub const uart1 = UART{
    .ibdf = @ptrCast(*volatile u32, regs.UART1.UARTIBRD),
    .fbdf = @ptrCast(*volatile u32, regs.UART1.UARTFBRD),
};

pub const UART =  struct {
    //dr: *volatile u32,
    //rsr: *volatile u32,
    //fr: *volatile u32,
    //ilpr: *volatile u32,
    ibrd: *volatile u32,
    fbrd: *volatile u32,
    //lcr_h: *volatile u32,
    //cr: *volatile u32,
    //ifls: *volatile u32,
    //imsc: *volatile u32,
    //ris: *volatile u32,
    //mis: *volatile u32,
    //icr: *volatile u32,
    //macr: *volatile u32,
    //periphid0: *volatile u32,
    //periphid1: *volatile u32,
    //periphid2: *volatile u32,
    //periphid3: *volatile u32,
    //cellid0: *volatile u32,
    //cellid1: *volatile u32,
    //cellid2: *volatile u32,
    //cellid3: *volatile u32,

    pub fn transmit(uart: UART, payload: []const u8) !void {
        _ = uart;
        _ = payload;
    }
};

pub const Uart = struct {
    id: u1,
    word_type: type,

    /// transmit entire slice of words
    pub fn transmit(comptime uart: Uart, payload: []const uart.word_type) !void {
        _ = uart;
        _ = payload;
    }
};

pub const Config = struct {
    clock_config: clocks.GlobalConfiguration,
    tx_pin: u32,
    rx_pin: u32,
    baud_rate: u32,
    word_bits: u8 = 8,
    stop_bits: u8 = 1,
};

fn reset(comptime id: u32) void {}

pub fn init(comptime id: u32, comptime opts: Options) Uart {
    assert(opts.baud_rate > 0);

    const peri_freq = opts.clock_config.peri.?.output_freq;
    gpio.setFunction(opts.tx_pin);
    gpio.setFunction(opts.rx_pin);

    reset(id);

    setBaudRate(id, opts.baud_rate);
    setFormat(id, opts.width, opts.stop_bits);

    enable(id);
    enableFifos(id);

    // - always enable DREQ signals -- no harm if dma isn't listening

    return Uart{
        .id = id,
        .word_type = std.meta.Int(.unsigned, opts.word_bits),
    };
}

fn setBaudRate(comptime id: u32, peri_freq: u32, baud_rate: u32) void {
    assert(baud_rate > 0);
    const uart_regs = getUart(id);
    const baud_rate_div = (8 * peri_freq / baud_rate);
    var baud_ibrd = baud_rate_div >> 7;

    const baud_fbrd = if (baud_ibrd == 0) baud_fbrd: {
        baud_ibrd = 1;
        break :baud_fbrd 0;
    } else if (baud_ibrd >= 65535) baud_fbrd: {
        baud_ibrd = 65535;
        break :baud_fbrd 0;
    } else ((baud_rate_div & 0x7f) + 1) / 2;


    uart_regs.ibrd.* = baud_ibrd;
    uart_regs.fbrd.* = baud_fbrd;
}
