const std = @import("std");
const expect = std.testing.expect;

pub const Stack = struct {
    pointer: u8,
    buffer: [1 << 8]u8,

    const Self = @This();

    pub fn init() Stack {
        return Stack{
            .pointer = 0xFF,
            .buffer = [_]u8{0} ** (1 << 8),
        };
    }

    fn peek8(self: Self) u8 {
        return self.buffer[self.pointer +% 1];
    }

    fn peek16(self: Self) u16 {
        const lo = self.buffer[self.pointer +% 1];
        const hi = self.buffer[self.pointer +% 2];
        return @as(u16, hi) << 8 | lo;
    }

    pub inline fn peek(self: Self, comptime T: type) T {
        return switch (T) {
            u8 => self.peek8(),
            u16 => self.peek16(),
            else => unreachable,
        };
    }

    fn pop8(self: *Self) u8 {
        self.pointer +%= 1;
        return self.buffer[self.pointer];
    }

    fn pop16(self: *Self) u16 {
        const lo = self.pop8();
        const hi = self.pop8();
        return @as(u16, hi) << 8 | lo;
    }

    pub inline fn pop(self: *Self, comptime T: type) T {
        return switch (T) {
            u8 => self.pop8(),
            u16 => self.pop16(),
            else => unreachable,
        };
    }

    fn push8(self: *Self, byte: u8) void {
        self.buffer[self.pointer] = byte;
        self.pointer -%= 1;
    }

    fn push16(self: *Self, short: u16) void {
        self.push8(@truncate(u8, (short >> 8) & 0xFF));
        self.push8(@truncate(u8, short & 0xFF));
    }

    pub inline fn push(self: *Self, comptime T: type, val: T) void {
        switch (T) {
            u8 => self.push8(val),
            u16 => self.push16(val),
            else => unreachable,
        }
    }
};

test "Stack pop" {
    var stack = Stack.init();
    stack.push(u8, 0xCC);
    stack.push(u16, 0xDDEE);

    try expect((stack.pop(u8)) == 0xEE);
    try expect(stack.pointer == 0xFD);

    try expect((stack.pop(u16)) == 0xCCDD);
    try expect(stack.pointer == 0xFF);
}

test "Stack pop underflow" {
    var stack = Stack.init();
    stack.pointer = 0xFE;
    stack.buffer[0xFF] = 0xCC;
    stack.buffer[0x00] = 0xDD;

    try expect(stack.pop(u8) == 0xCC);
    try expect(stack.pop(u8) == 0xDD);
    try expect(stack.pointer == 0x00);
}

test "Stack push" {
    var stack = Stack.init();
    stack.push(u8, 0xCC);
    try expect(stack.buffer[0xFF] == 0xCC);
    try expect(stack.pointer == 0xFE);

    stack.push(u16, 0xDDEE);
    try expect(stack.buffer[0xFE] == 0xDD);
    try expect(stack.buffer[0xFD] == 0xEE);
    try expect(stack.pointer == 0xFC);
}

test "Stack push overflow" {
    var stack = Stack.init();
    stack.pointer = 0x01;
    stack.push(u16, 0xCCDD);

    try expect(stack.buffer[0x01] == 0xCC);
    try expect(stack.buffer[0x00] == 0xDD);
    try expect(stack.pointer == 0xFF);
}
