const std = @import("std");
const expect = std.testing.expect;

const Memory = @import("./Memory.zig").Memory;
const Stack = @import("./Stack.zig").Stack;

pub const VirtualMachine = struct {
    memory: Memory = Memory.init(),
    workingStack: Stack = Stack.init(),
    returnStack: Stack = Stack.init(),

    const page_program = 0x0100;

    const Self = @This();

    const StackRole = enum {
        source,
        destination,
    };

    pub fn init() VirtualMachine {
        return .{};
    }

    pub fn stack(self: Self, role: StackRole, returnMode: bool) Stack {
        switch (role) {
            .source => self.workingStack,
            .destination => self.returnStack,
        }
    }
};
