const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;

pub const Stack = struct {
    pointer: u8,
    buffer: [1 << 8]u8,

    const Error = error{
        StackOverflow,
        StackUnderflow,
    };

    const Self = @This();

    pub fn init() Stack {
        return Stack{
            .pointer = 0xFF,
            .buffer = [_]u8{0} ** (1 << 8),
        };
    }

    inline fn peek8(self: Self) Error!u8 {
        if (self.pointer == 0xFF) {
            return Error.StackUnderflow;
        }
        return self.buffer[self.pointer + 1];
    }

    inline fn peek16(self: Self) Error!u16 {
        if (self.pointer == 0xFF) {
            return Error.StackUnderflow;
        }
        const byte = self.buffer[self.pointer - 1];
    }

    pub fn peek(self: Self, comptime T: type) Error!T {
        return switch (T) {
            u8 => self.peek8(),
            u16 => self.peek16(),
            else => unreachable,
        };
    }

    inline fn pop8(self: *Self) Error!u8 {
        const byte = try self.peek8();
        self.pointer += 1;
        return byte;
    }

    inline fn pop16(self: *Self) Error!u16 {
        const lo = try self.pop8();
        const hi = try self.pop8();
        return @as(u16, hi) << 8 | lo;
    }

    pub fn pop(self: *Self, comptime T: type) Error!T {
        return try switch (T) {
            u8 => self.pop8(),
            u16 => self.pop16(),
            else => unreachable,
        };
    }

    inline fn push8(self: *Self, byte: u8) Error!void {
        if (self.pointer == 0) {
            return Error.StackOverflow;
        }
        self.buffer[self.pointer] = byte;
        self.pointer -= 1;
    }

    inline fn push16(self: *Self, short: u16) Error!void {
        try self.push8(@truncate(u8, (short >> 8) & 0xFF));
        try self.push8(@truncate(u8, short & 0xFF));
    }

    pub fn push(self: *Self, comptime T: type, val: T) Error!void {
        switch (T) {
            u8 => try self.push8(val),
            u16 => try self.push16(val),
            else => unreachable,
        }
    }
};

test "Stack push" {
    var stack = Stack.init();
    try stack.push(u8, 0xCC);
    try expect(stack.buffer[0xFF] == 0xCC);
    try expect(stack.pointer == 0xFE);

    try stack.push(u16, 0xDDEE);
    try expect(stack.buffer[0xFE] == 0xDD);
    try expect(stack.buffer[0xFD] == 0xEE);
    try expect(stack.pointer == 0xFC);
}

test "Stack push overflow" {
    var stack = Stack.init();
    stack.pointer = 0x00;

    try expectError(error.StackOverflow, stack.push(u8, 0xDD));
}

test "Stack pop" {
    var stack = Stack.init();
    try stack.push(u8, 0xCC);
    try stack.push(u16, 0xDDEE);

    try expect((try stack.pop(u8)) == 0xEE);
    try expect(stack.pointer == 0xFD);

    try expect((try stack.pop(u16)) == 0xCCDD);
    try expect(stack.pointer == 0xFF);
}

test "Stack pop underflow" {
    var stack = Stack.init();

    try expectError(error.StackUnderflow, stack.pop(u8));
}
