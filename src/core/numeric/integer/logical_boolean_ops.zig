const runtime = @import("shortint_runtime.zig");

fn logicalOpResult(res: bool, xtype: u32, ytype: u32) void {
    if (xtype == runtime.dtLongInteger and ytype == runtime.dtLongInteger) {
        // Straight to a long integer: routing the 0/1 through a short-integer
        // register would pick up the word size and sign mode, and at WSIZE 1 a
        // stored 1 reads back as -1.
        var ires: runtime.longInteger_t = undefined;
        runtime.longIntegerInit(&ires[0]);
        runtime.uInt32ToLongInteger(@intFromBool(res), &ires[0]);
        runtime.convertLongIntegerToLongIntegerRegister(&ires[0], runtime.REGISTER_X);
        runtime.longIntegerFree(&ires[0]);
        return;
    }

    var real_result = runtime.realFromBoolean(res);
    var imag_result = runtime.zeroReal();

    if (xtype == runtime.dtComplex34 or ytype == runtime.dtComplex34) {
        runtime.convertComplexPartsToResultRegister(&real_result, &imag_result, runtime.REGISTER_X);
    } else {
        runtime.convertRealToResultRegister(&real_result, runtime.REGISTER_X, runtime.amNone);
    }
}

fn dyadicLogicalOp(table: [4]u8) void {
    var cx: runtime.cplx_t = .{ .Real = runtime.zeroReal(), .Imag = runtime.zeroReal() };
    var cy: runtime.cplx_t = .{ .Real = runtime.zeroReal(), .Imag = runtime.zeroReal() };

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &cx) or
        !runtime.getRegisterAsComplex(runtime.REGISTER_Y, &cy))
    {
        return;
    }

    const x = !runtime.isRealZero(&cx.Real) or !runtime.isRealZero(&cx.Imag);
    const y = !runtime.isRealZero(&cy.Real) or !runtime.isRealZero(&cy.Imag);
    const table_index: usize = @intFromBool(x) + 2 * @as(usize, @intFromBool(y));
    const res = table[table_index] != 0;

    logicalOpResult(res, runtime.getRegisterDataType(runtime.REGISTER_X), runtime.getRegisterDataType(runtime.REGISTER_Y));
}

fn andCplx() callconv(.c) void {
    dyadicLogicalOp(.{ 0, 0, 0, 1 });
}

fn andShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* &= runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*;
    runtime.setRegisterShortIntegerBase(runtime.REGISTER_X, runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y));
}

fn orCplx() callconv(.c) void {
    dyadicLogicalOp(.{ 0, 1, 1, 1 });
}

fn orShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* |= runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*;
    runtime.setRegisterShortIntegerBase(runtime.REGISTER_X, runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y));
}

fn xorCplx() callconv(.c) void {
    dyadicLogicalOp(.{ 0, 1, 1, 0 });
}

fn xorShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* ^= runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*;
    runtime.setRegisterShortIntegerBase(runtime.REGISTER_X, runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y));
}

fn nandCplx() callconv(.c) void {
    dyadicLogicalOp(.{ 1, 1, 1, 0 });
}

fn nandShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = ~(runtime.registerShortIntegerPtr(runtime.REGISTER_X).* & runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*) & runtime.shortIntegerMask;
    runtime.setRegisterShortIntegerBase(runtime.REGISTER_X, runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y));
}

fn norCplx() callconv(.c) void {
    dyadicLogicalOp(.{ 1, 0, 0, 0 });
}

fn norShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = ~(runtime.registerShortIntegerPtr(runtime.REGISTER_X).* | runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*) & runtime.shortIntegerMask;
    runtime.setRegisterShortIntegerBase(runtime.REGISTER_X, runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y));
}

fn xnorCplx() callconv(.c) void {
    dyadicLogicalOp(.{ 1, 0, 0, 1 });
}

fn xnorShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = ~(runtime.registerShortIntegerPtr(runtime.REGISTER_X).* ^ runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*) & runtime.shortIntegerMask;
    runtime.setRegisterShortIntegerBase(runtime.REGISTER_X, runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y));
}

fn notCplx() callconv(.c) void {
    var x: runtime.cplx_t = .{ .Real = runtime.zeroReal(), .Imag = runtime.zeroReal() };
    const xtype = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    logicalOpResult(runtime.isRealZero(&x.Real) and runtime.isRealZero(&x.Imag), xtype, xtype);
}

fn notShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = ~runtime.registerShortIntegerPtr(runtime.REGISTER_X).* & runtime.shortIntegerMask;
}

pub export fn fnLogicalAnd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(null, &andCplx, &andShoI, null);
}

pub export fn fnLogicalOr(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(null, &orCplx, &orShoI, null);
}

pub export fn fnLogicalXor(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(null, &xorCplx, &xorShoI, null);
}

pub export fn fnLogicalNand(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(null, &nandCplx, &nandShoI, null);
}

pub export fn fnLogicalNor(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(null, &norCplx, &norShoI, null);
}

pub export fn fnLogicalXnor(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(null, &xnorCplx, &xnorShoI, null);
}

pub export fn fnLogicalNot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(null, &notCplx, &notShoI, null);
}
