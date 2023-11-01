// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "display.h"

#include "saveRestoreCalcState.h"
#include "c43Extensions/addons.h"
#include "charString.h"
#include "constantPointers.h"
#include "conversionAngles.h"
#include "dateTime.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "fractions.h"
#include "items.h"
#include "c43Extensions/jm.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/matrix.h"
#include "mathematics/toPolar.h"
#include "programming/input.h"
#include "mathematics/wp34s.h"
#include "mathematics/rsd.h"
#include "c43Extensions/radioButtonCatalog.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "screen.h"
#include "softmenus.h"
#include "store.h"
#include "ui/matrixEditor.h"
#include <string.h>

#include "wp43.h"

static void fnDisplayFormatReset(uint16_t displayFormatN) {
  displayFormatDigits = displayFormatN > DSP_MAX ? DSP_MAX : displayFormatN;
  clearSystemFlag(FLAG_FRACT);
  constantFractionsOn = false;
  DM_Cycling = 0;
}

/********************************************//**
 * \brief Sets the display format FIX and refreshes the stack
 *
 * \param[in] displayFormatN uint16_t Display format
 * \return void
 ***********************************************/
void fnDisplayFormatFix(uint16_t displayFormatN) {
  fnDisplayFormatReset(displayFormatN);
  displayFormat = DF_FIX;
  fnRefreshState();                              //drJM
}


/********************************************//**
 * \brief Sets the display format SCI and refreshes the stack
 *
 * \param[in] displayFormatN uint16_t Display format
 * \return void
 ***********************************************/
void fnDisplayFormatSci(uint16_t displayFormatN) {
  fnDisplayFormatReset(displayFormatN);
  displayFormat = DF_SCI;
  fnRefreshState();                              //drJM
}


/********************************************//**
 * \brief Sets the display format ENG and refreshes the stack
 *
 * \param[in] displayFormatN uint16_t Display format
 * \return void
 ***********************************************/
void fnDisplayFormatEng(uint16_t displayFormatN) {
  fnDisplayFormatReset(displayFormatN);
  displayFormat = DF_ENG;
  fnRefreshState();                              //drJM
}


/********************************************//**
 * \brief Sets the display format ALL and refreshes the stack
 *
 * \param[in] displayFormatN uint16_t Display format
 * \return void
 ***********************************************/
void fnDisplayFormatAll(uint16_t displayFormatN) {
  fnDisplayFormatReset(displayFormatN);
  displayFormat = DF_ALL;
  fnRefreshState();                              //drJM
}


/********************************************//**
 * \Set SIGFIG mode
 *
 * FROM DISPLAY.C
 ***********************************************/
void fnDisplayFormatSigFig(uint16_t displayFormatN) {
  fnDisplayFormatReset(displayFormatN);
  displayFormat = DF_SF;
  displayFormatDigits = min(18,displayFormatDigits);
  fnRefreshState();
}


/********************************************//**
 * \Set UNIT mode
 *
 * FROM DISPLAY.C
 ***********************************************/
void fnDisplayFormatUnit(uint16_t displayFormatN) {
  fnDisplayFormatReset(displayFormatN);
  displayFormatDigits = min(20, displayFormatDigits);
  displayFormat = DF_UN;
  fnRefreshState();
}


/********************************************//**
 * \brief Sets the number of digits afer the period and refreshes the stack
 *
 * \param[in] displayFormatN uint16_t Display format
 * \return void
 ***********************************************/
void fnDisplayFormatDsp(uint16_t displayFormatN) {
  displayFormatN = displayFormatN > DSP_MAX ? DSP_MAX : displayFormatN;
  displayFormatDigits = displayFormatN;
  clearSystemFlag(FLAG_FRACT);
  fnRefreshState();                              //drJM
}


/********************************************//**
 * \brief Sets the display format for time and refreshes the stack
 *
 * \param[in] displayFormatN uint16_t Display format
 * \return void
 ***********************************************/
void fnDisplayFormatTime(uint16_t displayFormatN) {
  timeDisplayFormatDigits = displayFormatN > DSP_MAX ? DSP_MAX : displayFormatN;
}


/********************************************//**
 * \brief Adds the power of 10 using numeric font to displayString
 *
 * \param[out] displayString char*     Result string
 * \param[in]  exponent int32_t Power of 10 to format
 * \return void
 ***********************************************/
void exponentToDisplayString(int32_t exponent, char *displayString, char *displayValueString, bool_t nimMode) {
  strcpy(displayString, PRODUCT_SIGN);
  displayString += 2;
  strcpy(displayString, STD_SUB_10);
  displayString += 2;
  displayString[0] = 0;

  if(displayValueString != NULL) {
    *displayValueString++ = 'e';
    *displayValueString = 0;
  }

  if(nimMode) {
    if(exponent != 0) {
      supNumberToDisplayString(exponent, displayString, displayValueString, false);
    }
  }
  else {
    supNumberToDisplayString(exponent, displayString, displayValueString, false);
  }
}


void supNumberToDisplayString(int32_t supNumber, char *displayString, char *displayValueString, bool_t insertGap) {
  if(displayValueString != NULL) {
    sprintf(displayValueString, "%" PRId32, supNumber);
  }

  if(supNumber == 0) {
    strcat(displayString, STD_SUP_0);
  }
  else {
    int16_t digitCount=0;
    bool_t greaterThan9999;

    if(supNumber < 0) {
      supNumber = -supNumber;
      strcat(displayString, STD_SUP_MINUS);
      displayString += 2;
    }

    greaterThan9999 = (supNumber > 9999);
    while(supNumber > 0) {
      int16_t digit;

      digit = supNumber % 10;
      supNumber /= 10;

      xcopy(displayString + 2, displayString, stringByteLength(displayString) + 1);

      displayString[0] = STD_SUP_0[0];
      displayString[1] = STD_SUP_0[1];
      displayString[1] += digit;

      if(insertGap && greaterThan9999 && supNumber > 0 && !GROUPLEFT_DISABLED && ((++digitCount) % GROUPWIDTH_LEFT) == 0) {
        if(SEPARATOR_LEFT[1]!=1) {
          xcopy(displayString + 2, displayString, stringByteLength(displayString) + 1);
          displayString[0] = SEPARATOR_LEFT[0];
          displayString[1] = SEPARATOR_LEFT[1];
        } else if(SEPARATOR_LEFT[0]!=1) {
          xcopy(displayString + 1, displayString, stringByteLength(displayString) + 1);
          displayString[0] = SEPARATOR_LEFT[0];
        }
      }
    }
  }

  strcat(displayString, STD_SPACE_HAIR);
}


void subNumberToDisplayString(int32_t subNumber, char *displayString, char *displayValueString) {
  if(displayValueString != NULL) {
    sprintf(displayValueString, "%" PRId32, subNumber);
  }

  if(subNumber < 0) {
    subNumber = -subNumber;
    strcat(displayString, STD_SUB_MINUS);
    displayString += 2;
  }

  if(subNumber == 0) {
    strcat(displayString, STD_SUB_0);
  }
  else {
    while(subNumber > 0) {
      int16_t digit = subNumber % 10;
      subNumber /= 10;

      xcopy(displayString + 2, displayString, stringByteLength(displayString) + 1);

      displayString[0] = STD_SUB_0[0];
      displayString[1] = STD_SUB_0[1];
      displayString[1] += digit;
    }
  }
}


void real34ToDisplayString(const real34_t *real34, uint32_t tag, char *displayString, const font_t *font, int16_t maxWidth, int16_t displayHasNDigits, bool_t limitExponent, bool_t frontSpace) {
  uint8_t savedDisplayFormatDigits = displayFormatDigits;

  #if(REAL34_WIDTH_TEST == 1)
    maxWidth = largeur;
  #endif // (REAL34_WIDTH_TEST == 1)

  if(updateDisplayValueX) {
    displayValueX[0] = 0;
  }

  if(displayFormat == DF_SF) {        //This portion limits the SIGFIG digits to really n digits, even in the case of SIG3 12345000000000 to be displayed as 1.2340 x 10^5
      uint8_t digits = checkHP ? 10 : displayHasNDigits;
      if(tag == amNone) {
        real34ToDisplayString2(real34, displayString, digits, limitExponent, false, frontSpace);
        if(stringWidth(displayString, font, true, true) > maxWidth) {
          real34ToDisplayString2(real34, displayString, digits, limitExponent, true, frontSpace);
        }
      }
      else {
        angle34ToDisplayString2(real34, tag, displayString, digits, limitExponent, frontSpace);
      }

  }
  else { // not DF_SF
    if(tag == amNone) {
      real34ToDisplayString2(real34, displayString, displayHasNDigits, limitExponent, false, frontSpace);
    }
    else {
      angle34ToDisplayString2(real34, tag, displayString, displayHasNDigits, limitExponent, frontSpace);
    }

  while(stringWidth(displayString, font, true, true) > maxWidth) {
    if(displayFormat == DF_ALL) {
      if(displayHasNDigits == 2) {
        break;
      }
      displayHasNDigits--;
    }
    else {
      if(displayFormatDigits == 0) {
        break;
      }
      displayFormatDigits--;
    }

    if(updateDisplayValueX) {
      displayValueX[0] = 0;
    }

      if(tag == amNone) {
        real34ToDisplayString2(real34, displayString, displayHasNDigits, limitExponent, false, frontSpace);
      }
      else {
        angle34ToDisplayString2(real34, tag, displayString, displayHasNDigits, limitExponent, frontSpace);
      }
    }
  }

  displayFormatDigits = savedDisplayFormatDigits;
}


#define return_fr {constantFractionsMode = CF_NORMAL; return;}
/********************************************//**
 * \brief Formats a real
 *
 * \param[out] displayString char* Result string
 * \param[in]  x const real34_t*  Value to format
 * \return void
 ***********************************************/
void real34ToDisplayString2(const real34_t *real34, char *displayString, int16_t displayHasNDigits, bool_t limitExponent, bool_t noFix, bool_t frontSpace) {
  #undef MAX_DIGITS
  #define MAX_DIGITS 37 // 34 + 1 before (used when rounding from 9.999 to 10.000) + 2 after (used for rounding and ENG display mode)

  uint8_t charIndex, valueIndex;
  int16_t digitToRound=0;
  uint8_t *bcd;
  int16_t digitsToDisplay=0, numDigits, digitPointer, firstDigit, lastDigit, i, digitCount, digitsToTruncate, exponent;
  int32_t sign;
  bool_t  ovrSCI=false, ovrENG=false, firstDigitAfterPeriod=true;
  real34_t value34;


// JM^^ multiples and fractions of constants

  //printf(">>---\n");
  //Not checked for reals smaller than 1x10^-6 and integers
  //Fractions are switched off id MULTPI is used
  //Checking for root(3), pi, e, root(2), phi, root(5), in this sequence

  real34_t tol34;
  real_t value, c_temp;
  uint16_t constNr;

  realToReal34(const_1e_24, &tol34);   //Tolerance declaration 1x10^-32

  //printf(">>>## flag_proper %u\n",getSystemFlag(FLAG_PROPFR));
  if(constantFractions && constantFractionsOn && !getSystemFlag(FLAG_FRACT) && constantFractionsMode != CF_OFF && !real34CompareAbsLessThan(real34,const34_1e_6) && !real34IsAnInteger(real34)) {

    if(checkForAndChange_(displayString, real34, const_1, &tol34, "",frontSpace))                                            return_fr;

    if(checkForAndChange_(displayString, real34, const_rt3, &tol34, STD_SQUARE_ROOT STD_SUB_3,frontSpace))                   return_fr;
    if(checkForAndChange_(displayString, real34, const_pi , &tol34, STD_pi                   ,frontSpace))                   return_fr;

    fnConstantR( 8  /*const_eE     */,  &constNr, &c_temp);
    if(checkForAndChange_(displayString, real34, &c_temp, &tol34,  STD_EulerE                                  ,frontSpace)) return_fr;

    realMultiply(const_root2on2, const_2, &c_temp, &ctxtReal39);
    if(checkForAndChange_(displayString, real34, &c_temp, &tol34,  STD_SQUARE_ROOT STD_SUB_2                   ,frontSpace)) return_fr;

    fnConstantR( 73 /*const_PHI    */,  &constNr, &c_temp);
    if(checkForAndChange_(displayString, real34, &c_temp, &tol34,  indexOfItems[CST_01+constNr].itemCatalogName,frontSpace)) return_fr;

    realSquareRoot(const_5, &c_temp, &ctxtReal39);
    if(checkForAndChange_(displayString, real34, &c_temp, &tol34,   STD_SQUARE_ROOT STD_SUB_5,frontSpace))                   return_fr;
  }
  constantFractionsMode = CF_NORMAL;

// JM^^ ***********************

  //sigfig
  //printReal34ToConsole(real34," ------- 001 >>>>>"," <<<<<\n");   //JM
  if(displayFormat == DF_SF) {                                 //convert real34 to string, eat away all zeroes from the right and give back to FIX as a real
    char tmpString100[100];                           //cleaning up the REAL
    real34_t reduced;
    real_t tmp1;
    //printReal34ToConsole(real34," ------- 002a >>>>>"," <<<<<\n");   //JM
    real34ToReal(real34, &tmp1);
    roundToSignificantDigits(&tmp1, &tmp1, displayFormatDigits+1, &ctxtReal75);
    realToReal34(&tmp1, &reduced);
    //printReal34ToConsole(&reduced," ------- 002b >>>>>"," <<<<<\n");   //JM
    real34Reduce(&reduced, &reduced);
    //printReal34ToConsole(&reduced," ------- 002c >>>>>"," <<<<<\n");   //JM
    real34ToString(&reduced, tmpString100);
    //printf("------- 003 displayFormatDigits=%u >>>>>%s\n",displayFormatDigits, tmpString100);
    int8_t ii=0;
    while(tmpString100[ii]!=0) {                       //skip all zeroes
      while(tmpString100[ii] == '0') {
        if(tmpString100[ii] == 0) break;
        ii++;
      }                                                //counter at first non-'0' or at end
      if(tmpString100[ii] == '.') {
      //printf("------- 004 >>>>%s|, %i\n",tmpString100, ii);

          ii++;                                        //move to first non-'.' and skip all zeroes
          while(tmpString100[ii] == '0') {
            if(tmpString100[ii] == 0) break;
            ii++;
          }                                            //counter at first non-'0' or end, eg. 3.14159265358979E+15
          //printf("------- 004a >>>>%s|, %i, displayFormatDigits=%i\n",tmpString100, ii, displayFormatDigits);

          if(tmpString100[ii] != 0) {
            ii = ii + displayFormatDigits+1;           //2023-06-01 added 1 digit, giving FIX one extra digit for rounding. If it does not work properly, to do rounding here.
            int8_t jj = ii;
            //round here

            while(tmpString100[jj] != 0 && tmpString100[jj] != 'E') {   //find E or first non-zero
              jj++;
            }
            if(tmpString100[jj] == 'E') {              //If E, then move over the exponent to have only the specified significant digts, eg. 3.141E+15
              while(tmpString100[jj] != 0) {
                tmpString100[ii] = tmpString100[jj];
                jj++; ii++;
              }
              tmpString100[ii] = 0;
            }
          }
        //printf("------- 005 >>>>%s|\n",tmpString100);
        break;
      }
      else {
        ii++;
      }

    }

    stringToReal(tmpString100,&value,&ctxtReal39);
    //printRealToConsole(&value," ------- 006 >>>>>"," <<<<<\n\n");   //JM
  }
  else {
    real34ToReal(real34, &value);
  }
  //printRealToConsole(&value," ------- 006 >>>>>"," <<<<<\n\n");   //JM


  ctxtReal39.digits =  ((displayFormat == DF_FIX || displayFormat == DF_SF) ? 24 : displayHasNDigits); // This line is for FIX n displaying more than 16 digits. e.g. in FIX 15: 123 456.789 123 456 789 123
  //ctxtReal39.digits =  displayHasNDigits; // This line is for fixed number of displayed digits, e.g. in FIX 15: 123 456.789 123 456 8
  if(checkHP) ctxtReal39.digits = min(10,displayHasNDigits);
  realPlus(&value, &value, &ctxtReal39);
  ctxtReal39.digits = 39;
  realToReal34(&value, &value34);
  if(displayFormat == DF_SF) {
    real34Reduce(&value34, &value34);  //JM NEW SIG 2023-03-18
  }
  if(real34IsNegative(real34)) {
    real34SetNegativeSign(&value34);
  }

  bcd = (uint8_t *)(tmpString + 256 - MAX_DIGITS);
  memset(bcd, 0, MAX_DIGITS);

  sign = real34GetCoefficient(&value34, bcd + 1);
  exponent = real34GetExponent(&value34);

  // Calculate the number of significant digits
  for(digitPointer=1; digitPointer<=MAX_DIGITS-3; digitPointer++) {
    if(bcd[digitPointer] != 0) {
      break;
    }
  }

  if(digitPointer >= MAX_DIGITS-2) { // *real = 0.0
    firstDigit = 0;
    lastDigit  = 0;
    numDigits  = 1;
    exponent   = 0;
  }
  else {
    firstDigit = digitPointer;

    for(digitPointer=MAX_DIGITS-3; digitPointer>=1; digitPointer--) {
      if(bcd[digitPointer] == 0) {
        exponent++;
      }
      else {
        break;
      }
    }
    lastDigit = digitPointer;

    numDigits = lastDigit - firstDigit;
    exponent += numDigits++;
  }
/*
  if(limitExponent && abs(exponent) > exponentLimit) {
    if(exponent > exponentLimit) {
      if(real34IsPositive(&value34)) {
        realToReal34(const_plusInfinity, &value34);
      }
      else {
        realToReal34(const_minusInfinity, &value34);
      }
    }
    else if(exponent < -exponentLimit) {
      real34Zero(&value34);

      bcd = (uint8_t *)(tmpString + 256 - MAX_DIGITS);
      memset(bcd, 0, MAX_DIGITS);

      sign = 0;
      exponent = 0;
      firstDigit = 0;
      lastDigit  = 0;
      numDigits  = 1;
      exponent   = 0;
    }
  }*/

  if(limitExponent && (abs(exponent) > exponentLimit || (exponentHideLimit != 0 && exponent < exponentHideLimit))) {
    if(exponent > exponentLimit) {
      if(real34IsPositive(&value34)) {
        if(frontSpace) {
          strcpy(displayString, " " STD_LEFT_SINGLE_QUOTE STD_INFINITY STD_RIGHT_SINGLE_QUOTE);
        }
        else {
          strcpy(displayString, STD_LEFT_SINGLE_QUOTE STD_INFINITY STD_RIGHT_SINGLE_QUOTE);
        }
        if(updateDisplayValueX) {
          strcpy(displayValueX + strlen(displayValueX), "9e9999");
        }
      }
      else if(real34IsNegative(&value34)) {
        strcpy(displayString, "-" STD_LEFT_SINGLE_QUOTE STD_INFINITY STD_RIGHT_SINGLE_QUOTE);
        if(updateDisplayValueX) {
          strcpy(displayValueX + strlen(displayValueX), "-9e9999");
        }
      }
      return;
    }
    else if(exponent < -exponentLimit || (exponentHideLimit != 0 && exponent < -exponentHideLimit)) {
      if(real34IsPositive(&value34)) {
        strcpy(displayString, STD_LEFT_SINGLE_QUOTE "0." STD_RIGHT_SINGLE_QUOTE);
        if(updateDisplayValueX) {
          strcpy(displayValueX + strlen(displayValueX), "0");
        }
      }
      else if(real34IsNegative(&value34)) {
        strcpy(displayString, STD_LEFT_SINGLE_QUOTE "0." STD_RIGHT_SINGLE_QUOTE);
        if(updateDisplayValueX) {
          strcpy(displayValueX + strlen(displayValueX), "0");
        }
      }
      return;
    }
  }

  if(real34IsInfinite(&value34)) {
    if(real34IsNegative(&value34)) {
      strcpy(displayString, "-" STD_INFINITY);
      if(updateDisplayValueX) {
        strcpy(displayValueX + strlen(displayValueX), "-9e9999");
      }
    }
    else {
      strcpy(displayString, " " STD_INFINITY);
      if(updateDisplayValueX) {
        strcpy(displayValueX + strlen(displayValueX), "9e9999");
      }
    }
    return;
  }

  if(real34IsNaN(&value34)) {
    real34ToString(&value34, displayString);
    if(updateDisplayValueX) {
      real34ToString(&value34, displayValueX + strlen(displayValueX));
    }
    return;
  }

  charIndex = 0;
  valueIndex = (updateDisplayValueX ? strlen(displayValueX) : 0);

  //////////////
  // ALL mode //
  //////////////
  if(displayFormat == DF_ALL) {
    if(noFix || exponent >= displayHasNDigits || (displayFormatDigits != 0 && exponent < -(int32_t)displayFormatDigits) || (displayFormatDigits == 0 && exponent < numDigits - displayHasNDigits)) { // Display in SCI or ENG format
      digitsToDisplay = numDigits - 1;
      digitToRound    = firstDigit + digitsToDisplay;
      ovrSCI = !getSystemFlag(FLAG_ALLENG);
      ovrENG = getSystemFlag(FLAG_ALLENG);
    }
    else { // display all digits without ten exponent factor
      // Number of digits to truncate
      digitsToTruncate = max(numDigits - exponent, displayHasNDigits) - displayHasNDigits;
      numDigits -= digitsToTruncate;
      lastDigit -= digitsToTruncate;

      // Round the displayed number
      if(bcd[lastDigit+1] >= 5) {
        bcd[lastDigit]++;
      }

      // Transfert the carry
      while(bcd[lastDigit] == 10) {
        bcd[lastDigit--] = 0;
        numDigits--;
        bcd[lastDigit]++;
      }

      // Case when 9.9999 rounds to 10.0000
      if(lastDigit < firstDigit) {
        firstDigit--;
        lastDigit = firstDigit;
        numDigits = 1;
        exponent++;
      }

      // The sign
      if(sign) {
        displayString[charIndex++] = '-';
        if(updateDisplayValueX) {
          displayValueX[valueIndex++] = '-';
        }
      }
      else {
        if(frontSpace) {
          displayString[charIndex++] = ' ';
        }
      }

      if(exponent < 0) { // negative exponent
        // first 0 and radix mark
        displayString[charIndex++] = '0';
        if(updateDisplayValueX) {
          displayValueX[valueIndex++] = '0';
        }
        displayString[charIndex] = 0;
        char tt[4];
        if(RADIX34_MARK_STRING[1]!=1) {strcpy(tt,RADIX34_MARK_STRING);}
        else {tt[0] = RADIX34_MARK_STRING[0]; tt[1] = 0;}
        strcat(displayString, tt);
        charIndex += strlen(tt);
        if(updateDisplayValueX) {
          displayValueX[valueIndex++] = '.';
        }

        // Zeros before first significant digit
        for(digitCount=0, i=exponent+1; i<0; i++, digitCount--) {
          if(digitCount != 0 && !GROUPRIGHT_DISABLED && digitCount%(uint16_t)GROUPWIDTH_RIGHT == 0) {
            xcopy(displayString + charIndex,  SEPARATOR_RIGHT, SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
            charIndex +=  ( SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
          }
          displayString[charIndex++] = '0';
          if(updateDisplayValueX) {
            displayValueX[valueIndex++] = '0';
          }
        }

        // Significant digits
        for(digitPointer=firstDigit; digitPointer<firstDigit+min(displayHasNDigits - 1 - exponent, numDigits); digitPointer++, digitCount--) {
          if(digitCount != 0 && !GROUPRIGHT_DISABLED && digitCount%(uint16_t)GROUPWIDTH_RIGHT == 0) {
            xcopy(displayString + charIndex, SEPARATOR_RIGHT,  SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
            charIndex +=  ( SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
          }
          displayString[charIndex++] = '0' + bcd[digitPointer];
          if(updateDisplayValueX) {
            displayValueX[valueIndex++] = '0' + bcd[digitPointer];
          }
        }
      }
      else { // zero or positive exponent
        for(digitCount=exponent, digitPointer=firstDigit; digitPointer<=lastDigit + max(exponent - numDigits + 1, 0); digitPointer++, digitCount--) {

//vvGRP handling
          if(digitCount!=-1 && digitCount!=exponent && GROUPWIDTH_(digitCount)!=0
                            && IS_SEPARATOR_(digitCount)
                            && (GROUP1_OVFL(digitCount, exponent)==0 || bcd[digitPointer-1] >= GROUP1_OVFL(digitCount, exponent) + 1)   ) {
            //printf("GROUPWIDTH_=%2i digitCountNEW=%2i IS_SEPARATOR_=%2i \n",GROUPWIDTH_(digitCount), digitCountNEW(digitCount), IS_SEPARATOR_(digitCount) );
            xcopy(displayString + charIndex, SEPARATOR_(digitCount), 2);
//^^GRP handling

//          if(digitCount != -1 && digitCount != exponent && !GROUPLEFT_DISABLED && modulo(digitCount, (uint16_t)GROUPWIDTH_LEFT) == (uint16_t)GROUPWIDTH_LEFT - 1) {
  //          xcopy(displayString + charIndex, SEPARATOR_LEFT, 2);
            charIndex += 2;
          }

          // Significant digit or zero
          if(digitPointer <= lastDigit) {
            displayString[charIndex++] = '0' + bcd[digitPointer];
            if(updateDisplayValueX) {
              displayValueX[valueIndex++] = '0' + bcd[digitPointer];
            }
          }
          else {
            displayString[charIndex++] = '0';
            if(updateDisplayValueX) {
              displayValueX[valueIndex++] = '0';
            }
          }

          // Radix mark
          if(digitCount == 0) {
            displayString[charIndex] = 0;
            char tt[4];
            if(RADIX34_MARK_STRING[1]!=1) {strcpy(tt,RADIX34_MARK_STRING);}
            else {tt[0] = RADIX34_MARK_STRING[0]; tt[1] = 0;}
            strcat(displayString, tt);
            charIndex += strlen(tt);
            if(updateDisplayValueX) {
              displayValueX[valueIndex++] = '.';
            }
          }
        }
      }

      displayString[charIndex] = 0;
      if(updateDisplayValueX) {
        displayValueX[valueIndex] = 0;
      }
      return;
    }
  }

  //////////////
  // FIX mode //
  //////////////
  if(displayFormat == DF_FIX || displayFormat == DF_SF) {
    if(noFix || exponent >= displayHasNDigits || 
         exponent < -(int32_t)displayFormatDigits ||
         ( displayFormat == DF_SF && exponent -(int32_t)displayFormatDigits < -(checkHP ? 10+1 : displayHasNDigits)) ||
         ( displayFormat == DF_SF && !checkHP && exponent -(int32_t)displayFormatDigits > GROUPWIDTH_LEFT1)
      ) { // Display in SCI or ENG format
      digitsToDisplay = displayFormatDigits;
      digitToRound    = min(firstDigit + digitsToDisplay, lastDigit);
      ovrSCI = !getSystemFlag(FLAG_ALLENG);
      ovrENG = getSystemFlag(FLAG_ALLENG);
    }
    else { // display fix number of digits without ten exponent factor
      // Number of digits to truncate

      uint8_t displayFormatDigits_Active;
      if(displayFormat == DF_SF) {
        displayFormatDigits_Active =  min(max(((int16_t)displayFormatDigits+1)-exponent-1,0),255); //Convert SIG to FIX.
      }
      else {
        displayFormatDigits_Active = displayFormatDigits;
      }
      //printf(">>>## displayFormatDigits_Active=%u displayFormatDigits=%u numDigits=%u exponent=%i\n",displayFormatDigits_Active,displayFormatDigits, numDigits, exponent);
      digitsToTruncate = max(numDigits - (int16_t)displayFormatDigits_Active - exponent - 1, 0);   //SIGFIGNEW hackpoint
      numDigits -= digitsToTruncate;
      lastDigit -= digitsToTruncate;

      if(displayFormat == DF_SF && firstDigit + displayFormatDigits <= 34) {
        digitToRound = firstDigit + displayFormatDigits;
      }
      else {
        digitToRound = lastDigit;
      }
      //printf(">>> ###A %d %d %d %d %d |",numDigits, firstDigit, lastDigit, digitToRound, exponent); for(i=firstDigit; i<=lastDigit; i++) {printf("%c",48+bcd[i]);} printf("\n");

      // Round the displayed number
      if(bcd[digitToRound+1] >= 5) {
        bcd[digitToRound]++;
      }

      // Transfert the carry
      while(bcd[digitToRound] == 10) {
        bcd[digitToRound--] = 0;
        if(displayFormat == DF_SF) numDigits--;
        bcd[digitToRound]++;
      }

      lastDigit = digitToRound; //JM

      // Case when 9.9999 rounds to 10.0000
      if(digitToRound < firstDigit) {
        firstDigit--;
        lastDigit = firstDigit;
        numDigits = 1;
        if(displayFormat == DF_SF) displayFormatDigits_Active--;
        exponent++;
      }


      //JM SIGFIG - blank out non-sig digits to the right                 //JM SIGFIGNEW vv
      if(displayFormat == DF_SF) {
        if((displayFormatDigits+1)-exponent-1 < 0) {
           for(digitCount = firstDigit + (displayFormatDigits+1); digitCount <= 34; digitCount++) {
            bcd[digitCount] = 0;
           }
        }
      }                                                                   //JM SIGFIG

      // The sign
      if(sign) {
        displayString[charIndex++] = '-';
        if(updateDisplayValueX) {
          displayValueX[valueIndex++] = '-';
        }
      }
      else {
        if(frontSpace) {
          displayString[charIndex++] = ' ';
        }
      }

      if(exponent < 0) { // negative exponent
        // first 0 and radix mark
        displayString[charIndex++] = '0';
        if(updateDisplayValueX) {
          displayValueX[valueIndex++] = '0';
        }
        displayString[charIndex] = 0;
        char tt[4];
        if(RADIX34_MARK_STRING[1]!=1) {strcpy(tt,RADIX34_MARK_STRING);}
        else {tt[0] = RADIX34_MARK_STRING[0]; tt[1] = 0;}
        strcat(displayString, tt);
        charIndex += strlen(tt);
        if(updateDisplayValueX) {
          displayValueX[valueIndex++] = '.';
        }
//WHY is THIS . and displayValueX
        // Zeros before first significant digit
        for(digitCount=0, i=exponent+1; i<0; i++, digitCount--) {
          if(digitCount!=0 && !GROUPRIGHT_DISABLED && digitCount%(uint16_t)GROUPWIDTH_RIGHT==0) {
            xcopy(displayString + charIndex, SEPARATOR_RIGHT,  SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
            charIndex +=  ( SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
          }
          displayString[charIndex++] = '0';
          if(updateDisplayValueX) {
            displayValueX[valueIndex++] = '0';
          }
        }

        // Significant digits
        for(digitPointer=firstDigit; digitPointer<=lastDigit; digitPointer++, digitCount--) {
          if(digitCount!=0 && !GROUPRIGHT_DISABLED && digitCount%(uint16_t)GROUPWIDTH_RIGHT==0) {
            xcopy(displayString + charIndex, SEPARATOR_RIGHT,  SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
            charIndex +=  ( SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
          }
          displayString[charIndex++] = '0' + bcd[digitPointer];
          if(updateDisplayValueX) {
            displayValueX[valueIndex++] = '0' + bcd[digitPointer];
          }
        }

        // Zeros after last significant digit
        for(i=1; i<=(int16_t)displayFormatDigits_Active+exponent+1-numDigits; i++, digitCount--) {   //JM SIGFIGNEW hackpoint
          if(!GROUPRIGHT_DISABLED && digitCount%(uint16_t)GROUPWIDTH_RIGHT==0) {
            xcopy(displayString + charIndex, SEPARATOR_RIGHT,  SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
            charIndex +=  ( SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
          }
          displayString[charIndex++] = '0';
          if(updateDisplayValueX) {
            displayValueX[valueIndex++] = '0';
          }
        }
      }
      else { // zero or positive exponent
  //JM SIGFIGNEW hackpoint
        for(digitCount=exponent, digitPointer=firstDigit; digitPointer<=firstDigit + exponent + (int16_t)displayFormatDigits_Active; digitPointer++, digitCount--) { // This line is for FIX n displaying more than 16 digits. e.g. in FIX 15: 123 456.789 123 456 789 123
        //for(digitCount=exponent, digitPointer=firstDigit; digitPointer<=firstDigit + min(exponent + (int16_t)displayFormatDigits, 15); digitPointer++, digitCount--) { // This line is for fixed number of displayed digits, e.g. in FIX 15: 123 456.789 123 456 8

//vvGRP handling
          //printf(">>>> digitCount=(%2i)digitPointer=(%2i) bcd[digitPointer]=%2u GROUP1_OVFL=%2i GROUPWIDTH_LEFT1=%2u: %i ?? %i :",digitCount, digitPointer, bcd[digitPointer], GROUP1_OVFL(digitCount, exponent), GROUPWIDTH_LEFT1, bcd[digitPointer-1] , GROUP1_OVFL(digitCount, exponent) + 1);
          if(digitCount!=-1 && digitCount!=exponent && GROUPWIDTH_(digitCount)!=0
                            && IS_SEPARATOR_(digitCount)
                            && (GROUP1_OVFL(digitCount, exponent)==0 || bcd[digitPointer-1] >= GROUP1_OVFL(digitCount, exponent) + 1)   ) {
            //printf("GROUPWIDTH_=%2i digitCountNEW=%2i IS_SEPARATOR_=%2i \n",GROUPWIDTH_(digitCount), digitCountNEW(digitCount), IS_SEPARATOR_(digitCount) );
            xcopy(displayString + charIndex, SEPARATOR_(digitCount), 2);
//^^GRP handling

            charIndex += 2;
          }
          //else printf("\n");


          // Significant digit or zero
          if(digitPointer <= lastDigit) {
            displayString[charIndex++] = '0' + bcd[digitPointer];
            if(updateDisplayValueX) {
              displayValueX[valueIndex++] = '0' + bcd[digitPointer];
            }
          }
          else {
            displayString[charIndex++] = '0';
            if(updateDisplayValueX) {
              displayValueX[valueIndex++] = '0';
            }
          }

          // Radix mark
          if(digitCount == 0) {
            displayString[charIndex] = 0;
            char tt[4];
            if(RADIX34_MARK_STRING[1]!=1) {strcpy(tt,RADIX34_MARK_STRING);}
            else {tt[0] = RADIX34_MARK_STRING[0]; tt[1] = 0;}
            strcat(displayString, tt);
            charIndex += strlen(tt);
            if(updateDisplayValueX) {
              displayValueX[valueIndex++] = '.';
            }
          }
        }
      }

      displayString[charIndex] = 0;
      if(updateDisplayValueX) {
        displayValueX[valueIndex] = 0;
      }
      return;
    }
  }

  //////////////
  // SCI mode //
  //////////////
  if(ovrSCI  || displayFormat == DF_SCI) {
    // Round the displayed number
    if(!ovrSCI) {
      digitsToDisplay = displayFormatDigits;
      digitToRound    = min(firstDigit + (int16_t)displayFormatDigits, lastDigit);
    }

    if(bcd[digitToRound + 1] >= 5) {
      bcd[digitToRound]++;
    }

    // Transfert the carry
    while(bcd[digitToRound] == 10) {
      bcd[digitToRound--] = 0;
      numDigits--;
      bcd[digitToRound]++;
    }

    // Case when 9.9999 rounds to 10.0000
    if(digitToRound < firstDigit) {
      firstDigit--;
      numDigits = 1;
      exponent++;
    }

    // Sign
    if(sign) {
      displayString[charIndex++] = '-';
      if(updateDisplayValueX) {
        displayValueX[valueIndex++] = '-';
      }
    }
    else {
      if(frontSpace) {
        displayString[charIndex++] = ' ';
      }
    }

    // First digit
    displayString[charIndex++] = '0' + bcd[firstDigit];
    if(updateDisplayValueX) {
      displayValueX[valueIndex++] = '0' + bcd[firstDigit];
    }

    // Radix mark
    displayString[charIndex] = 0;
    char tt[4];
    if(RADIX34_MARK_STRING[1]!=1) {strcpy(tt,RADIX34_MARK_STRING);}
    else {tt[0] = RADIX34_MARK_STRING[0]; tt[1] = 0;}
    strcat(displayString, tt);
    charIndex += strlen(tt);
    if(updateDisplayValueX) {
      displayValueX[valueIndex++] = '.';
    }

    // Significant digits
    for(digitCount=-1, digitPointer=firstDigit+1; digitPointer<firstDigit+min(numDigits, digitsToDisplay+1); digitPointer++, digitCount--) {
      if(!firstDigitAfterPeriod && !GROUPRIGHT_DISABLED && modulo(digitCount, (uint16_t)GROUPWIDTH_RIGHT) == (uint16_t)GROUPWIDTH_RIGHT - 1) {
        xcopy(displayString + charIndex, SEPARATOR_RIGHT,  SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
        charIndex +=  ( SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
      }
      else {
        firstDigitAfterPeriod = false;
      }

      displayString[charIndex++] = '0' + bcd[digitPointer];
      if(updateDisplayValueX) {
        displayValueX[valueIndex++] = '0' + bcd[digitPointer];
      }
    }

    // The ending zeros
    for(digitPointer=0; digitPointer<=digitsToDisplay-numDigits; digitPointer++, digitCount--) {
      if(!firstDigitAfterPeriod && !GROUPRIGHT_DISABLED && modulo(digitCount, (uint16_t)GROUPWIDTH_RIGHT) == (uint16_t)GROUPWIDTH_RIGHT - 1) {
        xcopy(displayString + charIndex, SEPARATOR_RIGHT,  SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
        charIndex +=  ( SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
      }
      else {
        firstDigitAfterPeriod = false;
      }

      displayString[charIndex++] = '0';
      if(updateDisplayValueX) {
        displayValueX[valueIndex++] = '0';
      }
    }

    displayString[charIndex] = 0;
    if(updateDisplayValueX) {
      displayValueX[valueIndex] = 0;
    }

    if(exponent != 0) {
      if(updateDisplayValueX) {
        exponentToDisplayString(exponent, displayString + charIndex, displayValueX + valueIndex, false);
      }
      else {
        exponentToDisplayString(exponent, displayString + charIndex, NULL,                       false);
      }
    }
    return;
  }

  //////////////
  // ENG mode //
  //////////////
  if(ovrENG || displayFormat == DF_ENG || displayFormat == DF_UN) {
    // Round the displayed number
    if(!ovrENG) {
      digitsToDisplay = displayFormatDigits;
      digitToRound    = min(firstDigit + digitsToDisplay, lastDigit);
    }

    if(bcd[digitToRound + 1] >= 5) {
      bcd[digitToRound]++;
    }

    bcd[digitToRound + 1] = 0;
    bcd[digitToRound + 2] = 0;

    // Transfert the carry
    while(bcd[digitToRound] == 10) {
      bcd[digitToRound--] = 0;
      numDigits--;
      bcd[digitToRound]++;
    }

    // Case when 9.9999 rounds to 10.0000
    if(digitToRound < firstDigit) {
      firstDigit--;
      numDigits = 1;
      exponent++;
    }

    // The sign
    if(sign) {
      displayString[charIndex++] = '-';
      if(updateDisplayValueX) {
        displayValueX[valueIndex++] = '-';
      }
    }
    else {
      if(frontSpace){
        displayString[charIndex++] = ' ';
      }
    }

    // Digits before radix mark
    displayString[charIndex++] = '0' + bcd[firstDigit];
    if(updateDisplayValueX) {
      displayValueX[valueIndex++] = '0' + bcd[firstDigit];
    }
    firstDigit++;
    numDigits--;
    digitsToDisplay--;
    while(modulo(exponent, 3) != 0) {
      exponent--;
      displayString[charIndex++] = '0' + bcd[firstDigit];
      if(updateDisplayValueX) {
        displayValueX[valueIndex++] = '0' + bcd[firstDigit];
      }
      firstDigit++;
      numDigits--;
      digitsToDisplay--;
    }

    // Radix Mark
    displayString[charIndex] = 0;
    char tt[4];
    if(RADIX34_MARK_STRING[1]!=1) {strcpy(tt,RADIX34_MARK_STRING);}
    else {tt[0] = RADIX34_MARK_STRING[0]; tt[1] = 0;}
    strcat(displayString, tt);
    charIndex += strlen(tt);
    if(updateDisplayValueX) {
      displayValueX[valueIndex++] = '.';
    }

    // Digits after radix mark
    for(digitCount=-1, digitPointer=firstDigit; digitPointer<firstDigit+min(numDigits, digitsToDisplay+1); digitPointer++, digitCount--) {
      if(!firstDigitAfterPeriod && !GROUPRIGHT_DISABLED && modulo(digitCount, (uint16_t)GROUPWIDTH_RIGHT) == (uint16_t)GROUPWIDTH_RIGHT - 1) {
        xcopy(displayString + charIndex, SEPARATOR_RIGHT,  SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
        charIndex +=  ( SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
      }
      else {
        firstDigitAfterPeriod = false;
      }

      displayString[charIndex++] = '0' + bcd[digitPointer];
      if(updateDisplayValueX) {
        displayValueX[valueIndex++] = '0' + bcd[digitPointer];
      }
    }

    // The ending zeros
    for(digitPointer=0; digitPointer<=digitsToDisplay-max(0, numDigits); digitPointer++, digitCount--) {
      if(!firstDigitAfterPeriod && !GROUPRIGHT_DISABLED && modulo(digitCount, (uint16_t)GROUPWIDTH_RIGHT) == (uint16_t)GROUPWIDTH_RIGHT - 1) {
        xcopy(displayString + charIndex, SEPARATOR_RIGHT,  SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
        charIndex +=  ( SEPARATOR_RIGHT[0]!=1 ? (SEPARATOR_RIGHT[1]!=1 ? 2 : 1) : 0);
      }
      else {
        firstDigitAfterPeriod = false;
      }

      displayString[charIndex++] = '0';
      if(updateDisplayValueX) {
        displayValueX[valueIndex++] = '0';
      }
    }

    displayString[charIndex] = 0;
    if(updateDisplayValueX) {
      displayValueX[valueIndex] = 0;
    }

    if(exponent != 0) {
      if(displayFormat != DF_UN) {                                                        //JM UNIT
        if(updateDisplayValueX) {
          exponentToDisplayString(exponent, displayString + charIndex, displayValueX + valueIndex, false);
        }
        else {
          exponentToDisplayString(exponent, displayString + charIndex, NULL,                       false);
        }
      }                                                                                 //JM UNIT
      else {                                                                            //JM UNIT
        exponentToUnitDisplayString(exponent, displayString + charIndex, displayValueX + valueIndex, false);          //JM UNIT
      }                                                                                 //JM UNIT
    }
  }
}


void complex34ToDisplayString(const complex34_t *complex34, char *displayString, const font_t *font, int16_t maxWidth, int16_t displayHasNDigits, bool_t limitExponent, bool_t frontSpace, const uint16_t tagAngle, const bool_t tagPolar) {
  uint8_t savedDisplayFormatDigits = displayFormatDigits;
  uint8_t saveddisplayFormat       = displayFormat;

  if(updateDisplayValueX) {
    displayValueX[0] = 0;
  }

  complex34ToDisplayString2(complex34, displayString, displayHasNDigits, limitExponent, frontSpace, tagAngle, tagPolar);
  while(stringWidth(displayString, font, true, true) > maxWidth) {

    //complex34ToDisplayString2(complex34, displayString, displayHasNDigits, limitExponent, frontSpace, tagAngle, tagPolar);
    //printf("#### Xw=%i displayHasNDigits=%u  displayFormatDigits=%u str:%s\n",stringWidth(displayString, font, true, true),displayHasNDigits,displayFormatDigits,displayString);

    if(displayFormat == DF_ALL) {
      if(displayHasNDigits == 2) {
        break;
      }
      displayHasNDigits--;
    }
    else {
      if(displayFormatDigits == 0) {
        break;
      }
      displayFormatDigits--;
      if(displayFormatDigits == 3) displayFormat = DF_ALL;
    }

    if(updateDisplayValueX) {
      displayValueX[0] = 0;
    }

    complex34ToDisplayString2(complex34, displayString, displayHasNDigits, limitExponent, frontSpace, tagAngle, tagPolar);
  }
  displayFormatDigits = savedDisplayFormatDigits;
  displayFormat       = saveddisplayFormat;
}


void complex34ToDisplayString2(const complex34_t *complex34, char *displayString, int16_t displayHasNDigits, bool_t limitExponent, bool_t frontSpace, const uint16_t tagAngle, const bool_t tagPolar) {
  int16_t i = 100;
  real34_t real34, imag34, absimag34;
  real_t real, imagIc;

  if(tagPolar) { // polar mode
    real34ToReal(VARIABLE_REAL34_DATA(complex34), &real);
    real34ToReal(VARIABLE_IMAG34_DATA(complex34), &imagIc);
    if(temporaryInformation == TI_NO_INFO) ctxtReal39.digits = 16; //speedup
    realRectangularToPolar(&real, &imagIc, &real, &imagIc, &ctxtReal39); // imagIc in radian
    convertAngleFromTo(&imagIc, amRadian, tagAngle == amNone ? currentAngularMode : tagAngle, &ctxtReal39);
    ctxtReal39.digits = 39; //speedup
    realToReal34(&real, &real34);
    realToReal34(&imagIc, &imag34);
  }
  else { // rectangular mode
    real34Copy(VARIABLE_REAL34_DATA(complex34), &real34);
    real34Copy(VARIABLE_IMAG34_DATA(complex34), &imag34);
  }

  constantFractionsMode = CF_COMPLEX_1st_Re_or_L;  //JM
//printf("###>> displayHasNDigits=%u\n",displayHasNDigits);
  real34ToDisplayString2(&real34, displayString, displayHasNDigits, limitExponent, false, frontSpace);

  if(updateDisplayValueX) {                //This is used by ROUND only and it does not seem to work.
    if(tagPolar) {
      strcat(displayValueX, "j");
    }
    else {
      strcat(displayValueX, "i");
    }
  }

  constantFractionsMode = CF_COMPLEX_2nd_Im;  //JM
//printf("###>>> displayHasNDigits=%u\n",displayHasNDigits);
  real34ToDisplayString2(&imag34, displayString + i, displayHasNDigits, limitExponent, false, false);

  if(tagPolar) { // polar mode
    strcat(displayString, STD_SPACE_4_PER_EM STD_MEASURED_ANGLE STD_SPACE_4_PER_EM);
    angle34ToDisplayString2(&imag34, tagAngle == amNone ? currentAngularMode : tagAngle, displayString + stringByteLength(displayString), displayHasNDigits, limitExponent, false);
  }
  else { // rectangular mode
    if(strncmp(displayString + stringByteLength(displayString) - 2, STD_SPACE_HAIR, 2) != 0) {
      strcat(displayString, STD_SPACE_HAIR);
    }

    if(real34IsZero(&real34)) {       //JM
      if(displayString[i] == '-') {
        displayString[0]=0;           // force a zero real not to display the real part
        strcat(displayString, "-");   // re-add the - which could be trailing the real value. Do ot add the +, it is not needed
        i++;
      }
      else {
        displayString[0]=0;           // force a zero real not to display the real part
      }
    }
    else {                            // JM normal full display of the full imag part, + and - shown
      if(displayString[i] == '-') {
        strcat(displayString, "-");
        i++;
      }
      else {
        strcat(displayString, "+");
      }
    }

    if(CPXMULT) {                  // i x 1.0
      strcat(displayString, COMPLEX_UNIT);
      real34CopyAbs(&imag34, &absimag34);
//      if(!real34CompareEqual(&absimag34, const34_1)) {     //JM force a |imag|=1 not to display. Maybe make it part of IRFRAC.
        strcat(displayString, PRODUCT_SIGN);
        xcopy(strchr(displayString, '\0'), displayString + i, strlen(displayString + i) + 1);
//      }
    }

    if(!CPXMULT) {                   // 1.0 i
      real34CopyAbs(&imag34, &absimag34);
//      if(!real34CompareEqual(&absimag34, const34_1)) {     //JM force a |imag|=1 not to display.  Maybe make it part of IRFRAC.
        xcopy(strchr(displayString, '\0'), displayString + i, strlen(displayString + i) + 1);
//      }
      strcat(displayString, STD_SPACE_HAIR);
      strcat(displayString, STD_SPACE_HAIR);
      strcat(displayString, COMPLEX_UNIT);
    }
  }
}


/********************************************//**
 * \brief formats a fraction
 *
 * \param regist calcRegister_t
 * \param displayString char*
 * \return void
 ***********************************************/
void fractionToDisplayString(calcRegister_t regist, char *displayString) {
  int16_t  sign, lessEqualGreater;
  uint64_t intPart, numer, denom;
  int16_t  u, insertAt, endingZero, gap;

  //printf("regist = "); printRegisterToConsole(regist); printf("\n");
  fraction(regist, &sign, &intPart, &numer, &denom, &lessEqualGreater);

  //printf("result of fraction(...) = %c%" PRIu64 " %" PRIu64 "/%" PRIu64 "\n", sign==-1 ? '-' : ' ', intPart, numer, denom);

  // Comparison sign
  if(getSystemFlag(FLAG_FRCSRN)) {
    if(lessEqualGreater == -1) {
      sprintf(displayString, "%c" STD_SPACE_PUNCTUATION ">" STD_SPACE_PUNCTUATION, "xyzt"[regist - REGISTER_X]);
    }
    else if(lessEqualGreater ==  0) {
      sprintf(displayString, "%c" STD_SPACE_PUNCTUATION "=" STD_SPACE_PUNCTUATION, "xyzt"[regist - REGISTER_X]);
    }
    else if(lessEqualGreater ==  1) {
      sprintf(displayString, "%c" STD_SPACE_PUNCTUATION "<" STD_SPACE_PUNCTUATION, "xyzt"[regist - REGISTER_X]);
    }
    else {
      strcpy(displayString, "?" STD_SPACE_PUNCTUATION);
      sprintf(errorMessage, commonBugScreenMessages[bugMsgValueFor], "fractionToDisplayString", lessEqualGreater, "lessEqualGreater");
      displayBugScreen(errorMessage);
    }
  }
  else {
    if(lessEqualGreater == -1) {
      sprintf(displayString, ">" STD_SPACE_PUNCTUATION);
    }
    else if(lessEqualGreater ==  0) {
      displayString[0] = 0;
    }
    else if(lessEqualGreater ==  1) {
      sprintf(displayString, "<" STD_SPACE_PUNCTUATION);
    }
    else {
      strcpy(displayString, "?" STD_SPACE_PUNCTUATION);
      sprintf(errorMessage, commonBugScreenMessages[bugMsgValueFor], "fractionToDisplayString", lessEqualGreater, "lessEqualGreater");
      displayBugScreen(errorMessage);
    }
  }

  endingZero = strlen(displayString);

  if(getSystemFlag(FLAG_PROPFR)) { // a b/c
    if(updateDisplayValueX) {
      sprintf(displayValueX, "%s%" PRIu32 " %" PRIu32 "/%" PRIu32, (sign == -1 ? "-" : ""), (uint32_t)intPart, (uint32_t)numer, (uint32_t)denom);
    }

    if(sign == -1) {
      strcat(displayString, "-");
      endingZero++;
    }

    // Integer part
    insertAt = endingZero;
    gap = -1;
    do {
      gap++;
      if(gap == GROUPWIDTH_LEFT) {
        gap = 0;
        endingZero++;
        xcopy(displayString + insertAt + 2, displayString + insertAt, endingZero++ - insertAt);
        displayString[insertAt]     = SEPARATOR_LEFT[0];
        displayString[insertAt + 1] = SEPARATOR_LEFT[1];
      }

      u = intPart % 10;
      intPart /= 10;
      endingZero++;
      xcopy(displayString + insertAt + 1, displayString + insertAt, endingZero - insertAt);
      displayString[insertAt] = '0' + u;
    } while(intPart != 0);

    strcat(displayString, STD_SPACE_PUNCTUATION);
    endingZero += 2;
  }

  else { // FT_IMPROPER d/c
    if(updateDisplayValueX) {
      sprintf(displayValueX, "%s%" PRIu32 "/%" PRIu32, (sign == -1 ? "-" : ""), (uint32_t)numer, (uint32_t)denom);
    }

    if(sign == -1) {
      strcat(displayString, STD_SUP_MINUS);
      endingZero += 2;
    }
  }

  // Numerator
  insertAt = endingZero;
  gap = -1;
  do {
    gap++;
    if(gap == GROUPWIDTH_LEFT) {
      gap = 0;
      endingZero++;
      xcopy(displayString + insertAt + 2, displayString + insertAt, endingZero++ - insertAt);
      displayString[insertAt]     = SEPARATOR_FRAC[0];
      displayString[insertAt + 1] = SEPARATOR_FRAC[1];
    }

    u = numer % 10;
    numer /= 10;
    endingZero++;
    xcopy(displayString + insertAt + 2, displayString + insertAt, endingZero++ - insertAt);

    displayString[insertAt]     = STD_SUP_0[0];
    displayString[insertAt + 1] = STD_SUP_0[1];
    displayString[insertAt + 1] += u;
  } while(numer != 0);


  // Fraction bar
  strcat(displayString, "/");
  endingZero++;


  // Denominator
  insertAt = endingZero;
  gap = -1;
  do {
    gap++;
    if(gap == GROUPWIDTH_LEFT) {
      gap = 0;
      endingZero++;
      xcopy(displayString + insertAt + 2, displayString + insertAt, endingZero++ - insertAt);
      displayString[insertAt]     = SEPARATOR_FRAC[0];
      displayString[insertAt + 1] = SEPARATOR_FRAC[1];
    }

    u = denom % 10;
    denom /= 10;
    endingZero++;
    xcopy(displayString + insertAt + 2, displayString + insertAt, endingZero++ - insertAt);
    displayString[insertAt]     = STD_SUB_0[0];
    displayString[insertAt + 1] = STD_SUB_0[1];
    displayString[insertAt + 1] += u;
  } while(denom != 0);
}


void angle34ToDisplayString2(const real34_t *angle34, uint8_t mode, char *displayString, int16_t displayHasNDigits, bool_t limitExponent, bool_t frontSpace) {
  if(mode == amDMS) {
    char degStr[27];
    uint32_t m, s, fs;
    int16_t sign;
    bool_t overflow;
    real34_t angle34Dms;
    real_t angleDms, degrees, minutes, seconds;

    real34FromDegToDms(angle34, &angle34Dms);
    real34ToReal(&angle34Dms, &angleDms);

    sign = realIsNegative(&angleDms);
    realSetPositiveSign(&angleDms);

    // Get the degrees
    realToIntegralValue(&angleDms, &degrees, DEC_ROUND_DOWN, &ctxtReal39);

    // Get the minutes
    realSubtract(&angleDms, &degrees, &angleDms, &ctxtReal39);
    realMultiply(&angleDms, const_100, &angleDms, &ctxtReal39);
    realToIntegralValue(&angleDms, &minutes, DEC_ROUND_DOWN, &ctxtReal39);

    // Get the seconds
    realSubtract(&angleDms, &minutes, &angleDms, &ctxtReal39);
    realMultiply(&angleDms, const_100, &angleDms, &ctxtReal39);
    realToIntegralValue(&angleDms, &seconds, DEC_ROUND_DOWN, &ctxtReal39);

    // Get the fractional seconds
    realSubtract(&angleDms, &seconds, &angleDms, &ctxtReal39);
    realMultiply(&angleDms, const_100, &angleDms, &ctxtReal39);

    realToUInt32(&angleDms, DEC_ROUND_DOWN, &fs, &overflow);
    realToUInt32(&seconds,  DEC_ROUND_DOWN, &s,  &overflow);
    realToUInt32(&minutes,  DEC_ROUND_DOWN, &m,  &overflow);

    if(fs >= 100) {
      fs -= 100;
      s++;
    }

    if(s >= 60) {
      s -= 60;
      m++;
    }

    if(m >= 60) {
      m -= 60;
      realAdd(&degrees, const_1, &degrees, &ctxtReal39);
    }

    realToString(&degrees, degStr);
    for(int32_t i=0; degStr[i]!=0; i++) {
      if(degStr[i] == '.') {
        degStr[i] = 0;
        break;
      }
    }
    char tt[4];
    if(RADIX34_MARK_STRING[1]!=1) {strcpy(tt,RADIX34_MARK_STRING);}
    else {tt[0] = RADIX34_MARK_STRING[0]; tt[1] = 0;}

    sprintf(displayString, "%s%s" STD_DEGREE "%s%" PRIu32 STD_RIGHT_SINGLE_QUOTE "%s%" PRIu32 "%s%02" PRIu32 STD_RIGHT_DOUBLE_QUOTE,
                            sign ? "-" : " ",
                              degStr,         m < 10 ? " " : "",
                                                m,                   s < 10 ? " " : "",
                                                                       s,         tt,
                                                                                    fs);
  }
  else if(mode == amMultPi) {
    constantFractionsMode = CF_OFF;        //JM
    real34ToDisplayString2(angle34, displayString, displayHasNDigits, limitExponent, mode == amSecond, frontSpace);
    strcat(displayString, STD_SUP_pir);
  }
  else {
    real34ToDisplayString2(angle34, displayString, displayHasNDigits, limitExponent, mode == amSecond, frontSpace);

    if(mode == amRadian) {
      strcat(displayString, STD_SUP_r);
    }
    else if(mode == amGrad) {
      strcat(displayString, STD_SUP_g);
    }
    else if(mode == amDegree) {
      strcat(displayString, STD_DEGREE);
    }
    else if(mode == amSecond) {
      strcat(displayString, "s");
    }
    else {
      strcat(displayString, "?");
      sprintf(errorMessage, commonBugScreenMessages[bugMsgValueFor], "angle34ToDisplayString2", mode, "mode");
      displayBugScreen(errorMessage);
    }
  }
}


void shortIntegerToDisplayString(calcRegister_t regist, char *displayString, bool_t determineFont) {
  int16_t i, j, k, unit, gap, digit, bitsPerDigit, maxDigits, base;
  uint64_t orgnumber, number, sign;

//JM Pre-load X:
char str3[4];
j = 0;
str3[j] = displayString[j]; j++;
str3[j] = displayString[j]; j++;
str3[j] = displayString[j]; j++;
str3[j] = 0;

  base    = getRegisterTag(regist);
  number  = *(REGISTER_SHORT_INTEGER_DATA(regist));
  orgnumber = number;

  bool_t bcdFlag = false;   //JM BCDvv Base 17 is reserved for BCD
  if(base == 17) {
    base = 10;
    bcdFlag = true;
  }                         ////JMBCD ^^ Base 17 is reserved for BCD

  if(base <= 1 || base >= 17) {
    sprintf(errorMessage, commonBugScreenMessages[bugMsgValueFor], "shortIntegerToDisplayString", base, "base");
    displayBugScreen(errorMessage);
    base = 10;
  }

  //number &= shortIntegerMask;

  if(shortIntegerMode == SIM_UNSIGN || base == 2 || base == 4 || base == 8 || base == 16) {
    sign = 0;
  }
  else {
    sign = number & shortIntegerSignBit;
  }

  if(sign) {
    if(shortIntegerMode == SIM_2COMPL) {
      number |= ~shortIntegerMask;
      number = ~number + 1;
    }
    else if(shortIntegerMode == SIM_1COMPL) {
      number = ~number;
    }
    else if(shortIntegerMode == SIM_SIGNMT) {
      number &= ~shortIntegerSignBit;
    }
    else {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgValueFor], "shortIntegerToDisplayString", shortIntegerMode, "shortIntegerMode");
      displayBugScreen(errorMessage);
    }

    number &= shortIntegerMask;
  }

  i = ERROR_MESSAGE_LENGTH / 2;

  if(number == 0) {
    if(base == 10 && bcdFlag) {           //JM BCDvv
      char ss[5];
      if(bcdDisplaySign == BCD9c) {
        strcpy(displayString + i, "1001");
        strcpy(ss,STD_BASE_9);
      } else
      if(bcdDisplaySign == BCD10c) {
        strcpy(displayString + i, "0000");
        strcpy(ss,STD_SUB_o);
      }
      else {
        strcpy(displayString + i, "0000");
        strcpy(ss,STD_SUB_o);
      }
      i += 4;
      digit = 1;
      displayString[i++] = ss[1];
      displayString[i++] = ss[0];
    }
    else {                              //JM BCD^^
      displayString[i++] = '0';
      digit = 1;
    }
  }
  else {
    digit = 0;
  }

  if(GROUPLEFT_DISABLED) {
    gap = 0;
  }
  else {
    if(base == 2) {
      gap = 4;
    }
    else if(base == 4 || base == 16) { //JMGAP vv
      gap = 2;
    }
    else if(base == 8) {
      gap = 3;                         //  keeping base == 8 separate as opposed to just dropping it from base == 4 and base == 16  allows it to be changed back to 2 easily.
    }                                  //JMGAP ^^
    else if(base == 10 && bcdFlag) {   //JM BCD
      gap = 1;
    }
    else {
      gap = 3;
    }
  }

  uint8_t firstNonZero = 0;
  while(number) {
    if(gap != 0 && digit != 0 && digit%gap == 0) {
      displayString[i++] = ' ';
    }
    digit++;

    unit = number % base;
    number /= base;
    if(unit != 0) {firstNonZero++;}

    if(bcdFlag && base == 10) {                //JM BCDVV conversion - Note base 17 is code for BCD display od base 10
      if(bcdDisplaySign == BCD9c) {
        unit = 9 - unit;
      } else
      if(bcdDisplaySign == BCD10c) {           //see https://madformath.com/calculators/digital-systems/complement-calculators/10-s-complement-calculator-alternative/10-s-complement-calculator-alternative
        if(firstNonZero == 0) {
          unit = 0;
        } else
        if(firstNonZero == 1) {
          unit = 9 - unit + 1;
          firstNonZero++;
        }
        else {
          unit = 9 - unit;
          firstNonZero++;
        }
      }
      switch(unit){
        case 0:  displayString[i++] = '0'; displayString[i++] = '0'; displayString[i++] = '0'; displayString[i++] = '0'; break;
        case 1:  displayString[i++] = '1'; displayString[i++] = '0'; displayString[i++] = '0'; displayString[i++] = '0'; break;
        case 2:  displayString[i++] = '0'; displayString[i++] = '1'; displayString[i++] = '0'; displayString[i++] = '0'; break;
        case 3:  displayString[i++] = '1'; displayString[i++] = '1'; displayString[i++] = '0'; displayString[i++] = '0'; break;
        case 4:  displayString[i++] = '0'; displayString[i++] = '0'; displayString[i++] = '1'; displayString[i++] = '0'; break;
        case 5:  displayString[i++] = '1'; displayString[i++] = '0'; displayString[i++] = '1'; displayString[i++] = '0'; break;
        case 6:  displayString[i++] = '0'; displayString[i++] = '1'; displayString[i++] = '1'; displayString[i++] = '0'; break;
        case 7:  displayString[i++] = '1'; displayString[i++] = '1'; displayString[i++] = '1'; displayString[i++] = '0'; break;
        case 8:  displayString[i++] = '0'; displayString[i++] = '0'; displayString[i++] = '0'; displayString[i++] = '1'; break;
        case 9:  displayString[i++] = '1'; displayString[i++] = '0'; displayString[i++] = '0'; displayString[i++] = '1'; break;
        default: break;
      }
      if((orgnumber & 0x0FFFFFFFFFFFFFFF) <= 99999999999) {    //JM BCD add decimal to each BCD nibble
        char ss[5];
        if(unit == 0) {
          strcpy(ss,STD_SUB_o);
          displayString[i++] = ss[1];
          displayString[i++] = ss[0];
        }
        else {
          strcpy(ss,STD_BASE_1);
          displayString[i++] = ss[1] + unit - 1;
          displayString[i++] = ss[0];
        }
      }
    }
    else {                                   //JM BCD^^
      displayString[i++] = digits[unit];
    }                                          //JM

  }

  // Add leading zeros
  if(getSystemFlag(FLAG_LEAD0)) {
    if(base ==  2) {
      bitsPerDigit = 1;
    }
    else if(base ==  4) {
      bitsPerDigit = 2;
    }
    else if(base ==  8) {
      bitsPerDigit = 3;
    }
    else if(base == 16) {
      bitsPerDigit = 4;
    }
    else {
     bitsPerDigit = 0;
    }

    if(bitsPerDigit != 0) {
      maxDigits = shortIntegerWordSize / bitsPerDigit;
      if(shortIntegerWordSize % bitsPerDigit) {
        maxDigits++;
      }

      while(digit < maxDigits) {
        if(gap != 0 && digit%gap == 0) {
          displayString[i++] = ' ';
        }
        digit++;

        displayString[i++] = '0';
      }
    }
  }

  if(sign) {
    displayString[i++] = '-';
  }

//JM SHOW //ONLY ADD REGISTER NAME IF IT IS A LETTERED REGISTER - NO SPACE FOR MORE
if( str3[0] >= 'A' && str3[0] <= 'Z' && str3[1] == ':' && str3[2] == ' ' && str3[3] == 0 && !(base == 2 && orgnumber > 0x3FFF))
{
  displayString[i++] = str3[2];
  displayString[i++] = str3[1];
  displayString[i++] = str3[0];
}
if( str3[1] >= '0' && str3[1] <= '9' && str3[2] >= '0' && str3[2] <= '9' && str3[0] == 'R' && str3[3] == 0 && !(base == 2 && orgnumber > 0x3FFF))
{
  displayString[i++] = ':';
  displayString[i++] = str3[2];
  displayString[i++] = str3[1];
}

  if(determineFont) { // The font is not yet determined
    // 1st try: numeric font digits from 30 to 39
    fontForShortInteger = &numericFont;

    for(k=i-1, j=0; k>=ERROR_MESSAGE_LENGTH / 2; k--, j++) {
      if(displayString[k] == ' ') {
        displayString[j++] = STD_SPACE_PUNCTUATION[0];
        displayString[j]   = STD_SPACE_PUNCTUATION[1];
      }
      else {
        displayString[j] = displayString[k];
      }
    }
    displayString[j] = 0;

    if(bcdFlag && base == 10) {                              //JM BCD id display instead of base 10
      strcat(displayString, STD_SUB_b STD_SUB_c STD_SUB_d);
    }
    else {
      strcat(displayString, STD_BASE_2);
      displayString[strlen(displayString) - 1] += base - 2;
    }

    if(stringWidth(displayString, fontForShortInteger, false, false) < SCREEN_WIDTH) {
      return;
    }

    // 2nd try: numeric font digits from 2487 to 2490
    for(k=i-1, j=0; k>=ERROR_MESSAGE_LENGTH / 2; k--, j++) {
      if(displayString[k] == ' ') {
        displayString[j++] = STD_SPACE_PUNCTUATION[0];
        displayString[j]   = STD_SPACE_PUNCTUATION[1];
      }
      else if(0x30 <= displayString[k] && displayString[k] <= 0x39) {
        displayString[j++] = NUM_0_b[0];
        displayString[j]   = NUM_0_b[1] - '0' + displayString[k];
      }
      else {
        displayString[j] = displayString[k];
      }
    }
    displayString[j] = 0;

    if(bcdFlag && base == 10) {                             //JM BCD id display instead of base 10
      strcat(displayString, STD_SUB_b STD_SUB_c STD_SUB_d);
    }
    else {
      strcat(displayString, STD_BASE_2);
      displayString[strlen(displayString) - 1] += base - 2;
    }

    if(stringWidth(displayString, fontForShortInteger, false, false) < SCREEN_WIDTH) {
      return;
    }

    // 3rd try: standard font digits from 30 to 39
    fontForShortInteger = &standardFont;

    for(k=i-1, j=0; k>=ERROR_MESSAGE_LENGTH / 2; k--, j++) {
      if(displayString[k] == ' ') {
        displayString[j++] = STD_SPACE_PUNCTUATION[0];
        displayString[j]   = STD_SPACE_PUNCTUATION[1];
      }
      else {
       displayString[j] = displayString[k];
      }
    }
    displayString[j] = 0;

    if(bcdFlag && base == 10) {                             //JM BCD id display instead of base 10
      strcat(displayString, STD_SUB_b STD_SUB_c STD_SUB_d);
    }
    else {
      strcat(displayString, STD_BASE_2);
      displayString[strlen(displayString) - 1] += base - 2;
    }

    if(/*temporaryInformation == TI_SHOW_REGISTER_BIG ||*/ stringWidth(displayString, fontForShortInteger, false, false) < SCREEN_WIDTH) {     //JMSHOW
      return;
    }

    // 4th and last try: standard font digits 220e and 2064 (binary)
    for(k=i-1, j=0; k>=ERROR_MESSAGE_LENGTH / 2; k--, j++) {
      if(displayString[k] == ' ') {
        displayString[j++] = STD_SPACE_PUNCTUATION[0];
        displayString[j]   = STD_SPACE_PUNCTUATION[1];
      }
      else if(displayString[k] == '0') {
        displayString[j++] = STD_BINARY_ZERO[0];
        displayString[j]   = STD_BINARY_ZERO[1];
      }
      else if(displayString[k] == '1') {
        displayString[j++] = STD_BINARY_ONE[0];
        displayString[j]   = STD_BINARY_ONE[1];
      }
      else {
        displayString[j] = displayString[k];
      }
    }
    displayString[j] = 0;

    if(bcdFlag && base == 10) {                             //JM BCD id display instead of base 10
      strcat(displayString, STD_SUB_b STD_SUB_c STD_SUB_d);
    }
    else {
      strcat(displayString, STD_BASE_2);
      displayString[strlen(displayString) - 1] += base - 2;
    }

    if(stringWidth(displayString, fontForShortInteger, false, false) < SCREEN_WIDTH) {
      return;
    }

    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function shortIntegerToDisplayString: the integer data representation is too wide (1)!", displayString, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

    strcpy(displayString, "Integer data representation too wide!");
  }

  else { // the font is already determined (standard font)
    fontForShortInteger = &standardFont;

    // 1st try: standard font digits from 30 to 39
    for(k=i-1, j=0; k>=ERROR_MESSAGE_LENGTH / 2; k--, j++) {
      if(displayString[k] == ' ') {
        displayString[j++] = STD_SPACE_PUNCTUATION[0];
        displayString[j]   = STD_SPACE_PUNCTUATION[1];
      }
      else {
        displayString[j] = displayString[k];
      }
    }
    displayString[j] = 0;

    if(bcdFlag && base == 10) {                             //JM BCD id display instead of base 10
      strcat(displayString, STD_SUB_b STD_SUB_c STD_SUB_d);
    }
    else {
      strcat(displayString, STD_BASE_2);
      displayString[strlen(displayString) - 1] += base - 2;
    }

    if(stringWidth(displayString, fontForShortInteger, false, false) < SCREEN_WIDTH) {
      return;
    }

    // 2nd and last try: standard font digits 220e and 2064 (binary)
    for(k=i-1, j=0; k>=ERROR_MESSAGE_LENGTH / 2; k--, j++) {
      if(displayString[k] == ' ') {
        displayString[j++] = STD_SPACE_PUNCTUATION[0];
        displayString[j]   = STD_SPACE_PUNCTUATION[1];
      }
      else if(displayString[k] == '0') {
        displayString[j++] = STD_BINARY_ZERO[0];
        displayString[j]   = STD_BINARY_ZERO[1];
      }
      else if(displayString[k] == '1') {
        displayString[j++] = STD_BINARY_ONE[0];
        displayString[j]   = STD_BINARY_ONE[1];
      }
      else {
       displayString[j] = displayString[k];
      }
    }
    displayString[j] = 0;

    if(bcdFlag && base == 10) {                             //JM BCD id display instead of base 10
      strcat(displayString, STD_SUB_b STD_SUB_c STD_SUB_d);
    }
    else {
      strcat(displayString, STD_BASE_2);
      displayString[strlen(displayString) - 1] += base - 2;
    }

    if(stringWidth(displayString, fontForShortInteger, false, false) < SCREEN_WIDTH) {
      return;
    }

    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function shortIntegerToDisplayString: the integer data representation is too wide (2)!", displayString, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

    strcpy(displayString, "Integer data representation to wide!");
  }
}


void longIntegerRegisterToDisplayString(calcRegister_t regist, char *displayString, int32_t strLg, int16_t max_Width, int16_t maxExp, bool_t allowLARGELI) { //JM mod max_Width;   //JM added last parameter: Allow LARGELI
  int16_t exponentStep,exponentStep1;
  uint32_t exponentShift, exponentShiftLimit;
  longInteger_t lgInt;
  int16_t maxWidth;                                         //JM align longints

  convertLongIntegerRegisterToLongInteger(regist, lgInt);

  if(longIntegerIsNegative(lgInt)) {maxWidth = max_Width;}  //JM align longints
  else {maxWidth = max_Width - 8;}                          //JM align longints

  exponentShift = (longIntegerBits(lgInt) - 1) * 0.3010299956639811952137;
  exponentStep = (GROUPWIDTH_LEFT  == 0 || (SEPARATOR_LEFT[0]==1 && SEPARATOR_LEFT[1]==1) ? 1 : GROUPWIDTH_LEFT);   //TOCHECK
  exponentStep1= (                         (SEPARATOR_LEFT[0]==1 && SEPARATOR_LEFT[1]==1) ? 1 : GROUPWIDTH_LEFT1);  //TOCHECK

  exponentShift = (exponentShift / exponentStep  + 1) * exponentStep;
  exponentShiftLimit = ((maxExp-exponentStep1) / exponentStep + 1) * exponentStep;
  if(exponentShift > exponentShiftLimit) {
    exponentShift -= exponentShiftLimit;

    // Why do the following lines not work (for a big exponentShift) instead of the for loop below ?
    //longIntegerInitSizeInBits(divisor, longIntegerBits(lgInt));
    //longIntegerPowerUIntUInt(10u, exponentShift, divisor);
    //longIntegerDivide(lgInt, divisor, lgInt);
    //longIntegerFree(divisor);
    for(int32_t i=(int32_t)exponentShift; i>=1; i--) {
      if(i >= 9) {
        longIntegerDivideUInt(lgInt, 1000000000, lgInt); i -= 8;
      }
      else if(i >= 4) {
        longIntegerDivideUInt(lgInt,      10000, lgInt);
        i -= 3;
      }
      else {
        longIntegerDivideUInt(lgInt,         10, lgInt);
      }
    }
  }
  else {
    exponentShift = 0;
  }

  longIntegerToAllocatedString(lgInt, displayString, strLg);
  if(updateDisplayValueX) {
    strcpy(displayValueX, displayString);
  }

  longIntegerFree(lgInt);

  //IPGRP IPGRP1 IPGRP1x handling
  if(!GROUPLEFT_DISABLED && GROUPWIDTH_LEFT1 > 0) {
    //Handle IPGRP1, bearing in mind with a negative number, the digits start one deeper
    int16_t len = strlen(displayString);
    //printf("len %u %u %u %u\n",len, displayString[0], displayString[1], displayString[2]);
    int16_t digitOne = displayString[0] == '-' ? 1 : 0;
    int16_t Grp1 = ( (GROUPWIDTH_LEFT1X > 0)
                  && (displayString[digitOne] - 48 <= GROUPWIDTH_LEFT1X)
                  && (len - digitOne == GROUPWIDTH_LEFT1 + 1) ? GROUPWIDTH_LEFT1 + 1 : GROUPWIDTH_LEFT1);
    Grp1 = len >= (checkHP ? 10 : 20) ? GROUPWIDTH_LEFT : Grp1;
    int16_t i = len - Grp1;
    if(i > 0 && (i != 1 || displayString[0] != '-')) {
      if(SEPARATOR_LEFT[1]!=1) {
        xcopy(displayString + i + 2, displayString + i, len - i + 1);
        displayString[i] = SEPARATOR_LEFT[0];
        displayString[i + 1] = SEPARATOR_LEFT[1];
      } else if(SEPARATOR_LEFT[0]!=1){
        xcopy(displayString + i + 1, displayString + i, len - i + 1);
        displayString[i] = SEPARATOR_LEFT[0];
      }

      //Handle repeating IPGRP
      len = strlen(displayString);
      for(i=len - GROUPWIDTH_LEFT - (Grp1 + (SEPARATOR_LEFT[1] == 1 ? 1 : 2)); i>0; i-=GROUPWIDTH_LEFT) {
        if(i != 1 || displayString[0] != '-') {
          if(SEPARATOR_LEFT[1]!=1) {
            xcopy(displayString + i + 2, displayString + i, len - i + 1);
            displayString[i] = SEPARATOR_LEFT[0];
            displayString[i + 1] = SEPARATOR_LEFT[1];
            len += 2;
          } else if(SEPARATOR_LEFT[0]!=1) {
            xcopy(displayString + i + 1, displayString + i, len - i + 1);
            displayString[i] = SEPARATOR_LEFT[0];
            len += 1;
          }
        }
      }
    }
  }

  //for any exponent display, further manipulation of GRP is not needed
  if(stringWidth(displayString, allowLARGELI && jm_LARGELI ? &numericFont : &standardFont, false, false) > maxWidth) {      //JM
    char exponentString[14], lastRemovedDigit;
    int16_t lastChar, stringStep, tenExponent;

    stringStep = (GROUPLEFT_DISABLED ? 1 : GROUPWIDTH_LEFT + (SEPARATOR_LEFT[1] == 1 ? 1 : 2));
    tenExponent = exponentStep + exponentShift;
    lastChar = strlen(displayString) - stringStep;
    lastRemovedDigit = displayString[lastChar + (SEPARATOR_LEFT[1] == 1 ? 1 : 2)];
    displayString[lastChar] = 0;
    if(updateDisplayValueX) {
      displayValueX[strlen(displayValueX) - max(GROUPWIDTH_LEFT, 1)] = 0;
    }
    exponentString[0] = 0;
    exponentToDisplayString(tenExponent, exponentString, NULL, false);
    while(stringWidth(displayString,   allowLARGELI && jm_LARGELI ? &numericFont : &standardFont, false, true) + stringWidth(exponentString,   allowLARGELI && jm_LARGELI ? &numericFont : &standardFont, true, false) > maxWidth) {  //JM jm_LARGELI
      lastChar -= stringStep;
      tenExponent += exponentStep;
      lastRemovedDigit = displayString[lastChar + (SEPARATOR_LEFT[1] == 1 ? 1 : 2)];
      displayString[lastChar] = 0;
      if(updateDisplayValueX) {
        displayValueX[strlen(displayValueX) - max(GROUPWIDTH_LEFT, 1)] = 0;
      }
      exponentString[0] = 0;
      exponentToDisplayString(tenExponent, exponentString, NULL, false);
    }

    if(lastRemovedDigit >= '5') { // Round up
      lastChar = strlen(displayString) - 1;
      displayString[lastChar]++;
      while(displayString[lastChar] > '9') {
        displayString[lastChar--] = '0';
        while(lastChar >= 0 && (displayString[lastChar] < '0' || displayString[lastChar] > '9')) {
          lastChar--;
        }
        if(lastChar >= 0) {
          displayString[lastChar]++;
        }
        else { // We are rounding up from 9999... to 10000...
          lastChar = (displayString[0] == '-' ? 1 : 0);
          xcopy(displayString + lastChar + 1, displayString + lastChar, strlen(displayString) + 1);
          displayString[lastChar] = '1';
          if(SEPARATOR_LEFT[1]!=1) {
            if(!GROUPLEFT_DISABLED && displayString[lastChar + GROUPWIDTH_LEFT + 2] == SEPARATOR_LEFT[1]) { // We need to insert a new goup SEPARATOR_LEFT
              xcopy(displayString + lastChar + 3, displayString + lastChar + 1, strlen(displayString));
              displayString[lastChar + 1] = SEPARATOR_LEFT[0];
              displayString[lastChar + 2] = SEPARATOR_LEFT[1];
            }
          } else if(SEPARATOR_LEFT[0]!=1){
            if(!GROUPLEFT_DISABLED && displayString[lastChar + GROUPWIDTH_LEFT + 1] == SEPARATOR_LEFT[0]) { // We need to insert a new goup SEPARATOR_LEFT
              xcopy(displayString + lastChar + 2, displayString + lastChar + 1, strlen(displayString));
              displayString[lastChar + 1] = SEPARATOR_LEFT[0];
            }
          }

          // Has the string become too long?
          if(stringWidth(displayString,   allowLARGELI && jm_LARGELI ? &numericFont : &standardFont, false, true) + stringWidth(exponentString,   allowLARGELI && jm_LARGELI ? &numericFont : &standardFont, true, false) > maxWidth) {   //JM jm_LARGELI
            lastChar = strlen(displayString) - stringStep;
            tenExponent += exponentStep;
            displayString[lastChar] = 0;
            if(updateDisplayValueX) {
              displayValueX[strlen(displayValueX) - max(GROUPWIDTH_LEFT, 1)] = 0;
            }
            exponentString[0] = 0;
            exponentToDisplayString(tenExponent, exponentString, NULL, false);
          }
        }
      }

      if(updateDisplayValueX) {
        lastChar = strlen(displayValueX) - 1;
        displayValueX[lastChar]++;
        while(lastChar>0 && '0' <= displayValueX[lastChar - 1] && displayValueX[lastChar - 1] <= '9' && displayValueX[lastChar] > '9') {
          displayValueX[lastChar--] = '0';
          displayValueX[lastChar]++;
        }

        if(displayValueX[lastChar] > '9') { // We are rounding 9999... to 10000...
          xcopy(displayValueX + 1, displayValueX, strlen(displayValueX) + 1);
          displayValueX[lastChar++] = '1';
          displayValueX[lastChar] = '0';
        }
      }
    }

    strcat(displayString, exponentString);

    if(updateDisplayValueX) {
      sprintf(displayValueX + strlen(displayValueX), "e%d", tenExponent);
    }
  }
}


void longIntegerToAllocatedString(const longInteger_t lgInt, char *str, int32_t strLen) {
  int32_t numberOfDigits, stringLen, counter;
  longInteger_t x;

  str[0] = '0';
  str[1] = 0;
  if(lgInt->_mp_size == 0) {
    return;
  }

  //numberOfDigits = longIntegerBase10Digits(lgInt); // GMP documentation says the result can be 1 to big
  numberOfDigits = mpz_sizeinbase(lgInt, 10); // GMP documentation says the result can be 1 to big
  if(lgInt->_mp_size < 0) {
    stringLen = numberOfDigits + 2; // 1 for the trailing 0 and 1 for the minus sign
    str[0] = '-';
  }
  else {
    stringLen = numberOfDigits + 1; // 1 for the trailing 0
  }

  if(strLen < stringLen) {
    sprintf(errorMessage, "In function longIntegerToAllocatedString: the string str (%" PRId32 " bytes) is too small to hold the base 10 representation of lgInt, %" PRId32 " are needed!", strLen, stringLen);
    displayBugScreen(errorMessage);
    return;
  }

  str[stringLen - 1] = 0;

  //longIntegerInitSizeInBits(x, longIntegerBits(lgInt));
  mpz_init2(x, mpz_sizeinbase(lgInt, 2));

  //longIntegerAddUInt(lgInt, 0, x);
  mpz_add_ui(x, lgInt, 0);

  //longIntegerSetPositiveSign(x);
  x->_mp_size =  abs(x->_mp_size);


  stringLen -= 2; // set stringLen to the last digit of the base 10 representation
  counter = numberOfDigits;
  //while(!longIntegerIsZero(x)) {
  while(x->_mp_size != 0) {
    str[stringLen--] = '0' + mpz_tdiv_ui(x, 10);

    //longIntegerDivideUInt(x, 10, x);
    mpz_tdiv_q_ui(x, x, 10);

    counter--;
  }

  if(counter == 1) { // digit was 1 too big
    xcopy(str + stringLen, str + stringLen + 1, numberOfDigits);
  }

  //longIntegerFree(x);
  mpz_clear(x);
}


void dateToDisplayString(calcRegister_t regist, char *displayString) {
  real34_t j, y, yy, m, d;
  uint64_t yearval64;
  char sign[] = {0, 0};

  internalDateToJulianDay(REGISTER_REAL34_DATA(regist), &j);
  decomposeJulianDay(&j, &y, &m, &d);
  if(real34IsNegative(&y)) {
    sign[0] = '-';
  }
  real34CopyAbs(&y, &y);
  real34CopyAbs(&y, &yy);
  real34DivideRemainder(&y, const34_2p32, &y);
  real34Divide(&yy, const34_2p32, &yy);
  real34ToIntegralValue(&yy, &yy, DEC_ROUND_DOWN);
  yearval64 = (((uint64_t)real34ToUInt32(&yy) << 32) | ((uint64_t)real34ToUInt32(&y)));

  if(getSystemFlag(FLAG_DMY)) {
    sprintf(displayString, "%02" PRIu32 ".%02" PRIu32 ".%s%04" PRIu32, real34ToUInt32(&d), real34ToUInt32(&m), sign, (uint32_t)yearval64);
  }
  else if(getSystemFlag(FLAG_MDY)) {
    sprintf(displayString, "%02" PRIu32 "/%02" PRIu32 "/%s%04" PRIu32, real34ToUInt32(&m), real34ToUInt32(&d), sign, (uint32_t)yearval64);
  }
  else { // YMD
    sprintf(displayString, "%s%04" PRIu32 "-%02" PRIu32 "-%02" PRIu32, sign, (uint32_t)yearval64, real34ToUInt32(&m), real34ToUInt32(&d));
  }
}


void timeToDisplayString(calcRegister_t regist, char *displayString, bool_t ignoreTDisp) {
  real_t real, value, tmp, h, m, s;
  longInteger_t hli;
  int32_t sign, i;
  uint32_t digits, tDigits = 0u, bDigits, m32, s32;
  char digitBuf[16], digitBuf2[48];
  char* bufPtr;
  bool_t isValid12hTime = false, isAfternoon = false, overflow;
  uint8_t savedDisplayFormat = displayFormat, savedDisplayFormatDigits = displayFormatDigits;

  real34ToReal(REGISTER_REAL34_DATA(regist), &real);
  sign = realIsNegative(&real);

  // Short time (displayed like SCI/ENG)
  if(timeDisplayFormatDigits == 0) {
    realDivide(const_1, const_1000, &value, &ctxtReal39);
  }
  else if((timeDisplayFormatDigits == 1) || (timeDisplayFormatDigits == 2)) {
    realCopy(const_60, &value);
  }
  else {
    realCopy(const_1, &value);
    for(i = 3; i < timeDisplayFormatDigits; ++i) {
      --value.exponent;
      if(i == 5) {
        break;
      }
    }
  }
  if(realCompareAbsLessThan(&real, const_1)) {
    realCopy(const_1, &tmp), tmp.exponent -= 33;
    realDivideRemainder(&real, &tmp, &tmp, &ctxtReal39);
  }
  else {
    realZero(&tmp);
  }
  if(realCompareAbsLessThan(&real, &value) || (ignoreTDisp && (!realIsZero(&tmp)))) {
    if(ignoreTDisp || (timeDisplayFormatDigits == 0)) {
      displayFormat = DF_ALL;
      displayFormatDigits = 0;
    }
    else {
      displayFormat = getSystemFlag(FLAG_ALLENG) ? DF_ENG : DF_SCI;
      displayFormatDigits = 3;
    }
    real34ToDisplayString(REGISTER_REAL34_DATA(regist), amSecond, displayString, &standardFont, 2000, ignoreTDisp ? 34 : 16, false, false);
    displayFormatDigits = savedDisplayFormatDigits;
    displayFormat = savedDisplayFormat;
    return;
  }
  displayFormatDigits = savedDisplayFormatDigits;
  displayFormat = savedDisplayFormat;

  // Hours
  realDivide(&real, const_3600, &h, &ctxtReal39);
  realSetPositiveSign(&h);
  realToIntegralValue(&h, &h, DEC_ROUND_DOWN, &ctxtReal39);

  // Pre-rounding
  if(!ignoreTDisp) {
    switch(timeDisplayFormatDigits) {
      case 0: {
        int32ToReal(86400, &value);
        if((!sign) && (!getSystemFlag(FLAG_TDM24)) && realCompareLessThan(&real, &value)) {
          isValid12hTime = true;
        }
        for(bDigits = 0; bDigits < (isValid12hTime ? 14 : 16); ++bDigits) {
          if(realCompareAbsLessThan(&h, const_100)) {
            break;
          }
          ++value.exponent;
        }
        tDigits = isValid12hTime ? 13 : 15;
        isValid12hTime = false;
        goto do_rounding;
      }
      case 1:
      case 2: { // round to minutes
        realDivide(&real, const_60, &real, &ctxtReal39);
        realToIntegralValue(&real, &real, DEC_ROUND_DOWN, &ctxtReal39);
        realMultiply(&real, const_60, &real, &ctxtReal39);
        break;
      }
      default: { // round to seconds, milliseconds, microseconds, ...
        tDigits = timeDisplayFormatDigits + 1;
        bDigits = 4u;
      do_rounding:
        for(digits = bDigits; digits < tDigits; ++digits) {
          ++real.exponent;
        }
        realToIntegralValue(&real, &real, timeDisplayFormatDigits == 0 ? DEC_ROUND_HALF_UP : DEC_ROUND_DOWN, &ctxtReal39);
        for(digits = bDigits; digits < tDigits; ++digits) {
          --real.exponent;
        }
        tDigits = 0u;
      }
    }
  }
  realSetPositiveSign(&real);

  // Seconds
  realToIntegralValue(&real, &s, DEC_ROUND_DOWN, &ctxtReal39);
  realSubtract(&real, &s, &real, &ctxtReal39); // Fractional part
  // Minutes
  realDivide(&s, const_60, &m, &ctxtReal39);
  realToIntegralValue(&m, &m, DEC_ROUND_DOWN, &ctxtReal39);
  realDivideRemainder(&s, const_60, &s, &ctxtReal39);
  realDivideRemainder(&m, const_60, &m, &ctxtReal39);
  // 12-hour time
  if((!getSystemFlag(FLAG_TDM24)) && (!sign)) {
    int32ToReal(24, &value);
    if(realCompareLessThan(&h, &value)) {
      isValid12hTime = true;
      int32ToReal(12, &value);
      if(realCompareGreaterEqual(&h, &value)) {
        isAfternoon = true;
        if(!realCompareLessEqual(&h, &value)) {
          realSubtract(&h, &value, &h, &ctxtReal39);
        }
      }
      else if(realIsZero(&h)) {
        realAdd(&h, &value, &h, &ctxtReal39);
      }
    }
  }

  // Display Hours
  strcpy(displayString, sign ? "-" : " ");
  longIntegerInit(hli);
  convertRealToLongInteger(&h, hli, DEC_ROUND_DOWN);
  longIntegerToAllocatedString(hli, digitBuf2, sizeof(digitBuf2));
  longIntegerFree(hli);

  bufPtr = digitBuf2;
  digitBuf[1] = '\0';
  for(digits = strlen(digitBuf2); digits > 0; --digits){
    digitBuf[0] = *bufPtr++;
    strcat(displayString, digitBuf);
    if((digits % GROUPWIDTH_LEFT == 1) && (digits > 1)) {
      char tt[4]; tt[0]=0;
      if(SEPARATOR_LEFT[1]!=1) {
        strcpy(tt,SEPARATOR_LEFT);
      }
      else if(SEPARATOR_LEFT[0]!=1) {
        tt[0] = SEPARATOR_LEFT[0];
        tt[1] = 0;
      }
      strcat(displayString, tt);
    }
    ++tDigits;
  }

  if((!ignoreTDisp) && (timeDisplayFormatDigits == 1 || timeDisplayFormatDigits == 2 || (++tDigits) > (isValid12hTime ? 16 : 18))) {
    // Display Minutes
    realToUInt32(&m, DEC_ROUND_DOWN, &m32, &overflow);
    sprintf(digitBuf, ":%02" PRIu32, m32);
    strcat(displayString, digitBuf);
  }

  else {
    // Display MM:SS
    realToUInt32(&m, DEC_ROUND_DOWN, &m32, &overflow);
    realToUInt32(&s, DEC_ROUND_DOWN, &s32, &overflow);
    sprintf(digitBuf, ":%02" PRIu32 ":%02" PRIu32, m32, s32);
    strcat(displayString, digitBuf);

    // Display fractional part of seconds
    digits = 0u;
    realZero(&value);
    while(1) {
      realSubtract(&real, &value, &real, &ctxtReal39);
      if(ignoreTDisp || (timeDisplayFormatDigits == 0)) {
        if(realIsZero(&real)) {
          break;
        }
      }
      else {
        if(digits + 4 > timeDisplayFormatDigits) {
          break;
        }
      }
      if((!ignoreTDisp) && ((++tDigits) > (isValid12hTime ? 16 : 18))) {
        break;
      }
      realMultiply(&real, const_10, &real, &ctxtReal39);
      realToIntegralValue(&real, &value, DEC_ROUND_DOWN, &ctxtReal39);

      if(digits == 0u) {
        char tt[4];
        if(RADIX34_MARK_STRING[1]!=1) {strcpy(tt,RADIX34_MARK_STRING);}
        else {tt[0] = RADIX34_MARK_STRING[0]; tt[1] = 0;}
        strcat(displayString, tt);
      }
      else if(digits % GROUPWIDTH_RIGHT == 0u) {
        char tt[4]; tt[0]=0;
        if(SEPARATOR_RIGHT[1]!=1) {strcpy(tt,SEPARATOR_RIGHT);}
        else if(SEPARATOR_RIGHT[0]!=1) {tt[0] = SEPARATOR_RIGHT[0]; tt[1] = 0;}
        strcat(displayString, tt);
      }

      realToUInt32(&value, DEC_ROUND_DOWN, &s32, &overflow);
      sprintf(digitBuf, "%" PRIu32, s32);
      strcat(displayString, digitBuf);
      ++digits;
    }
  }

  // for 12-hour time
  if(isAfternoon) {
    strcat(displayString, "p.m.");
  }
  else if(isValid12hTime) {
    strcat(displayString, "a.m.");
  }
}


void real34MatrixToDisplayString(calcRegister_t regist, char *displayString) {
  dataBlock_t* dblock = REGISTER_REAL34_MATRIX_DBLOCK(regist);
  sprintf(displayString, "[%" PRIu16 STD_CROSS "%" PRIu16" Matrix]", dblock->matrixRows, dblock->matrixColumns);
}


void complex34MatrixToDisplayString(calcRegister_t regist, char *displayString) {
  dataBlock_t* dblock = REGISTER_REAL34_MATRIX_DBLOCK(regist);
  sprintf(displayString, "[%" PRIu16 STD_CROSS "%" PRIu16 " " STD_COMPLEX_C " Matrix]", dblock->matrixRows, dblock->matrixColumns);
}


static void _complex34ToShowTmpString(const real34_t *r, const real34_t *i) {
  int16_t last;
  real34_t real34;

  // Real part
  real34ToDisplayString(r, amNone, tmpString, &standardFont, 2000, 34, false, false);

  // +/- i×
  real34Copy(i, &real34);
  last = 300;
  while(tmpString[last]) {
    last++;
  }
  xcopy(tmpString + last++, (real34IsNegative(&real34) ? "-" : "+"), 1);
  xcopy(tmpString + last++, COMPLEX_UNIT, 2);
  xcopy(tmpString + last, PRODUCT_SIGN, 3);

  // Imaginary part
  real34SetPositiveSign(&real34);
  real34ToDisplayString(&real34, amNone, tmpString + 600, &standardFont, 2000, 34, false, false);

  if(stringWidth(tmpString + 300, &standardFont, true, true) + stringWidth(tmpString + 600, &standardFont, true, true) <= SCREEN_WIDTH) {
    last = 300;
    while(tmpString[last]) {
      last++;
    }
    xcopy(tmpString + last, tmpString + 600, strlen(tmpString + 600) + 1);
    tmpString[600] = 0;
  }

  if(stringWidth(tmpString, &standardFont, true, true) + stringWidth(tmpString + 300, &standardFont, true, true) <= SCREEN_WIDTH) {
    last = 0;
    while(tmpString[last]) {
      last++;
    }
    xcopy(tmpString + last, tmpString + 300, strlen(tmpString + 300) + 1);
    xcopy(tmpString + 300,  tmpString + 600, strlen(tmpString + 600) + 1);
    tmpString[600] = 0;
  }
}


void fnShow(uint16_t unusedButMandatoryParameter) {
  uint8_t savedDisplayFormat = displayFormat, savedDisplayFormatDigits = displayFormatDigits;
  int16_t source, dest, last, d, maxWidth, offset, bytesProcessed;
  bool_t thereIsANextLine;

  displayFormat = DF_ALL;
  displayFormatDigits = 0;

  tmpString[   0] = 0; // L1
  tmpString[ 300] = 0; // L2
  tmpString[ 600] = 0; // L3
  tmpString[ 900] = 0; // L4
  tmpString[1200] = 0; // L5
  tmpString[1500] = 0; // L6
  tmpString[1800] = 0; // L7

  temporaryInformation = TI_SHOW_REGISTER;

  switch(getRegisterDataType(REGISTER_X)) {
    case dtLongInteger: {
      longIntegerRegisterToDisplayString(REGISTER_X, errorMessage, WRITE_BUFFER_LEN, 3200, 400, false);//JM added last parameter: Allow LARGELI

      last = stringByteLength(errorMessage);
      source = 0;
      dest = 0;

      if(GROUPLEFT_DISABLED) {
        maxWidth = SCREEN_WIDTH - stringWidth("0", &standardFont, true, true);
      }
      else {
        char tt[4]; tt[0]=0;
        if(SEPARATOR_LEFT[1]!=1) {strcpy(tt,SEPARATOR_LEFT);}
        else if(SEPARATOR_LEFT[0]!=1){tt[0] = SEPARATOR_LEFT[0]; tt[1] = 0;}
        maxWidth = SCREEN_WIDTH - stringWidth("0", &standardFont, true, true)*GROUPWIDTH_LEFT - stringWidth(tt, &standardFont, true, true);
      }

      for(d=0; d<=1800 ; d+=300) {
        dest = d;
        while(source < last && stringWidth(tmpString + d, &standardFont, true, true) <= maxWidth) {
          do {
            tmpString[dest] = errorMessage[source];
            if(tmpString[dest] & 0x80) {
              tmpString[++dest] = errorMessage[++source];
            }
            source++;
            tmpString[++dest] = 0;
          } while(source < last && !GROUPLEFT_DISABLED && (errorMessage[source] != SEPARATOR_LEFT[0] || errorMessage[source + 1] != SEPARATOR_LEFT[1]));
        }
      }

      if(source < last) { // The long integer is too long
        xcopy(tmpString + dest - 2, STD_ELLIPSIS, 2);
        xcopy(tmpString + dest, STD_SPACE_6_PER_EM, 2);
        tmpString[dest + 2] = 0;
      }
      break;
    }

    case dtReal34: {
      real34ToDisplayString(REGISTER_REAL34_DATA(REGISTER_X), getRegisterAngularMode(REGISTER_X), tmpString, &standardFont, 2000, 34, false, false);
      break;
    }

    case dtComplex34: {
      _complex34ToShowTmpString(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_IMAG34_DATA(REGISTER_X));
      break;
    }

    case dtTime: {
      timeToDisplayString(REGISTER_X, tmpString, true);
      break;
    }

    case dtDate: {
      dateToDisplayString(REGISTER_X, tmpString);
      break;
    }

    case dtString: {
      char *remainingString;
      offset = 0;
      thereIsANextLine = true;
      bytesProcessed = 0;
      while(thereIsANextLine) {
        xcopy(tmpString + offset, REGISTER_STRING_DATA(REGISTER_X) + bytesProcessed, stringByteLength(REGISTER_STRING_DATA(REGISTER_X) + bytesProcessed) + 1);
        thereIsANextLine = false;
        remainingString = stringAfterPixels(tmpString + offset, &standardFont, SCREEN_WIDTH - 1, false, true);
        if(*remainingString != 0) {
          *remainingString = 0;
          thereIsANextLine = true;
        }
        bytesProcessed += stringByteLength(tmpString + offset);
        offset += 300;
        tmpString[offset] = 0;
      }
      break;
    }

    case dtConfig: {
      xcopy(tmpString, "Configuration data", 19);
      break;
    }

    default: {
      temporaryInformation = TI_NO_INFO;
      if(programRunStop == PGM_WAITING) {
        programRunStop = PGM_STOPPED;
      }
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "cannot SHOW %s", getRegisterDataTypeName(REGISTER_X, true, false));
        moreInfoOnError("In function fnShow:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }

  displayFormat = savedDisplayFormat;
  displayFormatDigits = savedDisplayFormatDigits;
}


void mimShowElement(void) {
  #if !defined(TESTSUITE_BUILD)
    uint8_t savedDisplayFormat = displayFormat, savedDisplayFormatDigits = displayFormatDigits;

    int16_t i = getIRegisterAsInt(true);
    int16_t j = getJRegisterAsInt(true);

    displayFormat = DF_ALL;
    displayFormatDigits = 0;

    tmpString[   0] = 0; // L1
    tmpString[ 300] = 0; // L2
    tmpString[ 600] = 0; // L3
    tmpString[ 900] = 0; // L4
    tmpString[1200] = 0; // L5
    tmpString[1500] = 0; // L6
    tmpString[1800] = 0; // L7

    temporaryInformation = TI_SHOW_REGISTER;

    if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
      real34ToDisplayString(&openMatrixMIMPointer.realMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j], amNone, tmpString, &standardFont, 2000, 34, false, false);
    }

    else {
      _complex34ToShowTmpString(VARIABLE_REAL34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j]),
                                VARIABLE_IMAG34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j]));
    }

    displayFormat = savedDisplayFormat;
    displayFormatDigits = savedDisplayFormatDigits;
  #endif
}


#if !defined(TESTSUITE_BUILD)

static void RegName(void) {    //JM using standard reg name, using SHOWregis, not using prefixWidth
  int16_t tmp;
  viewRegName2(tmpString + 2100, &tmp);
  //printf("|%s|%d|\n",tmpString + 2100, 2100+stringByteLength(tmpString + 2100));
}


static void SHOW_reset(void){
  uint8_t ix;

  for(ix=0; ix<=8; ix++) { //L1 ... L7
    tmpString[ix*300]=0;
  }

  temporaryInformation = TI_SHOW_REGISTER_SMALL;
  RegName();
}


static void checkAndEat(int16_t *source, int16_t last, int16_t *dest) {
  uint8_t ix;
  if(*source < last && !GROUPLEFT_DISABLED) {                  //Not in the last line
    for(ix=0; ix<=3; ix++) {
      if(!(tmpString[(*dest)-2] & 0x80)) {(*dest)--; (*source)--;} //Eat away characters at the end to line up the last space
    }
    tmpString[*dest] = 0;
  }
}


static void printXAngle(int16_t cc, int16_t d) {
  real34_t real34;
  int16_t ww, last, source, dest;
  real34Copy(REGISTER_REAL34_DATA(showRegis), &real34);
  convertAngle34FromTo(&real34, getRegisterAngularMode(showRegis), cc);
  RegName();
  ww = stringWidth(tmpString + 2100, &numericFont, true, true);
  real34ToDisplayString(&real34, cc, tmpString + 2100 + stringByteLength(tmpString + 2100), &numericFont, SCREEN_WIDTH - ww - 8*2, 34, false, false);
  last = 2100 + stringByteLength(tmpString + 2100);
  source = 2100;
  dest = d;
  while(source < last && stringWidth(tmpString + d, &numericFont, true, true) <= SCREEN_WIDTH - 8*2) {
    tmpString[dest] = tmpString[source];
    if(tmpString[dest] & 0x80) {
      tmpString[++dest] = tmpString[++source];
    }
    source++;
    tmpString[++dest] = 0;
  }
}


static void dispM(uint16_t regist, char * prefix) {
  uint32_t prefixWidth = 0;
  const int16_t baseY = 20;
  bool_t prefixPre = false;
  bool_t prefixPost = false;
  prefixWidth = stringWidth(prefix, &standardFont, true, true);
  temporaryInformation = TI_SHOWNOTHING;
  if(getRegisterDataType(regist) == dtReal34Matrix) {
    real34Matrix_t matrix;
    linkToRealMatrixRegister(regist, &matrix);
    showRealMatrix(&matrix, prefixWidth);
    //printf("#### tmpString=%s prefix=%s prefixWidth=%u lastErrorCode=%u temporaryInformation=%u\n",tmpString,prefix,prefixWidth,lastErrorCode, temporaryInformation);
    if(lastErrorCode != 0) {
      refreshRegisterLine(errorMessageRegisterLine);
    }
    if(prefixWidth > 0) {
      showString(prefix, &standardFont, 1, baseY, vmNormal, prefixPre, prefixPost);
    }
    if(temporaryInformation == TI_INACCURATE && regist == REGISTER_X) {
      showString("This result may be inaccurate", &standardFont, 1, Y_POSITION_OF_ERR_LINE, vmNormal, true, true);
    }
  }
  else if(getRegisterDataType(regist) == dtComplex34Matrix) {
    complex34Matrix_t matrix;
    linkToComplexMatrixRegister(regist, &matrix);
    showComplexMatrix(&matrix, prefixWidth);
    //printf("#### tmpString=%s prefix=%s prefixWidth=%u lastErrorCode=%u temporaryInformation=%u\n",tmpString,prefix,prefixWidth,lastErrorCode, temporaryInformation);
    if(lastErrorCode != 0) {
      refreshRegisterLine(errorMessageRegisterLine);
    }
    if(prefixWidth > 0) {
      showString(prefix, &standardFont, 1, baseY, vmNormal, prefixPre, prefixPost);
    }
    if(temporaryInformation == TI_INACCURATE && regist == REGISTER_X) {
      showString("This result may be inaccurate", &standardFont, 1, Y_POSITION_OF_ERR_LINE, vmNormal, true, true);
    }
  }
}
#endif //TESTSUITE_BUILD


void fnShow_SCROLL(uint16_t fnShow_param) {                // Heavily modified by JM from the original fnShow
#if !defined(SAVE_SPACE_DM42_9)
  #if !defined(TESTSUITE_BUILD)
    uint8_t savedDisplayFormat = displayFormat, savedDisplayFormatDigits = displayFormatDigits;
    bool_t thereIsANextLine;
    int16_t source, dest, last, d, maxWidth, i, offset, bytesProcessed, aa, bb, cc, dd, aa2=0, aa3=0, aa4=0;
    uint64_t nn;

    displayFormat = DF_ALL;
    displayFormatDigits = 0;

    switch(fnShow_param) {
      case NOPARAM:
               showSoftmenu(-MNU_SHOW);
               showRegis = REGISTER_X;
               break;
      case 0:  showRegis = REGISTER_X;
               break;
      case 1:  if(showRegis==9999) {showRegis = REGISTER_X;}                       //Activated by KEY_UP
               else
               {
                 if(showRegis >= FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1) {
                   showRegis = 0;
                 } else 
                 if(showRegis == REGISTER_K) {
                   showRegis = FIRST_NAMED_VARIABLE;
                 } else {
                   showRegis++;
                 }
                 while(!regInRange(showRegis) && showRegis < FIRST_NAMED_VARIABLE + numberOfNamedVariables) {
                   showRegis++;
                 }
               }
               #if defined(PC_BUILD) && defined(MONITOR_CLRSCR)
                 printf("R=%u TI=%u\n",showRegis, temporaryInformation);
               #endif // PC_BUILD && MONITOR_CLRSCR
               break;
      case 2:  if(showRegis==9999) {showRegis = REGISTER_X;}                       //Activate by Key_DOWN
               else
               {
                 if(showRegis == 0) {
                   showRegis = FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1;
                 } else
                 if(showRegis == FIRST_NAMED_VARIABLE) {
                   showRegis = REGISTER_K;
                 } else {
                   showRegis--;
                 }
                 while(!regInRange(showRegis) && showRegis != 0) {
                   showRegis--;
                 }
               }
               #if defined(PC_BUILD) && defined(MONITOR_CLRSCR)
                 printf("R=%u TI=%u\n",showRegis, temporaryInformation);
               #endif // PC_BUILD && MONITOR_CLRSCR
               break;
      case 255:                                       //Allow fnView to enter a value into Show without changing the register number
               break;
      default:
        break;
    }


    #if !defined(TESTSUITE_BUILD)
      #if defined(PC_BUILD) && defined(MONITOR_CLRSCR)
        printf(">>> ---- clearScreenOld from display.c fnShow_SCROLL\n");
      #endif // PC_BUILD && MONITOR_CLRSCR
        //      clearScreenOld(!clrStatusBar, clrRegisterLines, !clrSoftkeys); //Clear screen content while NEW SHOW
        refreshScreen(153);

    #endif // !TESTSUITE_BUILD
    SHOW_reset();

    switch(getRegisterDataType(showRegis)) {
      case dtLongInteger:

        #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
          printf("SHOW:Longint\n");
        #endif // VERBOSE_SCREEN && PC_BUILD

        strcpy(errorMessage,tmpString + 2100);
        longIntegerRegisterToDisplayString(showRegis, errorMessage + stringByteLength(tmpString + 2100), WRITE_BUFFER_LEN, 9*400, 9*50-3, false);  //JM added last parameter: Allow LARGELI

        last = stringByteLength(errorMessage);
        source = 0;
        dest = 0;


        //LARGE font
        { //printf("2: %d\n",stringGlyphLength(tmpString + 2100));
          temporaryInformation = TI_SHOW_REGISTER_BIG;
          if(GROUPLEFT_DISABLED) {
            maxWidth = SCREEN_WIDTH - stringWidth("00", &numericFont, true, true);
          }
          else {              //not 0x0101:
            char tmp[4];
            strcpy(tmp, "0");
            char tt[4];
            if(SEPARATOR_LEFT[1] != 1) {
              strcpy(tt,SEPARATOR_LEFT);
            }
            else {
              tt[0] = SEPARATOR_LEFT[0];
              tt[1] = 0;
            }
            strcat(tmp,tt);
            maxWidth = SCREEN_WIDTH - stringWidth(tmp , &numericFont, true, true);          //Add the separator that gets added to the last character
          }

          //LARGE font, fill 6 lines at 0, 300, 600, 900, 1200, 1500
          #define maxLarge 1800
          for(d=0; d<=maxLarge ; d+=300) {
            //printf("LARGE>>> source:%u|%s|d:%u|%s|\n",source,errorMessage+source,d,tmpString+d);
            dest = d;
            while(source < last && stringWidth(tmpString + d, &numericFont, true, true) <=  maxWidth) {
              tmpString[dest] = errorMessage[source];
              if(tmpString[dest] & 0x80) {
                tmpString[++dest] = errorMessage[++source];
              }
              source++;
              tmpString[++dest] = 0;
            }

            uint8_t cnt = GROUPWIDTH_LEFT+1;
            while(cnt-- != 0 && source < last && !GROUPLEFT_DISABLED ) { //Eat away characters at the end to line, up to and excluding the last seperator.
              if(  !((SEPARATOR_LEFT[1] != 1 && tmpString[dest-2] == SEPARATOR_LEFT[0] && tmpString[dest-1] == SEPARATOR_LEFT[1]) || 
                     (SEPARATOR_LEFT[1] == 1 && tmpString[dest-1] == SEPARATOR_LEFT[0])) ) {
                dest--;  //line does not end on separator, so reduce the characters until is does
                source--;
              } else {
                dest--; //line ends on a seperator so reduce only the target and let the next line begins onthe number, not separator
                if(SEPARATOR_LEFT[1] != 1) dest--; //line ends on a double byte seperator
                break;
              }
            }

            tmpString[dest] = 0;
            //printf(">>>AA %u %u |%s|\n", d, (uint8_t)tmpString[d], tmpString+d);
          }
        }



        if(tmpString[maxLarge] != 0) {    //overflow
          #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
            printf("SHOW:Longint too long\n");
          #endif // VERBOSE_SCREEN && PC_BUILD

          SHOW_reset();
          strcpy(errorMessage,tmpString + 2100);
          longIntegerRegisterToDisplayString(showRegis, errorMessage + stringByteLength(tmpString + 2100), WRITE_BUFFER_LEN, 9*400, 9*50-3, false);  //JM added last parameter: Allow LARGELI
          //printf("1: %d\n",stringGlyphLength(tmpString + 2100));
          tmpString[2100] = 0;

          last = stringByteLength(errorMessage);
          source = 0;
          dest = 0;

          //Small font start
          if(GROUPLEFT_DISABLED) {
            maxWidth = SCREEN_WIDTH - stringWidth("0", &standardFont, true, true);
          }
          else {
            char tt[4];
            if(SEPARATOR_LEFT[1]!=1) {
              strcpy(tt,SEPARATOR_LEFT);
            }
            else if(SEPARATOR_LEFT[0] != 1) {
              tt[0] = SEPARATOR_LEFT[0];
              tt[1] = 0;
            }
            maxWidth = SCREEN_WIDTH - stringWidth("0", &standardFont, true, true)*GROUPWIDTH_LEFT - stringWidth(tt, &standardFont, true, true);
          }

          //SMALL font, fill 7 lines at 0, 300, 600, 900, 1200, 1500, 1800
          for(d=0; d<=2400 ; d+=300) {
            //printf("SMALL>>> source:%u|%s|d:%u|%s|\n",source,errorMessage+source,d,tmpString+d);
            dest = d;
            while(source < last && stringWidth(tmpString + d, &standardFont, true, true) <=  maxWidth) {
              tmpString[dest] = errorMessage[source];
              if(tmpString[dest] & 0x80) {
                tmpString[++dest] = errorMessage[++source];
              }
              source++;
              tmpString[++dest] = 0;
            }

            uint8_t cnt = GROUPWIDTH_LEFT+1;
            while(cnt-- != 0 && source < last && !GROUPLEFT_DISABLED ) { //Eat away characters at the end to line, up to and excluding the last seperator.
              if(  !((SEPARATOR_LEFT[1] != 1 && tmpString[dest-2] == SEPARATOR_LEFT[0] && tmpString[dest-1] == SEPARATOR_LEFT[1]) || 
                     (SEPARATOR_LEFT[1] == 1 && tmpString[dest-1] == SEPARATOR_LEFT[0])) ) {
                dest--;  //line does not end on separator, so reduce the characters until is does
                source--;
              } else {
                dest--; //line ends on a seperator so reduce only the target and let the next line begins onthe number, not separator
                if(SEPARATOR_LEFT[1] != 1) dest--; //line ends on a double byte seperator
                break;
              }
            }
            tmpString[dest] = 0;
            //printf(">>>AA %u %u |%s|\n", d, (uint8_t)tmpString[d], tmpString+d);
          }


          if(source < last) { // The long integer is too long
            xcopy(tmpString + dest - 2, STD_ELLIPSIS, 2);
            xcopy(tmpString + dest, STD_SPACE_6_PER_EM, 2);
            tmpString[dest + 2] = 0;
          }
        }
        break;

      case dtReal34:
        #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
          printf("SHOW:Real\n");
        #endif // VERBOSE_SCREEN && PC_BUILD
        temporaryInformation = TI_SHOW_REGISTER_BIG;
        int16_t angleM = getRegisterAngularMode(showRegis);
        if(angleM == amDMS) angleM = amDegree;
        real34ToDisplayString(REGISTER_REAL34_DATA(showRegis), angleM, tmpString + 2100+stringByteLength(tmpString + 2100), &numericFont, SCREEN_WIDTH * 2, 34, false, false);
        last = 2100 + stringByteLength(tmpString + 2100);
        source = 2100;
        for(d=0; d<=900 ; d+=300) {
          dest = d;
          while(source < last && stringWidth(tmpString + d, &numericFont, true, true) <= SCREEN_WIDTH - 8*2-5) {
            //check if a full triplet of digits will fit otherwise break line
            if((tmpString[source] == SEPARATOR_LEFT[0] && (SEPARATOR_LEFT[1]==1 ? true : tmpString[source + 1] == SEPARATOR_LEFT[1])     ) ||
               (tmpString[source] == SEPARATOR_RIGHT[0] && (SEPARATOR_RIGHT[1]==1 ? true : tmpString[source + 1] == SEPARATOR_RIGHT[1]) )) {
              aa = source;
              if(tmpString[aa] & 0x80) aa += 2;
              if(tmpString[aa] & 0x80) aa += 2;
              if(tmpString[aa] & 0x80) aa += 2;
              if(tmpString[aa] & 0x80) aa += 2;
              char tmpString20[20];
              tmpString20[0]=0;
              xcopy(tmpString20, tmpString + source, aa - source);
              tmpString20[aa - source]=0;
              if(stringWidth(tmpString + d, &numericFont, true, true) + stringWidth(tmpString20, &numericFont, true, true) > SCREEN_WIDTH - 8*2-5) break;
            }

            tmpString[dest] = tmpString[source];
            if(tmpString[dest] & 0x80) {
              tmpString[++dest] = tmpString[++source];
            }
            source++;
            tmpString[++dest] = 0;
          }
        }

        if(getRegisterAngularMode(showRegis) != amNone) {
          aa = 0;
          bb = 0;
          cc = 0;
          dd = 0;
          switch(getRegisterAngularMode(showRegis)) {
            case amDegree: aa = amDMS;    bb = amRadian; cc = amMultPi; dd = amGrad;   break;
            case amRadian: aa = amMultPi; bb = amDegree; cc = amDMS;    dd = amGrad;   break;
            case amGrad:   aa = amDegree; bb = amDMS;    cc = amRadian; dd = amMultPi; break;
            case amMultPi: aa = amRadian; bb = amDegree; cc = amDMS;    dd = amGrad;   break;
            case amDMS:    aa = amDMS;    bb = amRadian; cc = amMultPi; dd = amGrad;   break;  //note amDMS displays the same way as amDegree, to show all 34 digits in the top line
            default: ;
          }

          printXAngle(aa, 600);
          printXAngle(bb, 900);
          printXAngle(cc,1200);
          printXAngle(dd,1500);
        }
        break;

      case dtComplex34:
        #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
          printf("SHOW:Complex\n");
        #endif // VERBOSE_SCREEN && PC_BUILD
        temporaryInformation = TI_SHOW_REGISTER_BIG;

        complex34ToDisplayString(REGISTER_COMPLEX34_DATA(showRegis), tmpString, &numericFont,2000, 34 ,true, true, getComplexRegisterAngularMode(showRegis), getComplexRegisterPolarMode(showRegis));
        for(i=stringByteLength(tmpString) - 1; i>0; i--) {
          if(tmpString[i] == 0x08) {
            tmpString[i] = 0x05;
          }
        }


        //copy result into destination 2100 (label already in 2100-2102)
        last = 2100;
        while(tmpString[last]) last++;
        xcopy(tmpString + last, tmpString + 0,  strlen(tmpString + 0) + 1);
        tmpString[0] = 0;

        //write 2100+ into four lines, 0+ to 900+
        last = 2100 + stringByteLength(tmpString + 2100);
        source = 2100;
        for(d=0; d<=900 ; d+=300) {
          dest = d;
          while(source < last && stringWidth(tmpString + d, &numericFont, true, true) <= SCREEN_WIDTH - 8*2-5) {
            tmpString[dest] = tmpString[source];
            if(tmpString[dest] & 0x80) {
              tmpString[++dest] = tmpString[++source];
            }
            source++;
            tmpString[++dest] = 0;

            if(stringWidth(tmpString + d, &numericFont, true, true) >= SCREEN_WIDTH -60 && (uint8_t)tmpString[source-2] == 160 && tmpString[source-1]==5) break;
            if(d>0 &&
              (    ( !getComplexRegisterPolarMode(showRegis) && (tmpString[source]=='+' || tmpString[source]=='-')) ||
                   ( (uint8_t)tmpString[source]==162)
              ) ) {
              break;
            }
          }
        }

        //if(tmpString[300]==0) {                          //shift up if line is empty
        //  //vv new       strcpy(tmpString + 300, tmpString + 600);
        //  xcopy(tmpString + 300, tmpString + 600,  min(300,strlen(tmpString + 600) + 1));
        //  //vv new        strcpy(tmpString + 600, tmpString + 900);
        //  xcopy(tmpString + 600, tmpString + 900,  min(300,strlen(tmpString + 900) + 1));
        //  tmpString[900] = 0;
        //}

        //if(tmpString[600]==0) {                          //shift up if line is empty
        //  //vv new        strcpy(tmpString + 600, tmpString + 900);
        //  xcopy(tmpString + 600, tmpString + 900,  min(300,strlen(tmpString + 900) + 1));
        //  tmpString[900] = 0;
        //}

        break;

      case dtShortInteger:
        #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
          printf("SHOW:Shortint\n");
        #endif // VERBOSE_SCREEN && PC_BUILD
        temporaryInformation = TI_SHOW_REGISTER_BIG;

        shortIntegerToDisplayString(showRegis, tmpString + 2100, true); //jm include X:
  /*
        if(getRegisterTag(SHOWregis) == 2) {
          source = 2100;
          dest = 2400;
          while(tmpString[source] !=0 ) {
            if((uint8_t)(tmpString[source]) == 160 && (uint8_t)(tmpString[source+1]) == 39) {
              source++;
              tmpString[dest++]=49;
            } else
              if((uint8_t)(tmpString[source]) == 162 && (uint8_t)(tmpString[source+1]) == 14) {
                source++;
                tmpString[dest++]=48;
              }
              else {
                tmpString[dest++] = tmpString[source];
              }
            source++;
          }
          tmpString[dest]=0;
        }
  */
  //      else {
          strcpy(tmpString + 2400,tmpString + 2100);
  //      }

        last = 2400 + stringByteLength(tmpString + 2400);
        source = 2400;
        tmpString[0]=0;
        for(d=0; d<=900 ; d+=300) {
          dest = d;
          if(dest != 0){strcat(tmpString + dest,"  ");dest+=2;}               //space below the T:
          while(source < last) {
            tmpString[dest] = tmpString[source];
            if(tmpString[dest] & 0x80) {
              tmpString[++dest] = tmpString[++source];
            }
            source++;
            tmpString[++dest] = 0;
          }
          checkAndEat(&source, last, &dest);
        }

        convertShortIntegerRegisterToUInt64(showRegis, &aa, &nn);
        aa = getRegisterTag(showRegis);

        switch(aa) {
          case  2: aa2=10;  aa3= 8;  aa4=16; break;   //Keeping the 2 8 16 sequence where possible
          case  4: aa2= 2;  aa3= 8;  aa4=16; break;   //Keeping the 2 8 16 sequence where possible
          case  8: aa2= 2;  aa3=10;  aa4=16; break;   //Keeping the 2 8 16 sequence where possible
          case 10: aa2= 2;  aa3= 8;  aa4=16; break;   //Keeping the 2 8 16 sequence where possible
          case 16: aa2= 2;  aa3= 8;  aa4=10; break;   //Keeping the 2 8 16 sequence where possible

          case  3:
          case  5:
          case  6:
          case  7:
          case  9:
          case 11:
          case 12:
          case 13:
          case 14:
          case 15: aa2=10;  aa3= 8;  aa4=16; break;
        }

        if(aa2){
          setRegisterTag(showRegis,aa2);
          RegName();
          shortIntegerToDisplayString(showRegis, tmpString + 2100, true);
          strcpy(tmpString + 2400,tmpString + 2100);
          last = 2400 + stringByteLength(tmpString + 2400);
          source = 2400;
          tmpString[300]=0;
          for(d=300; d<=900 ; d+=300) {
            dest = d;
            if(dest != 300){strcat(tmpString + dest,"  ");dest+=2;}               //space below the T:
            while(source < last) {
              tmpString[dest] = tmpString[source];
              if(tmpString[dest] & 0x80) {
                tmpString[++dest] = tmpString[++source];
              }
              source++;
              tmpString[++dest] = 0;
            }
            checkAndEat(&source, last, &dest);
          }
        }
        if(aa3){
          RegName();
          setRegisterTag(showRegis,aa3);
          shortIntegerToDisplayString(showRegis, tmpString + 2100, true);
          strcpy(tmpString + 2400,tmpString + 2100);
          last = 2400 + stringByteLength(tmpString + 2400);
          source = 2400;
          tmpString[600]=0;
          for(d=600; d<=900 ; d+=300) {
            dest = d;
            if(dest != 600){strcat(tmpString + dest,"  ");dest+=2;}               //space below the T:
            while(source < last) {
              tmpString[dest] = tmpString[source];
              if(tmpString[dest] & 0x80) {
                tmpString[++dest] = tmpString[++source];
              }
              source++;
              tmpString[++dest] = 0;
            }
            checkAndEat(&source, last, &dest);
          }
        }
        if(aa4){
          RegName();
          setRegisterTag(showRegis,aa4);
          shortIntegerToDisplayString(showRegis, tmpString + 2100, true);
          strcpy(tmpString + 2400,tmpString + 2100);
          last = 2400 + stringByteLength(tmpString + 2400);
          source = 2400;
          tmpString[900]=0;
          for(d=900; d<=900 ; d+=300) {
            dest = d;
            if(dest != 900){strcat(tmpString + dest,"  ");dest+=2;}               //space below the T:
            while(source < last) {
              tmpString[dest] = tmpString[source];
              if(tmpString[dest] & 0x80) {
                tmpString[++dest] = tmpString[++source];
              }
              source++;
              tmpString[++dest] = 0;
            }
            checkAndEat(&source, last, &dest);
          }
        }
        setRegisterTag(showRegis,aa);
        break;

      case dtTime:
        //SHOW_reset();
        strcpy(tmpString, tmpString + 2100);
        temporaryInformation = TI_SHOW_REGISTER_BIG;
        timeToDisplayString(showRegis, tmpString + stringByteLength(tmpString + 2100), true);
        break;

      case dtDate:
        //SHOW_reset();
        strcpy(tmpString, tmpString + 2100);
        temporaryInformation = TI_SHOW_REGISTER_BIG;
        dateToDisplayString(showRegis, tmpString + stringByteLength(tmpString + 2100));
        break;


      case dtString:
        #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
          printf("SHOW:String\n");
        #endif // VERBOSE_SCREEN && PC_BUILD

        SHOW_reset();
        temporaryInformation = TI_SHOW_REGISTER_BIG; //First try one line of big font.
        offset = 0;
        thereIsANextLine = true;
        bytesProcessed = 2100;
        strcat(tmpString + 2100, "'");
        strcat(tmpString + 2100, REGISTER_STRING_DATA(showRegis));//, stringByteLength(REGISTER_STRING_DATA(showRegis)) + 4+1);
        strcat(tmpString + 2100, "'");
        #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
          uint32_t tmp = 0;
          printf("^^^0 %4u", tmp);
          printf("^^^^$$ %s %d\n", tmpString + 2100, stringWidthC43(tmpString + 2100, stdnumEnlarge, nocompress, false, true));
        #endif // VERBOSE_SCREEN && PC_BUILD
        while(thereIsANextLine) {
          char *strw;
          xcopy(tmpString + offset, tmpString + bytesProcessed, stringByteLength(tmpString + bytesProcessed) + 1);
          thereIsANextLine = false;
          strw = stringAfterPixelsC43(tmpString + offset, stdnumEnlarge, nocompress, SCREEN_WIDTH - 1, false, true);
          if(*strw != 0) {
            *strw = 0;
            thereIsANextLine = true;
            #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
              printf("^^^A %4u",tmp++);
              printf("^^^^$$ %s %d\n",tmpString + offset,stringWidthC43(tmpString + offset, stdnumEnlarge, nocompress, false, true));
            #endif // VERBOSE_SCREEN && PC_BUILD
          }
          bytesProcessed += stringByteLength(tmpString + offset);
          offset += 300;
          tmpString[offset] = 0;
        }
        if(offset <= 1200) break; //else continue on the small font


        SHOW_reset();
        temporaryInformation = TI_SHOW_REGISTER_SMALL;
        offset = 0;
        thereIsANextLine = true;
        bytesProcessed = 2100;
        strcat(tmpString + 2100, "'");
        strcat(tmpString + 2100, REGISTER_STRING_DATA(showRegis));//, stringByteLength(REGISTER_STRING_DATA(showRegis)) + 4+1);
        strcat(tmpString + 2100, "'");
        #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
          uint32_t tmp2 = 0;
        #endif // VERBOSE_SCREEN && PC_BUILD
        while(thereIsANextLine) {
          char *remainingString;
          xcopy(tmpString + offset, tmpString + bytesProcessed, stringByteLength(tmpString + bytesProcessed) + 1);
          thereIsANextLine = false;
          #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
            tmp =0;
          #endif // VERBOSE_SCREEN && PC_BUILD
          remainingString = stringAfterPixels(tmpString + offset, &standardFont, SCREEN_WIDTH, false, true);
          if(*remainingString != 0) {
            *remainingString = 0;
            thereIsANextLine = true;
            #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
              printf("^^^B %4u %4u",tmp2, tmp++);
              printf("^^^^$$ %s %d\n",tmpString + offset,stringWidth(tmpString + offset, &standardFont, false, true));
            #endif // VERBOSE_SCREEN && PC_BUILD
          }
          #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
            tmp2++;
          #endif // VERBOSE_SCREEN && PC_BUILD
          bytesProcessed += stringByteLength(tmpString + offset);
          offset += 300;
          tmpString[offset] = 0;
        }
        break;


      case dtConfig:
        temporaryInformation = TI_SHOW_REGISTER_BIG;
        xcopy(tmpString, "Configuration data", 19);
        break;

      case dtReal34Matrix:
      case dtComplex34Matrix:
        clearScreenOld(!clrStatusBar, clrRegisterLines, clrSoftkeys);
        dispM(showRegis, tmpString + 2100);                   //then display the matrix
        lcd_fill_rect(0, Y_POSITION_OF_REGISTER_T_LINE-4, SCREEN_WIDTH, 1, LCD_EMPTY_VALUE);
        temporaryInformation = TI_SHOWNOTHING;                //then tell the system it is in show nothing mode,
        if(programRunStop == PGM_RUNNING) {   //this needs to be checked - maybe needed for all show items not only here
          refreshScreen(150);
          fnPause(10);
          temporaryInformation = TI_NO_INFO;
        }
        break;


      default:
        temporaryInformation = TI_NO_INFO;
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, showRegis);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "cannot SHOW %s%s", tmpString + 2100, getRegisterDataTypeName(showRegis, true, false));
          moreInfoOnError("In function fnShow:", errorMessage, NULL, NULL);
        #endif
        return;
    }


    displayFormat = savedDisplayFormat;
    displayFormatDigits = savedDisplayFormatDigits;
    #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
      printf("SHOW:Done |%s|\n",tmpString);
    #endif

  #endif // !TESTSUITE_BUILD
#else
      fnShow(0);
#endif // !SAVE_SPACE_DM42_9
}

void fnView(uint16_t regist) {
  if(regInRange(regist)) {
    currentViewRegister = regist;
    temporaryInformation = TI_VIEW_REGISTER;
    if(programRunStop == PGM_RUNNING) {
      refreshScreen(151);
      fnPause(10);
      temporaryInformation = TI_NO_INFO;
    }
  }
}
