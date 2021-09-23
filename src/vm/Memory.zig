const std = @import("std");
const expect = std.testing.expect;

pub const Memory = struct {
    pointer: u16,
    buffer: [1 << 16]u8,

    const Self = @This();

    pub fn init() Memory {
        return Memory{
            .pointer = 0x0000,
            .buffer = [_]u8{0} ** (1 << 16),
        };
    }

    fn read8(self: Self, addr: u16) u8 {
        return self.buffer[addr];
    }

    fn read16(self: Self, addr: u16) u16 {
        const hi = self.read8(addr);
        const lo = self.read8(addr +% 1);
        return @as(u16, hi) << 8 | lo;
    }

    pub fn read(self: Self, comptime T: type, addr: u16) T {
        return switch (T) {
            u8 => self.read8(addr),
            u16 => self.read16(addr),
            else => unreachable,
        };
    }

    fn write8(self: *Self, addr: u16, byte: u8) void {
        self.buffer[addr] = byte;
    }

    fn write16(self: *Self, addr: u16, short: u16) void {
        self.write8(addr, @truncate(u8, (short >> 8) & 0xFF));
        self.write8(addr +% 1, @truncate(u8, short & 0xFF));
    }

    pub fn write(self: *Self, comptime T: type, addr: u16, val: T) void {
        switch (T) {
            u8 => self.write8(addr, val),
            u16 => self.write16(addr, val),
            else => unreachable,
        }
    }

    pub fn fetch(self: *Self, comptime T: type) T {
        switch (T) {
            u8 => {
                const val = self.read8(self.pointer);
                self.pointer +%= 1;
                return val;
            },
            u16 => {
                const val = self.read16(self.pointer);
                self.pointer +%= 2;
                return val;
            },
            else => unreachable,
        }
    }

    pub fn load(self: *Self, bytes: []const u8, start_addr: u16) void {
        var addr = start_addr;
        for (bytes) |byte| {
            self.write(u8, addr, byte);
            addr +%= 1;
        }
    }
};

test "Memory initialization" {
    var ram = Memory.init();
    try expect(ram.pointer == 0x0000);
    try expect(ram.buffer.len == (0xFFFF + 1));
}

test "Memory read8/write8" {
    var ram = Memory.init();
    ram.write(u8, 0x00FF, 0xCC);
    try expect(ram.read(u8, 0x00FF) == 0xCC);
}

test "Memory read16/write16" {
    var ram = Memory.init();
    ram.write(u16, 0x00FF, 0xCCDD);
    try expect(ram.read(u16, 0x00FF) == 0xCCDD);
}

test "Memory read16/write16 overflow" {
    var ram = Memory.init();
    ram.write(u16, 0xFFFF, 0xCCDD);
    try expect(ram.read(u8, 0xFFFF) == 0xCC);
    try expect(ram.read(u8, 0x0000) == 0xDD);
}

test "Memory fetch" {
    var ram = Memory.init();
    ram.buffer[0] = 0xFF;
    ram.buffer[1] = 0xCC;
    ram.buffer[2] = 0xDD;
    ram.buffer[3] = 0xEE;
    try expect(ram.fetch(u8) == 0xFF);
    try expect(ram.pointer == 1);
    try expect(ram.fetch(u16) == 0xCCDD);
    try expect(ram.pointer == 3);
}

test "Memory fetch overflow" {
    var ram = Memory.init();
    ram.pointer = 0xFFFF;
    _ = ram.fetch(u8);
    try expect(ram.pointer == 0x0000);
}

test "Memory load" {
    var ram = Memory.init();
    const prog = [_]u8{ 0x80, 0xCC, 0x80, 0x11, 0x18 };
    ram.load(&prog, 0x0100);
    try expect(ram.read(u16, 0x0100) == 0x80CC);
    try expect(ram.read(u16, 0x0102) == 0x8011);
    try expect(ram.read(u8, 0x0104) == 0x18);
}
