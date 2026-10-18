// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the euclidean-norm commands of src/c47/mathematics/matrix.c:
// fnVectorDist, with its worker _fnEuclideanNorm (kept private here). The
// sibling fnEuclideanNorm went with upstream's "remove two functions the tree
// no longer calls": no item row and no caller ever reached it. The numeric
// p-norm is the already Zig-owned euclideanNormRealMatrix /
// euclideanNormComplexMatrix; these are the command-level wrappers that link
// register X, drive the norm and store the scalar result. fnVectorDist between
// two matrices of one shape is the Euclidean distance |Y - X| kept at 39 digits
// until the result is stored; with a scalar operand it is subtract then 2-norm.

const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");
const abi = @import("abi");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;
const std_cross = "\x80\xd7";

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    return std.mem.printSentinel(buffer, format, args, 0);
}

// Exported (was file-local) so fnPNorm in the MIM-commands owner can dispatch
// to it; _fnEuclideanNorm is static in matrix.c so there is no symbol clash.
pub export fn _fnEuclideanNorm(p_param: u16) callconv(.c) void {
    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (data_type == runtime.dtReal34Matrix) {
        var matrix: real34Matrix_t = undefined;
        var sum: real34_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &matrix);
        runtime.euclideanNormRealMatrix(&matrix, p_param, &sum);
        // `matrix` invalidates here.
        runtime.convertReal34ToReal34Register(&sum, runtime.REGISTER_X);
    } else if (data_type == runtime.dtComplex34Matrix) {
        var matrix: complex34Matrix_t = undefined;
        var sum: real34_t = undefined;
        runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &matrix);
        runtime.euclideanNormComplexMatrix(&matrix, p_param, &sum);
        // `matrix` invalidates here.
        runtime.convertReal34ToReal34Register(&sum, runtime.REGISTER_X);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [64]u8 = undefined;
            const message = bufPrintZ(&buffer, "DataType {d}", .{data_type}) catch "DataType";
            runtime.moreInfoOnError("In function _fnEuclideanNorm:", message, "is not a matrix.", "");
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
}

// The element block of the matrix a register holds, read as either kind.
const MatrixOperand = struct {
    is_complex: bool,
    real: [*]const real34_t,
    complex: [*]const complex34_t,

    fn link(reg: runtime.calcRegister_t, data_type: u32) MatrixOperand {
        if (data_type == runtime.dtReal34Matrix) {
            var m: real34Matrix_t = undefined;
            runtime.linkToRealMatrixRegister(reg, &m);
            const elems = abi.matrixConstRealElems(&m);
            return .{ .is_complex = false, .real = elems, .complex = @ptrCast(elems) };
        }
        var m: complex34Matrix_t = undefined;
        runtime.linkToComplexMatrixRegister(reg, &m);
        const elems = abi.matrixConstComplexElems(&m);
        return .{ .is_complex = true, .real = @ptrCast(elems), .complex = elems };
    }

    fn element(self: MatrixOperand, index: usize, value: *cplx_t) void {
        if (self.is_complex) {
            runtime.real34ToReal(&self.complex[index].real, &value.Real);
            runtime.real34ToReal(&self.complex[index].imag, &value.Imag);
        } else {
            runtime.real34ToReal(&self.real[index], &value.Real);
            runtime.realSetZero(&value.Imag);
        }
    }
};

// The 39-digit magnitude of one element difference Y[i] - X[i]. A real matrix
// supplies an exact zero imaginary part; both component differences stay wide,
// with no Real34 conversion between the subtraction and the magnitude.
fn matrixElementDifferenceMagnitude(y: MatrixOperand, x: MatrixOperand, element: usize, magnitude: *real_t) void {
    var y_element: cplx_t = undefined;
    var x_element: cplx_t = undefined;

    y.element(element, &y_element);
    x.element(element, &x_element);

    runtime.realSubtract(&y_element.Real, &x_element.Real, &y_element.Real, &runtime.ctxtReal39);
    if (!y.is_complex and !x.is_complex) {
        runtime.realSetPositiveSign(&y_element.Real);
        realCopy(&y_element.Real, magnitude);
    } else {
        runtime.realSubtract(&y_element.Imag, &x_element.Imag, &y_element.Imag, &runtime.ctxtReal39);
        runtime.complexMagnitude(&y_element, magnitude, &runtime.ctxtReal39);
    }
}

// The Euclidean distance between two equally shaped real or complex matrices.
// Component differences, scaling, the non-negative sum and the closing square
// root remain at 39 digits until the public Real34 conversion.
fn matrixEuclideanDistance(y: MatrixOperand, x: MatrixOperand, elements: usize, distance: *real_t) void {
    var element_magnitude: real_t = undefined;
    var scale: real_t = undefined;
    var sum: real_t = undefined;

    runtime.realSetZero(&scale);
    var i: usize = 0;
    while (i < elements) : (i += 1) {
        matrixElementDifferenceMagnitude(y, x, i, &element_magnitude);
        if (runtime.realIsNaN(&element_magnitude)) {
            realCopy(&element_magnitude, distance);
            return;
        }
        if (runtime.realCompareGreaterThan(&element_magnitude, &scale)) {
            realCopy(&element_magnitude, &scale);
        }
    }
    if (runtime.realIsInfinite(&scale) or runtime.realIsZero(&scale)) {
        realCopy(&scale, distance);
        return;
    }

    runtime.realSetZero(&sum);
    i = 0;
    while (i < elements) : (i += 1) {
        matrixElementDifferenceMagnitude(y, x, i, &element_magnitude);
        runtime.realDivide(&element_magnitude, &scale, &element_magnitude, &runtime.ctxtReal39);
        runtime.realFMA(&element_magnitude, &element_magnitude, &sum, &sum, &runtime.ctxtReal39);
    }
    runtime.realSquareRoot(&sum, distance, &runtime.ctxtReal39);
    runtime.realMultiply(&scale, distance, distance, &runtime.ctxtReal39);
}

pub export fn fnVectorDist(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    const x_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const y_type = runtime.getRegisterDataType(runtime.REGISTER_Y);
    var distance: real_t = undefined;

    if ((x_type != runtime.dtReal34Matrix and x_type != runtime.dtComplex34Matrix) or (y_type != runtime.dtReal34Matrix and y_type != runtime.dtComplex34Matrix)) {
        runtime.fnSubtract(runtime.NOPARAM);
        _fnEuclideanNorm(2);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    const x_header = runtime.registerMatrixHeader(runtime.REGISTER_X);
    const y_header = runtime.registerMatrixHeader(runtime.REGISTER_Y);
    if (x_header.matrixRows != y_header.matrixRows or x_header.matrixColumns != y_header.matrixColumns) {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [96]u8 = undefined;
            const message = bufPrintZ(&buffer, "cannot calculate the distance between {d}" ++ std_cross ++ "{d} and {d}" ++ std_cross ++ "{d} matrices", .{ y_header.matrixRows, y_header.matrixColumns, x_header.matrixRows, x_header.matrixColumns }) catch "cannot calculate the distance";
            runtime.moreInfoOnError("In function fnVectorDist:", message, null, null);
        }
    } else {
        const y = MatrixOperand.link(runtime.REGISTER_Y, y_type);
        const x = MatrixOperand.link(runtime.REGISTER_X, x_type);
        matrixEuclideanDistance(y, x, @as(usize, x_header.matrixRows) * x_header.matrixColumns, &distance);
        runtime.convertRealToResultRegister(&distance, runtime.REGISTER_X, runtime.amNone);
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, -1);
}
