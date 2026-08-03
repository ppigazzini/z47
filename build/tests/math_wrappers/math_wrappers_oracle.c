// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void z47_math_wrappers_legacy_fnXAlmostEqual(uint16_t regist);
void z47_math_wrappers_legacy_fnRound(uint16_t unusedButMandatoryParameter);
void z47_math_wrappers_legacy_fnDivide(uint16_t unusedButMandatoryParameter);
void z47_math_wrappers_legacy_fnAdd(uint16_t unusedButMandatoryParameter);
void z47_math_wrappers_legacy_fnSubtract(uint16_t unusedButMandatoryParameter);
void z47_math_wrappers_legacy_fnMultiply(uint16_t unusedButMandatoryParameter);
void z47_math_wrappers_legacy_fnIDiv(uint16_t unusedButMandatoryParameter);
void z47_math_wrappers_legacy_fnIDivR(uint16_t unusedButMandatoryParameter);

#define fnMin oracle_fnMin
#include "../../../upstream/src/c47/mathematics/min.c"
#undef fnMin

#define fnMax oracle_fnMax
#include "../../../upstream/src/c47/mathematics/max.c"
#undef fnMax

#define fnCeil oracle_fnCeil
#include "../../../upstream/src/c47/mathematics/ceil.c"
#undef fnCeil

#define fnFloor oracle_fnFloor
#include "../../../upstream/src/c47/mathematics/floor.c"
#undef fnFloor

#define integerPartNoOp oracle_integerPartNoOp
#define integerPartReal oracle_integerPartReal
#define integerPartCplx oracle_integerPartCplx
#define fnIp oracle_fnIp
#include "../../../upstream/src/c47/mathematics/integerPart.c"
#undef fnIp
#undef integerPartCplx
#undef integerPartReal
#undef integerPartNoOp

#define fnLint oracle_fnLint
#include "../../../upstream/src/c47/mathematics/integerPartLonginteger.c"
#undef fnLint

#define fnSint oracle_fnSint
#include "../../../upstream/src/c47/mathematics/integerPartShortinteger.c"
#undef fnSint

#define fpLonI oracle_fpLonI
#define fpShoI oracle_fpShoI
#define fpReal oracle_fpReal
#define fnFp oracle_fnFp
#include "../../../upstream/src/c47/mathematics/fractionalPart.c"
#undef fnFp
#undef fpReal
#undef fpShoI
#undef fpLonI

#define sinComplex oracle_sinComplex
#define fnSinc oracle_fnSinc
#include "../../../upstream/src/c47/mathematics/sinc.c"
#undef fnSinc
#undef sinComplex

#define fnSincpi oracle_fnSincpi
#include "../../../upstream/src/c47/mathematics/sincpi.c"
#undef fnSincpi

#define lnComplex oracle_lnComplex
#define fnLn oracle_fnLn
#include "../../../upstream/src/c47/mathematics/ln.c"
#undef fnLn
#undef lnComplex

#define fnLnP1 oracle_fnLnP1
#include "../../../upstream/src/c47/mathematics/lnPOne.c"
#undef fnLnP1

#define sqrt1Px2Complex oracle_sqrt1Px2Complex
#define fnSqrt1Px2 oracle_fnSqrt1Px2
#include "../../../upstream/src/c47/mathematics/sqrt1Px2.c"
#undef fnSqrt1Px2
#undef sqrt1Px2Complex

#define ArcsinComplex oracle_ArcsinComplex
uint8_t oracle_ArcsinComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
#define fnArcsin oracle_fnArcsin
#include "../../../upstream/src/c47/mathematics/arcsin.c"
#undef fnArcsin
#undef ArcsinComplex

#define fnArccos oracle_fnArccos
#include "../../../upstream/src/c47/mathematics/arccos.c"
#undef fnArccos

#define ArctanComplex oracle_ArctanComplex
uint8_t oracle_ArctanComplex(real_t *xReal, real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
#define fnArctan oracle_fnArctan
#include "../../../upstream/src/c47/mathematics/arctan.c"
#undef fnArctan
#undef ArctanComplex

#define ArcsinhReal oracle_ArcsinhReal
#define ArcsinhComplex oracle_ArcsinhComplex
uint8_t oracle_ArcsinhReal(const real_t *x, real_t *res, realContext_t *realContext);
uint8_t oracle_ArcsinhComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
#define fnArcsinh oracle_fnArcsinh
#include "../../../upstream/src/c47/mathematics/arcsinh.c"
#undef fnArcsinh
#undef ArcsinhComplex
#undef ArcsinhReal

#define realArcosh oracle_realArcosh
void oracle_realArcosh(const real_t *x, real_t *res, realContext_t *realContext);
#define fnArccosh oracle_fnArccosh
#include "../../../upstream/src/c47/mathematics/arccosh.c"
#undef fnArccosh
#undef realArcosh

#define fnArctanh oracle_fnArctanh
#include "../../../upstream/src/c47/mathematics/arctanh.c"
#undef fnArctanh

#define fnInvert oracle_fnInvert
#include "../../../upstream/src/c47/mathematics/invert.c"
#undef fnInvert

#define fnSign oracle_fnSign
#include "../../../upstream/src/c47/mathematics/sign.c"
#undef fnSign

#define chsShoI oracle_chsShoI
#define chsReal oracle_chsReal
#define chsCplx oracle_chsCplx
#define fnChangeSign oracle_fnChangeSign
#include "../../../upstream/src/c47/mathematics/changeSign.c"
#undef fnChangeSign
#undef chsCplx
#undef chsReal
#undef chsShoI

#define sinComplex oracle_sinComplex
#define sinCosReal oracle_sinCosReal
#define sinCosCplx oracle_sinCosCplx
#define fnSin oracle_fnSin
#include "../../../upstream/src/c47/mathematics/sin.c"
#undef fnSin
#undef sinCosCplx
#undef sinCosReal
#undef sinComplex

#define cosComplex oracle_cosComplex
#define fnCos oracle_fnCos
#include "../../../upstream/src/c47/mathematics/cos.c"
#undef fnCos
#undef cosComplex

#define TanComplex oracle_TanComplex
#define fnTan oracle_fnTan
uint8_t oracle_TanComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
#include "../../../upstream/src/c47/mathematics/tan.c"
#undef fnTan
#undef TanComplex

#define sinhCoshReal oracle_sinhCoshReal
#define sinhCoshCplx oracle_sinhCoshCplx
#define fnSinh oracle_fnSinh
#include "../../../upstream/src/c47/mathematics/sinh.c"
#undef fnSinh
#undef sinhCoshCplx
#undef sinhCoshReal

#define sinhCoshReal oracle_sinhCoshReal
#define sinhCoshCplx oracle_sinhCoshCplx
#define fnCosh oracle_fnCosh
#include "../../../upstream/src/c47/mathematics/cosh.c"
#undef fnCosh
#undef sinhCoshCplx
#undef sinhCoshReal

#define TanhComplex oracle_TanhComplex
#define fnTanh oracle_fnTanh
uint8_t oracle_TanhComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
#include "../../../upstream/src/c47/mathematics/tanh.c"
#undef fnTanh
#undef TanhComplex

#define realExpLimitCheck oracle_realExpLimitCheck
#define realExp oracle_realExp
#define expComplex oracle_expComplex
#define fnExp oracle_fnExp
#include "../../../upstream/src/c47/mathematics/exp.c"
#undef fnExp
#undef expComplex
#undef realExp
#undef realExpLimitCheck

#define sinComplex oracle_sinComplex
#define expComplex oracle_expComplex
#define realExpM1 oracle_realExpM1
void oracle_realExpM1(const real_t *x, real_t *res, realContext_t *realContext);
#define fnExpM1 oracle_fnExpM1
#include "../../../upstream/src/c47/mathematics/expMOne.c"
#undef fnExpM1
#undef realExpM1
#undef expComplex
#undef sinComplex

#define fnExpt oracle_fnExpt
#include "../../../upstream/src/c47/mathematics/expt.c"
#undef fnExpt

#define fnBn oracle_fnBn
#define fnBnStar oracle_fnBnStar
#include "../../../upstream/src/c47/mathematics/bn.c"
#undef fnBnStar
#undef fnBn

#define fnErf oracle_fnErf
#include "../../../upstream/src/c47/mathematics/erf.c"
#undef fnErf

#define fnErfc oracle_fnErfc
#include "../../../upstream/src/c47/mathematics/erfc.c"
#undef fnErfc

#define logxyLonI oracle_logxyLonI
#define logxyReal oracle_logxyReal
#define logxyCplx oracle_logxyCplx
#define realLog10 oracle_realLog10
void oracle_realLog10(const real_t *x, real_t *res, realContext_t *realContext);
#define fnLog10 oracle_fnLog10
#include "../../../upstream/src/c47/mathematics/log10.c"
#undef fnLog10
#undef realLog10
#undef logxyCplx
#undef logxyReal
#undef logxyLonI

#define realPower2 oracle_realPower2
#define intPowReal oracle_intPowReal
#define intPowCplx oracle_intPowCplx
// intPowReal/intPowCplx are defined in 10pow.c (included below), but 2pow.c now
// calls them, so forward-declare the renamed oracle_* symbols here to avoid the
// implicit-declaration / conflicting-types errors (same pattern as realLog10).
void oracle_intPowReal(void (*powf)(const real_t *x, real_t *res, realContext_t *realContext));
void oracle_intPowCplx(const real_t *lnBase);
#define realExp oracle_realExp
#define fn2Pow oracle_fn2Pow
#include "../../../upstream/src/c47/mathematics/2pow.c"
#undef fn2Pow
#undef realExp
#undef intPowCplx
#undef intPowReal
#undef realPower2

#define realPower10 oracle_realPower10
#define intPowReal oracle_intPowReal
#define intPowCplx oracle_intPowCplx
#define realExp oracle_realExp
#define fn10Pow oracle_fn10Pow
#include "../../../upstream/src/c47/mathematics/10pow.c"
#undef fn10Pow
#undef realExp
#undef intPowCplx
#undef intPowReal
#undef realPower10

#define fnLog2 oracle_fnLog2
#include "../../../upstream/src/c47/mathematics/log2.c"
#undef fnLog2

#define expComplex oracle_expComplex
#define eulersFormula oracle_eulersFormula
#define fnEulersFormula oracle_fnEulersFormula
#include "../../../upstream/src/c47/mathematics/eulersFormula.c"
#undef fnEulersFormula
#undef eulersFormula
#undef expComplex

#define fnWinverse oracle_fnWinverse
#include "../../../upstream/src/c47/mathematics/w_inverse.c"
#undef fnWinverse

#define fnWnegative oracle_fnWnegative
#include "../../../upstream/src/c47/mathematics/w_negative.c"
#undef fnWnegative

#define fnWpositive oracle_fnWpositive
#include "../../../upstream/src/c47/mathematics/w_positive.c"
#undef fnWpositive

#define fnGcd oracle_fnGcd
#include "../../../upstream/src/c47/mathematics/gcd.c"
#undef fnGcd

#define fnLcm oracle_fnLcm
#include "../../../upstream/src/c47/mathematics/lcm.c"
#undef fnLcm

#define modReal oracle_modReal
#define fnMod oracle_fnMod
#include "../../../upstream/src/c47/mathematics/modulo.c"
#undef fnMod
#undef modReal

#define fnRmd oracle_fnRmd
#include "../../../upstream/src/c47/mathematics/remainder.c"
#undef fnRmd

#define fnDblMultiply oracle_fnDblMultiply
#include "../../../upstream/src/c47/mathematics/dblMultiplication.c"
#undef fnDblMultiply

#define dblDivide oracle_dblDivide
#define fnDblDivide oracle_fnDblDivide
#define fnDblDivideRemainder oracle_fnDblDivideRemainder
#include "../../../upstream/src/c47/mathematics/dblDivision.c"
#undef fnDblDivideRemainder
#undef fnDblDivide
#undef dblDivide

#define fnUlp oracle_fnUlp
#include "../../../upstream/src/c47/mathematics/ulp.c"
#undef fnUlp

#define mant oracle_mant
#define mantError oracle_mantError
#define mantLonI oracle_mantLonI
#define mantReal oracle_mantReal
#define fnMant oracle_fnMant
void mantError(void);
void mantLonI(void);
void mantReal(void);
#include "../../../upstream/src/c47/mathematics/mant.c"
#undef fnMant
#undef mantReal
#undef mantLonI
#undef mantError
#undef mant

#define Roundi oracle_Roundi
#define roundiError oracle_roundiError
#define roundiRema oracle_roundiRema
#define roundiReal oracle_roundiReal
#define fnRoundi oracle_fnRoundi
void roundiError(void);
void roundiRema(void);
void roundiReal(void);
#include "../../../upstream/src/c47/mathematics/roundi.c"
#undef fnRoundi
#undef roundiReal
#undef roundiRema
#undef roundiError
#undef Roundi

void oracle_decompError(void);
void oracle_decompLonI(void);
void oracle_decompReal(void);
#define Decomp oracle_Decomp
#define decompError oracle_decompError
#define decompLonI oracle_decompLonI
#define decompReal oracle_decompReal
#define fnDecomp oracle_fnDecomp
#include "../../../upstream/src/c47/mathematics/decomp.c"
#undef fnDecomp
#undef decompReal
#undef decompLonI
#undef decompError
#undef Decomp

#define fnNeighb oracle_fnNeighb
#include "../../../upstream/src/c47/mathematics/neighb.c"
#undef fnNeighb

#define fnIxyz oracle_fnIxyz
#include "../../../upstream/src/c47/mathematics/ixyz.c"
#undef fnIxyz

#define log z47_math_wrappers_log
#define fnFactorial oracle_fnFactorial
#include "../../../upstream/src/c47/mathematics/factorial.c"
#undef fnFactorial
#undef log

#define realRandomU01 oracle_realRandomU01
#define fnRandom oracle_fnRandom
#define fnRandomI oracle_fnRandomI
#define fnSeed oracle_fnSeed
#include "../../../upstream/src/c47/mathematics/random.c"
#undef fnSeed
#undef fnRandomI
#undef fnRandom
#undef realRandomU01

static void oracle_compareTypeErrorX(void) {
	temporaryInformation = 12;
	displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, (calcRegister_t)103);
}

void oracle_fnCheckReal(uint16_t unusedButMandatoryParameter) {
	const uint32_t t = getRegisterDataType(REGISTER_X);

	(void)unusedButMandatoryParameter;
	temporaryInformation = 12 + (t <= 4 || t == 8);
}

static bool_t oracle_getConvergenceInput(calcRegister_t reg, real_t *real, real_t *imag, bool_t *isComplex) {
	switch(getRegisterDataType(reg)) {
		case dtComplex34:
			*isComplex = true;
			return getRegisterAsComplex(reg, real, imag);

		case dtReal34:
			if(!getRegisterAsReal(reg, real)) {
				return false;
			}
			realSetZero(imag);
			return true;

		case dtLongInteger:
			convertLongIntegerRegisterToReal(reg, real, &ctxtReal39);
			realSetZero(imag);
			return true;

		case dtShortInteger:
			convertShortIntegerRegisterToReal(reg, real, &ctxtReal39);
			realSetZero(imag);
			return true;

		default:
			return false;
	}
}

#define ORACLE_COMPARE_MODE_LESS_THAN 0x1
#define ORACLE_COMPARE_MODE_EQUAL 0x2
#define ORACLE_COMPARE_MODE_LESS_EQUAL 0x3
#define ORACLE_COMPARE_MODE_GREATER_THAN 0x4
#define ORACLE_COMPARE_MODE_NOT_EQUAL 0x5
#define ORACLE_COMPARE_MODE_GREATER_EQUAL 0x6

static void oracle_compareTypeError(calcRegister_t reg) {
	temporaryInformation = 12;
	displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_T);
	sprintf(errorMessage, "cannot convert Register %d from %s", reg, getRegisterDataTypeName(reg, true, false));
	moreInfoOnError("In function badTypeError:", errorMessage, NULL, NULL);
}

static int oracle_isOwnedCompareType(uint32_t dataType) {
	return dataType == dtLongInteger || dataType == dtShortInteger || dataType == dtReal34 || dataType == dtComplex34;
}

static void oracle_cmpToResult(int result, uint8_t mode) {
	if(result < 0) {
		temporaryInformation = 12 + ((mode & ORACLE_COMPARE_MODE_LESS_THAN) != 0);
	}
	else if(result > 0) {
		temporaryInformation = 12 + ((mode & ORACLE_COMPARE_MODE_GREATER_THAN) != 0);
	}
	else {
		temporaryInformation = 12 + ((mode & ORACLE_COMPARE_MODE_EQUAL) != 0);
	}
}

static void oracle_compareRealsToTemporaryInformation(real_t *left, real_t *right, uint8_t mode) {
	if(realIsNaN(left) || realIsNaN(right)) {
		temporaryInformation = 12;
		return;
	}

	if(realCompareEqual(left, right)) {
		oracle_cmpToResult(0, mode);
	}
	else if(realCompareLessThan(left, right)) {
		oracle_cmpToResult(-1, mode);
	}
	else {
		oracle_cmpToResult(1, mode);
	}
}

static void oracle_compareComplexToTemporaryInformation(real_t *leftReal,
	                                                    real_t *leftImag,
	                                                    real_t *rightReal,
	                                                    real_t *rightImag,
	                                                    uint8_t mode,
	                                                    calcRegister_t reg) {
	if(mode != ORACLE_COMPARE_MODE_EQUAL && mode != ORACLE_COMPARE_MODE_NOT_EQUAL) {
		oracle_compareTypeError(reg);
		return;
	}

	oracle_compareRealsToTemporaryInformation(leftReal, rightReal, mode);
	if(temporaryInformation != 12) {
		oracle_compareRealsToTemporaryInformation(leftImag, rightImag, mode);
	}
}

static void oracle_compareScalarRegister(calcRegister_t reg, uint8_t mode) {
	const uint32_t xType = getRegisterDataType(REGISTER_X);
	const uint32_t regType = getRegisterDataType(reg);
	real_t xReal, xImag, regReal, regImag;
	bool_t isComplex = false;

	if(!oracle_isOwnedCompareType(xType) || !oracle_isOwnedCompareType(regType)) {
		oracle_compareTypeError(reg);
		return;
	}

	if(!oracle_getConvergenceInput(REGISTER_X, &xReal, &xImag, &isComplex) || !oracle_getConvergenceInput(reg, &regReal, &regImag, &isComplex)) {
		oracle_compareTypeError(reg);
		return;
	}

	if(isComplex) {
		oracle_compareComplexToTemporaryInformation(&xReal, &xImag, &regReal, &regImag, mode, reg);
	}
	else {
		oracle_compareRealsToTemporaryInformation(&xReal, &regReal, mode);
	}
}

enum {
	ORACLE_INTEGER_ADD = 0,
	ORACLE_INTEGER_SUBTRACT = 1,
	ORACLE_INTEGER_MULTIPLY = 2,
};

#define fnAdd oracle_full_fnAdd
#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
#endif
#include "../../../upstream/src/c47/mathematics/addition.h"
#include "../../../upstream/src/c47/mathematics/addition.c"
#undef fnAdd

#define fnSubtract oracle_full_fnSubtract
#include "../../../upstream/src/c47/mathematics/subtraction.h"
#include "../../../upstream/src/c47/mathematics/subtraction.c"
#undef fnSubtract

#define fnMultiply oracle_full_fnMultiply
#define mulComplexi oracle_mulComplexi
#define mulComplexComplex oracle_mulComplexComplex
#define mulComplexReal oracle_mulComplexReal
#include "../../../upstream/src/c47/mathematics/multiplication.h"
#include "../../../upstream/src/c47/mathematics/multiplication.c"
#undef mulComplexReal
#undef mulComplexComplex
#undef mulComplexi
#undef fnMultiply

#define fnDivide oracle_full_fnDivide
#define divRealComplex oracle_divRealComplex
#define divComplexComplex oracle_divComplexComplex
#include "../../../upstream/src/c47/mathematics/division.h"
#include "../../../upstream/src/c47/mathematics/division.c"
#undef divComplexComplex
#undef divRealComplex
#undef fnDivide
#if defined(__clang__)
#pragma clang diagnostic pop
#endif

static bool_t oracle_tryIntegerLongDivide(bool_t withRemainder) {
	const uint32_t xType = getRegisterDataType(REGISTER_X);
	const uint32_t yType = getRegisterDataType(REGISTER_Y);
	const bool_t xIsLong = xType == dtLongInteger;
	const bool_t yIsLong = yType == dtLongInteger;
	const bool_t xIsShort = xType == dtShortInteger;
	const bool_t yIsShort = yType == dtShortInteger;
	longInteger_t x;
	longInteger_t y;

	if((!xIsLong && !xIsShort) || (!yIsLong && !yIsShort)) {
		return false;
	}

	if(!saveLastX()) {
		return true;
	}

	if(xIsShort && yIsShort && !withRemainder) {
		int16_t sign = 0;
		uint64_t divisor = 0;

		convertShortIntegerRegisterToUInt64(REGISTER_X, &sign, &divisor);
		if(divisor == 0) {
			displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
			moreInfoOnError(withRemainder ? "In function fnIDivR:" : "In function fnIDiv:", "cannot divide current integer pair by 0", NULL, NULL);
		}
		else {
			uint64_t *const xShort = (uint64_t *)getRegisterDataPointer(REGISTER_X);
			const uint64_t *const yShort = (const uint64_t *)getRegisterDataPointer(REGISTER_Y);

			*xShort = WP34S_intDivide(*yShort, *xShort);
			setRegisterTag(REGISTER_X, getRegisterShortIntegerBase(REGISTER_Y));
		}

		adjustResult(REGISTER_X, true, false, REGISTER_X, REGISTER_Y, -1);
		return true;
	}

	if(xIsLong) {
		convertLongIntegerRegisterToLongInteger(REGISTER_X, x);
	}
	else {
		convertShortIntegerRegisterToLongInteger(REGISTER_X, x);
	}

	if(yIsLong) {
		convertLongIntegerRegisterToLongInteger(REGISTER_Y, y);
	}
	else {
		convertShortIntegerRegisterToLongInteger(REGISTER_Y, y);
	}

	if(mpz_sgn(x) == 0) {
		displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
		moreInfoOnError(withRemainder ? "In function fnIDivR:" : "In function fnIDiv:", "cannot divide current integer pair by 0", NULL, NULL);
	}
	else if(withRemainder) {
		longInteger_t quotient;
		longInteger_t remainder;

		mpz_init(quotient);
		mpz_init(remainder);
		mpz_tdiv_qr(quotient, remainder, y, x);
		if(xIsShort && yIsShort) {
			const uint32_t baseY = getRegisterShortIntegerBase(REGISTER_Y);
			convertLongIntegerToShortIntegerRegister(quotient, baseY, REGISTER_X);
			convertLongIntegerToShortIntegerRegister(remainder, baseY, REGISTER_Y);
		}
		else {
			convertLongIntegerToLongIntegerRegister(quotient, REGISTER_X);
			if(yIsShort) {
				convertLongIntegerToShortIntegerRegister(remainder, getRegisterShortIntegerBase(REGISTER_Y), REGISTER_Y);
			}
			else {
				convertLongIntegerToLongIntegerRegister(remainder, REGISTER_Y);
			}
		}
		mpz_clear(quotient);
		mpz_clear(remainder);
	}
	else {
		longInteger_t remainder;

		mpz_init(remainder);
		mpz_tdiv_qr(x, remainder, y, x);
		convertLongIntegerToLongIntegerRegister(x, REGISTER_X);
		mpz_clear(remainder);
	}

	mpz_clear(y);
	mpz_clear(x);

	if(withRemainder) {
		adjustResult(REGISTER_X, false, false, REGISTER_X, REGISTER_Y, -1);
		adjustResult(REGISTER_Y, false, false, REGISTER_X, REGISTER_Y, -1);
	}
	else {
		adjustResult(REGISTER_X, true, false, REGISTER_X, REGISTER_Y, -1);
	}

	return true;
}

static void oracle_pushGetTypeIntegerOut(uint32_t value) {
	longInteger_t lgInt;

	longIntegerInit(lgInt);
	uInt32ToLongInteger(value, lgInt);
	setSystemFlag(FLAG_ASLIFT);
	liftStack();
	convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
	longIntegerFree(lgInt);
	setSystemFlag(FLAG_ASLIFT);
}

static void oracle_pushGetTypeRealOut(uint32_t value) {
	real_t realOut;
	real_t scale;

	uInt32ToReal(value, &realOut);
	uInt32ToReal(1000, &scale);
	realDivide(&realOut, &scale, &realOut, &ctxtReal39);
	setSystemFlag(FLAG_ASLIFT);
	liftStack();
	reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
	convertRealToReal34ResultRegister(&realOut, REGISTER_X);
	setSystemFlag(FLAG_ASLIFT);
}

#define fnRealPart oracle_fnRealPart
#include "../../../upstream/src/c47/mathematics/realPart.c"
#undef fnRealPart

#define fnImaginaryPart oracle_fnImaginaryPart
#include "../../../upstream/src/c47/mathematics/imaginaryPart.c"
#undef fnImaginaryPart

#define arg oracle_arg
#define fnArg oracle_fnArg
#include "../../../upstream/src/c47/mathematics/arg.c"
#undef fnArg
#undef arg

#define complexMagnitude2 oracle_complexMagnitude2
#define complexMagnitude oracle_complexMagnitude
#define fnMagnitude oracle_fnMagnitude
void complexMagnitude(const real_t *a, const real_t *b, real_t *c, realContext_t *realContext);
#include "../../../upstream/src/c47/mathematics/magnitude.c"
#undef fnMagnitude
#undef complexMagnitude
#undef complexMagnitude2

#define conjCplx oracle_conjCplx
#define fnConjugate oracle_fnConjugate_legacy
#include "../../../upstream/src/c47/mathematics/conjugate.c"
#undef fnConjugate
#undef conjCplx

static void oracle_conjRema(void) {
	complex34Matrix_t cMat;

	convertReal34MatrixRegisterToComplex34Matrix(REGISTER_X, &cMat);
	if(getSystemFlag(FLAG_SPCRES)) {
		for(uint16_t i = 0; i < cMat.header.matrixRows * cMat.header.matrixColumns; ++i) {
			real34ChangeSign(VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]));
		}
	}
	convertComplex34MatrixToComplex34MatrixRegister(&cMat, REGISTER_X);
}

static void oracle_conjCxma(void) {
	complex34Matrix_t cMat;

	linkToComplexMatrixRegister(REGISTER_X, &cMat);
	for(uint16_t i = 0; i < cMat.header.matrixRows * cMat.header.matrixColumns; ++i) {
		real34ChangeSign(VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]));
		if(real34IsZero(VARIABLE_IMAG34_DATA(&cMat.matrixElements[i])) && !getSystemFlag(FLAG_SPCRES)) {
			real34SetPositiveSign(VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]));
		}
	}
	convertComplex34MatrixToComplex34MatrixRegister(&cMat, REGISTER_X);
}

// WHY THESE FOUR STILL HAVE A HAND-WRITTEN BODY, measured.
//
// fnAdd / fnSubtract / fnMultiply / fnDivide used to have one too, and it was pure
// duplication: repointing their 91 driver call sites at the compiled
// `oracle_full_*` bodies -- c43's own, already linked in this binary -- produced
// ZERO mismatches, and 428 lines went with them.
//
// The same experiment on these four produces exactly SIX mismatches, all MATRIX
// cases, and compiling toPolar.c / toRect.c in place of their mirrors produces
// TWELVE. The cause is the same in both, and it is the environment rather than the
// reference: this lane's `real_t` is a hand-declared 25-limb struct, its arithmetic
// is math_wrappers_fake_runtime.c, and its `const39_*` values are placeholder
// decimals -- there is no decNumber and no matrix subsystem here. c43's real files
// dispatch into leaves the fake core answers differently, so swapping a mirror for
// the real file changes the observable counters without either side being wrong.
//
// So this lane compares CONTROL FLOW over a fake numeric core, and these mirrors
// were written to match what that core can express. They cannot be removed by
// compiling more c43 into the mock; the lane needs the full-core treatment
// calc_state and register_metadata got. Do not repeat either
// experiment -- both are recorded here so nobody has to.
//
// THE ROUTE OUT is build/tests/math_wrappers_full_core/, which compiles c43's own
// mathematics/*.c beside the Zig owners on real decNumber and compares the state
// each leaves behind. The fifteen predicate mirrors that used to sit here --
// fnCheckAngle, fnCheckForZero, fnCheckInfinite, fnCheckInteger, fnCheckIsVect2d,
// fnCheckIsVect3d, fnCheckMatrix, fnCheckMatrixSquare, fnCheckMinusZero,
// fnCheckNaN, fnCheckNumber, fnCheckPlusZero, fnCheckSpecial, fnCheckType and
// fnGetType -- moved there and are gone from this file. Every remaining mirror
// below goes the same way; none of them go by being reasoned about here.

void oracle_fnConjugate(uint16_t unusedButMandatoryParameter) {
	const uint32_t typex = getRegisterDataType(REGISTER_X);

	(void)unusedButMandatoryParameter;

	if(!saveLastX()) {
		return;
	}

	if(typex == dtComplex34Matrix) {
		oracle_conjCxma();
	}
	else if(typex == dtReal34Matrix) {
		oracle_conjRema();
	}
	else {
		oracle_conjCplx();
	}
}

#define fnSwapRealImaginary oracle_fnSwapRealImaginary_legacy
#include "../../../upstream/src/c47/mathematics/swapRealImaginary.c"
#undef fnSwapRealImaginary

static void oracle_swapReImRema(void) {
	complex34Matrix_t c;
	real34Matrix_t r;

	linkToRealMatrixRegister(REGISTER_X, &r);
	convertReal34MatrixToComplex34Matrix(&r, &c);

	for(uint16_t i = 0; i < c.header.matrixRows * c.header.matrixColumns; ++i) {
		real34Copy(VARIABLE_REAL34_DATA(&c.matrixElements[i]), VARIABLE_IMAG34_DATA(&c.matrixElements[i]));
		real34SetZero(VARIABLE_REAL34_DATA(&c.matrixElements[i]));
	}

	convertComplex34MatrixToComplex34MatrixRegister(&c, REGISTER_X);
	complexMatrixFree(&c);
}

static void oracle_swapReImCxma(void) {
	complex34Matrix_t cMat;
	real34_t tmp;

	linkToComplexMatrixRegister(REGISTER_X, &cMat);
	for(uint16_t i = 0; i < cMat.header.matrixRows * cMat.header.matrixColumns; ++i) {
		real34Copy(VARIABLE_REAL34_DATA(&cMat.matrixElements[i]), &tmp);
		real34Copy(VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]), VARIABLE_REAL34_DATA(&cMat.matrixElements[i]));
		real34Copy(&tmp, VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]));
	}
	convertComplex34MatrixToComplex34MatrixRegister(&cMat, REGISTER_X);
}

void oracle_fnSwapRealImaginary(uint16_t unusedButMandatoryParameter) {
	real_t a, b;
	const uint32_t type = getRegisterDataType(REGISTER_X);

	(void)unusedButMandatoryParameter;

	if(!saveLastX()) {
		return;
	}

	if(type == dtReal34Matrix) {
		oracle_swapReImRema();
	}
	else if(type == dtComplex34Matrix) {
		oracle_swapReImCxma();
	}
	else {
		if(!getRegisterAsComplex(REGISTER_X, &a, &b)) {
			return;
		}
		convertComplexToResultRegister(&b, &a, REGISTER_X);
	}
}

#define arctan2 oracle_arctan2
#define atan2Error oracle_atan2Error
#define atan2RealReal oracle_atan2RealReal
#define atan2RemaRema oracle_atan2RemaRema
#define atan2RemaReal oracle_atan2RemaReal
#define atan2RealRema oracle_atan2RealRema
#define atan2LonIRema oracle_atan2LonIRema
#define fnAtan2 oracle_fnAtan2_legacy
void atan2Error(void);
void atan2RealReal(void);
void atan2RemaRema(void);
void atan2RemaReal(void);
void atan2RealRema(void);
void atan2LonIRema(void);
#include "../../../upstream/src/c47/mathematics/atan2.c"
#undef fnAtan2
#undef atan2LonIRema
#undef atan2RealRema
#undef atan2RemaReal
#undef atan2RemaRema

static void oracle_atan2RealRemaFixed(void) {
	real_t y;
	real34Matrix_t x;

	if(!getRegisterAsReal(REGISTER_Y, &y)) {
		return;
	}

	linkToRealMatrixRegister(REGISTER_X, &x);
	for(uint16_t i = 0; i < x.header.matrixRows * x.header.matrixColumns; ++i) {
		real_t xx;
		real34ToReal(&x.matrixElements[i], &xx);
		if(realIsZero(&y) && realIsZero(&xx) && !getSystemFlag(FLAG_SPCRES)) {
			displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
			moreInfoOnError("In function atan2RealRema:", "X = 0 and Y = 0", NULL, NULL);
			return;
		}
		C47_WP34S_Atan2(&y, &xx, &xx, &ctxtReal39);
		convertAngleFromTo(&xx, amRadian, currentAngularMode, &ctxtReal39);
		roundToSignificantDigits(&xx, &xx, significantDigits == 0 ? 34 : significantDigits, &ctxtReal75);
		realToReal34(&xx, &x.matrixElements[i]);
	}

	convertReal34MatrixToReal34MatrixRegister(&x, REGISTER_X);
}

static void oracle_atan2RemaRemaFixed(void) {
	real34Matrix_t y, x;

	linkToRealMatrixRegister(REGISTER_Y, &y);
	linkToRealMatrixRegister(REGISTER_X, &x);

	if(y.header.matrixRows == x.header.matrixRows && y.header.matrixColumns == x.header.matrixColumns) {
		for(uint16_t i = 0; i < x.header.matrixRows * x.header.matrixColumns; ++i) {
			real_t yy, xx;
			real34ToReal(&y.matrixElements[i], &yy);
			real34ToReal(&x.matrixElements[i], &xx);
			if(realIsZero(&yy) && realIsZero(&xx) && !getSystemFlag(FLAG_SPCRES)) {
				displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
				moreInfoOnError("In function atan2RemaRema:", "X = 0 and Y = 0", NULL, NULL);
				return;
			}
			C47_WP34S_Atan2(&yy, &xx, &xx, &ctxtReal39);
			convertAngleFromTo(&xx, amRadian, currentAngularMode, &ctxtReal39);
			roundToSignificantDigits(&xx, &xx, significantDigits == 0 ? 34 : significantDigits, &ctxtReal75);
			realToReal34(&xx, &x.matrixElements[i]);
		}
		convertReal34MatrixToReal34MatrixRegister(&x, REGISTER_X);
	}
	else {
		displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
		moreInfoOnError("In function atan2RemaRema:", "matrix size mismatch", NULL, NULL);
	}
}

void oracle_fnAtan2(uint16_t unusedButMandatoryParameter) {
	const uint32_t typex = getRegisterDataType(REGISTER_X);
	const uint32_t typey = getRegisterDataType(REGISTER_Y);

	(void)unusedButMandatoryParameter;

	if(!saveLastX()) {
		return;
	}

	if((typex == dtLongInteger || typex == dtReal34) && (typey == dtLongInteger || typey == dtReal34)) {
		oracle_atan2RealReal();
	}
	else if(typex == dtReal34Matrix && typey == dtReal34Matrix) {
		oracle_atan2RemaRemaFixed();
	}
	else if(typex == dtReal34Matrix && (typey == dtReal34 || typey == dtLongInteger || typey == dtShortInteger)) {
		oracle_atan2RealRemaFixed();
	}
	else if(typey == dtReal34Matrix && (typex == dtReal34 || typex == dtLongInteger || typex == dtShortInteger)) {
		oracle_atan2RemaReal();
	}
	else {
		oracle_atan2Error();
	}

	adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
}
#undef atan2RealReal
#undef atan2Error
#undef arctan2

#define percentReal oracle_percentReal
#define fnPercent oracle_fnPercent
#include "../../../upstream/src/c47/mathematics/percent.c"
#undef fnPercent
#undef percentReal

#define eulersFormula oracle_eulersFormula
#define fnM1Pow oracle_fnM1Pow
#include "../../../upstream/src/c47/mathematics/minusOnePow.c"
#undef fnM1Pow
#undef eulersFormula

#define fnSquare oracle_fnSquare
#include "../../../upstream/src/c47/mathematics/square.c"
#undef fnSquare

#define fnCube oracle_fnCube
#include "../../../upstream/src/c47/mathematics/cube.c"
#undef fnCube

void oracle_fnToPolar2(uint16_t unusedButMandatoryParameter) {
	uint32_t dataTypeX, dataTypeY, dataAtagX, dataAtagY;
	calcRegister_t REG_X, REG_Y;
	real_t x, y;

	(void)unusedButMandatoryParameter;

	if(getRegisterDataType(REGISTER_X) == dtComplex34 || getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {
		setComplexRegisterPolarMode(REGISTER_X, amPolar);
		if(getComplexRegisterAngularMode(REGISTER_X) == amNone) {
			setComplexRegisterAngularMode(REGISTER_X, currentAngularMode);
		}
		return;
	}
	else if(getRegisterDataType(REGISTER_X) == dtReal34Matrix) {
		if(isRegisterMatrix3dVector(REGISTER_X)) {
			setVectorRegisterPolarMode(REGISTER_X,
				((getVectorRegisterPolarMode(REGISTER_X) == 0) ? amPolarSPH : (getVectorRegisterPolarMode(REGISTER_X) == amPolarSPH) ? amPolarCYL : (getVectorRegisterPolarMode(REGISTER_X) == amPolarCYL) ? amPolarSPH : 0));
			setVectorRegisterAngularMode(REGISTER_X, currentAngularMode);
			return;
		}
		else if(isRegisterMatrix2dVector(REGISTER_X)) {
			setVectorRegisterPolarMode(REGISTER_X, amPolar);
			setVectorRegisterAngularMode(REGISTER_X, currentAngularMode);
			return;
		}
	}

	dataTypeX = getRegisterDataType(REGISTER_X);
	dataAtagX = getRegisterAngularMode(REGISTER_X);
	dataTypeY = getRegisterDataType(REGISTER_Y);
	dataAtagY = getRegisterAngularMode(REGISTER_Y);

	if(!((dataTypeX == dtLongInteger || (dataTypeX == dtReal34 && dataAtagX == amNone)) &&
	     (dataTypeY == dtLongInteger || (dataTypeY == dtReal34 && dataAtagY == amNone)))) {
		displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
		return;
	}

	if(getSystemFlag(FLAG_HPRP)) {
		REG_X = REGISTER_X;
		REG_Y = REGISTER_Y;
	}
	else {
		REG_X = REGISTER_Y;
		REG_Y = REGISTER_X;
	}

	if(!saveLastX()) {
		return;
	}

	if(dataTypeX == dtLongInteger) {
		convertLongIntegerRegisterToReal(REG_X, &x, &ctxtReal39);
	}
	else {
		real34ToReal(REGISTER_REAL34_DATA(REG_X), &x);
	}

	if(dataTypeY == dtLongInteger) {
		convertLongIntegerRegisterToReal(REG_Y, &y, &ctxtReal39);
	}
	else {
		real34ToReal(REGISTER_REAL34_DATA(REG_Y), &y);
	}

	realRectangularToPolar(&x, &y, &x, &y, &ctxtReal39);
	convertAngleFromTo(&y, amRadian, currentAngularMode, &ctxtReal39);

	reallocateRegister(REG_X, dtReal34, 0, amNone);
	reallocateRegister(REG_Y, dtReal34, 0, currentAngularMode);
	convertRealToReal34ResultRegister(&x, REG_X);
	convertRealToReal34ResultRegister(&y, REG_Y);

	if(getSystemFlag(FLAG_HPRP)) {
		temporaryInformation = TI_RADIUS_THETA;
	}
	else {
		temporaryInformation = TI_RADIUS_THETA_SWAPPED;
	}
}

void oracle_fnToRect2(uint16_t unusedButMandatoryParameter) {
	uint32_t dataTypeX, dataTypeY, dataAtagX, dataAtagY;
	calcRegister_t REG_X, REG_Y;
	angularMode_t yAngularMode;
	int8_t angleInY = 1;
	real_t x, y;

	(void)unusedButMandatoryParameter;

	if(getRegisterDataType(REGISTER_X) == dtComplex34 || getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {
		setComplexRegisterPolarMode(REGISTER_X, ~amPolar);
		setComplexRegisterAngularMode(REGISTER_X, amNone);
		return;
	}
	else if(getRegisterDataType(REGISTER_X) == dtReal34Matrix) {
		if(isRegisterMatrixVector(REGISTER_X)) {
			setVectorRegisterPolarMode(REGISTER_X, 0);
			setVectorRegisterAngularMode(REGISTER_X, amNone);
			temporaryInformation = TI_VECTOR;
			return;
		}
	}

	dataTypeX = getRegisterDataType(REGISTER_X);
	dataAtagX = getRegisterAngularMode(REGISTER_X);
	dataTypeY = getRegisterDataType(REGISTER_Y);
	dataAtagY = getRegisterAngularMode(REGISTER_Y);

	if(!getSystemFlag(FLAG_HPRP)) {
		angleInY = -angleInY;
		if(dataTypeX == dtReal34 && dataAtagX != amNone && dataTypeY == dtReal34 && dataAtagY == amNone) {
		}
		else if(dataTypeY == dtReal34 && dataAtagY != amNone && dataTypeX == dtReal34 && dataAtagX == amNone) {
			angleInY = -angleInY;
		}
	}
	else {
		if(dataTypeX == dtReal34 && dataAtagX != amNone && dataTypeY == dtReal34 && dataAtagY == amNone) {
			angleInY = -angleInY;
		}
		else if(dataTypeY == dtReal34 && dataAtagY != amNone && dataTypeX == dtReal34 && dataAtagX == amNone) {
		}
	}

	if(!((dataTypeX == dtLongInteger || dataTypeX == dtReal34) &&
	     (dataTypeY == dtLongInteger || dataTypeY == dtReal34))) {
		displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
		return;
	}

	if(angleInY == 1) {
		REG_X = REGISTER_X;
		REG_Y = REGISTER_Y;
	}
	else {
		REG_X = REGISTER_Y;
		REG_Y = REGISTER_X;
	}

	dataTypeX = getRegisterDataType(REG_X);
	dataTypeY = getRegisterDataType(REG_Y);
	if(!((dataTypeX == dtLongInteger || dataTypeX == dtReal34) &&
	     (dataTypeY == dtLongInteger || dataTypeY == dtReal34))) {
		displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REG_X);
		return;
	}

	yAngularMode = getRegisterAngularMode(REG_Y);
	if(!saveLastX()) {
		return;
	}

	if(dataTypeX == dtLongInteger) {
		convertLongIntegerRegisterToReal(REG_X, &x, &ctxtReal39);
	}
	else {
		real34ToReal(REGISTER_REAL34_DATA(REG_X), &x);
	}

	if(dataTypeY == dtReal34 && yAngularMode == amNone) {
		yAngularMode = currentAngularMode;
	}
	if(dataTypeY == dtLongInteger) {
		convertLongIntegerRegisterToReal(REG_Y, &y, &ctxtReal39);
	}
	else {
		real34ToReal(REGISTER_REAL34_DATA(REG_Y), &y);
	}
	convertAngleFromTo(&y, yAngularMode, amRadian, &ctxtReal39);
	realPolarToRectangular(&x, &y, &x, &y, &ctxtReal39);

	if(getSystemFlag(FLAG_HPRP)) {
		REG_X = REGISTER_X;
		REG_Y = REGISTER_Y;
	}
	else {
		REG_X = REGISTER_Y;
		REG_Y = REGISTER_X;
	}

	reallocateRegister(REG_X, dtReal34, 0, amNone);
	reallocateRegister(REG_Y, dtReal34, 0, amNone);
	convertRealToReal34ResultRegister(&x, REG_X);
	convertRealToReal34ResultRegister(&y, REG_Y);

	if(getSystemFlag(FLAG_HPRP)) {
		temporaryInformation = TI_X_Y;
	}
	else {
		temporaryInformation = TI_X_Y_SWAPPED;
	}
}

void oracle_fnToRect(uint16_t angleInY) {
	uint32_t dataTypeX, dataTypeY;
	calcRegister_t REG_X, REG_Y;
	angularMode_t yAngularMode;
	real_t x, y;

	if((int8_t)angleInY == 1) {
		REG_X = REGISTER_X;
		REG_Y = REGISTER_Y;
	}
	else {
		REG_X = REGISTER_Y;
		REG_Y = REGISTER_X;
	}

	dataTypeX = getRegisterDataType(REG_X);
	dataTypeY = getRegisterDataType(REG_Y);
	if(!((dataTypeX == dtLongInteger || dataTypeX == dtReal34) &&
	     (dataTypeY == dtLongInteger || dataTypeY == dtReal34))) {
		displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REG_X);
		moreInfoOnError("In function fnToRect:", "cannot convert current X/Y pair to rectangular coordinates", NULL, NULL);
		return;
	}

	yAngularMode = getRegisterAngularMode(REG_Y);
	if(!saveLastX()) {
		return;
	}

	if(dataTypeX == dtLongInteger) {
		convertLongIntegerRegisterToReal(REG_X, &x, &ctxtReal39);
	}
	else {
		real34ToReal(REGISTER_REAL34_DATA(REG_X), &x);
	}

	if(dataTypeY == dtLongInteger) {
		yAngularMode = currentAngularMode;
	}
	else if(yAngularMode == amNone) {
		yAngularMode = currentAngularMode;
	}

	if(dataTypeY == dtLongInteger) {
		convertLongIntegerRegisterToReal(REG_Y, &y, &ctxtReal39);
	}
	else {
		real34ToReal(REGISTER_REAL34_DATA(REG_Y), &y);
	}
	convertAngleFromTo(&y, yAngularMode, amRadian, &ctxtReal39);
	realPolarToRectangular(&x, &y, &x, &y, &ctxtReal39);

	if(getSystemFlag(FLAG_HPRP)) {
		REG_X = REGISTER_X;
		REG_Y = REGISTER_Y;
	}
	else {
		REG_X = REGISTER_Y;
		REG_Y = REGISTER_X;
	}

	reallocateRegister(REG_X, dtReal34, 0, amNone);
	reallocateRegister(REG_Y, dtReal34, 0, amNone);
	convertRealToReal34ResultRegister(&x, REG_X);
	convertRealToReal34ResultRegister(&y, REG_Y);

	if(getSystemFlag(FLAG_HPRP)) {
		temporaryInformation = TI_X_Y;
	}
	else {
		temporaryInformation = TI_X_Y_SWAPPED;
	}
}

#define fnParallel oracle_fnParallel
#include "../../../upstream/src/c47/mathematics/parallel.c"
#undef fnParallel

#define fnCross oracle_fnCross
#include "../../../upstream/src/c47/mathematics/cross.c"
#undef fnCross

#define fnDot oracle_fnDot
#include "../../../upstream/src/c47/mathematics/dot.c"
#undef fnDot

#define fnSdl oracle_fnSdl
#define fnSdr oracle_fnSdr
#include "../../../upstream/src/c47/mathematics/shiftDigits.c"
#undef fnSdr
#undef fnSdl

#ifndef STD_SQUARE_ROOT
#define STD_SQUARE_ROOT ""
#endif

#ifndef STD_x_UNDER_ROOT
#define STD_x_UNDER_ROOT ""
#endif

void oracle_curtReal(void);
void oracle_sqrtComplex75(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
void oracle_sqrtComplex159(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
void oracle_sqrtComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
#define curtReal oracle_curtReal
#define rootLonI oracle_rootLonI
#define sqrtComplex75 oracle_sqrtComplex75
#define sqrtComplex159 oracle_sqrtComplex159
#define sqrtComplex oracle_sqrtComplex
#define fnSquareRoot oracle_fnSquareRoot
#include "../../../upstream/src/c47/mathematics/squareRoot.c"
#undef fnSquareRoot
#undef sqrtComplex
#undef sqrtComplex159
#undef sqrtComplex75
#undef rootLonI
#undef curtReal

void oracle_curtReal(void) {
}

void oracle_curtReal_impl(void);
void oracle_curtComplex75(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
void oracle_curtComplex159(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
void oracle_curtComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
#define rootLonI oracle_rootLonI
#define curtReal oracle_curtReal_impl
#define curtComplex75 oracle_curtComplex75
#define curtComplex159 oracle_curtComplex159
#define curtComplex oracle_curtComplex
#define fnCubeRoot oracle_fnCubeRoot
#include "../../../upstream/src/c47/mathematics/cubeRoot.c"
#undef fnCubeRoot
#undef curtComplex
#undef curtComplex159
#undef curtComplex75
#undef curtReal
#undef rootLonI

#define cosComplex oracle_cosComplex
#define fnFib oracle_fnFib
#include "../../../upstream/src/c47/mathematics/fib.c"
#undef fnFib
#undef cosComplex

#define linpol oracle_linpol
#define fnLINPOL oracle_fnLINPOL
#include "../../../upstream/src/c47/mathematics/linpol.c"
#undef fnLINPOL
#undef linpol

#define FIRST_LOCAL_REGISTER REGISTER_X
#define currentNumberOfLocalRegisters 4
#define INC_FLAG 0
#define DEC_FLAG 1
#define fnDec oracle_fnDec
#define fnInc oracle_fnInc
#define incDecError oracle_incDecError
#define incDecLonI oracle_incDecLonI
#define incDecReal oracle_incDecReal
#define incDecCplx oracle_incDecCplx
#define incDecShoI oracle_incDecShoI
#define incDecTime oracle_incDecTime
void oracle_incDecError(uint16_t regist, uint8_t flag);
void oracle_incDecLonI(uint16_t regist, uint8_t flag);
void oracle_incDecReal(uint16_t regist, uint8_t flag);
void oracle_incDecCplx(uint16_t regist, uint8_t flag);
void oracle_incDecShoI(uint16_t regist, uint8_t flag);
void oracle_incDecTime(uint16_t regist, uint8_t flag);
#include "../../../upstream/src/c47/mathematics/incDec.c"
#undef incDecTime
#undef incDecShoI
#undef incDecCplx
#undef incDecReal
#undef incDecLonI
#undef incDecError
#undef fnInc
#undef fnDec
#undef DEC_FLAG
#undef INC_FLAG
#undef currentNumberOfLocalRegisters
#undef FIRST_LOCAL_REGISTER

#define fnPercentMRR oracle_fnPercentMRR
#include "../../../upstream/src/c47/mathematics/percentMRR.c"
#undef fnPercentMRR

#define fnPercentPlusMG oracle_fnPercentPlusMG
#include "../../../upstream/src/c47/mathematics/percentPlusMG.c"
#undef fnPercentPlusMG

#define fnPercentT oracle_fnPercentT
#include "../../../upstream/src/c47/mathematics/percentT.c"
#undef fnPercentT

#define fnDeltaPercent oracle_fnDeltaPercent
#include "../../../upstream/src/c47/mathematics/deltaPercent.c"
#undef fnDeltaPercent

#define fnLogXY oracle_fnLogXY
#include "../../../upstream/src/c47/mathematics/logxy.c"
#undef fnLogXY

void oracle_unitVectorError(void);
void oracle_unitVectorCplx(void);
void oracle_unitVectorRema(void);
void oracle_unitVectorCxma(void);
#define unitVectorError oracle_unitVectorError
#define unitVectorCplx oracle_unitVectorCplx
#define unitVectorRema oracle_unitVectorRema
#define unitVectorCxma oracle_unitVectorCxma
#define fnUnitVector oracle_fnUnitVector_upstream
#include "../../../upstream/src/c47/mathematics/unitVector.c"
#undef fnUnitVector
#undef unitVectorCxma
#undef unitVectorRema
#undef unitVectorCplx
#undef unitVectorError

static void oracle_unitVectorErrorFixed(void) {
	char message[128];
	sprintf(message, "cannot calculate the unit vector of %s", getRegisterDataTypeName(REGISTER_X, true, false));
	displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
	moreInfoOnError("In function fnUnitVector:", message, NULL, NULL);
}

static void oracle_unitVectorRemaFixed(void) {
	real34Matrix_t matrix;
	real_t elem, sum;

	linkToRealMatrixRegister(REGISTER_X, &matrix);
	realSetZero(&sum);
	for(int i = 0; i < matrix.header.matrixRows * matrix.header.matrixColumns && i < 4; ++i) {
		real34ToReal(&matrix.matrixElements[i], &elem);
		realMultiply(&elem, &elem, &elem, &ctxtReal39);
		realAdd(&sum, &elem, &sum, &ctxtReal39);
	}
	realSquareRoot(&sum, &sum, &ctxtReal39);
	for(int i = 0; i < matrix.header.matrixRows * matrix.header.matrixColumns && i < 4; ++i) {
		real34ToReal(&matrix.matrixElements[i], &elem);
		realDivide(&elem, &sum, &elem, &ctxtReal39);
		realToReal34(&elem, &matrix.matrixElements[i]);
	}
	convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
}

static void oracle_unitVectorCxmaFixed(void) {
	complex34Matrix_t matrix;
	real_t real, imag, sum;

	linkToComplexMatrixRegister(REGISTER_X, &matrix);
	realSetZero(&sum);
	for(int i = 0; i < matrix.header.matrixRows * matrix.header.matrixColumns && i < 4; ++i) {
		real34ToReal(&matrix.matrixElements[i].real, &real);
		realMultiply(&real, &real, &real, &ctxtReal39);
		realAdd(&sum, &real, &sum, &ctxtReal39);
		real34ToReal(&matrix.matrixElements[i].imag, &imag);
		realMultiply(&imag, &imag, &imag, &ctxtReal39);
		realAdd(&sum, &imag, &sum, &ctxtReal39);
	}
	realSquareRoot(&sum, &sum, &ctxtReal39);
	for(int i = 0; i < matrix.header.matrixRows * matrix.header.matrixColumns && i < 4; ++i) {
		real34ToReal(&matrix.matrixElements[i].real, &real);
		real34ToReal(&matrix.matrixElements[i].imag, &imag);
		divComplexComplex(&real, &imag, &sum, const_0, &real, &imag, &ctxtReal39);
		realToReal34(&real, &matrix.matrixElements[i].real);
		realToReal34(&imag, &matrix.matrixElements[i].imag);
	}
	convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
}

void oracle_fnUnitVector(uint16_t unusedButMandatoryParameter) {
	(void)unusedButMandatoryParameter;

	if(!saveLastX()) {
		return;
	}

	switch(getRegisterDataType(REGISTER_X)) {
		case dtComplex34:
			oracle_unitVectorCplx();
			break;
		case dtReal34Matrix:
			oracle_unitVectorRemaFixed();
			break;
		case dtComplex34Matrix:
			oracle_unitVectorCxmaFixed();
			break;
		default:
			oracle_unitVectorErrorFixed();
			break;
	}

	adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}
