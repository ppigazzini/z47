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

#define lnComplex oracle_lnComplex
#define fnLn oracle_fnLn
#include "../../../src/c47/mathematics/ln.c"
#undef fnLn
#undef lnComplex

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

#define fnErf oracle_fnErf
#include "../../../src/c47/mathematics/erf.c"
#undef fnErf

#define fnErfc oracle_fnErfc
#include "../../../src/c47/mathematics/erfc.c"
#undef fnErfc

#define logxyLonI oracle_logxyLonI
#define logxyReal oracle_logxyReal
#define logxyCplx oracle_logxyCplx
#define fnLog10 oracle_fnLog10
#include "../../../src/c47/mathematics/log10.c"
#undef fnLog10
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