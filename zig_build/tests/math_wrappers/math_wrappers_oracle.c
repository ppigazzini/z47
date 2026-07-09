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
#include "../../../src/c47/mathematics/min.c"
#undef fnMin

#define fnMax oracle_fnMax
#include "../../../src/c47/mathematics/max.c"
#undef fnMax

#define fnCeil oracle_fnCeil
#include "../../../src/c47/mathematics/ceil.c"
#undef fnCeil

#define fnFloor oracle_fnFloor
#include "../../../src/c47/mathematics/floor.c"
#undef fnFloor

#define integerPartNoOp oracle_integerPartNoOp
#define integerPartReal oracle_integerPartReal
#define integerPartCplx oracle_integerPartCplx
#define fnIp oracle_fnIp
#include "../../../src/c47/mathematics/integerPart.c"
#undef fnIp
#undef integerPartCplx
#undef integerPartReal
#undef integerPartNoOp

#define fnLint oracle_fnLint
#include "../../../src/c47/mathematics/integerPartLonginteger.c"
#undef fnLint

#define fnSint oracle_fnSint
#include "../../../src/c47/mathematics/integerPartShortinteger.c"
#undef fnSint

#define fpLonI oracle_fpLonI
#define fpShoI oracle_fpShoI
#define fpReal oracle_fpReal
#define fnFp oracle_fnFp
#include "../../../src/c47/mathematics/fractionalPart.c"
#undef fnFp
#undef fpReal
#undef fpShoI
#undef fpLonI

#define sinComplex oracle_sinComplex
#define fnSinc oracle_fnSinc
#include "../../../src/c47/mathematics/sinc.c"
#undef fnSinc
#undef sinComplex

#define fnSincpi oracle_fnSincpi
#include "../../../src/c47/mathematics/sincpi.c"
#undef fnSincpi

#define lnComplex oracle_lnComplex
#define fnLn oracle_fnLn
#include "../../../src/c47/mathematics/ln.c"
#undef fnLn
#undef lnComplex

#define fnLnP1 oracle_fnLnP1
#include "../../../src/c47/mathematics/lnPOne.c"
#undef fnLnP1

#define sqrt1Px2Complex oracle_sqrt1Px2Complex
#define fnSqrt1Px2 oracle_fnSqrt1Px2
#include "../../../src/c47/mathematics/sqrt1Px2.c"
#undef fnSqrt1Px2
#undef sqrt1Px2Complex

#define ArcsinComplex oracle_ArcsinComplex
uint8_t oracle_ArcsinComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
#define fnArcsin oracle_fnArcsin
#include "../../../src/c47/mathematics/arcsin.c"
#undef fnArcsin
#undef ArcsinComplex

#define fnArccos oracle_fnArccos
#include "../../../src/c47/mathematics/arccos.c"
#undef fnArccos

#define ArctanComplex oracle_ArctanComplex
uint8_t oracle_ArctanComplex(real_t *xReal, real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
#define fnArctan oracle_fnArctan
#include "../../../src/c47/mathematics/arctan.c"
#undef fnArctan
#undef ArctanComplex

#define ArcsinhReal oracle_ArcsinhReal
#define ArcsinhComplex oracle_ArcsinhComplex
uint8_t oracle_ArcsinhReal(const real_t *x, real_t *res, realContext_t *realContext);
uint8_t oracle_ArcsinhComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
#define fnArcsinh oracle_fnArcsinh
#include "../../../src/c47/mathematics/arcsinh.c"
#undef fnArcsinh
#undef ArcsinhComplex
#undef ArcsinhReal

#define realArcosh oracle_realArcosh
void oracle_realArcosh(const real_t *x, real_t *res, realContext_t *realContext);
#define fnArccosh oracle_fnArccosh
#include "../../../src/c47/mathematics/arccosh.c"
#undef fnArccosh
#undef realArcosh

#define fnArctanh oracle_fnArctanh
#include "../../../src/c47/mathematics/arctanh.c"
#undef fnArctanh

#define fnInvert oracle_fnInvert
#include "../../../src/c47/mathematics/invert.c"
#undef fnInvert

#define fnSign oracle_fnSign
#include "../../../src/c47/mathematics/sign.c"
#undef fnSign

#define chsShoI oracle_chsShoI
#define chsReal oracle_chsReal
#define chsCplx oracle_chsCplx
#define fnChangeSign oracle_fnChangeSign
#include "../../../src/c47/mathematics/changeSign.c"
#undef fnChangeSign
#undef chsCplx
#undef chsReal
#undef chsShoI

#define sinComplex oracle_sinComplex
#define sinCosReal oracle_sinCosReal
#define sinCosCplx oracle_sinCosCplx
#define fnSin oracle_fnSin
#include "../../../src/c47/mathematics/sin.c"
#undef fnSin
#undef sinCosCplx
#undef sinCosReal
#undef sinComplex

#define cosComplex oracle_cosComplex
#define fnCos oracle_fnCos
#include "../../../src/c47/mathematics/cos.c"
#undef fnCos
#undef cosComplex

#define TanComplex oracle_TanComplex
#define fnTan oracle_fnTan
uint8_t oracle_TanComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
#include "../../../src/c47/mathematics/tan.c"
#undef fnTan
#undef TanComplex

#define sinhCoshReal oracle_sinhCoshReal
#define sinhCoshCplx oracle_sinhCoshCplx
#define fnSinh oracle_fnSinh
#include "../../../src/c47/mathematics/sinh.c"
#undef fnSinh
#undef sinhCoshCplx
#undef sinhCoshReal

#define sinhCoshReal oracle_sinhCoshReal
#define sinhCoshCplx oracle_sinhCoshCplx
#define fnCosh oracle_fnCosh
#include "../../../src/c47/mathematics/cosh.c"
#undef fnCosh
#undef sinhCoshCplx
#undef sinhCoshReal

#define TanhComplex oracle_TanhComplex
#define fnTanh oracle_fnTanh
uint8_t oracle_TanhComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
#include "../../../src/c47/mathematics/tanh.c"
#undef fnTanh
#undef TanhComplex

#define realExpLimitCheck oracle_realExpLimitCheck
#define realExp oracle_realExp
#define expComplex oracle_expComplex
#define fnExp oracle_fnExp
#include "../../../src/c47/mathematics/exp.c"
#undef fnExp
#undef expComplex
#undef realExp
#undef realExpLimitCheck

#define sinComplex oracle_sinComplex
#define expComplex oracle_expComplex
#define realExpM1 oracle_realExpM1
void oracle_realExpM1(const real_t *x, real_t *res, realContext_t *realContext);
#define fnExpM1 oracle_fnExpM1
#include "../../../src/c47/mathematics/expMOne.c"
#undef fnExpM1
#undef realExpM1
#undef expComplex
#undef sinComplex

#define fnExpt oracle_fnExpt
#include "../../../src/c47/mathematics/expt.c"
#undef fnExpt

#define fnBn oracle_fnBn
#define fnBnStar oracle_fnBnStar
#include "../../../src/c47/mathematics/bn.c"
#undef fnBnStar
#undef fnBn

#define fnErf oracle_fnErf
#include "../../../src/c47/mathematics/erf.c"
#undef fnErf

#define fnErfc oracle_fnErfc
#include "../../../src/c47/mathematics/erfc.c"
#undef fnErfc

#define logxyLonI oracle_logxyLonI
#define logxyReal oracle_logxyReal
#define logxyCplx oracle_logxyCplx
#define realLog10 oracle_realLog10
void oracle_realLog10(const real_t *x, real_t *res, realContext_t *realContext);
#define fnLog10 oracle_fnLog10
#include "../../../src/c47/mathematics/log10.c"
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
#include "../../../src/c47/mathematics/2pow.c"
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
#include "../../../src/c47/mathematics/10pow.c"
#undef fn10Pow
#undef realExp
#undef intPowCplx
#undef intPowReal
#undef realPower10

#define fnLog2 oracle_fnLog2
#include "../../../src/c47/mathematics/log2.c"
#undef fnLog2

#define expComplex oracle_expComplex
#define eulersFormula oracle_eulersFormula
#define fnEulersFormula oracle_fnEulersFormula
#include "../../../src/c47/mathematics/eulersFormula.c"
#undef fnEulersFormula
#undef eulersFormula
#undef expComplex

#define fnWinverse oracle_fnWinverse
#include "../../../src/c47/mathematics/w_inverse.c"
#undef fnWinverse

#define fnWnegative oracle_fnWnegative
#include "../../../src/c47/mathematics/w_negative.c"
#undef fnWnegative

#define fnWpositive oracle_fnWpositive
#include "../../../src/c47/mathematics/w_positive.c"
#undef fnWpositive

#define fnGcd oracle_fnGcd
#include "../../../src/c47/mathematics/gcd.c"
#undef fnGcd

#define fnLcm oracle_fnLcm
#include "../../../src/c47/mathematics/lcm.c"
#undef fnLcm

#define modReal oracle_modReal
#define fnMod oracle_fnMod
#include "../../../src/c47/mathematics/modulo.c"
#undef fnMod
#undef modReal

#define fnRmd oracle_fnRmd
#include "../../../src/c47/mathematics/remainder.c"
#undef fnRmd

#define fnDblMultiply oracle_fnDblMultiply
#include "../../../src/c47/mathematics/dblMultiplication.c"
#undef fnDblMultiply

#define dblDivide oracle_dblDivide
#define fnDblDivide oracle_fnDblDivide
#define fnDblDivideRemainder oracle_fnDblDivideRemainder
#include "../../../src/c47/mathematics/dblDivision.c"
#undef fnDblDivideRemainder
#undef fnDblDivide
#undef dblDivide

#define fnUlp oracle_fnUlp
#include "../../../src/c47/mathematics/ulp.c"
#undef fnUlp

#define mant oracle_mant
#define mantError oracle_mantError
#define mantLonI oracle_mantLonI
#define mantReal oracle_mantReal
#define fnMant oracle_fnMant
void mantError(void);
void mantLonI(void);
void mantReal(void);
#include "../../../src/c47/mathematics/mant.c"
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
#include "../../../src/c47/mathematics/roundi.c"
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
#include "../../../src/c47/mathematics/decomp.c"
#undef fnDecomp
#undef decompReal
#undef decompLonI
#undef decompError
#undef Decomp

#define fnNeighb oracle_fnNeighb
#include "../../../src/c47/mathematics/neighb.c"
#undef fnNeighb

#define fnIxyz oracle_fnIxyz
#include "../../../src/c47/mathematics/ixyz.c"
#undef fnIxyz

#define log z47_math_wrappers_log
#define fnFactorial oracle_fnFactorial
#include "../../../src/c47/mathematics/factorial.c"
#undef fnFactorial
#undef log

#define realRandomU01 oracle_realRandomU01
#define fnRandom oracle_fnRandom
#define fnRandomI oracle_fnRandomI
#define fnSeed oracle_fnSeed
#include "../../../src/c47/mathematics/random.c"
#undef fnSeed
#undef fnRandomI
#undef fnRandom
#undef realRandomU01

static void oracle_compareTypeErrorX(void) {
	temporaryInformation = 12;
	displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, (calcRegister_t)103);
}

void oracle_fnCheckInteger(uint16_t mode) {
	longInteger_t value;
	bool_t frac;

	if(getRegisterAsLongIntQuiet(REGISTER_X, value, &frac) != ERROR_NONE) {
		oracle_compareTypeErrorX();
	}
	else if(frac) {
		temporaryInformation = 12 + (mode == 3);
	}
	else {
		const int is_odd = value[0]._mp_size != 0 && (value[0]._mp_d[0] & 1u) != 0;
		refreshLcd(NULL);

		switch(mode) {
			case 0:
				temporaryInformation = 13;
				break;

			case 1:
				temporaryInformation = 12 + (!is_odd);
				break;

			case 2:
				temporaryInformation = 12 + is_odd;
				break;

			case 3:
				temporaryInformation = 12;
				break;

			default:
				break;
		}
	}

	longIntegerFree(value);
}

void oracle_fnCheckForZero(uint16_t mode) {
	int real_is_zero;
	int imag_is_zero;

	switch(getRegisterDataType(REGISTER_X)) {
		case 0: {
			longInteger_t value;

			convertLongIntegerRegisterToLongInteger(REGISTER_X, value);
			real_is_zero = value[0]._mp_size == 0;
			imag_is_zero = 1;
			longIntegerFree(value);
			break;
		}

		case 8: {
			uint64_t value;

			convertShortIntegerRegisterToUInt64(REGISTER_X, NULL, &value);
			real_is_zero = value == 0;
			imag_is_zero = 1;
			break;
		}

		case 2: {
			const complex34_t *cpx = REGISTER_COMPLEX34_DATA(REGISTER_X);
			real_is_zero = real34IsZero(&cpx->real);
			imag_is_zero = real34IsZero(&cpx->imag);
			break;
		}

		case 3:
		case 4:
		case 1:
			real_is_zero = real34IsZero(REGISTER_REAL34_DATA(REGISTER_X));
			imag_is_zero = 1;
			break;

		default:
			oracle_compareTypeErrorX();
			return;
	}

	switch(mode) {
		case 2527:
			temporaryInformation = 12 + real_is_zero;
			break;

		case 2528:
			temporaryInformation = 12 + imag_is_zero;
			break;

		case 2529:
			temporaryInformation = 12 + (!real_is_zero);
			break;

		case 2530:
			temporaryInformation = 12 + (!imag_is_zero);
			break;

		default:
			break;
	}
}

void oracle_fnCheckType(uint16_t type) {
	temporaryInformation = 12 + (getRegisterDataType(REGISTER_X) == type);
}

void oracle_fnCheckReal(uint16_t unusedButMandatoryParameter) {
	const uint32_t t = getRegisterDataType(REGISTER_X);

	(void)unusedButMandatoryParameter;
	temporaryInformation = 12 + (t <= 4 || t == 8);
}

void oracle_fnCheckAngle(uint16_t unusedButMandatoryParameter) {
	(void)unusedButMandatoryParameter;
	temporaryInformation = 12 + (getRegisterDataType(REGISTER_X) == 1 && getRegisterAngularMode(REGISTER_X) != 5);
}

void oracle_fnCheckMatrix(uint16_t unusedButMandatoryParameter) {
	const uint32_t t = getRegisterDataType(REGISTER_X);

	(void)unusedButMandatoryParameter;
	temporaryInformation = 12 + (t == 6 || t == 7);
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

void oracle_fnIsConverged(uint16_t mode) {
	real_t xReal, xImag, yReal, yImag, tol;
	bool_t isComplex = false;

	convergenceTolerence(&tol);
	if(!oracle_getConvergenceInput(REGISTER_X, &xReal, &xImag, &isComplex) || !oracle_getConvergenceInput(REGISTER_Y, &yReal, &yImag, &isComplex)) {
		oracle_compareTypeErrorX();
		return;
	}

	if(realIsNaN(&xReal) || realIsNaN(&yReal) || realIsNaN(&xImag) || realIsNaN(&yImag)) {
		temporaryInformation = 12 + ((mode & 0x4) != 0);
	}
	else if(realIsInfinite(&xReal) || realIsInfinite(&yReal) || realIsInfinite(&xImag) || realIsInfinite(&yImag)) {
		temporaryInformation = 12 + ((mode & 0x2) != 0);
	}
	else if(mode & 0x1) {
		temporaryInformation = 12 + (isComplex ? WP34S_ComplexAbsError(&xReal, &xImag, &yReal, &yImag, &tol, &ctxtReal39) : WP34S_AbsoluteError(&xReal, &yReal, &tol, &ctxtReal39));
	}
	else {
		temporaryInformation = 12 + (isComplex ? WP34S_ComplexRelativeError(&xReal, &xImag, &yReal, &yImag, &tol, &ctxtReal39) : WP34S_RelativeError(&xReal, &yReal, &tol, &ctxtReal39));
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

void oracle_fnXLessThan(uint16_t regist) {
	oracle_compareScalarRegister((calcRegister_t)regist, ORACLE_COMPARE_MODE_LESS_THAN);
}

void oracle_fnXLessEqual(uint16_t regist) {
	oracle_compareScalarRegister((calcRegister_t)regist, ORACLE_COMPARE_MODE_LESS_EQUAL);
}

void oracle_fnXGreaterThan(uint16_t regist) {
	oracle_compareScalarRegister((calcRegister_t)regist, ORACLE_COMPARE_MODE_GREATER_THAN);
}

void oracle_fnXGreaterEqual(uint16_t regist) {
	oracle_compareScalarRegister((calcRegister_t)regist, ORACLE_COMPARE_MODE_GREATER_EQUAL);
}

void oracle_fnXEqualsTo(uint16_t regist) {
	oracle_compareScalarRegister((calcRegister_t)regist, ORACLE_COMPARE_MODE_EQUAL);
}

void oracle_fnXNotEqual(uint16_t regist) {
	oracle_compareScalarRegister((calcRegister_t)regist, ORACLE_COMPARE_MODE_NOT_EQUAL);
}

void oracle_fnXAlmostEqual(uint16_t regist) {
	const uint32_t xType = getRegisterDataType(REGISTER_X);
	const uint32_t regType = getRegisterDataType((calcRegister_t)regist);

	if((xType != dtShortInteger && xType != dtLongInteger) || (regType != dtShortInteger && regType != dtLongInteger)) {
		z47_math_wrappers_legacy_fnXAlmostEqual(regist);
		return;
	}

	oracle_compareScalarRegister((calcRegister_t)regist, ORACLE_COMPARE_MODE_EQUAL);
}

void oracle_fnRound(uint16_t unusedButMandatoryParameter) {
	const uint32_t xType = getRegisterDataType(REGISTER_X);

	if(xType != dtShortInteger && xType != dtLongInteger) {
		z47_math_wrappers_legacy_fnRound(unusedButMandatoryParameter);
		return;
	}

	if(!saveLastX()) {
		return;
	}

	adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}

enum {
	ORACLE_INTEGER_ADD = 0,
	ORACLE_INTEGER_SUBTRACT = 1,
	ORACLE_INTEGER_MULTIPLY = 2,
};

static bool_t oracle_tryIntegerLongArithmetic(uint8_t operation) {
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

	if(xIsShort && yIsShort) {
		uint64_t *const xShort = (uint64_t *)getRegisterDataPointer(REGISTER_X);
		const uint64_t *const yShort = (const uint64_t *)getRegisterDataPointer(REGISTER_Y);

		setRegisterTag(REGISTER_X, getRegisterTag(REGISTER_Y));
		if(operation == ORACLE_INTEGER_SUBTRACT) {
			*xShort = WP34S_intSubtract(*yShort, *xShort);
		}
		else if(operation == ORACLE_INTEGER_MULTIPLY) {
			*xShort = WP34S_intMultiply(*yShort, *xShort);
		}
		else {
			*xShort = WP34S_intAdd(*yShort, *xShort);
		}

		adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
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

	if(operation == ORACLE_INTEGER_SUBTRACT) {
		mpz_sub(x, y, x);
	}
	else if(operation == ORACLE_INTEGER_MULTIPLY) {
		mpz_mul(x, y, x);
	}
	else {
		mpz_add(x, y, x);
	}

	convertLongIntegerToLongIntegerRegister(x, REGISTER_X);
	mpz_clear(y);
	mpz_clear(x);
	adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
	return true;
}

static void oracle_applyDyadicRealOperation(uint8_t operation, const real_t *lhs, const real_t *rhs, real_t *result) {
	if(operation == ORACLE_INTEGER_SUBTRACT) {
		realSubtract(lhs, rhs, result, &ctxtReal39);
	}
	else if(operation == ORACLE_INTEGER_MULTIPLY) {
		realMultiply(lhs, rhs, result, &ctxtReal39);
	}
	else {
		realAdd(lhs, rhs, result, &ctxtReal39);
	}
}

static void oracle_applyDyadicReal34Operation(uint8_t operation, const real34_t *lhs, const real34_t *rhs, real34_t *result) {
	if(operation == ORACLE_INTEGER_SUBTRACT) {
		real34Subtract(lhs, rhs, result);
	}
	else if(operation == ORACLE_INTEGER_MULTIPLY) {
		real34Multiply(lhs, rhs, result);
	}
	else {
		real34Add(lhs, rhs, result);
	}
}

static bool_t oracle_tryScalarIntRealArithmetic(uint8_t operation) {
	const uint32_t xType = getRegisterDataType(REGISTER_X);
	const uint32_t yType = getRegisterDataType(REGISTER_Y);
	const bool_t xIsReal = xType == dtReal34;
	const bool_t yIsReal = yType == dtReal34;
	const bool_t xIsInt = xType == dtLongInteger || xType == dtShortInteger;
	const bool_t yIsInt = yType == dtLongInteger || yType == dtShortInteger;

	if(!((xIsReal && yIsInt) || (yIsReal && xIsInt))) {
		return false;
	}

	if(!saveLastX()) {
		return true;
	}

	if(xIsReal) {
		real_t y;
		real_t x;
		angularMode_t xAngularMode = getRegisterAngularMode(REGISTER_X);

		if(yType == dtLongInteger) {
			convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
		}
		else {
			convertShortIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
		}
		real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
		if(xAngularMode == amNone) {
			oracle_applyDyadicRealOperation(operation, &y, &x, &x);
			convertRealToReal34ResultRegister(&x, REGISTER_X);
		}
		else {
			convertAngleFromTo(&x, xAngularMode, currentAngularMode, &ctxtReal39);
			oracle_applyDyadicRealOperation(operation, &y, &x, &x);
			convertRealToReal34ResultRegister(&x, REGISTER_X);
			setRegisterAngularMode(REGISTER_X, currentAngularMode);
		}
	}
	else {
		real_t y;
		real_t x;
		angularMode_t yAngularMode = getRegisterAngularMode(REGISTER_Y);

		real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
		if(xType == dtLongInteger) {
			convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
		}
		else {
			convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
		}
		reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
		if(yAngularMode == amNone) {
			oracle_applyDyadicRealOperation(operation, &y, &x, &x);
			convertRealToReal34ResultRegister(&x, REGISTER_X);
		}
		else {
			convertAngleFromTo(&y, yAngularMode, currentAngularMode, &ctxtReal39);
			oracle_applyDyadicRealOperation(operation, &y, &x, &x);
			convertRealToReal34ResultRegister(&x, REGISTER_X);
			setRegisterAngularMode(REGISTER_X, currentAngularMode);
		}
	}

	adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
	return true;
}

static bool_t oracle_tryScalarRealArithmetic(uint8_t operation) {
	const angularMode_t yAngularMode = getRegisterAngularMode(REGISTER_Y);
	const angularMode_t xAngularMode = getRegisterAngularMode(REGISTER_X);

	if(getRegisterDataType(REGISTER_X) != dtReal34 || getRegisterDataType(REGISTER_Y) != dtReal34) {
		return false;
	}

	if(!saveLastX()) {
		return true;
	}

	if(operation == ORACLE_INTEGER_ADD || operation == ORACLE_INTEGER_SUBTRACT) {
		if(yAngularMode == amNone && xAngularMode == amNone) {
			oracle_applyDyadicReal34Operation(operation, REGISTER_REAL34_DATA(REGISTER_Y), REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(REGISTER_X));
		}
		else {
			real_t y;
			real_t x;
			angularMode_t resolvedYMode = yAngularMode;
			angularMode_t resolvedXMode = xAngularMode;

			real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
			real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
			if(resolvedYMode == amNone) {
				resolvedYMode = currentAngularMode;
			}
			else if(resolvedXMode == amNone) {
				resolvedXMode = currentAngularMode;
			}
			convertAngleFromTo(&y, resolvedYMode, currentAngularMode, &ctxtReal39);
			convertAngleFromTo(&x, resolvedXMode, currentAngularMode, &ctxtReal39);
			oracle_applyDyadicRealOperation(operation, &y, &x, &x);
			convertRealToReal34ResultRegister(&x, REGISTER_X);
			setRegisterAngularMode(REGISTER_X, currentAngularMode);
		}
	}
	else {
		if(yAngularMode == amNone && xAngularMode == amNone) {
			real34Multiply(REGISTER_REAL34_DATA(REGISTER_Y), REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(REGISTER_X));
		}
		else if(yAngularMode != amNone && xAngularMode != amNone) {
			real34Multiply(REGISTER_REAL34_DATA(REGISTER_Y), REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(REGISTER_X));
			setRegisterAngularMode(REGISTER_X, amNone);
		}
		else {
			real_t y;
			real_t x;

			real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
			real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
			realMultiply(&y, &x, &x, &ctxtReal39);
			convertAngleFromTo(&x, yAngularMode != amNone ? yAngularMode : xAngularMode, currentAngularMode, &ctxtReal39);
			convertRealToReal34ResultRegister(&x, REGISTER_X);
			setRegisterAngularMode(REGISTER_X, currentAngularMode);
		}
	}

	adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
	return true;
}

#define fnAdd oracle_full_fnAdd
#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
#endif
#include "../../../src/c47/mathematics/addition.h"
#include "../../../src/c47/mathematics/addition.c"
#undef fnAdd

#define fnSubtract oracle_full_fnSubtract
#include "../../../src/c47/mathematics/subtraction.h"
#include "../../../src/c47/mathematics/subtraction.c"
#undef fnSubtract

#define fnMultiply oracle_full_fnMultiply
#define mulComplexi oracle_mulComplexi
#define mulComplexComplex oracle_mulComplexComplex
#define mulComplexReal oracle_mulComplexReal
#include "../../../src/c47/mathematics/multiplication.h"
#include "../../../src/c47/mathematics/multiplication.c"
#undef mulComplexReal
#undef mulComplexComplex
#undef mulComplexi
#undef fnMultiply

#define fnDivide oracle_full_fnDivide
#define divRealComplex oracle_divRealComplex
#define divComplexComplex oracle_divComplexComplex
#include "../../../src/c47/mathematics/division.h"
#include "../../../src/c47/mathematics/division.c"
#undef divComplexComplex
#undef divRealComplex
#undef fnDivide
#if defined(__clang__)
#pragma clang diagnostic pop
#endif

void oracle_fnAdd(uint16_t unusedButMandatoryParameter) {
	if(oracle_tryIntegerLongArithmetic(ORACLE_INTEGER_ADD) ||
	   oracle_tryScalarIntRealArithmetic(ORACLE_INTEGER_ADD) ||
	   oracle_tryScalarRealArithmetic(ORACLE_INTEGER_ADD)) {
		return;
	}

	oracle_full_fnAdd(unusedButMandatoryParameter);
}

void oracle_fnSubtract(uint16_t unusedButMandatoryParameter) {
	if(oracle_tryIntegerLongArithmetic(ORACLE_INTEGER_SUBTRACT) ||
	   oracle_tryScalarIntRealArithmetic(ORACLE_INTEGER_SUBTRACT) ||
	   oracle_tryScalarRealArithmetic(ORACLE_INTEGER_SUBTRACT)) {
		return;
	}

	oracle_full_fnSubtract(unusedButMandatoryParameter);
}

void oracle_fnMultiply(uint16_t unusedButMandatoryParameter) {
	if(oracle_tryIntegerLongArithmetic(ORACLE_INTEGER_MULTIPLY) ||
	   oracle_tryScalarIntRealArithmetic(ORACLE_INTEGER_MULTIPLY) ||
	   oracle_tryScalarRealArithmetic(ORACLE_INTEGER_MULTIPLY)) {
		return;
	}

	oracle_full_fnMultiply(unusedButMandatoryParameter);
}

static bool_t oracle_tryScalarIntegerOverRealDivide(void) {
	const uint32_t xType = getRegisterDataType(REGISTER_X);
	const uint32_t yType = getRegisterDataType(REGISTER_Y);
	real_t y;

	if(xType != dtReal34 || (yType != dtLongInteger && yType != dtShortInteger)) {
		return false;
	}

	copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);

	if(yType == dtLongInteger) {
		convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
	}
	else {
		convertShortIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
	}

	setRegisterAngularMode(REGISTER_X, amNone);
	if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
		if(realIsZero(&y)) {
			if(getSystemFlag(FLAG_SPCRES)) {
				convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
			}
			else {
				displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
				moreInfoOnError(yType == dtLongInteger ? "In function divLonIReal:" : "In function divShoIReal:", "cannot divide 0 by 0", NULL, NULL);
			}
		}
		else if(getSystemFlag(FLAG_SPCRES)) {
			realToReal34(realIsNegative(&y) ? const_minusInfinity : const_plusInfinity, REGISTER_REAL34_DATA(REGISTER_X));
		}
		else {
			displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
			moreInfoOnError(yType == dtLongInteger ? "In function divLonIReal:" : "In function divShoIReal:", yType == dtLongInteger ? "cannot divide a long integer by 0" : "cannot divide a short integer by 0", NULL, NULL);
		}
	}
	else {
		real_t x;

		real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
		realDivide(&y, &x, &x, &ctxtReal39);
		convertRealToReal34ResultRegister(&x, REGISTER_X);
	}

	adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
	return true;
}

static bool_t oracle_tryScalarRealOverIntegerDivide(void) {
	const uint32_t xType = getRegisterDataType(REGISTER_X);
	const uint32_t yType = getRegisterDataType(REGISTER_Y);
	real_t x;

	if((xType != dtLongInteger && xType != dtShortInteger) || yType != dtReal34) {
		return false;
	}

	copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);

	if(xType == dtLongInteger) {
		convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
	}
	else {
		convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
	}

	reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
	if(realIsZero(&x)) {
		if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y))) {
			if(getSystemFlag(FLAG_SPCRES)) {
				convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
			}
			else {
				displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
				moreInfoOnError(xType == dtLongInteger ? "In function divRealLonI:" : "In function divRealShoI:", "cannot divide 0 by 0", NULL, NULL);
			}
		}
		else if(getSystemFlag(FLAG_SPCRES)) {
			realToReal34(real34IsPositive(REGISTER_REAL34_DATA(REGISTER_Y)) ? const_plusInfinity : const_minusInfinity, REGISTER_REAL34_DATA(REGISTER_X));
		}
		else {
			displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
			moreInfoOnError(xType == dtLongInteger ? "In function divRealLonI:" : "In function divRealShoI:", "cannot divide a real34 by 0", NULL, NULL);
		}
	}
	else {
		real_t y;
		angularMode_t yAngularMode;

		real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
		yAngularMode = getRegisterAngularMode(REGISTER_Y);
		if(yAngularMode == amNone) {
			realDivide(&y, &x, &x, &ctxtReal39);
			convertRealToReal34ResultRegister(&x, REGISTER_X);
		}
		else {
			convertAngleFromTo(&y, yAngularMode, currentAngularMode, &ctxtReal39);
			realDivide(&y, &x, &x, &ctxtReal39);
			convertRealToReal34ResultRegister(&x, REGISTER_X);
			setRegisterAngularMode(REGISTER_X, currentAngularMode);
		}
	}

	adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
	return true;
}

static bool_t oracle_tryScalarRealOverRealDivide(void) {
	if(getRegisterDataType(REGISTER_X) != dtReal34 || getRegisterDataType(REGISTER_Y) != dtReal34) {
		return false;
	}

	copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);
	if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y)) && real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
		if(getSystemFlag(FLAG_SPCRES)) {
			convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
		}
		else {
			displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
			moreInfoOnError("In function divRealReal:", "cannot divide 0 by 0", NULL, NULL);
		}
	}
	else if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
		if(getSystemFlag(FLAG_SPCRES)) {
			realToReal34(real34IsPositive(REGISTER_REAL34_DATA(REGISTER_Y)) ? const_plusInfinity : const_minusInfinity, REGISTER_REAL34_DATA(REGISTER_X));
		}
		else {
			displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
			moreInfoOnError("In function divRealReal:", "cannot divide a real34 by 0", NULL, NULL);
		}
	}
	else {
		real_t y;
		real_t x;
		angularMode_t yAngularMode;
		angularMode_t xAngularMode;

		yAngularMode = getRegisterAngularMode(REGISTER_Y);
		xAngularMode = getRegisterAngularMode(REGISTER_X);
		if(yAngularMode == amNone) {
			real34Divide(REGISTER_REAL34_DATA(REGISTER_Y), REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(REGISTER_X));
			setRegisterAngularMode(REGISTER_X, amNone);
		}
		else {
			real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
			real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
			if(xAngularMode != amNone) {
				convertAngleFromTo(&x, xAngularMode, yAngularMode, &ctxtReal39);
				realDivide(&y, &x, &x, &ctxtReal39);
				convertRealToReal34ResultRegister(&x, REGISTER_X);
				setRegisterAngularMode(REGISTER_X, amNone);
			}
			else {
				realDivide(&y, &x, &x, &ctxtReal39);
				convertAngleFromTo(&x, yAngularMode, currentAngularMode, &ctxtReal39);
				convertRealToReal34ResultRegister(&x, REGISTER_X);
				setRegisterAngularMode(REGISTER_X, currentAngularMode);
			}
		}
	}

	adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
	return true;
}

void oracle_fnDivide(uint16_t unusedButMandatoryParameter) {
	if(oracle_tryScalarIntegerOverRealDivide() ||
	   oracle_tryScalarRealOverIntegerDivide() ||
	   oracle_tryScalarRealOverRealDivide()) {
		return;
	}

	oracle_full_fnDivide(unusedButMandatoryParameter);
}

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

void oracle_fnIDiv(uint16_t unusedButMandatoryParameter) {
	if(!oracle_tryIntegerLongDivide(false)) {
		z47_math_wrappers_legacy_fnIDiv(unusedButMandatoryParameter);
	}
}

void oracle_fnIDivR(uint16_t unusedButMandatoryParameter) {
	if(!oracle_tryIntegerLongDivide(true)) {
		z47_math_wrappers_legacy_fnIDivR(unusedButMandatoryParameter);
	}
}

void oracle_fnCheckNumber(uint16_t unusedButMandatoryParameter) {
	int result = 1;

	(void)unusedButMandatoryParameter;

	switch(getRegisterDataType(REGISTER_X)) {
		default:
			result = 0;
			break;

		case 0:
		case 8:
			break;

		case 2:
			result = !(decQuadIsNaN(REGISTER_IMAG34_DATA(REGISTER_X)) != 0 || real34IsInfinite(REGISTER_IMAG34_DATA(REGISTER_X)));
			/* fall through */
		case 3:
		case 4:
		case 1:
			result &= !(decQuadIsNaN(REGISTER_REAL34_DATA(REGISTER_X)) != 0 || real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)));
			break;
	}

	temporaryInformation = 12 + result;
}

void oracle_fnCheckNaN(uint16_t unusedButMandatoryParameter) {
	(void)unusedButMandatoryParameter;

	switch(getRegisterDataType(REGISTER_X)) {
		case 2:
			temporaryInformation = 12 + ((decQuadIsNaN(REGISTER_IMAG34_DATA(REGISTER_X)) != 0) || (decQuadIsNaN(REGISTER_REAL34_DATA(REGISTER_X)) != 0));
			break;

		case 3:
		case 4:
		case 1:
			temporaryInformation = 12 + (decQuadIsNaN(REGISTER_REAL34_DATA(REGISTER_X)) != 0);
			break;

		case 6: {
			const matrixHeader_t *header = (const matrixHeader_t *)getRegisterDataPointer(REGISTER_X);
			const real34_t *values = (const real34_t *)((const uint8_t *)header + sizeof(*header));
			uint32_t elements = header->matrixRows * (uint32_t)header->matrixColumns;
			int check = 0;

			for(uint32_t i = 0; i < elements; ++i) {
				if(decQuadIsNaN(values + i) != 0) {
					check = 1;
					break;
				}
			}

			temporaryInformation = 12 + check;
			break;
		}

		case 7: {
			const matrixHeader_t *header = (const matrixHeader_t *)getRegisterDataPointer(REGISTER_X);
			const complex34_t *values = (const complex34_t *)((const uint8_t *)header + sizeof(*header));
			uint32_t elements = header->matrixRows * (uint32_t)header->matrixColumns;
			int check = 0;

			for(uint32_t i = 0; i < elements; ++i) {
				if(decQuadIsNaN(&values[i].real) != 0 || decQuadIsNaN(&values[i].imag) != 0) {
					check = 1;
					break;
				}
			}

			temporaryInformation = 12 + check;
			break;
		}

		default:
			oracle_compareTypeErrorX();
			break;
	}
}

void oracle_fnCheckInfinite(uint16_t unusedButMandatoryParameter) {
	(void)unusedButMandatoryParameter;

	switch(getRegisterDataType(REGISTER_X)) {
		case 2:
			temporaryInformation = 12 + (real34IsInfinite(REGISTER_IMAG34_DATA(REGISTER_X)) || real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)));
			break;

		case 3:
		case 4:
		case 1:
			temporaryInformation = 12 + real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X));
			break;

		case 6: {
			const matrixHeader_t *header = (const matrixHeader_t *)getRegisterDataPointer(REGISTER_X);
			const real34_t *values = (const real34_t *)((const uint8_t *)header + sizeof(*header));
			uint32_t elements = header->matrixRows * (uint32_t)header->matrixColumns;
			int check = 0;

			for(uint32_t i = 0; i < elements; ++i) {
				if(real34IsInfinite(values + i)) {
					check = 1;
					break;
				}
			}

			temporaryInformation = 12 + check;
			break;
		}

		case 7: {
			const matrixHeader_t *header = (const matrixHeader_t *)getRegisterDataPointer(REGISTER_X);
			const complex34_t *values = (const complex34_t *)((const uint8_t *)header + sizeof(*header));
			uint32_t elements = header->matrixRows * (uint32_t)header->matrixColumns;
			int check = 0;

			for(uint32_t i = 0; i < elements; ++i) {
				if(real34IsInfinite(&values[i].real) || real34IsInfinite(&values[i].imag)) {
					check = 1;
					break;
				}
			}

			temporaryInformation = 12 + check;
			break;
		}

		default:
			oracle_compareTypeErrorX();
			break;
	}
}

void oracle_fnCheckSpecial(uint16_t unusedButMandatoryParameter) {
	(void)unusedButMandatoryParameter;

	switch(getRegisterDataType(REGISTER_X)) {
		case 2: {
			int imag_special = (decQuadIsNaN(REGISTER_IMAG34_DATA(REGISTER_X)) != 0) || real34IsInfinite(REGISTER_IMAG34_DATA(REGISTER_X));
			int real_special = (decQuadIsNaN(REGISTER_REAL34_DATA(REGISTER_X)) != 0) || real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X));
			temporaryInformation = 12 + (imag_special || real_special);
			break;
		}

		case 3:
		case 4:
		case 1:
			temporaryInformation = 12 + ((decQuadIsNaN(REGISTER_REAL34_DATA(REGISTER_X)) != 0) || real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)));
			break;

		case 6: {
			const matrixHeader_t *header = (const matrixHeader_t *)getRegisterDataPointer(REGISTER_X);
			const real34_t *values = (const real34_t *)((const uint8_t *)header + sizeof(*header));
			uint32_t elements = header->matrixRows * (uint32_t)header->matrixColumns;
			int check = 0;

			for(uint32_t i = 0; i < elements; ++i) {
				if((decQuadIsNaN(values + i) != 0) || real34IsInfinite(values + i)) {
					check = 1;
					break;
				}
			}

			temporaryInformation = 12 + check;
			break;
		}

		case 7: {
			const matrixHeader_t *header = (const matrixHeader_t *)getRegisterDataPointer(REGISTER_X);
			const complex34_t *values = (const complex34_t *)((const uint8_t *)header + sizeof(*header));
			uint32_t elements = header->matrixRows * (uint32_t)header->matrixColumns;
			int check = 0;

			for(uint32_t i = 0; i < elements; ++i) {
				if((decQuadIsNaN(&values[i].real) != 0) || real34IsInfinite(&values[i].real) ||
				   (decQuadIsNaN(&values[i].imag) != 0) || real34IsInfinite(&values[i].imag)) {
					check = 1;
					break;
				}
			}

			temporaryInformation = 12 + check;
			break;
		}

		default:
			oracle_compareTypeErrorX();
			break;
	}
}

void oracle_fnCheckPlusZero(uint16_t unusedButMandatoryParameter) {
	int check = 0;

	(void)unusedButMandatoryParameter;

	switch(getRegisterDataType(REGISTER_X)) {
		case 0: {
			longInteger_t value;
			convertLongIntegerRegisterToLongInteger(REGISTER_X, value);
			check = longIntegerIsZero(value);
			longIntegerFree(value);
			break;
		}

		case 8: {
			uint64_t value;
			int16_t sign;
			convertShortIntegerRegisterToUInt64(REGISTER_X, &sign, &value);
			check = value == 0 && sign == 0;
			break;
		}

		case 2: {
			const complex34_t *cpx = REGISTER_COMPLEX34_DATA(REGISTER_X);
			check = real34IsZero(&cpx->real) && real34IsZero(&cpx->imag) && (!real34IsNegative(&cpx->real) || !real34IsNegative(&cpx->imag));
			break;
		}

		case 3:
		case 4:
		case 1:
			check = !real34IsNegative(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsZero(REGISTER_REAL34_DATA(REGISTER_X));
			break;

		default:
			oracle_compareTypeErrorX();
			return;
	}

	temporaryInformation = 12 + check;
}

void oracle_fnCheckMinusZero(uint16_t unusedButMandatoryParameter) {
	int check = 0;

	(void)unusedButMandatoryParameter;

	switch(getRegisterDataType(REGISTER_X)) {
		case 0:
			break;

		case 8: {
			uint64_t value;
			int16_t sign;
			convertShortIntegerRegisterToUInt64(REGISTER_X, &sign, &value);
			check = value == 0 && sign == 1;
			break;
		}

		case 2: {
			const complex34_t *cpx = REGISTER_COMPLEX34_DATA(REGISTER_X);
			check = real34IsZero(&cpx->real) && real34IsZero(&cpx->imag) && (real34IsNegative(&cpx->real) || real34IsNegative(&cpx->imag));
			break;
		}

		case 3:
		case 4:
		case 1:
			check = real34IsNegative(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsZero(REGISTER_REAL34_DATA(REGISTER_X));
			break;

		default:
			oracle_compareTypeErrorX();
			return;
	}

	temporaryInformation = 12 + check;
}

void oracle_fnCheckMatrixSquare(uint16_t unusedButMandatoryParameter) {
	const uint32_t t = getRegisterDataType(REGISTER_X);

	(void)unusedButMandatoryParameter;

	if(t == 6 || t == 7) {
		const matrixHeader_t *header = (const matrixHeader_t *)getRegisterDataPointer(REGISTER_X);
		temporaryInformation = 12 + (header->matrixRows == header->matrixColumns);
	} else {
		oracle_compareTypeErrorX();
	}
}

void oracle_fnCheckIsVect2d(uint16_t unusedButMandatoryParameter) {
	(void)unusedButMandatoryParameter;

	if(getRegisterDataType(REGISTER_X) == 6) {
		const matrixHeader_t *header = (const matrixHeader_t *)getRegisterDataPointer(REGISTER_X);
		temporaryInformation = 12 + ((header->matrixRows == 1 && header->matrixColumns == 2) || (header->matrixRows == 2 && header->matrixColumns == 1));
	} else {
		oracle_compareTypeErrorX();
	}
}

void oracle_fnCheckIsVect3d(uint16_t unusedButMandatoryParameter) {
	(void)unusedButMandatoryParameter;

	if(getRegisterDataType(REGISTER_X) == 6) {
		const matrixHeader_t *header = (const matrixHeader_t *)getRegisterDataPointer(REGISTER_X);
		temporaryInformation = 12 + ((header->matrixRows == 1 && header->matrixColumns == 3) || (header->matrixRows == 3 && header->matrixColumns == 1));
	} else {
		oracle_compareTypeErrorX();
	}
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

void oracle_fnGetType(uint16_t unusedButMandatoryParameter) {
	const uint32_t dtp = getRegisterDataType(REGISTER_X);
	const uint32_t dam = getRegisterAngularMode(REGISTER_X);

	(void)unusedButMandatoryParameter;

	switch(dtp) {
		case dtLongInteger:
		case dtTime:
		case dtDate:
		case dtString:
		case dtReal34Matrix:
		case dtConfig: {
			if(isRegisterMatrixVector(REGISTER_X)) {
				const uint32_t angle = 5 - (dam & 0x07);
				const uint32_t isCol = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows > 1 && REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns == 1;
				const uint32_t isRow = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows == 1 && REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns > 1;
				const uint32_t T = isCol ? 2 : isRow ? 1 : 0;
				const uint32_t polRec = isRegisterMatrix2dVector(REGISTER_X) ? 2 : (isRegisterMatrix3dVector(REGISTER_X) ? ((getVectorRegisterPolarMode(REGISTER_X) == amPolarCYL) ? 4 : 3) : 0);
				oracle_pushGetTypeRealOut(dtp * 1000 + 100 * angle + 10 * polRec + T);
			}
			else if(dtp == dtReal34Matrix) {
				const uint32_t isCol = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows > 1 && REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns == 1;
				const uint32_t isRow = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows == 1 && REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns > 1;
				if(isCol || isRow) {
					oracle_pushGetTypeRealOut(dtp * 1000 + (isCol ? 2 : 1));
				}
				else {
					oracle_pushGetTypeIntegerOut(dtp);
				}
			}
			else {
				oracle_pushGetTypeIntegerOut(dtp);
			}
			break;
		}
		case dtComplex34Matrix: {
			const uint32_t isPolar = getComplexRegisterPolarMode(REGISTER_X) != 0;
			const uint32_t angle = isPolar ? (5 - (dam & 0x07)) : 0;
			const uint32_t isCol = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows > 1 && REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns == 1;
			const uint32_t isRow = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows == 1 && REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns > 1;
			const uint32_t T = isCol ? 2 : isRow ? 1 : 0;
			const uint32_t polRec = isPolar ? 1 : 0;
			oracle_pushGetTypeRealOut(dtp * 1000 + 100 * angle + 10 * polRec + T);
			break;
		}
		case dtShortInteger:
		case dtReal34:
		case dtComplex34: {
			const uint32_t value = dtp == dtShortInteger ? 10 * (dtp * 100 + (dam & 0x1f)) : 100 * (dtp * 10 + 5 - (dam & 0x07));
			oracle_pushGetTypeRealOut(value);
			break;
		}
		default:
			break;
	}

	temporaryInformation = TI_REGTYPE;
}

#define fnRealPart oracle_fnRealPart
#include "../../../src/c47/mathematics/realPart.c"
#undef fnRealPart

#define fnImaginaryPart oracle_fnImaginaryPart
#include "../../../src/c47/mathematics/imaginaryPart.c"
#undef fnImaginaryPart

#define arg oracle_arg
#define fnArg oracle_fnArg
#include "../../../src/c47/mathematics/arg.c"
#undef fnArg
#undef arg

#define complexMagnitude2 oracle_complexMagnitude2
#define complexMagnitude oracle_complexMagnitude
#define fnMagnitude oracle_fnMagnitude
void complexMagnitude(const real_t *a, const real_t *b, real_t *c, realContext_t *realContext);
#include "../../../src/c47/mathematics/magnitude.c"
#undef fnMagnitude
#undef complexMagnitude
#undef complexMagnitude2

#define conjCplx oracle_conjCplx
#define fnConjugate oracle_fnConjugate_legacy
#include "../../../src/c47/mathematics/conjugate.c"
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
#include "../../../src/c47/mathematics/swapRealImaginary.c"
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
#include "../../../src/c47/mathematics/atan2.c"
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
#include "../../../src/c47/mathematics/percent.c"
#undef fnPercent
#undef percentReal

#define eulersFormula oracle_eulersFormula
#define fnM1Pow oracle_fnM1Pow
#include "../../../src/c47/mathematics/minusOnePow.c"
#undef fnM1Pow
#undef eulersFormula

#define fnSquare oracle_fnSquare
#include "../../../src/c47/mathematics/square.c"
#undef fnSquare

#define fnCube oracle_fnCube
#include "../../../src/c47/mathematics/cube.c"
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
#include "../../../src/c47/mathematics/parallel.c"
#undef fnParallel

#define fnCross oracle_fnCross
#include "../../../src/c47/mathematics/cross.c"
#undef fnCross

#define fnDot oracle_fnDot
#include "../../../src/c47/mathematics/dot.c"
#undef fnDot

#define fnSdl oracle_fnSdl
#define fnSdr oracle_fnSdr
#include "../../../src/c47/mathematics/shiftDigits.c"
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
#include "../../../src/c47/mathematics/squareRoot.c"
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
#include "../../../src/c47/mathematics/cubeRoot.c"
#undef fnCubeRoot
#undef curtComplex
#undef curtComplex159
#undef curtComplex75
#undef curtReal
#undef rootLonI

#define cosComplex oracle_cosComplex
#define fnFib oracle_fnFib
#include "../../../src/c47/mathematics/fib.c"
#undef fnFib
#undef cosComplex

#define linpol oracle_linpol
#define fnLINPOL oracle_fnLINPOL
#include "../../../src/c47/mathematics/linpol.c"
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
#include "../../../src/c47/mathematics/incDec.c"
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
#include "../../../src/c47/mathematics/percentMRR.c"
#undef fnPercentMRR

#define fnPercentPlusMG oracle_fnPercentPlusMG
#include "../../../src/c47/mathematics/percentPlusMG.c"
#undef fnPercentPlusMG

#define fnPercentT oracle_fnPercentT
#include "../../../src/c47/mathematics/percentT.c"
#undef fnPercentT

#define fnDeltaPercent oracle_fnDeltaPercent
#include "../../../src/c47/mathematics/deltaPercent.c"
#undef fnDeltaPercent

#define fnLogXY oracle_fnLogXY
#include "../../../src/c47/mathematics/logxy.c"
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
#include "../../../src/c47/mathematics/unitVector.c"
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