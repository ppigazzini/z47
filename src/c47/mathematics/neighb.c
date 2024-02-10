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
 * \file neighb.c
 ***********************************************/

#include "mathematics/neighb.h"

#include "debug.h"
#include "error.h"
#include "integers.h"
#include "mathematics/comparisonReals.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



void fnNeighb(uint16_t unusedButMandatoryParameter) {
  uint32_t dataTypeX, dataTypeY;
  real_t x, y;
  longInteger_t lgIntX, lgIntY;

  dataTypeX = getRegisterDataType(REGISTER_X);
  dataTypeY = getRegisterDataType(REGISTER_Y);
  if(   dataTypeX == dtTime            || dataTypeY == dtTime
     || dataTypeX == dtDate            || dataTypeY == dtDate
     || dataTypeX == dtString          || dataTypeY == dtString
     || dataTypeX == dtReal34Matrix    || dataTypeY == dtReal34Matrix
     || dataTypeX == dtComplex34Matrix || dataTypeY == dtComplex34Matrix
     || dataTypeX == dtComplex34       || dataTypeY == dtComplex34) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot get the NEIGHB from %s", getRegisterDataTypeName(REGISTER_X, true, false));
      sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "towards %s", getRegisterDataTypeName(REGISTER_Y, true, false));
      moreInfoOnError("In function fnNeighb:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(!saveLastX()) {
    return;
  }

  switch(dataTypeX) {
    case dtLongInteger: {
      convertLongIntegerRegisterToLongInteger(REGISTER_X, lgIntX);
      switch(dataTypeY) {
        case dtLongInteger: {
          convertLongIntegerRegisterToLongInteger(REGISTER_Y, lgIntY);
          intToLongInteger(longIntegerCompare(lgIntY, lgIntX) == 0 ? 0 : (longIntegerCompare(lgIntY, lgIntX) > 0 ? 1 : -1), lgIntY);
          break;
        }

        case dtShortInteger: {
          convertShortIntegerRegisterToLongInteger(REGISTER_Y, lgIntY);
          intToLongInteger(longIntegerCompare(lgIntY, lgIntX) == 0 ? 0 : (longIntegerCompare(lgIntY, lgIntX) > 0 ? 1 : -1), lgIntY);
          break;
        }

        case dtReal34: {
          convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal75);
          real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
          longIntegerInit(lgIntY);
          intToLongInteger(realCompareEqual(&y, &x) ? 0 : (realCompareGreaterThan(&y, &x) ? 1 : -1), lgIntY);
          break;
        }

        default: {
        }
      }

      longIntegerAdd(lgIntX, lgIntY, lgIntX);
      convertLongIntegerToLongIntegerRegister(lgIntX, REGISTER_X);

      longIntegerFree(lgIntX);
      longIntegerFree(lgIntY);
      break;
    }

    case dtShortInteger: {
      convertShortIntegerRegisterToLongInteger(REGISTER_X, lgIntX);
      switch(dataTypeY) {
        case dtLongInteger: {
          convertLongIntegerRegisterToLongInteger(REGISTER_Y, lgIntY);
          intToLongInteger(longIntegerCompare(lgIntY, lgIntX) == 0 ? 0 : (longIntegerCompare(lgIntY, lgIntX) > 0 ? 1 : -1), lgIntY);
          break;
        }

        case dtShortInteger: {
          convertShortIntegerRegisterToLongInteger(REGISTER_Y, lgIntY);
          intToLongInteger(longIntegerCompare(lgIntY, lgIntX) == 0 ? 0 : (longIntegerCompare(lgIntY, lgIntX) > 0 ? 1 : -1), lgIntY);
          break;
        }

        case dtReal34: {
          convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
          real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
          longIntegerInit(lgIntY);
          intToLongInteger(realCompareEqual(&y, &x) ? 0 : (realCompareGreaterThan(&y, &x) ? 1 : -1), lgIntY);
          break;
        }

        default: {
        }
      }

      longIntegerAdd(lgIntX, lgIntY, lgIntX);
      convertLongIntegerToShortIntegerRegister(lgIntX, getRegisterShortIntegerBase(REGISTER_X), REGISTER_X);

      longIntegerFree(lgIntX);
      longIntegerFree(lgIntY);
      break;
    }

    case dtReal34: {
      real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
      switch(dataTypeY) {
        case dtLongInteger: {
          convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal75);
          break;
        }
        case dtShortInteger: {
          convertShortIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal34);
          break;
        }
        case dtReal34: {
          real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
          break;
        }
        default: {
        }
      }

      realNextToward(&x, &y, &x, &ctxtReal34);
      convertRealToReal34ResultRegister(&x, REGISTER_X);
      break;
    }

    default: {
    }
  }

  adjustResult(REGISTER_X, true, false, REGISTER_X, -1, -1);
}
