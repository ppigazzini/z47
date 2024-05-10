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

#include "integers.h"

#include "constantPointers.h"
#include "debug.h"
#include "display.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "mathematics/wp34s.h"
#include "c43Extensions/radioButtonCatalog.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"

void fnChangeBase(uint16_t base) {
  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    if(2 <= base && base <= 16) {
      setRegisterTag(REGISTER_X, base);
      lastIntegerBase = base;                //JMNIM
      fnRefreshState();             //JM
    }
    else {
      displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_T);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "base = %" PRIu16 "! The base must be fron 2 to 16.", base);
        moreInfoOnError("In function fnChangeBase:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }

  else if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
    if(2 <= base && base <= 16) {
      convertLongIntegerRegisterToShortIntegerRegister(REGISTER_X, REGISTER_X);
      setRegisterShortIntegerBase(REGISTER_X, base);
      lastIntegerBase = base;                //JMNIM
      fnRefreshState();             //JM
    }
    else {
      displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_T);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "base = %" PRIu16 "! The base must be fron 2 to 16.", base);
        moreInfoOnError("In function fnChangeBase:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }

  else if(getRegisterDataType(REGISTER_X) == dtReal34) {
    if(2 <= base && base <= 16) {
      longInteger_t lgInt;
      real_t x, value;
      bool_t isNegative;
      uint32_t tmp32;

      real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
      isNegative = realIsNegative(&x);
      realSetPositiveSign(&x);
      realToIntegralValue(&x, &x, DEC_ROUND_DOWN, &ctxtReal39);

      // Calculate 32 bit high word
      realDivide(&x, const_2p32, &value, &ctxtReal39);

      tmp32 = realToUint32C47(&value);
      longIntegerInit(lgInt);
      uIntToLongInteger(tmp32, lgInt);
      longIntegerLeftShift(lgInt, 32, lgInt);

      // Calculate 32 bit low word
      WP34S_Mod(&x, const_2p32, &value, &ctxtReal39);

      tmp32 = realToUint32C47(&value);
      longIntegerAddUInt(lgInt, tmp32, lgInt);
      if(isNegative) {
        longIntegerSetNegativeSign(lgInt);
      }

      convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
      longIntegerFree(lgInt);
      fnChangeBase(base);
    }
    else {
      displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_T);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "base = %" PRIu16 "! The base must be fron 2 to 16.", base);
        moreInfoOnError("In function fnChangeBase:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }

  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "the input type %s is not allowed for " STD_RIGHT_ARROW "INT!", getDataTypeName(getRegisterDataType(REGISTER_X), false, false));
      moreInfoOnError("In function fnChangeBase:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



void longIntegerMultiply(longInteger_t opY, longInteger_t opX, longInteger_t result) {
  if(longIntegerBits(opY) + longIntegerBits(opX) <= MAX_LONG_INTEGER_SIZE_IN_BITS) {
    mpz_mul(result, opY, opX);
  }
  else {
    displayCalcErrorMessage(longIntegerSign(opY) == longIntegerSign(opX) ? ERROR_OVERFLOW_PLUS_INF : ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Multiplying this 2 values (%" PRIu64 " bits " STD_CROSS " %" PRIu64 " bits) would result in a value exceeding %" PRId16 " bits!", (uint64_t)longIntegerBits(opY), (uint64_t)longIntegerBits(opX), (uint16_t)MAX_LONG_INTEGER_SIZE_IN_BITS);
      longIntegerToAllocatedString(opY, tmpString, TMP_STR_LENGTH / 2);
      longIntegerToAllocatedString(opX, tmpString + TMP_STR_LENGTH / 2, TMP_STR_LENGTH / 2);
      moreInfoOnError("In function longIntegerMultiply:", errorMessage, tmpString, tmpString + TMP_STR_LENGTH / 2);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



void longIntegerSquare(longInteger_t op, longInteger_t result) {
  if(longIntegerBits(op) * 2 <= MAX_LONG_INTEGER_SIZE_IN_BITS) {
    mpz_mul(result, op, op);
  }
  else {
    displayCalcErrorMessage(ERROR_OVERFLOW_PLUS_INF, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Squaring this value (%" PRIu64 " bits) would result in a value exceeding %" PRId16 " bits!", (uint64_t)longIntegerBits(op), (uint16_t)MAX_LONG_INTEGER_SIZE_IN_BITS);
      longIntegerToAllocatedString(op, tmpString, TMP_STR_LENGTH);
      moreInfoOnError("In function longIntegerSquare:", errorMessage, tmpString, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



void longIntegerAdd(longInteger_t opY, longInteger_t opX, longInteger_t result) {
  if(longIntegerSign(opY) != longIntegerSign(opX) || max(longIntegerBits(opY), longIntegerBits(opX)) <= MAX_LONG_INTEGER_SIZE_IN_BITS - 1) {
    mpz_add(result, opY, opX);
  }
  else {
    displayCalcErrorMessage(longIntegerSign(opY) == 0 ? ERROR_OVERFLOW_PLUS_INF : ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Adding this 2 values (%" PRIu64 " bits " STD_CROSS " %" PRIu64 " bits) would result in a value exceeding %" PRId16 " bits!", (uint64_t)longIntegerBits(opY), (uint64_t)longIntegerBits(opX), (uint16_t)MAX_LONG_INTEGER_SIZE_IN_BITS);
      longIntegerToAllocatedString(opY, tmpString, TMP_STR_LENGTH / 2);
      longIntegerToAllocatedString(opX, tmpString + TMP_STR_LENGTH / 2, TMP_STR_LENGTH / 2);
      moreInfoOnError("In function longIntegerAdd:", errorMessage, tmpString, tmpString + TMP_STR_LENGTH / 2);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



void longIntegerSubtract(longInteger_t opY, longInteger_t opX, longInteger_t result) {
  if(longIntegerSign(opY) == longIntegerSign(opX) || max(longIntegerBits(opY), longIntegerBits(opX)) <= MAX_LONG_INTEGER_SIZE_IN_BITS - 1) {
    mpz_sub(result, opY, opX);
  }
  else {
    displayCalcErrorMessage(longIntegerSign(opY) == 0 ? ERROR_OVERFLOW_PLUS_INF : ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Subtracting this 2 values (%" PRIu64 " bits " STD_CROSS " %" PRIu64 " bits) would result in a value exceeding %" PRId16 " bits!", (uint64_t)longIntegerBits(opY), (uint64_t)longIntegerBits(opX), (uint16_t)MAX_LONG_INTEGER_SIZE_IN_BITS);
      longIntegerToAllocatedString(opY, tmpString, TMP_STR_LENGTH / 2);
      longIntegerToAllocatedString(opX, tmpString + TMP_STR_LENGTH / 2, TMP_STR_LENGTH / 2);
      moreInfoOnError("In function longIntegerSubtract:", errorMessage, tmpString, tmpString + TMP_STR_LENGTH / 2);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}






/*
 * The functions below are borrowed
 * from the WP34S project and sligtly
 * modified and adapted
 */

/* Helper routine for addition and subtraction that detemines the proper
 * setting for the overflow bit.  This routine should only be called when
 * the signs of the operands are the same for addition and different
 * for subtraction.  Overflow isn't possible if the signs are opposite.
 * The arguments of the operator should be passed in after conversion
 * to positive unsigned quantities nominally in two's complement.
 */
static int32_t WP34S_calc_overflow(uint64_t xv, uint64_t yv, int32_t neg) {
  uint64_t u;
  int32_t i;

  switch(shortIntegerMode) {
    case SIM_UNSIGN: {
      // C doesn't expose the processor's status bits to us so we
      // break the addition down so we don't lose the overflow.
      u = (yv & (shortIntegerSignBit-1)) + (xv & (shortIntegerSignBit-1));
      i = ((u & shortIntegerSignBit)?1:0) + ((xv & shortIntegerSignBit)?1:0) + ((yv & shortIntegerSignBit)?1:0);
      if(i > 1) {
        break;
      }
      return 0;
    }

    case SIM_2COMPL: {
      u = xv + yv;
      if(neg && u == shortIntegerSignBit) {
        return 0;
      }

      if(shortIntegerSignBit & u) {
        break;
      }

      if((xv == shortIntegerSignBit && yv !=0) || (yv == shortIntegerSignBit && xv != 0)) {
        break;
      }
      return 0;
    }

    case SIM_SIGNMT:
    case SIM_1COMPL: {
      if(shortIntegerSignBit & (xv + yv)) {
        break;
      }
      return 0;
    }

    default: {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgValueFor], "calc_overflow", shortIntegerMode, "shortIntegerMode");
      displayBugScreen(errorMessage);
      return 0;
    }
  }

  setSystemFlag(FLAG_OVERFLOW);

  return 1;
}


/* Utility routine to convert a binary integer into separate sign and
 * value components.  The sign returned is 1 for negative and 0 for positive.
 */
uint64_t WP34S_extract_value(const uint64_t val, int32_t *const sign) {
  uint64_t value = val & shortIntegerMask;

  if(shortIntegerMode == SIM_UNSIGN) {
    *sign = 0;
    return value;
  }

  if(value & shortIntegerSignBit) {
    *sign = 1;
    if(shortIntegerMode == SIM_2COMPL) {
      value = -value;
    }
    else if(shortIntegerMode == SIM_1COMPL) {
      value = ~value;
    }
    else { // if(shortIntegerMode == SIM_SIGNMT)
      value ^= shortIntegerSignBit;
    }
  }
  else {
    *sign = 0;
  }

  return value & shortIntegerMask;
}


/* Helper routine to construct a value from the magnitude and sign
 */
int64_t WP34S_build_value(const uint64_t x, const int32_t sign) {
  int64_t value = x & shortIntegerMask;

  if(sign == 0 || shortIntegerMode == SIM_UNSIGN) {
    return value;
  }

  if(shortIntegerMode == SIM_2COMPL) {
    return (-(int64_t)value) & shortIntegerMask;
  }

  if(shortIntegerMode == SIM_1COMPL) {
    return (~value) & shortIntegerMask;
  }

  return value | shortIntegerSignBit;
}


static uint64_t WP34S_multiply_with_overflow(uint64_t multiplier, uint64_t multiplicand, int32_t *overflow) {
  const uint64_t product = (multiplier * multiplicand) & shortIntegerMask;

  if(!*overflow && multiplicand != 0) {
    const uint64_t tbm = (shortIntegerMode == SIM_UNSIGN) ? 0 : shortIntegerSignBit;

    if((product & tbm) != 0 || product / multiplicand != multiplier) {
      *overflow = 1;
    }
  }
  return product;
}

uint64_t WP34S_intAdd(uint64_t y, uint64_t x) {
  int32_t termXSign, termYSign;
  uint64_t termX = WP34S_extract_value(x, &termXSign);
  uint64_t termY = WP34S_extract_value(y, &termYSign);
  uint64_t sum;
  int32_t overflow;

  clearSystemFlag(FLAG_OVERFLOW);
  if(termXSign == termYSign) {
    overflow = WP34S_calc_overflow(termX, termY, termXSign);
  }
  else {
    overflow = 0;
  }

  if(shortIntegerMode == SIM_SIGNMT) {
    const uint64_t x2 = (x & shortIntegerSignBit)?-(x ^ shortIntegerSignBit):x;
    const uint64_t y2 = (y & shortIntegerSignBit)?-(y ^ shortIntegerSignBit):y;

    if(overflow) {
      setSystemFlag(FLAG_CARRY);
    }
    else {
      clearSystemFlag(FLAG_CARRY);
    }

    sum = y2 + x2;
    if(sum & shortIntegerSignBit) {
      sum = -sum | shortIntegerSignBit;
    }
  }
  else {
    const uint64_t maskedSum = (y + x) & shortIntegerMask;

    sum = y + x;

    if(maskedSum < (y & shortIntegerMask)) {
      setSystemFlag(FLAG_CARRY);

      if(shortIntegerMode == SIM_1COMPL) {
        sum++;
      }
    }
    else {
      clearSystemFlag(FLAG_CARRY);
    }
  }
  return sum & shortIntegerMask;
}


uint64_t WP34S_intSubtract(uint64_t y, uint64_t x) {
  int32_t termXSign, termYSign;
  uint64_t termX = WP34S_extract_value(x, &termXSign);
  uint64_t termY = WP34S_extract_value(y, &termYSign);
  uint64_t difference;

  clearSystemFlag(FLAG_OVERFLOW);
  if(termXSign != termYSign) {
    WP34S_calc_overflow(termX, termY, termYSign);
  }

  if(shortIntegerMode == SIM_SIGNMT) {
    int64_t x2, y2;

    if((termXSign == 0 && termYSign == 0 && termX > termY) || (termXSign != 0 && termYSign != 0 && termX < termY)) {
      setSystemFlag(FLAG_CARRY);
    }
    else {
      clearSystemFlag(FLAG_CARRY);
    }

    x2 = (x & shortIntegerSignBit) ? -(x ^ shortIntegerSignBit) : x;
    y2 = (y & shortIntegerSignBit) ? -(y ^ shortIntegerSignBit) : y;

    difference = y2 - x2;
    if(difference & shortIntegerSignBit) {
      difference = -difference | shortIntegerSignBit;
    }
  }
  else {
    difference = y - x;

    if((uint64_t)y < (uint64_t)x) {
      setSystemFlag(FLAG_CARRY);
      if(shortIntegerMode == SIM_UNSIGN) {
        setSystemFlag(FLAG_OVERFLOW);
      }

      if(shortIntegerMode == SIM_1COMPL) {
        difference--;
      }
    }
    else {
      clearSystemFlag(FLAG_CARRY);
    }
  }
  return difference & shortIntegerMask;
}


uint64_t WP34S_intMultiply(uint64_t y, uint64_t x) {
  uint64_t product;
  int32_t multiplicandSign, multiplierSign;
  uint64_t multiplicand = WP34S_extract_value(x, &multiplicandSign);
  uint64_t multiplier   = WP34S_extract_value(y, &multiplierSign);
  int32_t overflow = 0;

  product = WP34S_multiply_with_overflow(multiplier, multiplicand, &overflow);

  if(overflow) {
    setSystemFlag(FLAG_OVERFLOW);
  }
  else {
    clearSystemFlag(FLAG_OVERFLOW);
  }

  if(shortIntegerMode == SIM_UNSIGN) {
    return product;
  }
  return WP34S_build_value(product & ~shortIntegerSignBit, multiplicandSign ^ multiplierSign);
}


uint64_t WP34S_intDivide(uint64_t y, uint64_t x) {
  int32_t divisorSign, dividendSign;
  uint64_t divisor = WP34S_extract_value(x, &divisorSign);
  uint64_t dividend   = WP34S_extract_value(y, &dividendSign);
  uint64_t quotient;

  if(divisor == 0) {
    if(dividend == 0) {
      displayCalcErrorMessage(ERROR_BAD_TIME_OR_DATE_INPUT, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function WP34S_intDivide: cannot divide 0 by 0!", NULL, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else if(dividendSign) {
      displayCalcErrorMessage(ERROR_BAD_TIME_OR_DATE_INPUT, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function WP34S_intDivide: cannot divide a negative short integer by 0!", NULL, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      displayCalcErrorMessage(ERROR_BAD_TIME_OR_DATE_INPUT, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function WP34S_intDivide: cannot divide a positive short integer by 0!", NULL, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    return 0;
  }

  clearSystemFlag(FLAG_OVERFLOW);
  quotient = (dividend / divisor) & shortIntegerMask;
  // Set carry if there is a remainder
  if(quotient * divisor != dividend) {
    setSystemFlag(FLAG_CARRY);
  }
  else {
    clearSystemFlag(FLAG_CARRY);
  }

  if(shortIntegerMode != SIM_UNSIGN) {
    if(quotient & shortIntegerSignBit) {
      setSystemFlag(FLAG_CARRY);
    }
    // Special case for 0x8000...00 / -1 in 2's complement
    if(shortIntegerMode == SIM_2COMPL && divisorSign && divisor == 1 && y == shortIntegerSignBit) {
      setSystemFlag(FLAG_OVERFLOW);
    }
  }
  return WP34S_build_value(quotient, divisorSign ^ dividendSign);
}

/* never used
uint64_t WP34S_intSqr(uint64_t x) {
  return WP34S_intMultiply(x, x);
}
*/
/* never used
uint64_t WP34S_intCube(uint64_t x) {
  int64_t y = WP34S_intMultiply(x, x);
  int32_t overflow = (getSystemFlag(FLAG_OVERFLOW) == ON ? 1 : 0);

  y = WP34S_intMultiply(x, y);
  if(overflow) {
    setSystemFlag(FLAG_OVERFLOW);
  }
  return y;
}
*/

static uint64_t WP34S_int_gcd(uint64_t a, uint64_t b) {
  while(b != 0) {
    uint64_t t = b;
    b = a % b;
    a = t;
  }
  return a;
}


uint64_t WP34S_intGCD(uint64_t y, uint64_t x) {
  int32_t s;
  uint64_t xv = WP34S_extract_value(x, &s);
  uint64_t yv = WP34S_extract_value(y, &s);
  uint64_t gcd;

  if(xv == 0) {
    gcd = yv;
  }
  else if(yv == 0) {
    gcd = xv;
  }
  else {
    gcd = WP34S_int_gcd(xv, yv);
  }
  return WP34S_build_value(gcd, 0);
}


uint64_t WP34S_intLCM(uint64_t y, uint64_t x) {
  int32_t s;
  uint64_t xv = WP34S_extract_value(x, &s);
  uint64_t yv = WP34S_extract_value(y, &s);
  uint64_t gcd;

  if(xv == 0 || yv == 0) {
    return 0;
  }

  gcd = WP34S_int_gcd(xv, yv);
  return WP34S_intMultiply((xv / gcd) & shortIntegerMask, WP34S_build_value(yv, 0));
}


uint64_t WP34S_intChs(uint64_t x) {
  int32_t signValue;
  uint64_t value = WP34S_extract_value(x, &signValue);

  if(shortIntegerMode == SIM_UNSIGN || (shortIntegerMode == SIM_2COMPL && x == shortIntegerSignBit)) {
    temporaryInformation = TI_DATA_NEG_OVRFL;
    setSystemFlag(FLAG_OVERFLOW);
    return (-(int64_t)value) & shortIntegerMask;
  }

  clearSystemFlag(FLAG_OVERFLOW);
  return WP34S_build_value(value, !signValue);
}


/* Integer floor(sqrt())
 */
uint64_t WP34S_intSqrt(uint64_t x) {
  int32_t signValue;
  uint64_t value = WP34S_extract_value(x, &signValue);
  uint64_t nn0, nn1;

  if(signValue) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function WP34S_intSqrt: Cannot extract the square root of a negative short integer!", NULL, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return 0;
  }
  if(value == 0) {
    nn1 = 0;
  }
  else {
    nn0 = value / 2 + 1;
    nn1 = value / nn0 + nn0 / 2;
    while(nn1 < nn0) {
      nn0 = nn1;
      nn1 = (nn0 + value / nn0) / 2;
    }
    nn0 = nn1 * nn1;
    if(nn0 > value) {
      nn1--;
    }

    if(nn0 != value) {
      setSystemFlag(FLAG_CARRY);
    }
    else {
      clearSystemFlag(FLAG_CARRY);
    }
  }
  return WP34S_build_value(nn1, signValue);
}


uint64_t WP34S_intAbs(uint64_t x) {
  int32_t signValue;
  uint64_t value = WP34S_extract_value(x, &signValue);

  clearSystemFlag(FLAG_OVERFLOW);
  if(shortIntegerMode == SIM_2COMPL && x == shortIntegerSignBit) {
    setSystemFlag(FLAG_OVERFLOW);
    return x;
  }
  return WP34S_build_value(value, 0);
}


//uint64_t WP34S_intNot(uint64_t x) {
//  return (~x) & shortIntegerMask;
//}


/* Fraction and integer parts are very easy for integers.
 */
//uint64_t WP34S_intFP(uint64_t x) {
//  return 0;
//}


//uint64_t WP34S_intIP(uint64_t x) {
//  return x;
//}


uint64_t WP34S_intSign(uint64_t x) {
  int32_t signValue;
  uint64_t value = WP34S_extract_value(x, &signValue);

  if(value == 0) {
    signValue = 0;
  }
  else {
    value = 1;
  }
  return WP34S_build_value(value, signValue);
}


static uint64_t WP34S_int_power_helper(uint64_t base, uint64_t exponent, int32_t overflow) {
  uint64_t power = 1;
  uint32_t i;
  int32_t overflow_next = 0;

  for(i=0; i<shortIntegerWordSize && exponent != 0; i++) {
    if(exponent & 1) {
      if(overflow_next) {
        overflow = 1;
      }
      power = WP34S_multiply_with_overflow(power, base, &overflow);
    }
    exponent >>= 1;

    if(exponent != 0) {
      base = WP34S_multiply_with_overflow(base, base, &overflow_next);
    }
  }

  if(overflow) {
    setSystemFlag(FLAG_OVERFLOW);
  }
  else {
    clearSystemFlag(FLAG_OVERFLOW);
  }

  return power;
}


/* Integer power y^x
 */
uint64_t WP34S_intPower(uint64_t b, uint64_t e) {
  int32_t exponentSign, baseSign, powerSign;
  uint64_t exponent = WP34S_extract_value(e, &exponentSign);
  uint64_t base     = WP34S_extract_value(b, &baseSign);

  if(exponent == 0 && base == 0) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function WP34S_intPower: Cannot calculate 0^0!", NULL, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    setSystemFlag(FLAG_OVERFLOW);
    return 0;
  }
  clearSystemFlag(FLAG_CARRY);
  clearSystemFlag(FLAG_OVERFLOW);

  if(exponent == 0) {
    return 1;
  }
  else if(base == 0) {
    return 0;
  }

  //if(exponentSign) { when WP34S_intPower is called, exponent cannot be negative
  //  setSystemFlag(FLAG_CARRY);
  //  return 0;
  //}

  powerSign = (baseSign && (exponent & 1))?1:0; // Determine the sign of the result
  return WP34S_build_value(WP34S_int_power_helper(base, exponent, 0), powerSign);
}


/* 2^x
 */
uint64_t WP34S_int2pow(uint64_t x) {
  int32_t signExponent;
  uint64_t exponent = WP34S_extract_value(x, &signExponent);
  uint32_t wordSize = shortIntegerWordSize;

  clearSystemFlag(FLAG_OVERFLOW);
  if(signExponent && exponent == 1) {
    setSystemFlag(FLAG_CARRY);
  }
  else {
    clearSystemFlag(FLAG_CARRY);
  }

  if(signExponent && exponent != 0) {
    return 0;
  }

  if(shortIntegerMode != SIM_UNSIGN) {
    wordSize--;
  }
  if(exponent >= wordSize) {
    if(exponent == wordSize) {
      setSystemFlag(FLAG_CARRY);
    }
    else {
      clearSystemFlag(FLAG_CARRY);
    }

    setSystemFlag(FLAG_OVERFLOW);
    return 0;
  }
  return 1LL << (uint32_t)(exponent & 0xff);
}


/* 10^x
 */
uint64_t WP34S_int10pow(uint64_t x) {
  int32_t sx;
  uint64_t exponent = WP34S_extract_value(x, &sx);
  int32_t overflow = 0;

  clearSystemFlag(FLAG_CARRY);
  if(exponent == 0) {
    clearSystemFlag(FLAG_OVERFLOW);
    return 1;
  }

  if(sx) {
    setSystemFlag(FLAG_CARRY);
    return 0;
  }

  if(shortIntegerWordSize <= 3 || (shortIntegerMode != SIM_UNSIGN && shortIntegerWordSize == 4)) {
    overflow = 1;
  }
  return WP34S_build_value(WP34S_int_power_helper(10, x, overflow), 0);
}


/* Integer floor(log2())
 */
uint64_t WP34S_intLog2(uint64_t x) {
  int32_t signValue;
  uint64_t value = WP34S_extract_value(x, &signValue);
  uint32_t log2 = 0;

  if(value == 0 || signValue) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function WP34S_intLog2: Cannot calculate the log" STD_SUB_2 " of a number " STD_LESS_EQUAL " 0!", NULL, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return 0;
  }

  if(value & (value - 1)) {
    setSystemFlag(FLAG_CARRY);
  }
  else {
    clearSystemFlag(FLAG_CARRY);
  }

  while(value >>= 1) {
    log2++;
  }

  return WP34S_build_value(log2, signValue);
}


/* Integer floor(log10())
 */
uint64_t WP34S_intLog10(uint64_t x) {
  int32_t signValue;
  uint64_t value = WP34S_extract_value(x, &signValue);
  int32_t r = 0;
  int32_t c = 0;

  if(value == 0 || signValue) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function WP34S_intLog10: Cannot calculate the log" STD_SUB_10 " of a number " STD_LESS_EQUAL " 0!", NULL, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return 0;
  }

  while(value >= 10) {
    r++;
    if(value % 10) {
      c = 1;
    }
    value /= 10;
  }

  if(c || value != 1) {
    setSystemFlag(FLAG_CARRY);
  }
  else {
    clearSystemFlag(FLAG_CARRY);
  }

  return WP34S_build_value(r, signValue);
}

/* Calculate (a . b) mod c taking care to avoid overflow */
uint64_t WP34S_mulmod(const uint64_t a, uint64_t b, const uint64_t c) {
  uint64_t x = 0, y = a % c;
  while(b > 0) {
    if((b & 1)) {
      x = (x + y) % c;
    }
    y = (y + y) % c;
    b /= 2;
  }
  return x % c;
}



/* Calculate (a ^ b) mod c */
uint64_t WP34S_expmod(const uint64_t a, uint64_t b, const uint64_t c) {
  uint64_t x = 1, y = a;
  while(b > 0) {
    if((b & 1)) {
      x = WP34S_mulmod(x, y, c);
    }
    y = WP34S_mulmod(y, y, c);
    b /= 2;
  }
  return (x % c);
}



#if 0
  /* Justify to the end of the register
   */
  void justify(int64_t (*shift)(int64_t), const int64_t mask) {
    uint32_t c = 0;
    int64_t v;

    v = getX_int();
    setlastX();
    lift();
    if(v != 0) {
      const int32_t flags = save_flags();
      while((v & mask) == 0) {
        v = (*shift)(v);
        c++;
      }
      restore_flags(flags);
      set_reg_n_int(regY_idx, v);
    }

    setX_int((int64_t)c);
  }

  void int_justify(enum nilop op) {
    const uint64_t mask = (op == OP_LJ) ? shortIntegerSignBit : 1LL;
    justify((op == OP_LJ) ? &intLSL : &intLSR, mask);
  }


  /* Create n bit masks at either end of the word.
   * If the n is negative, the mask is created at the other end of the
   * word.
   */
  void intmsks(uint32_t arg, enum rarg op) {
    int64_t mask;
    int64_t x;
    int64_t (*f)(int64_t);
    const int32_t carry = (getSystemFlag(FLAG_CARRY) == ON ? 1 : 0);

    lift();

    if(op == RARG_MASKL) {
      mask = shortIntegerSignBit;
      f = &intLSR;
    }
    else {
      mask = 1LL;
      f = &intLSL;
    }

    if(arg >= shortIntegerWordSize) {
      x = (-1) & shortIntegerMask;
    }
    else {
      x = 0;
      for(uint32_t i=0; i<arg; i++) {
        x |= mask;
        mask = (*f)(mask);
      }
    }

    setX_int(x);
    set_carry(carry);
  }


  /* Set, clear, flip and test bits */
  void intbits(uint32_t arg, enum rarg op) {
    int64_t m, x;

    m =  (arg >= shortIntegerWordSize)?0:(1LL << arg);
    x = getX_int();

    switch(op) {
      case RARG_SB: {
        x |= m;
        setlastX();
        break;
      }
      case RARG_CB: {
        x &= ~m;
        setlastX();
        break;
      }
      case RARG_FB: {
        x ^= m;
        setlastX();
        break;
      }
      case RARG_BS: {
        fin_tst((x&m)?1:0);
        break;
      }
      case RARG_BC: {
        fin_tst((m != 0 && (x&m) != 0)?0:1);
        break;
      }
      default: {
        return;
      }
    }

    setX_int(x);
  }

  int64_t intFib(int64_t x) {
    int32_t sx, s;
    uint64_t v = extract_value(x, &sx);
    uint64_t a0, a1;
    uint32_t n, i;
    int64_t tbm;

    /* Limit things so we don't loop for too long.
     * The actual largest non-overflowing values for 64 bit integers
     * are Fib(92) for signed quantities and Fib(93) for unsigned.
     * We allow a bit more and maintain the low order digits.
     */
    if(v >= 100) {
      set_overflow(1);
      return 0;
    }

    set_overflow(0);
    n = v & 0xff;
    if(n <= 1) {
      return build_value(n, 0);
    }

    /* Negative integers produce the same values as positive
     * except the sign for negative evens is negative.
     */
    s = (sx && (n & 1) == 0)?1:0;

    /* Mask to check for overflow */
    tbm = shortIntegerSignBit;
    if(shortIntegerMode == SIM_UNSIGN) {
      tbm <<= 1;
    }

    /* Down to the computation.
     */
    a0 = 0;
    a1 = 1;
    for(i=1; i<n; i++) {
      const uint64_t anew = a0 + a1;
      if((anew & tbm) || anew < a1) {
        set_overflow(1);
      }
      a0 = a1;
      a1 = anew;
    }

    return build_value(a1, s);
  }


  int64_t intmodop(int64_t z, int64_t y, int64_t x) {
    int32_t sx, sy, sz;
    uint64_t vx = extract_value(x, &sx);
    uint64_t vy = extract_value(y, &sy);
    uint64_t vz = extract_value(z, &sz);
    uint64_t r;

    if(sx || sy || sz || vx <= 1) {
      err(ERR_DOMAIN);
    }

    if(XeqOpCode == (OP_TRI | OP_MULMOD)) {
      r = mulmod(vz, vy, vx);
    }
    else {
      r = expmod(vz, vy, vx);
    }

    return build_value(r, 0);
  }


  // only need 8 terms for factors > 256
  #define MAX_TERMS 8

  int32_t dscanOdd(uint32_t d, uint32_t limit, int32_t nd, uint32_t ad[MAX_TERMS]) {
    /* given starting odd `d', skip two divisors at a time and thus
    * scan only the odd numbers.
    */
    int32_t i, j;
    while(ad[0]) {
      d += 2;
      if(d > limit) {
        return 0; // limit reached
      }
      for(i = nd-2; i >= 0; --i) {
        for(j = i; j < nd-1; ++j) {
          int32_t v = ad[j] - ad[j+1] - ad[j+1];
          if(v < 0) {
            v += d;
            --ad[j+1];
            if(v < 0) {
              v += d;
              --ad[j+1];
            }
          }
          ad[j] = v;
        }
        if(!ad[j]) {
          --nd;
        }
      }
    }

    return d;
  }

  uint64_t doFactor(uint64_t n) {
    /* find the least prime factor of `n'.
    * numbers up to 10^14 can be factored. worst case about 30 seconds
    * on realbuild.
    *
    * returns least prime factor or `n' if prime.
    * returns 0 if failed to find factor.
    *
    * we will only fail if we have a 14 digit number with a factor > dmax (1e7).
    * since we have a 12 digit display, this ought to be good, but actually more digits are
    * held internally. for example 10000019*1000079 displays as scientific, but actually all
    * the digits are held. this example will return 0.
    */

    uint32_t d;
    uint32_t dmax = 10000000; // biggest factor, 10^7
    uint32_t rt;
    uint32_t limit;

    uint32_t ad[MAX_TERMS];
    int32_t nd;
    int32_t i, j;
    uint8_t* cp;

    // eliminate small cases < 257
    if(n <= 2) {
      return n;
    }
    if((n & 1) == 0) {
      return 2;
    }
    for(i=1; i<N_PRIMES; i++) {
      if(n % primes[i] == 0) {
        return primes[i];
      }
    }

    if(n <= QUICK_CHECK) { // the number is prime
      return n;
    }

    rt = (uint32_t)intSqrt(n);
    limit = rt;
    if(limit > dmax) {
      limit = dmax; // max time about 30 seconds
    }

    // starting factor for search
    d = 257;

    // since we've eliminated all factors < 257, convert
    // the initial number to bytes to get base 256
    // XX ASSUME little endian here.
    cp = (uint8_t*)&n;
    nd = 0;
    for(i = 0; i < sizeof(n); ++i) {
      if((ad[i] = *cp++) != 0) {
        ++nd;
      }
    }

    // and slide to 257
    for(i = nd-2; i >= 0; --i) {
      for(j = i; j < nd-1; ++j) {
        if((ad[j] -= ad[j+1]) < 0) {
          ad[j] += d;
          --ad[j+1];
        }
      }
      if(!ad[j]) {
        --nd;
      }
    }

    if(ad[0]) {
      // find factor or return 0 if limit reached
      d = dscanOdd(d, limit, nd, ad);
      if(!d) {
        // no factor found, if limit reached, we've failed
        // otherwise `n' is prime
        if(limit == dmax) {
          n = 0; // fail
        }
      }
    }

    if(d) {
      n = d;
    }

    return n;
  }
  #undef MAX_TERMS


  int64_t intFactor(int64_t x) {
    int32_t sx;
    uint64_t vx = extract_value(x, &sx);
    uint64_t r = doFactor(vx);
    return build_value(r, sx);
  }

  int64_t intRecv(int64_t x) {
    int32_t sx;
    uint64_t xv = extract_value(x, &sx);
    int32_t to = xv & 0x7fffffff;
    int32_t c;

    if(sx) {
      to = -1;
    }
    c = recv_byte(to);

    sx = c < 0;
    if(sx) {
      c = -c;
    }
    set_overflow(sx);

    return build_value(c, sx);
  }

  /* Some utility routines for saving and restoring carry and overflow.
   * Some operations don't change these flags but their subcomponents might.
   */
  int32_t save_flags(void) {
    return (getSystemFlag(FLAG_OVERFLOW) == ON ? 2 : 0) | (getSystemFlag(FLAG_CARRY) == ON ? 1 : 0);
  }

  void restore_flags(int32_t co) {
    set_carry(co & 1);
    set_overflow(co & 2);
  }

  /* Utility routine to check if a value has overflowed or not */
  int32_t check_overflow(int64_t x) {
    return ((x) & shortIntegerMask) != x || (shortIntegerMode != SIM_UNSIGN && (x & shortIntegerSignBit) != 0);
  }


  int64_t intMod(int64_t y, int64_t x) {
    int32_t sx, sy;
    uint64_t xv = extract_value(x, &sx);
    uint64_t yv = extract_value(y, &sy);
    uint64_t r;

    if(xv == 0) {
      err_div0(yv, sy, sx);
      return 0;
    }
    r = yv % xv;

    if(XeqOpCode == (OP_DYA | OP_MOD41) && sx != sy) {
      if(r != 0) {
        r = xv - r;
      }
      sy = sx;
    }

    return build_value(r, sy);
  }


  int64_t intMin(int64_t y, int64_t x) {
    int32_t sx, sy;
    const uint64_t xv = extract_value(x, &sx);
    const uint64_t yv = extract_value(y, &sy);

    if(sx != sy) {   // different signs
      if(sx) {
        return x;
      }
    }
    else if(sx) {  // both negative
      if(xv > yv) {
        return x;
      }
    }
    else {   // both positive
      if(xv < yv) {
        return x;
      }
    }

    return y;
  }

  int64_t intMax(int64_t y, int64_t x) {
    int32_t sx, sy;
    uint64_t xv = extract_value(x, &sx);
    uint64_t yv = extract_value(y, &sy);

    if(sx != sy) {   // different signs
      if(sx) {
        return y;
      }
    }
    else if(sx) {  // both negative
      if(xv > yv) {
        return y;
      }
    }
    else {   // both positive
      if(xv < yv) {
        return y;
      }
    }

    return x;
  }


  int64_t intMAdd(int64_t z, int64_t y, int64_t x) {
    int64_t t = intMultiply(x, y);
    const int32_t of = (getSystemFlag(FLAG_OVERFLOW) == ON ? 1 : 0);

    t = intAdd(t, z);
    if(of) {
      set_overflow(1);
    }

    return t;
   }

  void breakup(uint64_t x, uint16_t xv[4]) {
    xv[0] = x & 0xffff;
    xv[1] = (x >> 16) & 0xffff;
    xv[2] = (x >> 32) & 0xffff;
    xv[3] = (x >> 48) & 0xffff;
   }

  uint64_t packup(uint16_t x[4]) {
    return (((uint64_t)x[3]) << 48) | (((uint64_t)x[2]) << 32) | (((uint32_t)x[1]) << 16) | x[0];
   }

  void intDblMul(void) {
    uint64_t xv, yv;
    int32_t s;
    uint16_t xa[4], ya[4];
    uint32_t t[8];
    uint16_t r[8];
    int32_t i, j;

    {
      int64_t xr, yr;
      int32_t sx, sy;

      xr = getX_int();
      yr = get_reg_n_int(regY_idx);

      xv = extract_value(xr, &sx);
      yv = extract_value(yr, &sy);

      s = sx != sy;
    }

   /* Do the multiplication by breaking the values into uint16_t
    * multiplying them all out and accumulating into uint32_t.
    * Then perform a second pass over the ints to propogate carry.
    * Finally, repack into uint64_ts.
    *
    * This isn't terribly efficient especially for shorter word
    * sizes but it works.  Special cases for WS <= 16 and/or WS <= 32
    * might be worthwhile since the CPU supports these multiplications
    * natively.
    */
    breakup(xv, xa);
    breakup(yv, ya);

    for(i=0; i<8; i++) {
      t[i] = 0;
    }

    for(i=0; i<4; i++) {
      for(j=0; j<4; j++) {
        t[i+j] += xa[i] * ya[j];
      }
    }

    for(i=0; i<8; i++) {
      if(t[i] >= 65536) {
        t[i+1] += t[i] >> 16;
      }
      r[i] = t[i];
    }

    yv = packup(r);
    xv = packup(r+4);

    i = shortIntegerWordSize;
    if(i != 64) {
      xv = (xv << (64-i)) | (yv >> i);
    }

    setlastX();

    if(s != 0) {
      if(shortIntegerMode == SIM_2COMPL) {
        yv = (1 + ~yv) & shortIntegerMask;
        xv = ~xv;
        if(yv == 0) {
          xv++;
        }
      }
      else if(shortIntegerMode == SIM_1COMPL) {
        yv = ~yv;
        xv = ~xv;
      }
      else {
        xv |= shortIntegerSignBit;
      }
    }

    set_reg_n_int(regY_idx, yv & shortIntegerMask);
    setX_int(xv & shortIntegerMask);
    set_overflow(0);
  }


  int32_t nlz(uint16_t x) {
    int32_t n;

    if(x == 0) {
      return 16;
    }
    n = 0;
    if(x <= 0x00ff) {
      n = n + 8; x = x << 8;
    }
    if(x <= 0x0fff) {
      n = n + 4; x = x << 4;
    }
    if(x <= 0x3fff) {
      n = n + 2; x = x << 2;
    }
    if(x <= 0x7fff) {
      n = n + 1;
    }
    return n;
  }

  /* q[0], r[0], u[0], and v[0] contain the LEAST significant halfwords.
  (The sequence is in little-endian order).

  This first version is a fairly precise implementation of Knuth's
  Algorithm D, for a binary computer with base b = 2**16.  The caller
  supplies
     1. Space q for the quotient, m - n + 1 halfwords (at least one).
     2. Space r for the remainder (optional), n halfwords.
     3. The dividend u, m halfwords, m >= 1.
     4. The divisor v, n halfwords, n >= 2.
  The most significant digit of the divisor, v[n-1], must be nonzero.  The
  dividend u may have leading zeros; this just makes the algorithm take
  longer and makes the quotient contain more leading zeros.  A value of
  NULL may be given for the address of the remainder to signify that the
  caller does not want the remainder.
     The program does not alter the input parameters u and v.
     The quotient and remainder returned may have leading zeros.
     For now, we must have m >= n.  Knuth's Algorithm D also requires
  that the dividend be at least as long as the divisor.  (In his terms,
  m >= 0 (unstated).  Therefore m+n >= n.) */

  void divmnu(uint16_t q[], uint16_t r[], const uint16_t u[], const uint16_t v[], const int32_t m, const int32_t n) {
    const uint32_t b = 65536;   // Number base (16 bits).
    uint32_t qhat;     // Estimated quotient digit.
    uint32_t rhat;     // A remainder.
    uint32_t p;        // Product of two digits.
    int32_t s, i, j, t, k;
    uint16_t vn[8];    // Normalised denominator
    uint16_t un[18];   // Normalised numerator

    if(n == 1) {                      // Take care of
      k = 0;                          // the case of a
      for(j = m - 1; j >= 0; j--) {   // single-digit
        q[j] = (k*b + u[j])/v[0];     // divisor here.
        k = (k*b + u[j]) - q[j]*v[0];
      }
      r[0] = k;
      return;
    }

    // Normalize by shifting v left just enough so that
    // its high-order bit is on, and shift u left the
    // same amount.  We may have to append a high-order
    // digit on the dividend; we do that unconditionally.

    s = nlz(v[n-1]);            // 0 <= s <= 16.
    for(i = n - 1; i > 0; i--) {
      vn[i] = (v[i] << s) | (v[i-1] >> (16-s));
    }
    vn[0] = v[0] << s;

    un[m] = u[m-1] >> (16-s);
    for(i = m - 1; i > 0; i--) {
      un[i] = (u[i] << s) | (u[i-1] >> (16-s));
    }
    un[0] = u[0] << s;

    for(j = m - n; j >= 0; j--) {         // Main loop.
      // Compute estimate qhat of q[j].
      qhat = (un[j+n]*b + un[j+n-1])/vn[n-1];
      rhat = (un[j+n]*b + un[j+n-1]) - qhat*vn[n-1];
again:
      if(qhat >= b || qhat*vn[n-2] > b*rhat + un[j+n-2]) {
        qhat = qhat - 1;
        rhat = rhat + vn[n-1];
        if(rhat < b) {
          goto again;
        }
      }

      // Multiply and subtract.
      k = 0;
      for(i = 0; i < n; i++) {
        p = qhat*vn[i];
        t = un[i+j] - k - (p & 0xFFFF);
        un[i+j] = t;
        k = (p >> 16) - (t >> 16);
      }
      t = un[j+n] - k;
      un[j+n] = t;

      q[j] = qhat;       // Store quotient digit.
      if(t < 0) {        // If we subtracted too
        q[j] = q[j] - 1; // much, add back.
        k = 0;
        for(i = 0; i < n; i++) {
          t = un[i+j] + vn[i] + k;
          un[i+j] = t;
          k = t >> 16;
        }
        un[j+n] = un[j+n] + k;
      }
    } // End j.

    // Unnormalize remainder
    for(i = 0; i < n; i++) {
      r[i] = (un[i] >> s) | (un[i+1] << (16-s));
    }
  }

  uint64_t divmod(const int64_t z, const int64_t y, const int64_t x, int32_t *sx, int32_t *sy, uint64_t *rem) {
    uint64_t d, h, l;
    uint16_t denom[4];
    uint16_t numer[8];
    uint16_t quot[5];
    uint16_t rmdr[4];
    int32_t num_denom;
    int32_t num_numer;

    l = (uint64_t)z;  // Numerator low
    h = (uint64_t)y;  // Numerator high
    if(shortIntegerMode != SIM_UNSIGN && (h & shortIntegerSignBit) != 0) {
      if(shortIntegerMode == SIM_2COMPL) {
        l = (1 + ~l) & shortIntegerMask;
        h = ~h;
        if(l == 0) {
          h++;
        }
        h = h & shortIntegerMask;
      }
      else if(shortIntegerMode == SIM_1COMPL) {
        l = (~l) & shortIntegerMask;
        h = (~h) & shortIntegerMask;
      }
      else {
        h ^= shortIntegerSignBit;
      }
      *sy = 1;
    }
    else {
      *sy = 0;
    }

    d = extract_value(x, sx);  // Demonimator
    if(d == 0) {
      err_div0(h|l, *sx, *sy);
      return 0;
    }

    if(shortIntegerWordSize != 64) {
      l |= h << shortIntegerWordSize;
      h >>= (64 - shortIntegerWordSize);
    }

    if(h == 0 && l == 0) {    // zero over
      *rem = 0;
      return 0;
    }

    xset(quot, 0, sizeof(quot));
    xset(rmdr, 0, sizeof(rmdr));

    breakup(d, denom);
    breakup(l, numer);
    breakup(h, numer+4);

    for(num_denom = 4; num_denom > 1 && denom[num_denom-1] == 0; num_denom--) {
    }
    for(num_numer = 8; num_numer > num_denom && numer[num_numer-1] == 0; num_numer--) {
    }

    divmnu(quot, rmdr, numer, denom, num_numer, num_denom);

    *rem = packup(rmdr);
    return packup(quot);
  }

  int64_t intDblDiv(int64_t z, int64_t y, int64_t x) {
    uint64_t q, r;
    int32_t sx, sy;

    q = divmod(z, y, x, &sx, &sy, &r);
    set_overflow(0);
    set_carry(r != 0);
    return build_value(q, sx != sy);
  }

  int64_t intDblRmdr(int64_t z, int64_t y, int64_t x) {
    uint64_t r;
    int32_t sx, sy;

    divmod(z, y, x, &sx, &sy, &r);
    return build_value(r, sy);
  }


  int64_t intBooleanOp(int64_t y, int64_t x) {
    int64_t result;
    const int32_t op = XeqOpCode - (OP_DYA | OP_LAND);
    const int32_t not = op >= 3 ? 3 : 0;

    switch(op - not) {
      case 0: {
        result = y & x;
        break;
      }
      case 1: {
        result = y | x;
        break;
      }
      default: {
        result = y ^ x;
      }
    }

    if(not) {
      result = ~result;
    }

    return result & shortIntegerMask;
  }

  /* Single bit shifts are special internal version.
   * The multi-bit shifts vector through these.
   */

  int64_t intLSL(int64_t x) {
    set_carry(0 != (shortIntegerSignBit & x));
    return ((x << 1) & ~1) & shortIntegerMask;
  }

  int64_t intLSR(int64_t x) {
    set_carry(0 != (x & 1));
    return ((x >> 1) & ~shortIntegerSignBit) & shortIntegerMask;
  }

  int64_t intASR(int64_t x) {
    int64_t y;

    set_carry(x & 1);
    if(shortIntegerMode == SIM_SIGNMT) {
      return ((x & ~shortIntegerSignBit) >> 1) | (x & shortIntegerSignBit);
    }

    y = x >> 1;
    if(shortIntegerMode != SIM_UNSIGN && (x & shortIntegerSignBit) != 0)  {
      y |= shortIntegerSignBit;
    }

    return y;
  }

  int64_t intRL(int64_t x) {
    const int32_t cry = (shortIntegerSignBit & x)?1:0;

    set_carry(cry);
    return (intLSL(x) | cry) & shortIntegerMask;
  }

  int64_t intRR(int64_t x) {
    const int32_t cry = x & 1;

    set_carry(cry);
    x = intLSR(x);
    if(cry) {
      x |= shortIntegerSignBit;
    }

    return x & shortIntegerMask;
  }

  int64_t intRLC(int64_t x) {
    const int32_t cin = (getSystemFlag(FLAG_CARRY) == ON ? 1 : 0);
    set_carry((shortIntegerSignBit & x)?1:0);

    return (intLSL(x) | cin) & shortIntegerMask;
 }

  int64_t intRRC(int64_t x) {
    const int32_t cin = (getSystemFlag(FLAG_CARRY) == ON ? 1 : 0);

    set_carry(x&1);
    x = intLSR(x);
    if(cin) {
      x |= shortIntegerSignBit;
    }

    return x & shortIntegerMask;
  }

  /* Like the above but taking the count argument from the opcode.
   * Also possibly register indirect but that is dealt with elsewhere.
   */
  void introt(uint32_t arg, enum rarg op) {
    int64_t (*f)(int64_t);
    uint32_t mod;
    int64_t x;
    uint32_t i;

    x = getX_int();

    if(arg != 0) {
      switch(op) {
        case RARG_RL: {
          f = &intRL;  mod = shortIntegerWordSize;
          break;
        }
        case RARG_RR: {
          f = &intRR;  mod = shortIntegerWordSize;
          break;
        }
        case RARG_RLC: {
          f = &intRLC; mod = shortIntegerWordSize + 1;
          break;
        }
        case RARG_RRC: {
          f = &intRRC; mod = shortIntegerWordSize + 1;
          break;
        }
        case RARG_SL: {
          f = &intLSL; mod = 0;
          break;
        }
        case RARG_SR: {
          f = &intLSR; mod = 0;
          break;
        }
        case RARG_ASR: {
          f = &intASR; mod = 0;
          break;
        }
        default: {
          return;
        }
      }

      if(arg > shortIntegerWordSize) {
        if(mod) {
          arg = arg % mod;
        }
        else {
          arg = shortIntegerWordSize;
        }
      }

      for(i=0; i<arg; i++) {
        x = (*f)(x);
      }
    }

    setlastX();
    setX_int(x & shortIntegerMask);
  }


  /* Some code to count bits.  We start with a routine to count bits in a single
   * 32 bit word and call this twice.
   */
  uint32_t count32bits(uint32_t v) {
   v = v - ((v >> 1) & 0x55555555);
   v = (v & 0x33333333) + ((v >> 2) & 0x33333333);
   return (((v + (v >> 4)) & 0xF0F0F0F) * 0x1010101) >> 24;
  }

  uint32_t count64bits(int64_t x) {
   return count32bits(x & 0xffffffff) + count32bits((x >> 32) & 0xffffffff);
  }

  int64_t intNumBits(int64_t x) {
   return count64bits(x) & shortIntegerMask;
  }
#endif // 0
