/* This file is part of WP43.
 *
 * WP43 is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * WP43 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with WP43.  If not, see <http://www.gnu.org/licenses/>.
 */

/********************************************//** //JM
 * \file jm.c JM_TEST
 ***********************************************/

/* ADDITIONAL C43 functions and routines */

#include "c43Extensions/jm.h"

#include "c43Extensions/addons.h"
#include "charString.h"
#include "display.h"
#include "flags.h"
#include "config.h"
#include "c43Extensions/graphs.h"
#include "c43Extensions/graphText.h"
#include "items.h"
#include "c43Extensions/keyboardTweak.h"
#include "keyboard.h"
#include "mathematics/mathematics.h"
#include "memory.h"
#include "c43Extensions/radioButtonCatalog.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "screen.h"
#include "stack.h"
#include "stats.h"
#include "c43Extensions/xeqm.h"
#include <string.h>

#include "wp43.h"



#if defined(PC_BUILD)
  #if defined(PC_BUILD_TELLTALE)
    static char * getCalcModeName(uint16_t cm) {
      if(cm == CM_NORMAL)                return "normal ";
      if(cm == CM_AIM)                   return "aim    ";
      if(cm == CM_EIM)                   return "eim    ";
      if(cm == CM_PEM)                   return "pem    ";
      if(cm == CM_NIM)                   return "nim    ";
      if(cm == CM_ASSIGN)                return "assign ";
      if(cm == CM_REGISTER_BROWSER)      return "reg.bro";
      if(cm == CM_ASN_BROWSER)           return "asn.bro";
      if(cm == CM_FLAG_BROWSER)          return "flg.bro";
      if(cm == CM_FONT_BROWSER)          return "fnt.bro";
      if(cm == CM_PLOT_STAT)             return "plot.st";
      if(cm == CM_GRAPH)                 return "plot.gr";
      if(cm == CM_ERROR_MESSAGE)         return "err.msg";
      if(cm == CM_BUG_ON_SCREEN)         return "bug.scr";
      if(cm == CM_MIM)                   return "mim    ";
      if(cm == CM_EIM)                   return "eim    ";
      if(cm == CM_TIMER)                 return "timer  ";
      if(cm == CM_CONFIRMATION)          return "confirm";
      if(cm == CM_LISTXY)                return "listxy ";    //JM
      return "???    ";
    }

    static char * getAlphaCaseName(uint16_t ac) {
      if(ac == AC_LOWER) return "lower";
      if(ac == AC_UPPER) return "upper";
      return "???  ";
    }
  #endif // PC_BUILD_TELLTALE


  void jm_show_calc_state(char comment[]) {
    #if defined(PC_BUILD_TELLTALE)
      printf("\n%s--------------------------------------------------------------------------------\n",comment);
      printf(".  calcMode: %s   last_CM=%s  AlphaCase=%s  doRefreshSoftMenu=%d    lastErrorCode=%d fnAsnDisplayUSER=%d TI=%u\n",getCalcModeName(calcMode), getCalcModeName(last_CM), getAlphaCaseName(alphaCase), doRefreshSoftMenu,lastErrorCode, fnAsnDisplayUSER, temporaryInformation);
      printf(".  softmenuStack[0].softmenuId=%d      softmenu[softmenuStack[0].softmenuId].menuItem=%d -MNU_ALPHA=%d\n",softmenuStack[0].,softmenu[softmenuStack[0].softmenuId].menuItem, -MNU_ALPHA);

      printf(".  ");
      int8_t ix=0;
      while(ix < SOFTMENU_STACK_SIZE) {
        printf("(%d)=%5d ", ix, softmenuStack[ix].softmenuId);
        ix++;
      }
      printf("\n");

      printf(".  ");
      ix=0;
      while(ix < SOFTMENU_STACK_SIZE) {
        printf("%9s ", indexOfItems[-softmenu[softmenuStack[ix].softmenuId].menuItem].itemSoftmenuName  );
        ix++;
      }
      printf("\n");

      printf(".  (tam.mode=%d, catalog=%d)\n",tam.mode, catalog);
      jm_show_comment("calcstate END:");
    #endif //PC_BUILD_TELLTALE
  }


  void jm_show_comment(char comment[]) {
    #if defined(PC_BUILD_VERBOSE2)
      char tmp[600];
      strcpy(tmp,comment);
      strcat(tmp,"                                                                                                                                                                ");
      tmp[130]=0;
      printf("....%s calcMode=%4d last_CM=%4d tam.mode=%5d catalog=%5d Id=%4d Name=%8s F=%d G=%d \n",tmp, calcMode, last_CM, tam.mode, catalog, softmenuStack[0].softmenuId, indexOfItems[-softmenu[softmenuStack[0].softmenuId].menuItem].itemSoftmenuName,shiftF,shiftG);
    //  printf("....%s\n",tmp);
    #endif // PC_BUILD_VERBOSE2
  }
#endif // PC_BUILD



/********************************************//** XXX
 * \brief Set Norm_Key_00_VAR
 *
 * \param[in] sigmaAssign uint16_t
 * \return void
 ***********************************************/
void fnSigmaAssign(uint16_t sigmaAssign) {             //DONE
  int16_t tt = (int16_t)sigmaAssign;
  Norm_Key_00_VAR = tt - 16384;
  fnRefreshState();                                 //drJM
  fnClearFlag(FLAG_USER);
}


/********************************************//**
 * \brief Show flag value
 * \param[in] jmConfig to display uint16_t
 * \return void
 ***********************************************/
void fnShowJM(uint16_t jmConfig) {                               //DONE
  longInteger_t mem;
  longIntegerInit(mem);
  saveForUndo();
  liftStack();

  switch(jmConfig) {
    case JC_ERPN:
      uIntToLongInteger(eRPN ? 1:0, mem);
      break;
    default:
      break;
  }

  convertLongIntegerToLongIntegerRegister(mem, REGISTER_X);
  longIntegerFree(mem);
}


/********************************************//**
 * \brief Get item-value of assigned key to X
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnGetSigmaAssignToX(uint16_t unusedButMandatoryParameter) {       //DONE
  longInteger_t mem;
  longIntegerInit(mem);
  liftStack();

  uIntToLongInteger(Norm_Key_00_VAR, mem);

  convertLongIntegerToLongIntegerRegister(mem, REGISTER_X);
  longIntegerFree(mem);
}


//JM CONFIGURE USER MODE - ASSIGN KEYS
/********************************************//**
 * \brief
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnJM_GetXToNORMmode(uint16_t unusedButMandatoryParameter) {      //DONE
  int16_t X_REG;
  longInteger_t lgInt;

  if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
    convertLongIntegerRegisterToLongInteger(REGISTER_X, lgInt);
    longIntegerToAllocatedString(lgInt, tmpString, TMP_STR_LENGTH);
    longIntegerToInt(lgInt,X_REG);
    longIntegerFree(lgInt);
    //printf("Xreg %d\n", X_REG);
    Norm_Key_00_VAR = X_REG;
    fnClearFlag(FLAG_USER);
  }
}


uint16_t nprimes = 0;
/********************************************//**
 * RPN PROGRAM.
 *
 * \param[in] JM_OPCODE uint16_t
 * \return void
 ***********************************************/
void fnJM(uint16_t JM_OPCODE) {
  #define JMTEMP    TEMP_REGISTER_1 // 98
  #define JM_TEMP_I REGISTER_I // 97
  #define JM_TEMP_J REGISTER_J // 96
  #define JM_TEMP_K REGISTER_K // 95

  #if !defined(SAVE_SPACE_DM42_6)
    if(JM_OPCODE == 6) {                                         // Delta to Star   ZYX to ZYX; destroys IJKL & JMTEMP
      saveForUndo();
      setSystemFlag(FLAG_ASLIFT);
      copySourceRegisterToDestRegister(REGISTER_X, JM_TEMP_I);   // STO I
      copySourceRegisterToDestRegister(REGISTER_Y, JM_TEMP_J);   // STO J
      copySourceRegisterToDestRegister(REGISTER_Z, JM_TEMP_K);   // STO K
      fnAdd(0);                                                  // +
      fnSwapXY(0);                                               // X<>Y

      fnAdd(0);                                                  // +
      copySourceRegisterToDestRegister(REGISTER_X, JMTEMP);      // STO JMTEMP
      fnRCL(JM_TEMP_K);                                          // RCL I
      fnRCL(JM_TEMP_J);                                          // RCL J     // z = (zx yz) / (x+y+z)
      fnMultiply(0);                                             // *
      fnSwapXY(0);                                               // X<>Y
      fnDivide(0);                                               // /

      fnRCL(JMTEMP);                                             // RCL JMTEMP
      fnRCL(JM_TEMP_I);                                          // RCL J
      fnRCL(JM_TEMP_J);                                          // RCL K     // y = (xy yz) / (x+y+z)
      fnMultiply(0);                                             // *
      fnSwapXY(0);                                               // X<>Y
      fnDivide(0);                                               // /

      fnRCL(JMTEMP);                                             // RCL JMTEMP
      fnRCL(JM_TEMP_I);                                          // RCL I
      fnRCL(JM_TEMP_K);                                          // RCL K     // z = (xy zx) / (x+y+z)
      fnMultiply(0);                                             // *
      fnSwapXY(0);                                               // X<>Y
      fnDivide(0);                                               // /

      copySourceRegisterToDestRegister(JM_TEMP_I, REGISTER_L);   // STO

      temporaryInformation = TI_ABC;

      adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
      adjustResult(REGISTER_Y, false, true, REGISTER_Y, -1, -1);
      adjustResult(REGISTER_Z, false, true, REGISTER_Z, -1, -1);
    }

    else if(JM_OPCODE == 7) {                                    // Star to Delta ZYX to ZYX; destroys IJKL & JMTEMP
      saveForUndo();
      setSystemFlag(FLAG_ASLIFT);
      copySourceRegisterToDestRegister(REGISTER_X, JM_TEMP_I);   // STO I
      copySourceRegisterToDestRegister(REGISTER_Y, JM_TEMP_J);   // STO J
      copySourceRegisterToDestRegister(REGISTER_Z, JM_TEMP_K);   // STO K

      fnMultiply(0);                          //IJ               // *
      fnSwapXY(0);
      fnRCL(JM_TEMP_I);                                          // RCL J
      fnMultiply(0);                          //IK               // *
      fnAdd(0);
      fnRCL(JM_TEMP_J);                                          // RCL J
      fnRCL(JM_TEMP_K);                                          // RCL K
      fnMultiply(0);                          //JK               // *
      fnAdd(0);
      copySourceRegisterToDestRegister(REGISTER_X, JMTEMP);      // STO JMTEMP
                                                                //
      fnRCL(JM_TEMP_J);                                          //      zx = () / y
      fnDivide(0);                                               //

      fnRCL(JMTEMP);                                             // RCL JMTEMP
      fnRCL(JM_TEMP_I);                                          //      yz = () / x
      fnDivide(0);                                               //

      fnRCL(JMTEMP);                                             // RCL JMTEMP
      fnRCL(JM_TEMP_K);                                          //      xy = () / z
      fnDivide(0);                                               //

      copySourceRegisterToDestRegister(JM_TEMP_I, REGISTER_L);   // STO

      temporaryInformation = TI_ABBCCA;
      adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
      adjustResult(REGISTER_Y, false, true, REGISTER_Y, -1, -1);
      adjustResult(REGISTER_Z, false, true, REGISTER_Z, -1, -1);
    }

    else if(JM_OPCODE == 8) {                                          //SYMMETRICAL COMP to ABC   ZYX to ZYX; destroys IJKL
      saveForUndo();
      setSystemFlag(FLAG_ASLIFT);
      copySourceRegisterToDestRegister(REGISTER_X, JM_TEMP_I);   // STO I  //A2
      copySourceRegisterToDestRegister(REGISTER_Y, JM_TEMP_J);   // STO J  //A1
      copySourceRegisterToDestRegister(REGISTER_Z, JM_TEMP_K);   // STO K  //A0
      fnAdd(0);                                                  // +
      fnAdd(0);                                                  // + Va = Vao + Va1 +Va2

      setSystemFlag(FLAG_ASLIFT);
      //liftStack();
      fn_cnst_op_a(0);
      fnRCL(JM_TEMP_I);                                          // A2
      fnMultiply(0);                                             // * a
      setSystemFlag(FLAG_ASLIFT);
      //liftStack();
      fn_cnst_op_aa(0);
      fnRCL(JM_TEMP_J);                                          // A1
      fnMultiply(0);                                             // * aa
      fnAdd(0);                                                  // +
      fnRCL(JM_TEMP_K);                                          // A0
      fnAdd(0);                                                  // + Vb = Vao + aaVa1 +aVa2

      setSystemFlag(FLAG_ASLIFT);
      //liftStack();
      fn_cnst_op_aa(0);
      fnRCL(JM_TEMP_I);                                          // A2
      fnMultiply(0);                                             // * a
      setSystemFlag(FLAG_ASLIFT);
      //liftStack();
      fn_cnst_op_a(0);
      fnRCL(JM_TEMP_J);                                          // A1
      fnMultiply(0);                                             // * aa
      fnAdd(0);                                                  // +
      fnRCL(JM_TEMP_K);                                          // A0
      fnAdd(0);                                                  // + Vb = Vao + aaVa1 +aVa2

      copySourceRegisterToDestRegister(JM_TEMP_I, REGISTER_L);  // STO

      temporaryInformation = TI_ABC;
    }

    else if(JM_OPCODE == 9) {                                   //ABC to SYMMETRICAL COMP   ZYX to ZYX; destroys IJKL & JMTEMP
      saveForUndo();
      setSystemFlag(FLAG_ASLIFT);
      copySourceRegisterToDestRegister(REGISTER_X, JM_TEMP_I);  // STO I  //c
      copySourceRegisterToDestRegister(REGISTER_Y, JM_TEMP_J);  // STO J  //b
      copySourceRegisterToDestRegister(REGISTER_Z, JM_TEMP_K);  // STO K  //a
      fnAdd(0);                                                 // +
      fnAdd(0);                                                 // + Va0 = (Va + Vb +Vc)/3
      liftStack();
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      stringToReal34("3", REGISTER_REAL34_DATA(REGISTER_X));
      stringToReal34("0", REGISTER_IMAG34_DATA(REGISTER_X));
      copySourceRegisterToDestRegister(REGISTER_X, JMTEMP);     // STO
      fnDivide(0);

      setSystemFlag(FLAG_ASLIFT);
      //liftStack();
      fn_cnst_op_a(0);
      fnRCL(JM_TEMP_J);                                         // VB
      fnMultiply(0);                                            // * a
      setSystemFlag(FLAG_ASLIFT);
      //liftStack();
      fn_cnst_op_aa(0);
      fnRCL(JM_TEMP_I);                                         // VC
      fnMultiply(0);                                            // * aa
      fnAdd(0);                                                 // +
      fnRCL(JM_TEMP_K);                                         // VA
      fnAdd(0);                                                 // + V1 = (VA +aVb +aaVc) /3
      fnRCL(JMTEMP);                                            // 3
      fnDivide(0);                                              // /

      setSystemFlag(FLAG_ASLIFT);
      //liftStack();
      fn_cnst_op_aa(0);
      fnRCL(JM_TEMP_J);                                         // VB
      fnMultiply(0);                                            // * a
      setSystemFlag(FLAG_ASLIFT);
      //liftStack();
      fn_cnst_op_a(0);
      fnRCL(JM_TEMP_I);                                         // VC
      fnMultiply(0);                                            // * aa
      fnAdd(0);                                                 // +
      fnRCL(JM_TEMP_K);                                         // VA
      fnAdd(0);                                                 // + V1 = (VA +aVb +aaVc) /3
      fnRCL(JMTEMP);                                            // 3
      fnDivide(0);                                              // /

      copySourceRegisterToDestRegister(JM_TEMP_I, REGISTER_L);  // STO

      temporaryInformation = TI_012;
    }

    else if(JM_OPCODE == 11) {                                  //STO Z
      saveForUndo();
      setSystemFlag(FLAG_ASLIFT);                               //  Registers: Z:90-92  V:93-95  I:96-98  XYZ
      copySourceRegisterToDestRegister(REGISTER_X, 90);
      copySourceRegisterToDestRegister(REGISTER_Y, 91);
      copySourceRegisterToDestRegister(REGISTER_Z, 92);
    }

    else if(JM_OPCODE == 13) {                                  //STO V
      saveForUndo();
      setSystemFlag(FLAG_ASLIFT);                               //  Registers: Z:90-92  V:93-95  I:96-98  XYZ
      copySourceRegisterToDestRegister(REGISTER_X, 93);
      copySourceRegisterToDestRegister(REGISTER_Y, 94);
      copySourceRegisterToDestRegister(REGISTER_Z, 95);
    }

    else if(JM_OPCODE == 15) {                                  //STO I
      saveForUndo();
      setSystemFlag(FLAG_ASLIFT);                               //  Registers: Z:90-92  V:93-95  I:96-98  XYZ
      copySourceRegisterToDestRegister(REGISTER_X, 96);
      copySourceRegisterToDestRegister(REGISTER_Y, 97);
      copySourceRegisterToDestRegister(REGISTER_Z, 98);
    }

    else if(JM_OPCODE == 12) {                                  //RCL Z
      saveForUndo();
      fnRCL(92);
      fnRCL(91);
      fnRCL(90);
    }

    else if(JM_OPCODE == 14) {                                  //RCL V
      saveForUndo();
      fnRCL(95);
      fnRCL(94);
      fnRCL(93);
    }

    else if(JM_OPCODE == 16) {                                  //RCL I
      saveForUndo();
      fnRCL(98);
      fnRCL(97);
      fnRCL(96);
    }

    else if(JM_OPCODE == 17) {                                  // V/I
      saveForUndo();
      fnRCL(95);
      fnRCL(98);
      fnDivide(0);
      fnRCL(94);
      fnRCL(97);
      fnDivide(0);
      fnRCL(93);
      fnRCL(96);
      fnDivide(0);
    }

    else if(JM_OPCODE == 18) {                                  // IZ
      saveForUndo();
      fnRCL(98);
      fnRCL(92);
      fnMultiply(0);
      fnRCL(97);
      fnRCL(91);
      fnMultiply(0);
      fnRCL(96);
      fnRCL(91);
      fnMultiply(0);
    }

    else if(JM_OPCODE == 19) {                                  // V/Z
      saveForUndo();
      fnRCL(95);
      fnRCL(92);
      fnDivide(0);
      fnRCL(94);
      fnRCL(91);
      fnDivide(0);
      fnRCL(93);
      fnRCL(90);
      fnDivide(0);
    }

    else if(JM_OPCODE == 20) {                                  //Copy Create X>ABC
      saveForUndo();
      setSystemFlag(FLAG_ASLIFT);
      copySourceRegisterToDestRegister(REGISTER_X, JM_TEMP_I);

      fnRCL(JM_TEMP_I);                                         //
      setSystemFlag(FLAG_ASLIFT);
      //liftStack();
      fn_cnst_op_a(0);
      fnMultiply(0);

      fnRCL(JM_TEMP_I);                                         //
      setSystemFlag(FLAG_ASLIFT);
      //liftStack();
      fn_cnst_op_aa(0);
      copySourceRegisterToDestRegister(REGISTER_X, JM_TEMP_J);
      fnMultiply(0);

      temporaryInformation = TI_ABC;
    }

    else if(JM_OPCODE == 45) {                                  //PRIME stats
      #if defined(PC_BUILD)
        //ramDump();
      #endif // PC_BUILD

      char line1[700];
      //Create a 3x3 A-matrix
      TO_QSPI static const char *aa001 = "XEQC43 ERPN RECT 3 ENTER 3 M.NEW STO 99 DROP INDEX 99 1 ENTER 1 STOIJ DROP DROP";
      TO_QSPI static const char *aa002 = " 1 STOEL J+ STOEL J+ STOEL";
      TO_QSPI static const char *aa003 = " J+ STOEL DROP 0.5 ENTER CHS 3 ENTER SQRT 2 / CHS COMPLEX J+ STOEL COMPLEX CHS COMPLEX J+ STOEL";
      TO_QSPI static const char *aa004 = " 1 J+ STOEL DROP J+ STOEL X^2 J+ STOEL DROP";
      TO_QSPI static const char *aa005 = " RCL 99 ";
      strcpy(line1, aa001);
      strcat(line1, aa002);
      strcat(line1, aa003);
      strcat(line1, aa004);
      strcat(line1, aa005);
      fnXEQMexecute(line1);
      }

    else if(JM_OPCODE == 46) {                                  //PRIME stats
      char line1[700];
      //Create a 3x1 matrix from Z Y X
      TO_QSPI static const char *aa006 = "XEQC43 ERPN 3 ENTER 1 M.NEW STO 99 DROP INDEX 99 3 ENTER 1 STOIJ DROP DROP STOEL DROP  I- STOEL DROP  I-  STOEL DROP RCL 99 ";
      strcpy(line1, aa006);
      fnXEQMexecute(line1);
    }

    else if(JM_OPCODE == 47) {                                  //PRIME stats
      char line1[700];
      //Create a ZYX form a 3x1 matrix
      TO_QSPI static const char *aa007 = "XEQC43 ERPN STO 99 INDEX 99 DROP 1 ENTER 1 STOIJ DROP DROP RCLEL I+ RCLEL I+ RCLEL ";
      strcpy(line1, aa007);
      fnXEQMexecute(line1);
    }

  #endif // !SAVE_SPACE_DM42_6
  // Item 255 is NOP
}


