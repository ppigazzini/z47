/* This file is part of 43S.
 *
 * 43S is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * 43S is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with 43S.  If not, see <http://www.gnu.org/licenses/>.
 */

/********************************************//**
 * \file xthRoot.c
 ***********************************************/
// Coded by JM, based on power.c, with reference to cuberoot.c

#include "mathematics/xthRoot.h"

#include "constantPointers.h"
#include "debug.h"
#include "display.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/division.h"
#include "mathematics/matrix.h"
#include "mathematics/power.h"
#include "mathematics/toPolar.h"
#include "mathematics/toRect.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"


TO_QSPI void (* const xthRoot[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>   1                2                3                4             5             6             7                8                9                10
//      V               Long integer     Real34           Complex34        Time          Date          String        Real34 mat       Complex34 m      Short integer    ConfigData
/*  1 Long integer  */ {xthRootLonILonI, xthRootRealLonI, xthRootCplxLonI, xthRootError, xthRootError, xthRootError, xthRootRemaLonI, xthRootCxmaLonI, xthRootShoILonI, xthRootError},
/*  2 Real34        */ {xthRootLonIReal, xthRootRealReal, xthRootCplxReal, xthRootError, xthRootError, xthRootError, xthRootRemaReal, xthRootCxmaReal, xthRootShoIReal, xthRootError},
/*  3 Complex34     */ {xthRootLonICplx, xthRootRealCplx, xthRootCplxCplx, xthRootError, xthRootError, xthRootError, xthRootRemaCplx, xthRootCxmaCplx, xthRootShoICplx, xthRootError},
/*  4 Time          */ {xthRootError,    xthRootError,    xthRootError,    xthRootError, xthRootError, xthRootError, xthRootError,    xthRootError,    xthRootError,    xthRootError},
/*  5 Date          */ {xthRootError,    xthRootError,    xthRootError,    xthRootError, xthRootError, xthRootError, xthRootError,    xthRootError,    xthRootError,    xthRootError},
/*  6 String        */ {xthRootError,    xthRootError,    xthRootError,    xthRootError, xthRootError, xthRootError, xthRootError,    xthRootError,    xthRootError,    xthRootError},
/*  7 Real34 mat    */ {xthRootError,    xthRootError,    xthRootError,    xthRootError, xthRootError, xthRootError, xthRootError,    xthRootError,    xthRootError,    xthRootError},
/*  8 Complex34 mat */ {xthRootError,    xthRootError,    xthRootError,    xthRootError, xthRootError, xthRootError, xthRootError,    xthRootError,    xthRootError,    xthRootError},
/*  9 Short integer */ {xthRootLonIShoI, xthRootRealShoI, xthRootCplxShoI, xthRootError, xthRootError, xthRootError, xthRootRemaShoI, xthRootCxmaShoI, xthRootShoIShoI, xthRootError},
/* 10 Config data   */ {xthRootError,    xthRootError,    xthRootError,    xthRootError, xthRootError, xthRootError, xthRootError,    xthRootError,    xthRootError,    xthRootError}
};



/********************************************//**
 * \brief Data type error in xthRoot
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void xthRootError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot obtain xthRoot of %s", getRegisterDataTypeName(REGISTER_Y, true, false));
    sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "to %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnRoot:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and regY ^ (1/regX) ==> regX
 * Drops Y, enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
void fnXthRoot(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  xthRoot[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

  adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
}



/********************************************//**
 * \brief (a+ib) ^ (1/(c+id))
 *
 * \param[in] Expecting a,b,c,d:   Y = a +ib;   X = c +id
 * \return REGISTER Y unchanged. REGISTER X with result of (a+ib) ^ (1/(c+id))
 ***********************************************/
void xthRootComplex(const real_t *aa, const real_t *bb, const real_t *cc, const real_t *dd, realContext_t *realContext) {
  real_t theta, a, b, c, d;

  realCopy(aa, &a);
  realCopy(bb, &b);
  realCopy(cc, &c);
  realCopy(dd, &d);

  if(!getSystemFlag(FLAG_SPCRES)) {
    if(realIsZero(&c)&&realIsZero(&d)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function xthRootComplexComplex: 0th Root is not defined!", NULL, NULL, NULL);
      #endif //  (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
     }
    else {
      if(realIsNaN(&a)||realIsNaN(&b)||realIsNaN(&c)||realIsNaN(&d)) {
        reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
        convertRealToImag34ResultRegister(const_NaN, REGISTER_X);
        return;
      }
    }
  }

  if(realIsZero(&a) && realIsZero(&b) && !realIsZero(&c)) {
    reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(const_0, REGISTER_X);
    convertRealToImag34ResultRegister(const_0, REGISTER_X);
    return;
  }

  divRealComplex(const_1, &c, &d, &c, &d, realContext);

  //From power.c
  realRectangularToPolar(&a, &b, &a, &theta, realContext);
  WP34S_Ln(&a, &a, realContext);
  realMultiply(&a, &d, &b, realContext);
  realFMA(&theta, &c, &b, &b, realContext);
  realChangeSign(&theta);
  realMultiply(&a, &c, &a, realContext);
  realFMA(&theta, &d, &a, &a, realContext);
  realExp(&a, &c, realContext);
  realPolarToRectangular(const_1, &b, &a, &b, realContext);
  realMultiply(&c, &b, &d, realContext);
  realMultiply(&c, &a, &c, realContext);

  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&c, REGISTER_X);
  convertRealToImag34ResultRegister(&d, REGISTER_X);
}


/********************************************//**
 * \brief y^(1/x)
 *
 * \param[in] Expecting x,y
 * \return REGISTER Y unchanged. REGISTER X with result of y^x
 ***********************************************/
void xthRootReal(real_t *yy, real_t *xx, realContext_t *realContext) {
  real_t r, o, x, y;
  uint8_t telltale;

  realCopy(xx, &x);
  realCopy(yy, &y);

  telltale = 0;
  if(getSystemFlag(FLAG_SPCRES)) {
    //0
    if(   ((realIsZero(&y)                            && (realCompareGreaterEqual(&x, const_0) || (realIsInfinite(&x) && realIsPositive(&x)))))
       || ((realIsInfinite(&y) && realIsPositive(&y)) && (realCompareLessThan(&x, const_0) && (!realIsInfinite(&x))))
      ) {
      telltale += 1;
      realCopy(const_0, &o);
    }

    //1
    if(((realCompareGreaterEqual(&y, const_0) || (realIsInfinite(&y) && realIsPositive(&y))) && realIsInfinite(&x))) {
      telltale += 2;
      realCopy(const_1, &o);
    }

    //inf
    if(   (realIsZero(&y) && (realCompareLessThan(&x, const_0) && (!realIsInfinite(&x)))) // (y=0.) AND (-inf < x < 0)
       || ((realIsInfinite(&y) && realIsPositive(&y))          && (realCompareGreaterEqual(&x, const_0) && (!realIsInfinite(&x)))) // (y=+inf)  AND (0>= x > inf)
      ) {
      telltale += 4;
      realCopy(const_plusInfinity, &o);
    }

    //NaN
    realDivideRemainder(&x, const_2, &r, realContext);
    if(    (realIsNaN(&x) || realIsNaN(&y))
       || ((realCompareLessThan(&y, const_0) || (realIsInfinite(&y) && realIsNegative(&y))) && (realIsInfinite(&x)   ))                  // (-inf <= y < 0)  AND (x =(inf or -inf))
       || ((realCompareLessThan(&y, const_0) && (!realIsInfinite(&y)                      ) && (!realIsAnInteger(&x))))                  // (-inf < y < 0)  AND (x in non-integer)
       || ((realIsInfinite(&y) && realIsNegative(&y)) && (realIsZero(&r) && realCompareGreaterThan(&x, const_0) && realIsAnInteger(&x))) // (y=-inf) AND (x is even > 0) [zero r means n/2 has no remainder, therefore even]
      ) {
      telltale += 8;
      realCopy(const_NaN, &o);
    }

    //-inf
    realAdd(&x, const_1, &r, realContext);
    realDivideRemainder(&r, const_2, &r, realContext);
    if((realIsInfinite(&y) && realIsNegative(&y)) && (realIsZero(&r) && realCompareGreaterThan(&x, const_0) && realIsAnInteger(&x))) { // (y=-inf) AND (x is odd > 0) [zero r means (n+1)/2 has no remainder, therefore even]
      telltale += 16;
      realCopy(const_minusInfinity, &o);
    }


    if(telltale != 0) {
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&o, REGISTER_X);
      setRegisterAngularMode(REGISTER_X, amNone);
      return;
    }
  }
  else { // not DANGER
    if(realIsZero(&x)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function xthRootRealReal: 0th Root is not defined!", NULL, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
    else {
      if(realIsNaN(&x)||realIsNaN(&y)) {
        reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
        setRegisterAngularMode(REGISTER_X, amNone);
        return;
      }
    }
  }

  if(realIsPositive(&y)) {                                         //positive base, no problem, get the power function y^(1/x)
    realDivide(const_1, &x, &x, realContext);

    PowerReal(&y, &x, &x, realContext);
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&x, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);
    return;
  }  //fall through, but returned
  else {
    if(realIsNegative(&y)) {
      realDivideRemainder(&x, const_2, &r, realContext);
      if(realIsZero(&r)) {                                          // negative base and even exp     (zero means no remainder means even)
        if(!getFlag(FLAG_CPXRES)) {
          displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function xthRootRealReal:", "cannot do complex xthRoots when CPXRES is not set", NULL, NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          return;
        }
        else {
          xthRootComplex(&y, const_0, &x, const_0, realContext);
        }
      } //fall through after Root CC
      else {
        realAdd(&x, const_1, &r, realContext);
        realDivideRemainder(&r, const_2, &r, realContext);
        if(realIsZero(&r)) {                                        // negative base and odd exp
          realDivide(const_1,&x, &x, realContext);

          realSetPositiveSign(&y);
          PowerReal(&y, &x, &x, realContext);
          realSetNegativeSign(&x);

          reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
          convertRealToReal34ResultRegister(&x, REGISTER_X);
          setRegisterAngularMode(REGISTER_X, amNone);
          return;
        } //fall though, but returned
        else {      //neither odd nor even, i.e. not integer
          if(!getFlag(FLAG_CPXRES)) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            #if(EXTRA_INFO_ON_CALC_ERROR == 1)
              moreInfoOnError("In function xthRootRealReal:", "cannot do complex xthRoots when CPXRES is not set", NULL, NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
            return;
          }
          else {
            xthRootComplex(&y, const_0, &x, const_0, realContext);
          }
        }
      } //fall through
    }
    else {
      if(realIsZero(&y)) {
        reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);

        if(!realIsZero(&x)) {                                         // zero base and non-zero exp
          convertRealToReal34ResultRegister(const_1, REGISTER_X);
        }
        else {                                                        // zero base and zero exp
          convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
        }

        setRegisterAngularMode(REGISTER_X, amNone);
      } //fall through, but returned
    }
  }
}


/******************************************************************************************************************************************************************************************/
/* long integer ^ ...                                                                                                                                                                     */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(long integer) ^ 1/X(long integer) ==> X(long integer)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootLonILonI(void) {
  real_t x, y;
  longInteger_t base, exponent, l;

  convertLongIntegerRegisterToLongInteger(REGISTER_Y, base);
  convertLongIntegerRegisterToLongInteger(REGISTER_X, exponent);

  if(longIntegerIsZero(exponent)) {    // 1/0 is not possible
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function xthRootLonILonI: Cannot divide by 0!", NULL, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    longIntegerFree(base);
    longIntegerFree(exponent);
    return;
  }

  if(longIntegerIsZero(base)) {          //base=0 -->  0
    uIntToLongInteger(0, base);
    convertLongIntegerToLongIntegerRegister(base, REGISTER_X);
    longIntegerFree(base);
    longIntegerFree(exponent);
    return;
  }

  if(longIntegerCompareUInt(base, 2147483640) == -1) {
    int32_t exp;

    longIntegerToInt(exponent, exp);
    if(longIntegerIsPositive(base)) {                                 // pos base
      longIntegerInit(l);
      if(longIntegerRoot(base, exp, l)) {                             // if integer xthRoot found, return
        convertLongIntegerToLongIntegerRegister(l, REGISTER_X);
        longIntegerFree(base);
        longIntegerFree(exponent);
        longIntegerFree(l);
        return;
      }
      longIntegerFree(l);
    }
    else {
      if(longIntegerIsNegative(base)) {                                 // neg base and even exponent
        if(longIntegerIsOdd(exponent)) {
          longIntegerChangeSign(base);
          longIntegerInit(l);
          if(longIntegerRoot(base, exp, l)) {                           // if negative integer xthRoot found, return
            longIntegerChangeSign(l);
            convertLongIntegerToLongIntegerRegister(l, REGISTER_X);
            longIntegerFree(base);
            longIntegerFree(exponent);
            longIntegerFree(l);
            return;
          }
          longIntegerFree(l);
          longIntegerChangeSign(base);
        }
      }
    }
  }

  longIntegerToAllocatedString(exponent, tmpString, TMP_STR_LENGTH);
  stringToReal(tmpString, &x, &ctxtReal39);
  longIntegerToAllocatedString(base, tmpString, TMP_STR_LENGTH);
  stringToReal(tmpString, &y, &ctxtReal39);

  longIntegerFree(base);
  longIntegerFree(exponent);

  xthRootReal(&y, &x, &ctxtReal39);
}



/********************************************//**
 * \brief Y(long integer) ^ 1/X(short integer) ==> X(long integer)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootLonIShoI(void) {
  convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
  xthRootLonILonI();
}



/********************************************//**
 * \brief Y(short integer) ^ 1/X(long integer) ==> X(long integer)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootShoILonI(void) {
  uint32_t base = getRegisterShortIntegerBase(REGISTER_Y);

  convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Y, REGISTER_Y);

  xthRootLonILonI();

  if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
    convertLongIntegerRegisterToShortIntegerRegister(REGISTER_X, REGISTER_X);
    setRegisterShortIntegerBase(REGISTER_X, base);
  }
}


/********************************************//**
 * \brief Y(long integer) ^ 1/X(real34) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootLonIReal(void) {
  real_t x, y;

  if(!real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsAnInteger(REGISTER_REAL34_DATA(REGISTER_X))) {
    convertReal34ToLongIntegerRegister(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_X, DEC_ROUND_DOWN);
    xthRootLonILonI();
  }
  else {
    convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

    xthRootReal(&y, &x, &ctxtReal39);
  }
}



/********************************************//**
 * \brief Y(real34) ^ 1/X(long integer) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootRealLonI(void) {
  real_t x, y;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);

  xthRootReal(&y, &x, &ctxtReal39);
}



/********************************************//**
 * \brief Y(long integer) ^ 1/X(complex34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootLonICplx(void) {
  real_t a, b, c, d;

  convertLongIntegerRegisterToReal(REGISTER_Y, &a, &ctxtReal39);
  real34ToReal(const_0, &b);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &c);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &d);

  xthRootComplex(&a, &b, &c, &d, &ctxtReal39);
 }



/********************************************//**
 * \brief Y(complex34) ^ 1/X(long integer) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootCplxLonI(void) {
  real_t a, b, c, d;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &a);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &b);
  convertLongIntegerRegisterToReal(REGISTER_X, &c, &ctxtReal39);
  real34ToReal(const_0, &d);

  xthRootComplex(&a, &b, &c, &d, &ctxtReal39);
}



/******************************************************************************************************************************************************************************************/
/* time ^ ...                                                                                                                                                                             */
/******************************************************************************************************************************************************************************************/

/******************************************************************************************************************************************************************************************/
/* date ^ ...                                                                                                                                                                             */
/******************************************************************************************************************************************************************************************/

/******************************************************************************************************************************************************************************************/
/* string ^ ...                                                                                                                                                                           */
/******************************************************************************************************************************************************************************************/

/******************************************************************************************************************************************************************************************/
/* real34 matrix ^ ...                                                                                                                                                                    */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(real34 matrix) ^ 1/X(long integer) ==> X(real34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootRemaLonI(void) {
  elementwiseRemaLonI(xthRootRealLonI);
}



/********************************************//**
 * \brief Y(real34 matrix) ^ 1/X(short integer) ==> X(real34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootRemaShoI(void) {
  elementwiseRemaShoI(xthRootRealShoI);
}



/********************************************//**
 * \brief Y(real34 matrix) ^ 1/X(real34) ==> X(real34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootRemaReal(void) {
  elementwiseRemaReal(xthRootRealReal);
}



/********************************************//**
 * \brief Y(real34 matrix) ^ 1/X(complex34) ==> X(complex34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootRemaCplx(void) {
  convertReal34MatrixRegisterToComplex34MatrixRegister(REGISTER_Y, REGISTER_Y);
  xthRootCxmaCplx();
}



/******************************************************************************************************************************************************************************************/
/* complex34 matrix ^ ...                                                                                                                                                                 */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(complex34 matrix) ^ 1/X(long integer) ==> X(complex34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootCxmaLonI(void) {
  elementwiseCxmaLonI(xthRootCplxLonI);
}



/********************************************//**
 * \brief Y(complex34 matrix) ^ 1/X(short integer) ==> X(complex34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootCxmaShoI(void) {
  elementwiseCxmaShoI(xthRootCplxShoI);
}



/********************************************//**
 * \brief Y(complex34 matrix) ^ 1/X(real34) ==> X(complex34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootCxmaReal(void) {
  elementwiseCxmaReal(xthRootCplxReal);
}



/********************************************//**
 * \brief Y(complex34 matrix) ^ 1/X(complex34) ==> X(complex34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootCxmaCplx(void) {
  elementwiseCxmaCplx(xthRootCplxCplx);
}



/******************************************************************************************************************************************************************************************/
/* short integer ^ ...                                                                                                                                                                    */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(short integer) ^ 1/X(short integer) ==> X(short integer)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootShoIShoI(void) {
  uint32_t base = getRegisterShortIntegerBase(REGISTER_Y);

  convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
  convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Y, REGISTER_Y);

  xthRootLonILonI();

  if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
    convertLongIntegerRegisterToShortIntegerRegister(REGISTER_X, REGISTER_X);
    setRegisterShortIntegerBase(REGISTER_X, base);
  }
}



/********************************************//**
 * \brief Y(short integer) ^ 1/X(real34) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootShoIReal(void) {
  real_t x, y;

  if(!real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsAnInteger(REGISTER_REAL34_DATA(REGISTER_X))) {
    uint32_t base = getRegisterShortIntegerBase(REGISTER_Y);
    convertReal34ToLongIntegerRegister(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_X, DEC_ROUND_DOWN);
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Y, REGISTER_Y);

    xthRootLonILonI();

    if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
      convertLongIntegerRegisterToShortIntegerRegister(REGISTER_X, REGISTER_X);
      setRegisterShortIntegerBase(REGISTER_X, base);
    }
  }
  else {
    convertShortIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
    xthRootReal(&y, &x, &ctxtReal39);
  }
}




/********************************************//**
 * \brief Y(real34) ^ 1/X(short integer) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootRealShoI(void) {
  real_t x, y;

  convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);

  xthRootReal(&y, &x, &ctxtReal39);
}




/********************************************//**
 * \brief Y(short integer) ^ 1/X(complex34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootShoICplx(void) {
  real_t a, b, c, d;

  convertShortIntegerRegisterToReal(REGISTER_Y, &a, &ctxtReal39);
  real34ToReal(const_0, &b);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &c);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &d);

  xthRootComplex(&a, &b, &c, &d, &ctxtReal39);
}




/********************************************//**
 * \brief Y(complex34) ^ 1/X(short integer) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootCplxShoI(void) {
  real_t a, b, c, d;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &a);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &b);
  convertShortIntegerRegisterToReal(REGISTER_X, &c, &ctxtReal39);
  real34ToReal(const_0, &d);

  xthRootComplex(&a, &b, &c, &d, &ctxtReal39);
}




/******************************************************************************************************************************************************************************************/
/* real34 ^ ...                                                                                                                                                                           */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(real34) ^ 1/X(real34) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootRealReal(void) {
  real_t x, y;

  if((real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)) || real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_Y))) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function xthRootRealReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X or Y input of xthRoot when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  xthRootReal(&y, &x, &ctxtReal39);
}



/********************************************//**
 * \brief Y(real34) ^ 1/X(complex34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootRealCplx(void) {
  real_t a, b, c, d;

  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_Y))) {
    if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X))) {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
      convertRealToImag34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(const_plusInfinity, REGISTER_X);
      convertRealToImag34ResultRegister(const_plusInfinity, REGISTER_X);
    }
    return;
  }

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &a);
  real34ToReal(const_0, &b);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &c);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &d);

  xthRootComplex(&a, &b, &c, &d, &ctxtReal39);
}



/********************************************//**
 * \brief Y(complex34) ^ 1/X(real34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootCplxReal(void) {
  real_t a, b, c, d;

  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_Y)) || real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_Y))) {
    if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
      convertRealToImag34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(const_plusInfinity, REGISTER_X);
      convertRealToImag34ResultRegister(const_plusInfinity, REGISTER_X);
    }
    return;
  }

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &a);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &b);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &c);
  real34ToReal(const_0, &d);

  xthRootComplex(&a, &b, &c, &d, &ctxtReal39);
}



/******************************************************************************************************************************************************************************************/
/* complex34 + ...                                                                                                                                                                        */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(complex34) ^ 1/X(complex34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void xthRootCplxCplx(void) {                       //checked
  real_t a, b, c, d;

  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_Y)) || real34IsInfinite(REGISTER_IMAG34_DATA(REGISTER_Y))) {
    if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X))) {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
      convertRealToImag34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(const_plusInfinity, REGISTER_X);
      convertRealToImag34ResultRegister(const_plusInfinity, REGISTER_X);
    }
    return;
  }

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &a);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &b);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &c);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &d);

  xthRootComplex(&a, &b, &c, &d, &ctxtReal39);
}
