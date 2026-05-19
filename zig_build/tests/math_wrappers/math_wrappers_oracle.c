// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

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
#define fnConjugate oracle_fnConjugate_retained
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

#define fnSwapRealImaginary oracle_fnSwapRealImaginary_retained
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
#define fnAtan2 oracle_fnAtan2_retained
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