const std = @import("std");
const expect = std.testing.expect;

const VirtualMachine = @import("VirtualMachine.zig").VirtualMachine;
const Memory = @import("Memory.zig").Memory;
const Stack = @import("Stack.zig").Stack;

pub const Instruction = struct {
    byte: u8,

    const Opcode = enum(u5) {
        // Stack
        LIT = 0x00, // Literal
        INC = 0x01, // Increment
        POP = 0x02, // Pop
        DUP = 0x03, // Duplicate
        NIP = 0x04, // Nip
        SWP = 0x05, // Swap
        OVR = 0x06, // Over
        ROT = 0x07, // Rotate
        // Logic
        EQU = 0x08, // Equal
        NEQ = 0x09, // Not Equal
        GTH = 0x0A, // Greater Than
        LTH = 0x0B, // Lesser Than
        JMP = 0x0C, // Jump
        JCN = 0x0D, // Jump Condition
        JSR = 0x0E, // Jump Stash
        STH = 0x0F, // Stash
        // Memory
        LDZ = 0x10, // Load Zero Page
        STZ = 0x11, // Store Zero Page
        LDR = 0x12, // Load Relative
        STR = 0x13, // Store Relative
        LDA = 0x14, // Load Absolute
        STA = 0x15, // Store Absolute
        DEI = 0x16, // Device In
        DEO = 0x17, // Device Out
        // Arithmetic
        ADD = 0x18, // Add
        SUB = 0x19, // Subtract
        MUL = 0x1A, // Multiply
        DIV = 0x1B, // Divide
        AND = 0x1C, // And
        ORA = 0x1D, // Or
        EOR = 0x1E, // Exclusive Or
        SFT = 0x1F, // Shift
    };

    const Self = @This();

    pub fn init(byte: u8) Instruction {
        return Instruction{ .byte = byte };
    }

    pub inline fn opcode(self: Self) Opcode {
        return @intToEnum(Opcode, @truncate(u5, self.byte & 0b000_11111));
    }

    pub fn execute(op: Opcode, src: Stack, dst: Stack, mem: Memory) void {
        switch (true) {}
    }
};

test "Instruction initialization" {
    const byte: u8 = 0b110_11111;
    const instr = Instruction.init(byte);
    try expect(instr.opcode() == Instruction.Opcode.SFT);
}

const Operation = struct {
    name: []const u8,
    opcode: u5,
    function: fn (*VirtualMachine) void,
};

fn ADD(mode: OperationMode, vm: *VirtualMachine) void {
    const a = vm.stack(.source, mode.RETURN).pop(mode.SHORT, mode.KEEP);
    const b = vm.stack(.source, mode.RETURN).pop(mode.SHORT, mode.KEEP);
    vm.stack(.source, mode.RETURN).push(mode.SHORT, a +% b);
}

fn JSR(comptime T: type, stack: Stack) void {
    const a = stack.pop(T);
    // push16(u->dst, u->ram.ptr);
    const b = stack.pop(T);
    stack.push(T, a +% b);
}

const Mode = enum {
    SHORT,
    RETURN,
    KEEP,

    pub fn testOpcode(mode: Mode, opcode: u8) bool {
        const mask: u8 = switch (mode) {
            .SHORT => 0x20,
            .RETURN => 0x40,
            .KEEP => 0x80,
        };
        return (opcode & mask) > 0;
    }
};

fn getWordType(opcode: u8) type {
    if ((opcode & 0x20) > 0) {
        return u16;
    } else {
        return u8;
    }
}

test "ADD2" {
    var stack = Stack.init();
    const opcode = 0b001_11000;
    comptime {
        const T = comptime if (Mode.testOpcode(.SHORT, opcode)) {
            return u16;
        } else {
            return u8;
        };
        @compileLog(T);
    }
}
