const check_value_owned = @import("compare/check_value.zig");
const build_options = @import("math_command_wrappers_build_options");
const compare_owned = @import("compare/compare.zig");
const convergence_owned = @import("convergence.zig");
const integer_part_owned = @import("rounding/integer_part.zig");
const runtime = @import("command_wrappers/runtime.zig");
const get_type_owned = @import("compare/get_type.zig");
const projection_owned = @import("projection.zig");
const arithmetic_dispatch_command_owned = @import("arithmetic/dispatch_command.zig");
const atan2_command_owned = @import("trig/atan2_command.zig");
const double_width_command_owned = @import("arithmetic/double_width_command.zig");
const percent_base_owned = @import("arithmetic/percent_base.zig");
const percent_extended_owned = @import("arithmetic/percent_extended.zig");
const random_primitives_owned = @import("random/random_primitives.zig");
const random_real_owned = @import("random/random_real.zig");
const random_integer_owned = @import("random/random_integer.zig");
const random_seed_owned = @import("random/random_seed.zig");
const special_algebraic_command_owned = @import("special/special_algebraic_command.zig");
const increment_decrement_command_owned = @import("arithmetic/increment_decrement_command.zig");
const decomp_owned = @import("arithmetic/scalar_integer_decomp_command.zig");
const precision_owned = @import("rounding/scalar_integer_precision.zig");
const trig_complex_primitives_owned = @import("trig/trig_complex_primitives.zig");
const logxy_command_owned = @import("powerlog/logxy_command.zig");
const circular_trig_command_owned = @import("trig/circular_trig_command.zig");
const inverse_trig_command_owned = @import("trig/inverse_trig_command.zig");
const transcendental_command_owned = @import("special/transcendental_command.zig");
const powlog_log_owned = @import("powerlog/powlog_log.zig");
const powlog_power_owned = @import("powerlog/powlog_power.zig");
const invert_command_owned = @import("arithmetic/invert_command.zig");
const sign_command_owned = @import("arithmetic/sign_command.zig");
const exponent_bernoulli_command_owned = @import("special/exponent_bernoulli_command.zig");
const lambertw_command_owned = @import("special/lambertw_command.zig");
const integer_residue_command_owned = @import("arithmetic/integer_residue_command.zig");
const atan_owned = @import("trig/atan.zig");
const atan2_owned = @import("trig/atan2.zig");
const circular_trig_owned = @import("trig/circular_trig.zig");
const ln_complex_owned = @import("ln_complex.zig");
const real_trig_owned = @import("trig/real_trig.zig");
const erf_owned = @import("special/special_function_erf.zig");
const factorial_owned = @import("special/special_function_factorial.zig");
const fibonacci_owned = @import("special/special_function_fibonacci.zig");
const ixyz_owned = @import("special/special_function_ixyz.zig");
const matrix_vector_cross_matrix_owned = @import("matrix/vector_cross_matrix.zig");
const matrix_vector_cross_scalar_owned = @import("matrix/vector_cross_scalar.zig");
const matrix_vector_dot_matrix_owned = @import("matrix/vector_dot_matrix.zig");
const matrix_vector_dot_scalar_owned = @import("matrix/vector_dot_scalar.zig");
const matrix_vector_validation_owned = @import("matrix/vector_validation.zig");
const rectangular_to_polar_owned = @import("transform/rectangular_to_polar.zig");
const linpol_pipeline_owned = @import("matrix/vector_linpol_pipeline.zig");
const linpol_compute_owned = @import("matrix/vector_linpol_compute.zig");
const shift_digits_command_owned = @import("arithmetic/shift_digits_command.zig");
const parallel_command_owned = @import("transform/transform_parallel_command.zig");
const polar_rect_command_owned = @import("transform/transform_polar_rect_command.zig");
const power_command_owned = @import("transform/transform_power_command.zig");
const root_command_owned = @import("transform/transform_root_command.zig");
const unit_vector_command_owned = @import("transform/transform_unit_vector_command.zig");

comptime {
    // Force-include the ported mathematics owners so their pub export fns are
    // linked into the product (fnIsPrime/fnNextPrime/fnPrimeFactors/fnEvPFacts,
    // the WP34S C47_WP34S_*/WP34S_* engine, fnBeta/fnLnBeta/fnGd/fnInvGd/fnAgm/
    // fnCyx/fnPyx). These are EXCLUDED from the math_command_wrappers parity
    // harness (use_fake_wp34s_harness_surface): that harness links
    // math_wrappers_fake_runtime.c, which both duplicates the WP34S_* surface
    // (wp34s owner) and lacks the real_t/decNumber/longInteger symbols these
    // owners call — so including them there breaks the link. Their parity is the
    // testSuite (prime/beta/lnbeta/gd/agm/cyx/pyx + all trig/gamma), not this
    // fake-runtime harness.
    if (!runtime.harness_surface_is_fake) {
        // The transform/complex helper owner exports upstream symbol names
        // (sqrtComplex, realRectangularToPolar, ...) that the parity harness
        // already gets from math_wrappers_fake_runtime.c.
        _ = @import("transform/transform_complex_helpers.zig");
        // The compare/incDec cluster owners export the legacy fallback names
        // (z47_math_wrappers_legacy_fnXLessThan, ...) that the parity harness
        // gets from math_wrappers_legacy_link_stubs.c.
        _ = @import("compare/comparison_reals.zig");
        _ = @import("compare/register_compare.zig");
        // The addition/subtraction cell owners export the dispatch matrices
        // and every add*/sub* cell plus the z47_math_wrappers_legacy_fnAdd
        // and ..._fnSubtract fallback commands; the parity harness keeps its
        // link stubs and oracle copies instead.
        _ = @import("arithmetic/addition_cells.zig");
        _ = @import("arithmetic/subtraction_cells.zig");
        // The multiplication/division/integer-division cell owners export the
        // remaining arithmetic dispatch matrices and every mul*/div*/idiv*/
        // dbl*/round/decomp cell plus the z47_math_wrappers_legacy_fnMultiply,
        // ..._fnDivide, ..._fnIDiv, ..._fnIDivR, ..._fnDblMultiply,
        // ..._fnDblDivide, ..._fnDblDivideRemainder, ..._fnRound and
        // ..._fnDecomp fallback commands; the parity harness keeps its link
        // stubs and oracle copies instead.
        _ = @import("arithmetic/multiplication_cells.zig");
        _ = @import("arithmetic/division_cells.zig");
        _ = @import("arithmetic/integer_division_cells.zig");
        // The runtime-helper owners replace math_wrappers_runtime_helpers.c:
        // the z47_math_wrappers_* helper API (const accessors, domain-error
        // reporters, gcd/lcm/fib/factorial/mod/remainder/neighbour helpers,
        // sign/integer-part helpers) and the thin real/real34 wrapper symbols.
        // The parity harness compiles the relocated C file instead, so these
        // owners are excluded there to avoid duplicate symbols.
        _ = @import("command_wrappers/helpers.zig");
        _ = @import("command_wrappers/error_reporters.zig");
        // The matrix lifecycle owner replaces the allocate/free/identity/redim,
        // copy and transpose primitives of mathematics/matrix.c. The matrix
        // bridge keeps the renamed legacy copies (still called by the rest of
        // the not-yet-ported matrix engine); the parity harness has its own
        // matrix surface in math_wrappers_fake_runtime.c.
        _ = @import("matrix/lifecycle.zig");
        // The matrix arithmetic owner replaces the elementwise add/subtract and
        // scalar-multiply functions of mathematics/matrix.c (the matrix*matrix
        // products, divide family and vector ops stay in the bridge for now).
        _ = @import("matrix/arithmetic.zig");
        // The matrix-by-matrix product owner replaces multiplyRealMatrices and
        // multiplyComplexMatrices of mathematics/matrix.c.
        _ = @import("matrix/product.zig");
        // The matrix-by-scalar divide owner replaces divideRealMatrix and
        // divideComplexMatrix (and their _-prefixed real_t variants).
        _ = @import("matrix/divide_scalar.zig");
        // The matrix swap owner replaces realMatrixSwapRows / realMatrixSwapColumns
        // and complexMatrixSwapRows / complexMatrixSwapColumns of mathematics/matrix.c.
        _ = @import("matrix/swap.zig");
        // The matrix insert owner replaces insRowRealMatrix / insColRealMatrix
        // and insRowComplexMatrix / insColComplexMatrix of mathematics/matrix.c.
        _ = @import("matrix/insert.zig");
        // The matrix delete owner replaces delRowRealMatrix / delColRealMatrix
        // and delRowComplexMatrix / delColComplexMatrix of mathematics/matrix.c.
        _ = @import("matrix/delete.zig");
        // The euclidean-norm owner replaces realVectorSize / complexVectorSize
        // and euclideanNormRealMatrix / euclideanNormComplexMatrix (with the
        // shared worker _euclideanNormRealMatrix) of mathematics/matrix.c.
        _ = @import("matrix/euclidean_norm.zig");
        // The dot-product owner replaces dotRealVectors / dotComplexVectors
        // (with the shared worker _dotRealVectors) of mathematics/matrix.c.
        _ = @import("matrix/dot.zig");
        // The cross-product owner replaces crossRealVectors / crossComplexVectors
        // of mathematics/matrix.c.
        _ = @import("matrix/cross.zig");
        // The vector-angle owner replaces vectorAngle of mathematics/matrix.c;
        // it reuses the Zig-owned _dotRealVectors / _euclideanNormRealMatrix.
        _ = @import("matrix/vector_angle.zig");
        // The determinant owner replaces detRealMatrix / detComplexMatrix of
        // mathematics/matrix.c (the complex LU workers are private to it).
        _ = @import("matrix/determinant.zig");
        // The register-link owner replaces linkToRealMatrixRegister /
        // linkToComplexMatrixRegister of mathematics/matrix.c.
        _ = @import("matrix/register_link.zig");
        // The matrix fn* command owners replace the register-level command
        // wrappers of mathematics/matrix.c (fnTranspose, ...).
        _ = @import("matrix/transpose_command.zig");
        _ = @import("matrix/determinant_command.zig");
        _ = @import("matrix/vector_angle_command.zig");
        _ = @import("matrix/euclidean_norm_command.zig");
        _ = @import("matrix/invert_command.zig");
        _ = @import("matrix/identity_command.zig");
        _ = @import("matrix/lu_command.zig");
        _ = @import("matrix/qr_command.zig");
        _ = @import("matrix/new_command.zig");
        _ = @import("matrix/set_dimensions_command.zig");
        // The complex dense core owner exports invCpxMat / mulCpxMat (LU-based
        // inverse and product on interleaved-complex real_t arrays) for the
        // matrix-divide and inverse owners. The upstream copies are file-local
        // statics, so no bridge rename is needed.
        _ = @import("matrix/complex_core.zig");
        // The matrix-by-matrix divide owner replaces divideRealMatrices /
        // divideComplexMatrices (y * inverse(x)) via the dense core.
        _ = @import("matrix/divide_matrices.zig");
        // The matrix inverse owner replaces invertRealMatrix /
        // invertComplexMatrix via the dense core.
        _ = @import("matrix/invert.zig");
        // The real LU owner replaces WP34S_LU_decomposition of mathematics/matrix.c.
        _ = @import("matrix/real_lu.zig");
        // The complex LU owner replaces complex_LU_decomposition of
        // mathematics/matrix.c (it reuses the Zig dense-core luCpxMat).
        _ = @import("matrix/complex_lu.zig");
        // The dimension-arg owner replaces getMatrixDims and getDimensionArg
        // (with the static worker getSingleDimension) of mathematics/matrix.c.
        _ = @import("matrix/dimension_arg.zig");
        // The named-matrix owner replaces allocateNamedMatrix and
        // appendRowAtMatrixRegister of mathematics/matrix.c.
        _ = @import("matrix/named.zig");
        // The register-memory owner replaces initMatrixRegister and
        // redimMatrixRegister (the matrix-register allocate/reshape core) of
        // mathematics/matrix.c.
        _ = @import("matrix/register_memory.zig");
        // The coordinate-conversions owner replaces the OPTION_VECTOR
        // rectangular <-> spherical/cylindrical/polar helpers of
        // mathematics/matrix.c.
        _ = @import("matrix/coordinate_conversions.zig");
        // The vector-helpers owner replaces the OPTION_VECTOR V3err error
        // reporter and VtoAngleMode of mathematics/matrix.c.
        _ = @import("matrix/vector_helpers.zig");
        // The eigen owner replaces the eigenvalue/eigenvector/matrix-sqrt
        // numeric engine of mathematics/matrix.c (built up bottom-up).
        _ = @import("matrix/eigen.zig");
        // The element-wise dispatch family + indexed-element dispatchers
        // (callByVectorElement/callByIndexedMatrix) of mathematics/matrix.c.
        _ = @import("matrix/elementwise.zig");
        // The MIM-routed commands (fnGetMatrix/fnPutMatrix/fnSwapRows/
        // fnSwapColumns/fnRowColSum/fnPNorm + getMatrixFromRegister).
        _ = @import("matrix/mim_commands.zig");
        // The simultaneous-linear-equation cluster (SIMQ + Mat_A/B/X editors +
        // real/complex_matrix_linear_eqn solvers).
        _ = @import("matrix/linear_eqn.zig");
        // Column min/max + matrix-find indexed commands.
        _ = @import("matrix/column_commands.zig");
        // Residual OPTION_VECTOR commands: is_2D3D_Register_Ready +
        // V3RectoToSph / V3RectoToCyl.
        _ = @import("matrix/vector3d.zig");
        // The stats-matrix owner replaces saveStatsMatrix / recallStatsMatrix
        // (the STATS undo backup/restore) of mathematics/matrix.c.
        _ = @import("matrix/stats.zig");
        // The get-dimensions command owner replaces fnGetMatrixDimensions /
        // fnGetMatrixDimensions42 of mathematics/matrix.c.
        _ = @import("matrix/get_dimensions_command.zig");
        // The matrix-index owner replaces isMatrixIndexed and fnIndexMatrix of
        // mathematics/matrix.c.
        _ = @import("matrix/index_command.zig");
        _ = @import("number_theory/prime.zig");
        _ = @import("special/wp34s.zig");
        _ = @import("special/cpyx.zig");
        _ = @import("special/agm.zig");
        _ = @import("special/gd.zig");
        _ = @import("special/lnbeta.zig");
        _ = @import("special/beta.zig");
        _ = @import("special/gamma.zig");
        _ = @import("special/zeta.zig");
        _ = @import("transform/retocx.zig");
        _ = @import("cxtore.zig");
        _ = @import("special/gammaX.zig");
        _ = @import("powerlog/power.zig");
        _ = @import("powerlog/xthroot.zig");
        _ = @import("number_theory/opmod.zig");
        _ = @import("special/bessel.zig");
        _ = @import("special/elliptic.zig");
        _ = @import("special/xfn.zig");
        _ = @import("slvc.zig");
        _ = @import("slvp.zig");
        _ = @import("slvq.zig");
        _ = @import("rounding/rsd.zig");
        _ = @import("rounding/rdp.zig");
        _ = @import("special/ortho_polynom.zig");
        _ = @import("arithmetic/percentSigma.zig");
        _ = @import("statistics/mean.zig");
        _ = @import("statistics/median.zig");
        _ = @import("statistics/variance.zig");
        _ = @import("statistics/deltaPercentXmean.zig");
        _ = @import("iteration.zig");
        _ = @import("arithmetic/percentSigmaDeltaPercentXmean.zig");
    }
}

const PowRealFn = *const fn (x: *const runtime.real_t, res: *runtime.real_t, real_context: *runtime.realContext_t) callconv(.c) void;
const no_register = @as(runtime.calcRegister_t, -1);

pub export fn z47_math_wrappers_owned_C47_WP34S_Atan2(
    y: *const runtime.real_t,
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    atan2_owned.arctan2Real(y, x, angle, real_context);
}

pub export fn z47_math_wrappers_owned_C47_WP34S_Atan(
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    atan_owned.arctanReal(x, angle, real_context);
}

pub export fn z47_math_wrappers_owned_realRectangularToPolar(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    magnitude: *runtime.real_t,
    theta: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    rectangular_to_polar_owned.rectangularToPolarReal(real, imag, magnitude, theta, real_context);
}

pub export fn z47_math_wrappers_owned_C47_WP34S_Cvt2RadSinCosTan(
    angle: *const runtime.real_t,
    mode: runtime.angularMode_t,
    sin: ?*runtime.real_t,
    cos: ?*runtime.real_t,
    tan: ?*runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    circular_trig_owned.convertAngleToSinCosTan(angle, mode, sin, cos, tan, real_context);
}

pub export fn z47_math_wrappers_owned_lnComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    ln_real: *runtime.real_t,
    ln_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    ln_complex_owned.lnComplex(real, imag, ln_real, ln_imag, real_context);
}

fn publicLnComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    ln_real: *runtime.real_t,
    ln_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    ln_complex_owned.lnComplex(real, imag, ln_real, ln_imag, real_context);
}

comptime {
    if (build_options.export_public_ln_complex) {
        @export(&publicLnComplex, .{ .name = "lnComplex" });
    }
}

pub export fn z47_math_wrappers_owned_C47_WP34S_Asin(
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    real_trig_owned.arcsinReal(x, angle, real_context);
}

pub export fn z47_math_wrappers_owned_C47_WP34S_Acos(
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    real_trig_owned.arccosReal(x, angle, real_context);
}

pub export fn z47_math_wrappers_owned_WP34S_SinhCosh(
    x: *const runtime.real_t,
    sinh_out: ?*runtime.real_t,
    cosh_out: ?*runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    real_trig_owned.sinhCoshReal(x, sinh_out, cosh_out, real_context);
}

pub export fn z47_math_wrappers_owned_WP34S_Tanh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    real_trig_owned.tanhReal(x, res, real_context);
}

pub export fn z47_math_wrappers_owned_WP34S_ArcSinh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    real_trig_owned.arcsinhReal(x, res, real_context);
}

pub export fn z47_math_wrappers_owned_WP34S_ArcTanh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    real_trig_owned.arctanhReal(x, res, real_context);
}

fn realLog10Value(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    transcendental_command_owned.lnRealValue(x, res, real_context);
    runtime.realDivide(res, runtime.z47_math_wrappers_const_ln10(), res, real_context);
}

fn realPower10Value(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    runtime.realMultiply(x, runtime.z47_math_wrappers_const_ln10(), res, real_context);
    transcendental_command_owned.realExp(res, res, real_context);
}

fn realPower2Value(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    runtime.realMultiply(x, runtime.z47_math_wrappers_const_ln2(), res, real_context);
    transcendental_command_owned.realExp(res, res, real_context);
}

fn intPowRealValue(powf: PowRealFn) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsSpecial(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_int_pow_real_domain_error();
        return;
    }

    powf(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn intPowCplxValue(ln_base: *const runtime.real_t) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var factor: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.realMultiply(ln_base, &a, &a, &runtime.ctxtReal39);
    runtime.realMultiply(ln_base, &b, &b, &runtime.ctxtReal39);

    transcendental_command_owned.realExp(&a, &factor, &runtime.ctxtReal39);
    runtime.realPolarToRectangular(runtime.z47_math_wrappers_const_1(), &b, &a, &b, &runtime.ctxtReal39);
    runtime.realMultiply(&factor, &a, &a, &runtime.ctxtReal39);
    runtime.realMultiply(&factor, &b, &b, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}
pub export fn pcg32_random_r(rng: *runtime.pcg32_random_t) callconv(.c) u32 {
    return random_primitives_owned.pcg32RandomR(rng);
}

pub export fn pcg32_srandom_r(rng: *runtime.pcg32_random_t, initstate: u64, initseq: u64) callconv(.c) void {
    random_primitives_owned.pcg32SrandomR(rng, initstate, initseq);
}

pub export fn pcg32_srandom(seed: u64, seq: u64) callconv(.c) void {
    random_primitives_owned.pcg32Srandom(seed, seq);
}

pub export fn z47_math_wrappers_bounded_rand(s: u32) callconv(.c) u32 {
    return random_primitives_owned.boundedRandExport(s);
}

pub export fn realRandomU01(res: *runtime.real_t) callconv(.c) void {
    random_primitives_owned.realRandomU01(res);
}

pub export fn sinComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    trig_complex_primitives_owned.sinComplex(real, imag, res_real, res_imag, real_context);
}

pub export fn cosComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    trig_complex_primitives_owned.cosComplex(real, imag, res_real, res_imag, real_context);
}

pub export fn sinCosReal(trig_type: runtime.trigType_t) callconv(.c) void {
    trig_complex_primitives_owned.sinCosReal(trig_type);
}

pub export fn sinCosCplx(trig_type: runtime.trigType_t) callconv(.c) void {
    trig_complex_primitives_owned.sinCosCplx(trig_type);
}

pub export fn sinhCoshReal(trig_type: runtime.trigType_t) callconv(.c) void {
    trig_complex_primitives_owned.sinhCoshReal(trig_type);
}

pub export fn sinhCoshCplx(trig_type: runtime.trigType_t) callconv(.c) void {
    trig_complex_primitives_owned.sinhCoshCplx(trig_type);
}

pub export fn TanComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return trig_complex_primitives_owned.TanComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub export fn TanhComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return trig_complex_primitives_owned.TanhComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub export fn realExpLimitCheck(
    x: *const runtime.real_t,
    result: *runtime.real_t,
    zero: *const runtime.real_t,
) callconv(.c) bool {
    return transcendental_command_owned.realExpLimitCheck(x, result, zero);
}

pub export fn realExp(
    x: *const runtime.real_t,
    result: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    transcendental_command_owned.realExp(x, result, real_context);
}

pub export fn expComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    transcendental_command_owned.expComplex(real, imag, res_real, res_imag, real_context);
}

pub export fn realExpM1(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    transcendental_command_owned.realExpM1(x, res, real_context);
}

pub export fn realLog10(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    realLog10Value(x, res, real_context);
}

pub export fn realPower10(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    realPower10Value(x, res, real_context);
}

pub export fn realPower2(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    realPower2Value(x, res, real_context);
}

pub export fn intPowReal(powf: PowRealFn) callconv(.c) void {
    intPowRealValue(powf);
}

pub export fn intPowCplx(ln_base: *const runtime.real_t) callconv(.c) void {
    intPowCplxValue(ln_base);
}

pub export fn logxyReal(denom: *const runtime.real_t) callconv(.c) void {
    logxy_command_owned.logxyReal(denom);
}

pub export fn logxyCplx(denom: *const runtime.real_t) callconv(.c) void {
    logxy_command_owned.logxyCplx(denom);
}

pub export fn logxyLonI(denom: *const runtime.real_t) callconv(.c) void {
    logxy_command_owned.logxyLonI(denom);
}

pub export fn sqrt1Px2Complex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    special_algebraic_command_owned.sqrt1Px2Complex(real, imag, res_real, res_imag, real_context);
}

pub export fn eulersFormula(
    in_real: *const runtime.real_t,
    in_imag: *const runtime.real_t,
    out_real: *runtime.real_t,
    out_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    special_algebraic_command_owned.eulersFormula(in_real, in_imag, out_real, out_imag, real_context);
}

pub export fn fnSqrt1Px2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_algebraic_command_owned.fnSqrt1Px2(unused_but_mandatory_parameter);
}

pub export fn fnM1Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_algebraic_command_owned.fnM1Pow(unused_but_mandatory_parameter);
}

pub export fn fnEulersFormula(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_algebraic_command_owned.fnEulersFormula(unused_but_mandatory_parameter);
}

pub export fn integerPartNoOp() callconv(.c) void {
    integer_part_owned.integerPartNoOp();
}

pub export fn integerPartReal(mode: runtime.rounding_t) callconv(.c) void {
    integer_part_owned.integerPartReal(mode);
}

pub export fn integerPartCplx(mode: runtime.rounding_t) callconv(.c) void {
    integer_part_owned.integerPartCplx(mode);
}

pub export fn ArcsinComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_command_owned.ArcsinComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub export fn ArctanComplex(
    x_real: *runtime.real_t,
    x_imag: *runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_command_owned.ArctanComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub export fn ArcsinhReal(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_command_owned.ArcsinhReal(x, res, real_context);
}

pub export fn ArcsinhComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_command_owned.ArcsinhComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub export fn realArcosh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    inverse_trig_command_owned.realArcosh(x, res, real_context);
}

pub export fn chsReal() callconv(.c) void {
    sign_command_owned.chsReal();
}

pub export fn chsCplx() callconv(.c) void {
    sign_command_owned.chsCplx();
}

pub export fn chsShoI() callconv(.c) void {
    sign_command_owned.chsShoI();
}

fn chsLonI() callconv(.c) void {
    sign_command_owned.chsLonI();
}

pub export fn fnRandom(unused_but_mandatory_parameter: u16) callconv(.c) void {
    random_real_owned.random(unused_but_mandatory_parameter);
}

pub export fn fnRandomI(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&random_real_owned.doRealRandomI, null, null, &random_integer_owned.doIntRandomI);
}

pub export fn fnSeed(unused_but_mandatory_parameter: u16) callconv(.c) void {
    random_seed_owned.seed(unused_but_mandatory_parameter);
}

pub export fn fnMin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.min(unused_but_mandatory_parameter);
}

pub export fn fnMax(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.max(unused_but_mandatory_parameter);
}

pub export fn fnCeil(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.ceil(unused_but_mandatory_parameter);
}

pub export fn fnFloor(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.floor(unused_but_mandatory_parameter);
}

pub export fn fnIp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.ip(unused_but_mandatory_parameter);
}

pub export fn fnLint(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.lint(unused_but_mandatory_parameter);
}

pub export fn fnSint(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.sint(unused_but_mandatory_parameter);
}

pub export fn fnFp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.fp(unused_but_mandatory_parameter);
}

pub export fn fnSinc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    @import("special/sinc_command.zig").fnSinc(unused_but_mandatory_parameter);
}

pub export fn fnSincpi(unused_but_mandatory_parameter: u16) callconv(.c) void {
    @import("special/sinc_command.zig").fnSincpi(unused_but_mandatory_parameter);
}

pub export fn fnSin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    circular_trig_command_owned.fnSin(unused_but_mandatory_parameter);
}

pub export fn fnCos(unused_but_mandatory_parameter: u16) callconv(.c) void {
    circular_trig_command_owned.fnCos(unused_but_mandatory_parameter);
}

pub export fn fnTan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    circular_trig_command_owned.fnTan(unused_but_mandatory_parameter);
}

pub export fn fnArcsin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    inverse_trig_command_owned.fnArcsin(unused_but_mandatory_parameter);
}

pub export fn fnArccos(unused_but_mandatory_parameter: u16) callconv(.c) void {
    inverse_trig_command_owned.fnArccos(unused_but_mandatory_parameter);
}

pub export fn fnArctan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    inverse_trig_command_owned.fnArctan(unused_but_mandatory_parameter);
}

pub export fn fnArcsinh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    inverse_trig_command_owned.fnArcsinh(unused_but_mandatory_parameter);
}

pub export fn fnArccosh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    inverse_trig_command_owned.fnArccosh(unused_but_mandatory_parameter);
}

pub export fn fnArctanh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    inverse_trig_command_owned.fnArctanh(unused_but_mandatory_parameter);
}

pub export fn fnSinh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    circular_trig_command_owned.fnSinh(unused_but_mandatory_parameter);
}

pub export fn fnCosh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    circular_trig_command_owned.fnCosh(unused_but_mandatory_parameter);
}

pub export fn fnTanh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    circular_trig_command_owned.fnTanh(unused_but_mandatory_parameter);
}

pub export fn fnExp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transcendental_command_owned.exp(unused_but_mandatory_parameter);
}

pub export fn fnExpM1(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transcendental_command_owned.expM1(unused_but_mandatory_parameter);
}

pub export fn fnLn(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transcendental_command_owned.ln(unused_but_mandatory_parameter);
}

pub export fn fnLnP1(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transcendental_command_owned.lnP1(unused_but_mandatory_parameter);
}

pub export fn fnErf(unused_but_mandatory_parameter: u16) callconv(.c) void {
    erf_owned.fnErf(unused_but_mandatory_parameter);
}

pub export fn fnErfc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    erf_owned.fnErfc(unused_but_mandatory_parameter);
}

pub export fn fn2Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    powlog_power_owned.fn2Pow(unused_but_mandatory_parameter);
}

pub export fn fn10Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    powlog_power_owned.fn10Pow(unused_but_mandatory_parameter);
}

pub export fn fnLog10(unused_but_mandatory_parameter: u16) callconv(.c) void {
    powlog_log_owned.fnLog10(unused_but_mandatory_parameter);
}

pub export fn fnLog2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    powlog_log_owned.fnLog2(unused_but_mandatory_parameter);
}

pub export fn fnInvert(unused_but_mandatory_parameter: u16) callconv(.c) void {
    invert_command_owned.invert(unused_but_mandatory_parameter);
}

pub export fn fnSign(unused_but_mandatory_parameter: u16) callconv(.c) void {
    sign_command_owned.sign(unused_but_mandatory_parameter);
}

pub export fn fnChangeSign(unused_but_mandatory_parameter: u16) callconv(.c) void {
    sign_command_owned.changeSign(unused_but_mandatory_parameter);
}

pub export fn fnSquare(unused_but_mandatory_parameter: u16) callconv(.c) void {
    power_command_owned.square(unused_but_mandatory_parameter);
}

pub export fn fnCube(unused_but_mandatory_parameter: u16) callconv(.c) void {
    power_command_owned.cube(unused_but_mandatory_parameter);
}

pub export fn fnBn(unused_but_mandatory_parameter: u16) callconv(.c) void {
    exponent_bernoulli_command_owned.bn(unused_but_mandatory_parameter);
}

pub export fn fnBnStar(unused_but_mandatory_parameter: u16) callconv(.c) void {
    exponent_bernoulli_command_owned.bnStar(unused_but_mandatory_parameter);
}

pub export fn fnExpt(unused_but_mandatory_parameter: u16) callconv(.c) void {
    exponent_bernoulli_command_owned.expt(unused_but_mandatory_parameter);
}

pub export fn fnWpositive(unused_but_mandatory_parameter: u16) callconv(.c) void {
    lambertw_command_owned.fnWpositive(unused_but_mandatory_parameter);
}

pub export fn fnWnegative(unused_but_mandatory_parameter: u16) callconv(.c) void {
    lambertw_command_owned.fnWnegative(unused_but_mandatory_parameter);
}

pub export fn fnWinverse(unused_but_mandatory_parameter: u16) callconv(.c) void {
    lambertw_command_owned.fnWinverse(unused_but_mandatory_parameter);
}

pub export fn fnGcd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_residue_command_owned.fnGcd(unused_but_mandatory_parameter);
}

pub export fn fnLcm(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_residue_command_owned.fnLcm(unused_but_mandatory_parameter);
}

pub export fn fnMod(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_residue_command_owned.fnMod(unused_but_mandatory_parameter);
}

pub export fn fnRmd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_residue_command_owned.fnRmd(unused_but_mandatory_parameter);
}

pub export fn fnUlp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    precision_owned.fnUlp(unused_but_mandatory_parameter);
}

pub export fn fnMant(unused_but_mandatory_parameter: u16) callconv(.c) void {
    precision_owned.fnMant(unused_but_mandatory_parameter);
}

pub export fn fnRoundi(unused_but_mandatory_parameter: u16) callconv(.c) void {
    precision_owned.fnRoundi(unused_but_mandatory_parameter);
}

pub export fn fnNeighb(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_residue_command_owned.fnNeighb(unused_but_mandatory_parameter);
}

pub export fn fnIxyz(unused_but_mandatory_parameter: u16) callconv(.c) void {
    ixyz_owned.fnIxyz(unused_but_mandatory_parameter);
}

pub export fn fnFactorial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    factorial_owned.fnFactorial(unused_but_mandatory_parameter);
}

pub export fn fnRealPart(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.realPart();
}

pub export fn fnImaginaryPart(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.imaginaryPart();
}

pub export fn fnArg(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.arg();
}

pub export fn fnMagnitude(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.magnitude();
}

pub export fn fnConjugate(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.conjugate();
}

pub export fn fnSwapRealImaginary(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.swapRealImaginary();
}

pub export fn fnAtan2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    atan2_command_owned.atan2(unused_but_mandatory_parameter);
}

pub export fn fnPercent(unused_but_mandatory_parameter: u16) callconv(.c) void {
    percent_base_owned.percent(unused_but_mandatory_parameter);
}

pub export fn fnAdd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnAdd(unused_but_mandatory_parameter);
}

pub export fn fnSubtract(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnSubtract(unused_but_mandatory_parameter);
}

pub export fn fnMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnMultiply(unused_but_mandatory_parameter);
}

pub export fn fnDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnDivide(unused_but_mandatory_parameter);
}

pub export fn fnIDiv(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnIDiv(unused_but_mandatory_parameter);
}

pub export fn fnIDivR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnIDivR(unused_but_mandatory_parameter);
}

pub export fn fnDblMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    double_width_command_owned.dblMultiply(unused_but_mandatory_parameter);
}

pub export fn fnRound(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (register_data_type != runtime.dtLongInteger and register_data_type != runtime.dtShortInteger) {
        runtime.legacy.fnRound(unused_but_mandatory_parameter);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnCheckInteger(mode: u16) callconv(.c) void {
    check_value_owned.checkInteger(mode);
}

pub export fn fnDecomp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    decomp_owned.decomp(unused_but_mandatory_parameter);
}

pub export fn fnDec(unused_but_mandatory_parameter: u16) callconv(.c) void {
    increment_decrement_command_owned.dec(unused_but_mandatory_parameter);
}

pub export fn fnInc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    increment_decrement_command_owned.inc(unused_but_mandatory_parameter);
}

pub export fn fnXLessThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_owned.fnXLessThan(unused_but_mandatory_parameter);
}

pub export fn fnXLessEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_owned.fnXLessEqual(unused_but_mandatory_parameter);
}

pub export fn fnXGreaterThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_owned.fnXGreaterThan(unused_but_mandatory_parameter);
}

pub export fn fnXGreaterEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_owned.fnXGreaterEqual(unused_but_mandatory_parameter);
}

pub export fn fnXEqualsTo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_owned.fnXEqualsTo(unused_but_mandatory_parameter);
}

pub export fn fnXNotEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_owned.fnXNotEqual(unused_but_mandatory_parameter);
}

pub export fn fnXAlmostEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_owned.fnXAlmostEqual(unused_but_mandatory_parameter);
}

pub export fn fnIsConverged(unused_but_mandatory_parameter: u16) callconv(.c) void {
    convergence_owned.isConverged(unused_but_mandatory_parameter);
}

pub export fn fnCheckType(type_: u16) callconv(.c) void {
    check_value_owned.checkType(type_);
}

pub export fn fnCheckReal(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkReal();
}

pub export fn fnCheckNumber(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkNumber();
}

pub export fn fnCheckAngle(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkAngle();
}

pub export fn fnCheckMatrix(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkMatrix();
}

pub export fn fnCheckMatrixSquare(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkMatrixSquare();
}

pub export fn fnCheckForZero(mode: u16) callconv(.c) void {
    check_value_owned.checkForZero(mode);
}

pub export fn fnCheckIsVect2d(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkRealMatrixVector(2);
}

pub export fn fnCheckIsVect3d(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkRealMatrixVector(3);
}

pub export fn fnCheckNaN(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkNaN();
}

pub export fn fnCheckInfinite(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkInfinite();
}

pub export fn fnCheckSpecial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkSpecial();
}

pub export fn fnCheckPlusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkPlusZero();
}

pub export fn fnCheckMinusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkMinusZero();
}

pub export fn fnCheckLessEqualMinusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkLessEqualMinusZero();
}

pub export fn fnCheckGreaterEqualPlusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkGreaterEqualPlusZero();
}

pub export fn fnGetType(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    get_type_owned.getType();
}

pub export fn fnDblDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    double_width_command_owned.dblDivide(unused_but_mandatory_parameter);
}

pub export fn fnDblDivideRemainder(unused_but_mandatory_parameter: u16) callconv(.c) void {
    double_width_command_owned.dblDivideRemainder(unused_but_mandatory_parameter);
}

pub export fn fnToPolar2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    polar_rect_command_owned.toPolar2(unused_but_mandatory_parameter);
}

pub export fn fnToRect2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    polar_rect_command_owned.toRect2(unused_but_mandatory_parameter);
}

pub export fn fnToRect(unused_but_mandatory_parameter: u16) callconv(.c) void {
    polar_rect_command_owned.toRect(unused_but_mandatory_parameter);
}

pub export fn fnParallel(unused_but_mandatory_parameter: u16) callconv(.c) void {
    parallel_command_owned.parallel(unused_but_mandatory_parameter);
}

pub export fn fnUnitVector(unused_but_mandatory_parameter: u16) callconv(.c) void {
    unit_vector_command_owned.unitVector(unused_but_mandatory_parameter);
}

pub export fn fnSdl(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shift_digits_command_owned.sdl(unused_but_mandatory_parameter);
}

pub export fn fnSdr(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shift_digits_command_owned.sdr(unused_but_mandatory_parameter);
}

pub export fn fnSquareRoot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    root_command_owned.squareRoot(unused_but_mandatory_parameter);
}

pub export fn fnCubeRoot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    root_command_owned.cubeRoot(unused_but_mandatory_parameter);
}

pub export fn fnPercentMRR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    percent_extended_owned.percentMRR(unused_but_mandatory_parameter);
}

pub export fn fnPercentPlusMG(unused_but_mandatory_parameter: u16) callconv(.c) void {
    percent_extended_owned.percentPlusMG(unused_but_mandatory_parameter);
}

pub export fn fnPercentT(unused_but_mandatory_parameter: u16) callconv(.c) void {
    percent_extended_owned.percentT(unused_but_mandatory_parameter);
}

pub export fn fnDeltaPercent(unused_but_mandatory_parameter: u16) callconv(.c) void {
    percent_extended_owned.deltaPercent(unused_but_mandatory_parameter);
}

pub export fn fnFib(unused_but_mandatory_parameter: u16) callconv(.c) void {
    fibonacci_owned.fnFib(unused_but_mandatory_parameter);
}

pub export fn fnLINPOL(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    linpol_pipeline_owned.linpol();
}

// Canonical scalar interpolation helper from mathematics/linpol.c, still
// externed by the median owner and the frontier distribution runtime.
pub export fn linpol(
    a: *const runtime.real_t,
    b: *const runtime.real_t,
    p: *const runtime.real_t,
    res: *runtime.real_t,
) callconv(.c) void {
    linpol_compute_owned.linpolScalar(a, b, p, res);
}

pub export fn fnCross(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (matrix_vector_cross_matrix_owned.tryCrossMatrices()) {
        return;
    }

    if (matrix_vector_validation_owned.classifyCurrentOperands().hasAnyMatrix()) {
        matrix_vector_validation_owned.crossDotMatrixTypeError("In function fnCross:");
        return;
    }

    matrix_vector_cross_scalar_owned.runScalarCross();
}
pub export fn fnDot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (matrix_vector_dot_matrix_owned.tryDotMatrices()) {
        return;
    }

    if (matrix_vector_validation_owned.classifyCurrentOperands().hasAnyMatrix()) {
        matrix_vector_validation_owned.crossDotMatrixTypeError("In function fnDot:");
        return;
    }

    matrix_vector_dot_scalar_owned.runScalarDot();
}

pub export fn fnLogXY(unused_but_mandatory_parameter: u16) callconv(.c) void {
    logxy_command_owned.fnLogXY(unused_but_mandatory_parameter);
}
