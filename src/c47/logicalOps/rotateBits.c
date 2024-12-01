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
 * \file rotateBits.c
 ***********************************************/

#include "logicalOps/rotateBits.h"

#include "config.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "stack.h"

#include "c47.h"



/********************************************//**
 * \brief regX ==> regL and ASR(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnAsr(uint16_t numberOfShifts) {
  int32_t i;
  uint64_t sign;

  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    if(!saveLastX()) {
      return;
    }

    sign = *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & shortIntegerSignBit;
    for(i=1; i<=numberOfShifts; i++) {
      if(i == numberOfShifts) {
        if(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & 1) {
          setSystemFlag(FLAG_CARRY);
        }
        else {
          clearSystemFlag(FLAG_CARRY);
        }
      }

      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = (*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) >> 1) | sign;
    }
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) &= shortIntegerMask;
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot ASR %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnAsr:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



/********************************************//**
 * \brief regX ==> regL and SL(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSl(uint16_t numberOfShifts) {
  int32_t i;

  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    if(!saveLastX()) {
      return;
    }

    for(i=1; i<=numberOfShifts; i++) {
      if(i == numberOfShifts) {
        if(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & shortIntegerSignBit) {
          setSystemFlag(FLAG_CARRY);
        }
        else {
          clearSystemFlag(FLAG_CARRY);
        }
      }

      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) <<= 1;
    }
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) &= shortIntegerMask;
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot SL %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnSl:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



/********************************************//**
 * \brief regX ==> regL and SR(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSr(uint16_t numberOfShifts) {
  int32_t i;

  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    if(!saveLastX()) {
      return;
    }

    for(i=1; i<=numberOfShifts; i++) {
      if(i == numberOfShifts) {
        if(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & 1) {
          setSystemFlag(FLAG_CARRY);
        }
        else {
          clearSystemFlag(FLAG_CARRY);
        }
      }

      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) >>= 1;
    }
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) &= shortIntegerMask;
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot SR %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnSr:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



/********************************************//**
 * \brief regX ==> regL and RL(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnRl(uint16_t numberOfShifts) {
  int32_t i;
  uint64_t sign;

  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    if(!saveLastX()) {
      return;
    }

    for(i=1; i<=numberOfShifts; i++) {
      sign = (*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & shortIntegerSignBit) >> (shortIntegerWordSize - 1);
      if(i == numberOfShifts) {
        if(sign) {
          setSystemFlag(FLAG_CARRY);
        }
        else {
          clearSystemFlag(FLAG_CARRY);
        }
      }

      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = (*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) << 1) | sign;
    }
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) &= shortIntegerMask;
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot RL %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnRl:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



/********************************************//**
 * \brief regX ==> regL and RR(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnRr(uint16_t numberOfShifts) {
  int32_t i;

  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    if(!saveLastX()) {
      return;
    }

    for(i=1; i<=numberOfShifts; i++) {
      if(i == numberOfShifts) {
        if(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & 1) {
          setSystemFlag(FLAG_CARRY);
        }
        else {
          clearSystemFlag(FLAG_CARRY);
        }
      }

      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = (*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) >> 1) | ((*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & 1) << (shortIntegerWordSize - 1));
    }
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) &= shortIntegerMask;
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot RR %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnRr:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



/********************************************//**
 * \brief regX ==> regL and RLC(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnRlc(uint16_t numberOfShifts) {
  int32_t i;
  uint64_t sign, carry;

  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    if(!saveLastX()) {
      return;
    }

    carry = getSystemFlag(FLAG_CARRY);
    for(i=1; i<=numberOfShifts; i++) {
      sign = (*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & shortIntegerSignBit) >> (shortIntegerWordSize - 1);
      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = (*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) << 1) | carry;
      carry = sign;
    }

    if(carry) {
      setSystemFlag(FLAG_CARRY);
    }
    else {
      clearSystemFlag(FLAG_CARRY);
    }
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) &= shortIntegerMask;
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot RLC %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnRlc:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



/********************************************//**
 * \brief regX ==> regL and RRC(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnRrc(uint16_t numberOfShifts) {
  int32_t i;
  uint64_t lsb, carry;

  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    if(!saveLastX()) {
      return;
    }

    carry = getSystemFlag(FLAG_CARRY);
    for(i=1; i<=numberOfShifts; i++) {
      lsb = *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & 1;
      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = (*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) >> 1) | (carry << (shortIntegerWordSize - 1));
      carry = lsb;
    }

    if(carry) {
      setSystemFlag(FLAG_CARRY);
    }
    else {
      clearSystemFlag(FLAG_CARRY);
    }
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) &= shortIntegerMask;
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot RRC %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnRrc:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



/********************************************//**
 * \brief regX ==> regL and LJ(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnLj(uint16_t numberOfShifts) {
  int32_t count;
  longInteger_t regX;

  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    if(!saveLastX()) {
      return;
    }

    count = 0;
    while((*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & shortIntegerSignBit) == 0) {
      count++;
      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) <<= 1;
    }

    longIntegerInit(regX);
    intToLongInteger(count, regX);

    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    convertLongIntegerToLongIntegerRegister(regX, REGISTER_X);
    longIntegerFree(regX);
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot LJ %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnLj:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



/********************************************//**
 * \brief regX ==> regL and RJ(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnRj(uint16_t numberOfShifts) {
  int32_t count;
  longInteger_t regX;

  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    if(!saveLastX()) {
      return;
    }

    count = 0;
    while((*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & 1) == 0) {
      count++;
      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) >>= 1;
    }

    longIntegerInit(regX);
    intToLongInteger(count, regX);

    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    convertLongIntegerToLongIntegerRegister(regX, REGISTER_X);
    longIntegerFree(regX);
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot RJ %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnRj:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



void fnMirror(uint16_t unusedButMandatoryParameter) {
  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    uint64_t x, r=0;

    if(!saveLastX()) {
      return;
    }

    x = *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X));
    if(x != 0) {
      for(uint32_t i=0; i<shortIntegerWordSize; i++) {
        if(x & (1LL << i)) {
          r |= 1LL << (shortIntegerWordSize-i-1);
        }
      }
    }

    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = r;
  }

  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "the input type %s is not allowed for MIRROR!", getDataTypeName(getRegisterDataType(REGISTER_X), false, false));
      moreInfoOnError("In function fnMirror:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}

/********************************************//**                    //JM vv
 * \brief regX ==> regL and Change Endianness(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSwapEndian(uint8_t bitWidth) {
uint64_t b7,b6,b5,b4,b3,b2,b1,b0;
uint64_t x;

  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);

    x = *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X));

    //printf("### %d %d",(shortIntegerWordSize & (bitWidth-1)), (shortIntegerWordSize |  (bitWidth-1) ) + 1 );

    b7 = (x & 0xFF00000000000000) >> (64- 8);
    b6 = (x & 0x00FF000000000000) >> (64-16);
    b5 = (x & 0x0000FF0000000000) >> (64-24);
    b4 = (x & 0x000000FF00000000) >> (64-32);
    b3 = (x & 0x00000000FF000000) >> (64-40);
    b2 = (x & 0x0000000000FF0000) >> (64-48);
    b1 = (x & 0x000000000000FF00) >> (64-56);
    b0 = (x & 0x00000000000000FF) >> (64-64);

    if(bitWidth == 8) {
      if(shortIntegerWordSize<16) {fnSetWordSize(16);}
      else
        if( (shortIntegerWordSize & (bitWidth-1)) != 0 ) {fnSetWordSize((shortIntegerWordSize |  (bitWidth-1) ) + 1);}
      switch(shortIntegerWordSize) {
        case 16: x =                                                                               (b0 << 8 ) | b1; break;
        case 24: x =                                                                  (b0 << 16) | (b1 << 8 ) | b2; break;
        case 32: x =                                                     (b0 << 24) | (b1 << 16) | (b2 << 8 ) | b3; break;
        case 40: x =                                        (b0 << 32) | (b1 << 24) | (b2 << 16) | (b3 << 8 ) | b4; break;
        case 48: x =                           (b0 << 40) | (b1 << 32) | (b2 << 24) | (b3 << 16) | (b4 << 8 ) | b5; break;
        case 56: x =              (b0 << 48) | (b1 << 40) | (b2 << 32) | (b3 << 24) | (b4 << 16) | (b5 << 8 ) | b6; break;
        case 64: x = (b0 << 56) | (b1 << 48) | (b2 << 40) | (b3 << 32) | (b4 << 24) | (b5 << 16) | (b6 << 8 ) | b7; break;
        default:break;
      }
    }
    else
    if(bitWidth == 16) {
      if(shortIntegerWordSize<32) {fnSetWordSize(32);}
      else
        if( (shortIntegerWordSize & (bitWidth-1)) != 0 ) {fnSetWordSize((shortIntegerWordSize |  (bitWidth-1) ) + 1);}
      switch(shortIntegerWordSize) {
        case 32: x =                                                     (b1 << 24) | (b0 << 16) | (b3 << 8 ) | b2; break;
        case 48: x =                           (b1 << 40) | (b0 << 32) | (b3 << 24) | (b2 << 16) | (b5 << 8 ) | b4; break;
        case 64: x = (b1 << 56) | (b0 << 48) | (b3 << 40) | (b2 << 32) | (b5 << 24) | (b4 << 16) | (b7 << 8 ) | b6; break;
        default:break;
      }

    }
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = x;

  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot Swap %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnSwapEndian:", errorMessage, NULL, NULL);
    #endif
  }
}                                                              //JM ^^


