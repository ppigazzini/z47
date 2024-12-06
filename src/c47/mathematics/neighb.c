// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file neighb.c
 ***********************************************/

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
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
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
