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

#include "softmenus.h"

#include "c43Extensions/addons.h"
#include "calcMode.h"
#include "charString.h"
#include "error.h"
#include "fonts.h"
#include "flags.h"
#include "items.h"
#include "memory.h"
#include "programming/manage.h"
#include "c43Extensions/jm.h"
#include "c43Extensions/keyboardTweak.h"
#include "plotstat.h"
#include "programming/nextStep.h"
#include "c43Extensions/radioButtonCatalog.h"
#include "registers.h"
#include "screen.h"
#include "solver/differentiate.h"
#include "solver/equation.h"
#include "sort.h"
#include "c43Extensions/xeqm.h"
#include <string.h>
#include <stdlib.h>

#include "wp43.h"

#if !defined(TESTSUITE_BUILD)
  TO_QSPI static const char bugScreenIdMustNotBe0[] = "In function showSoftmenu: id must not be 0!";
#endif //TESTSUITE_BUILD

/* The numbers refer to the index of items in items.c
 *         item <     0  ==>  sub menu
 *     0 < item <  9999  ==>  item with top and bottom line
 * 10000 < item < 19999  ==>  item without top line
 * 20000 < item < 29999  ==>  item without bottom line
 * 30000 < item < 39999  ==>  item without top and bottom line
 */

/*      Menu name                           <----------------------------------------------------------------------------- 6 functions ---------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 f shifted functions ------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 g shifted functions ------------------------------------------------------------------------->  */
TO_QSPI const int16_t menu_ADV[]         = { ITM_SOLVE,                     ITM_SLVQ,                   ITM_FQX,                  ITM_PIn,               ITM_SIGMAn,                  -MNU_Sfdx,
                                             ITM_PGMSLV,                    ITM_NULL,                   ITM_FDQX,                 ITM_iPIn,              ITM_iSIGMAn,                 ITM_PGMINT                    };

TO_QSPI const int16_t menu_Sfdx[]        = { ITM_NULL,                      ITM_DRAW,                   VAR_ACC,                  VAR_LLIM,              VAR_ULIM,                    ITM_INTEGRAL                  };

TO_QSPI const int16_t menu_BITS[]        = { ITM_LOGICALAND,                ITM_LOGICALOR,              ITM_LOGICALXOR,           ITM_LOGICALNOT,        ITM_MASKL,                   ITM_MASKR,
                                             ITM_LOGICALNAND,               ITM_LOGICALNOR,             ITM_LOGICALXNOR,          ITM_MIRROR,            ITM_NULL,                    ITM_NULL,
                                             ITM_SB,                        ITM_BS,                     ITM_NUMB,                 ITM_FB,                ITM_BC,                      ITM_CB,
                                             ITM_A,                         ITM_B,                      ITM_C,                    ITM_D,                 ITM_E,                       ITM_F,
                                             ITM_SL,                        ITM_RL,                     ITM_RLC,                  ITM_RRC,               ITM_RR,                      ITM_SR,
                                             ITM_LJ,                        ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_RJ,                      ITM_ASR,
                                             ITM_1COMPL,                    ITM_2COMPL,                 ITM_UNSIGN,               ITM_SIGNMT,            ITM_NULL,                    ITM_WSIZE                     };

#if defined(DMCP_BUILD)
  #define ITM_SD ITM_SETDAT
  #define ITM_ST ITM_SETTIM
#else // !DMCP_BUILD
  #define ITM_SD ITM_RESERVE
  #define ITM_ST ITM_RESERVE
#endif // DMCP_BUILD


TO_QSPI const int16_t menu_CLK[]         = { ITM_DATE,                      ITM_TIME,                   ITM_DTtoJ,                ITM_JtoDT,             ITM_DtoJ,                    ITM_XtoDATE,
                                             ITM_DATEto,                    ITM_TIMEto,                 ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,
                                             ITM_toDATE,                    ITM_toTIME,                 ITM_NULL,                 ITM_NULL,              ITM_toHMS,                   ITM_msTo,

                                             ITM_DATE,                      ITM_TIME,                   ITM_TDISP,                ITM_DMY,               ITM_MDY,                     ITM_YMD,
                                             ITM_SD,                        ITM_ST,                     ITM_WDAY,                 ITM_DAY,               ITM_MONTH,                   ITM_YEAR,
                                             ITM_CLK12,                     ITM_CLK24,                  ITM_NULL,                 ITM_SECOND,            ITM_MINUTE,                  ITM_HR_DEG,

                                             ITM_GET_JUL_GREG,              ITM_JUL_GREG,               ITM_JUL_GREG_1582,        ITM_JUL_GREG_1752,     ITM_JUL_GREG_1873,           ITM_JUL_GREG_1949             };


TO_QSPI const int16_t menu_CLR[]         = { ITM_CLSIGMA,                   ITM_CLP,                    ITM_CF,                   ITM_CLMENU,            ITM_CLCVAR,                  ITM_CLX,
                                             ITM_CLREGS,                    ITM_CLPALL,                 ITM_CLFALL,               ITM_CLGRF,             ITM_CLLCD,                   ITM_CLSTK,
                                             ITM_CLALL,                     ITM_CLBKUP,                 ITM_NULL,                 ITM_DELITM,            ITM_NULL,                    ITM_RESET                     };

/*      Menu name                           <----------------------------------------------------------------------------- 6 functions ---------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 f shifted functions ------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 g shifted functions ------------------------------------------------------------------------->  */
TO_QSPI const int16_t menu_CPX[]         = { ITM_RE,                        ITM_IM,                     ITM_MAGNITUDE,            ITM_ARG,               ITM_REexIM,                  ITM_CC,                      //JM re-arranged menu. CPX menu
                                             KEY_COMPLEX,                   ITM_CONJ,                   ITM_DOT_PROD,             ITM_CROSS_PROD,        ITM_op_j,                    ITM_UNITV,                                          //JM re-arranged menu. CPX menu
                                             ITM_CPXI,                      ITM_CPXJ,                   ITM_CXtoRE,               ITM_REtoCX,            ITM_RECT,                    ITM_POLAR                     };    //JM re-arranged menu

TO_QSPI const int16_t menu_DISP[]        = { ITM_FIX,                       ITM_SCI,                    ITM_ENG,                  ITM_ALL,               ITM_SIGFIG,                  ITM_UNIT,
                                             ITM_GAP_L,                     ITM_GAP_RX,                 ITM_GAP_R,                ITM_TDISP,             ITM_RECT,                    ITM_POLAR,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,

                                             ITM_DMY,                       ITM_MDY,                    ITM_YMD,                  ITM_CPXMULT,           ITM_MULTCR,                  ITM_MULTDOT,
                                             ITM_SI_All,                    ITM_DSTACK,                 ITM_SHOIREP,              ITM_LARGELI,           ITM_CPXI,                    ITM_CPXJ,
                                             ITM_SCIOVR,                    ITM_ENGOVR,                 ITM_RNG,                  ITM_HIDE,              ITM_CLK12,                   ITM_CLK24,

                                             ITM_SETCHN,                    ITM_SETEUR,                 ITM_SETIND,               ITM_SETJPN,            ITM_SETUK,                   ITM_SETUSA,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_SETDFLT,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                        };


TO_QSPI const int16_t menu_EQN[]         = { ITM_EQ_NEW,                    ITM_EQ_EDI,                 -MNU_2NDDERIV,            -MNU_1STDERIV,         -MNU_Sf,                     -MNU_Solver,
                                             ITM_EQ_DEL,                    ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };

TO_QSPI const int16_t menu_EXP[]         = { ITM_CUBE,                      ITM_YX,                     ITM_SQUARE,               ITM_LOG2,              ITM_LN1X,                    ITM_LOGXY,                          //JM re-arranged menu. logxy and square to follow DM42 keyboard. Re-aligned with 42S keys.
                                             ITM_CUBEROOT,                  ITM_XTHROOT,                ITM_SQUAREROOTX,          ITM_2X,                ITM_EX1,                     ITM_EXP,                           //JM re-arranged menu. Added YˆX to follow DM42 keyboard. Swapped YˆX and Yˆ(1/X). Re-aligned with 42S keys.
                                             ITM_sinh,                      ITM_cosh,                   ITM_tanh,                 ITM_arsinh,            ITM_arcosh,                  ITM_artanh                    };

TO_QSPI const int16_t menu_TRI[]         = { ITM_DEG2,                      ITM_RAD2,                   ITM_GRAD2,                ITM_sin,               ITM_cos,                     ITM_tan,
                                             ITM_sinc,                      ITM_sincpi,                 ITM_atan2,                ITM_arcsin,            ITM_arccos,                  ITM_arctan,                         //JM re-arranged menu TRIG menu
                                             ITM_sinh,                      ITM_cosh,                   ITM_tanh,                 ITM_arsinh,            ITM_arcosh,                  ITM_artanh                    };    //JM re-arranged menu TRIG menu

TO_QSPI const int16_t menu_TRG_C47[]     = { ITM_DEG2,                      ITM_RAD2,                   ITM_GRAD2,                ITM_DMS2,              ITM_MULPI2,                  -MNU_TRG_C47_MORE,
                                             ITM_sinc,                      ITM_sincpi,                 ITM_atan2,                ITM_ms,                ITM_dotD,                    ITM_msTo                      };

TO_QSPI const int16_t menu_TRG_C47_MORE[]= { ITM_DEG2,                      ITM_RAD2,                   ITM_GRAD2,                ITM_sin,               ITM_cos,                     ITM_tan,
                                             ITM_sinc,                      ITM_sincpi,                 ITM_atan2,                ITM_arcsin,            ITM_arccos,                  ITM_arctan,                         //JM re-arranged menu TRIG menu
                                             ITM_sinh,                      ITM_cosh,                   ITM_tanh,                 ITM_arsinh,            ITM_arcosh,                  ITM_artanh                    };    //JM re-arranged menu TRIG menu


//D47 vv
TO_QSPI const int16_t menu_TRG[]         = { ITM_DEG,                       ITM_RAD,                    ITM_GRAD,                 ITM_sinc,              ITM_sincpi,                  ITM_atan2,
                                             ITM_DEG2,                      ITM_RAD2,                   ITM_GRAD2,                ITM_DMS2,              ITM_MULPI2,                  ITM_msTo,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };
//D47 ^^

TO_QSPI const int16_t menu_FIN[]         = { ITM_SIGMAPLUS ,                ITM_PCT    ,                ITM_PC         ,          ITM_DELTAPC,            ITM_PCPMG,                   -MNU_TVM,
                                             ITM_SIGMAMINUS,                ITM_SIGMAx ,                ITM_NSIGMA     ,          ITM_XBAR   ,            ITM_PCMRR,                   ITM_NULL,
                                             ITM_CLSIGMA   ,                ITM_PCSIGMA,                ITM_PCSGM_DPCMN,          ITM_DPCMEAN,            ITM_NULL  ,                  ITM_NULL                     };

/*      Menu name                           <----------------------------------------------------------------------------- 6 functions ---------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 f shifted functions ------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 g shifted functions ------------------------------------------------------------------------->  */
TO_QSPI const int16_t menu_TVM[]         = { VAR_NPER,                      VAR_IPonA,                  VAR_PERonA,               VAR_PV,                VAR_PMT,                     VAR_FV,
                                             ITM_RCL_NPER,                  ITM_RCL_IPonA,              ITM_RCL_PERonA,           ITM_RCL_PV,            ITM_RCL_PMT,                 ITM_RCL_FV,
                                             ITM_BEGINP,                    ITM_ENDP,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                   -MNU_FIN                      };

TO_QSPI const int16_t menu_FLAGS[]       = { ITM_SF,                        ITM_FS,                     ITM_FF,                   ITM_STATUS,            ITM_FC,                      ITM_CF,
                                             ITM_FSS,                       ITM_FSC,                    ITM_FSF,                  ITM_FCF,               ITM_FCS,                     ITM_FCC,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_CLFALL                    };

#if defined(DMCP_BUILD)
  #define ITM_DSK ITM_DISK
#else // !DMCP_BUILD
  #define ITM_DSK ITM_RESERVE
#endif // DMCP_BUILD


TO_QSPI const int16_t menu_INFO[]        = { ITM_SSIZE,                     ITM_MEM,                    ITM_RMODEQ,               ITM_ISM,               ITM_WSIZEQ,                  ITM_KTYP,
                                             ITM_LocRQ,                     ITM_DSK,                    ITM_ULP,                  ITM_NEIGHB,            ITM_GETSDIGS,                ITM_BATT,
                                             ITM_WHO,                       ITM_VERS,                   ITM_M_DIMQ,               ITM_PMINFINITY,        ITM_ALPHAPOS,                ITM_ALPHALENG,
                                             ITM_GETRANGE,                  ITM_GETHIDE,                ITM_GET_JUL_GREG,         ITM_VOLQ,              ITM_SH_ERPN,                 ITM_BESTFQ,
                                             ITM_GETDMX,                    ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                        };


TO_QSPI const int16_t menu_INTS[]        = { ITM_A,                         ITM_B,                      ITM_C,                    ITM_D,                 ITM_E,                       ITM_F,
                                             ITM_IDIV,                      ITM_RMD,                    ITM_MOD,                  ITM_XMOD,              ITM_LINT,                    ITM_LCM,
                                             ITM_DBLDIV,                    ITM_DBLR,                   ITM_DBLMULT,              ITM_PMOD,              ITM_NULL,                    ITM_GCD,
                                             ITM_1COMPL,                    ITM_2COMPL,                 ITM_UNSIGN,               ITM_SIGNMT,            ITM_NULL,                    ITM_WSIZE                     };

TO_QSPI const int16_t menu_LOOP[]        = { ITM_DSE,                       ITM_DSZ,                    ITM_DSL,                  ITM_ISE,               ITM_ISZ,                     ITM_ISG,
                                             ITM_DEC,                       ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_INC                       };

/*      Menu name                           <----------------------------------------------------------------------------- 6 functions ---------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 f shifted functions ------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 g shifted functions ------------------------------------------------------------------------->  */
TO_QSPI const int16_t menu_MATX[]        = { ITM_M_NEW,                     ITM_M_INV,                  ITM_M_DET,                ITM_M_TRANSP,          ITM_SIM_EQ,                  ITM_M_EDI,
                                             ITM_DOT_PROD,                  ITM_CROSS_PROD,             ITM_UNITV,                ITM_M_DIM,             ITM_INDEX,                   ITM_M_EDIN,
                                             ITM_ENORM,                     ITM_VANGLE,                 ITM_STOEL,                ITM_RCLEL,             ITM_M_PUT,                   ITM_M_GET,
                                             ITM_IPLUS,                     ITM_IMINUS,                 ITM_STOIJ,                ITM_RCLIJ,             ITM_JMINUS,                  ITM_JPLUS,
                                             ITM_RSUM,                      ITM_RNORM,                  ITM_M_LU,                 ITM_M_DIMQ,            ITM_NULL,                    ITM_M_RR,
                                             ITM_EIGVAL,                    ITM_NULL,                   ITM_M_QR,                 ITM_NULL,              ITM_NULL,                    ITM_EIGVEC                    };

TO_QSPI const int16_t menu_M_SIM_Q[]     = { VAR_MATA,                      VAR_MATB,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_MATX                      }; // Should VAR_MATA and VAR_MATB be reclaced by ITM_MATA (to be created) and ITM_MATB (to be created) here?

TO_QSPI const int16_t menu_M_EDIT[]      = { ITM_UP_ARROW,                  ITM_DOWN_ARROW,             ITM_M_OLD,                ITM_CC,                ITM_LEFT_ARROW,              ITM_RIGHT_ARROW,                  //JM
                                             ITM_M_INSR,                    ITM_NULL,                   ITM_M_DELR,               ITM_M_GOTO,            ITM_M_WRAP,                  ITM_M_GROW                    };  //JM



#if defined(INLINE_TEST) && defined(DMCP_BUILD)
  #define ITM_TST -MNU_INL_TST
#else
  #define ITM_TST ITM_RESERVE2
#endif

#if defined(DMCP_BUILD)
  #define ITM_SYS ITM_SYSTEM
  #define ITM_SYS2 ITM_SYSTEM2
  #define ITM_DMCP ITM_ACTUSB
#else // !DMCP_BUILD
  #define ITM_SYS ITM_RESERVE
  #define ITM_SYS2 ITM_RESERVE
  #define ITM_DMCP ITM_RESERVE
#endif // DMCP_BUILD




TO_QSPI const int16_t menu_MODE[]        = { ITM_DEG,                       ITM_RAD,                    ITM_GRAD,                 ITM_HPRP,              ITM_RECT,                    ITM_POLAR,
                                             ITM_SYS,                       ITM_SYS2,                   ITM_DMCP,                 ITM_ERPN,             -MNU_INFO,                    ITM_CFG,              //JM
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,                                       //JM

                                             ITM_SSIZE4,                    ITM_SSIZE8,                 ITM_CB_CPXRES,            ITM_CB_SPCRES,         ITM_DENMAX2,                 ITM_CFG,                           //JM
                                             ITM_SETSIG2,                   ITM_RMODE,                  ITM_IRFRAC,               ITM_DENANY,            ITM_DENFIX,                  ITM_PROPFR,        //JM
                                             ITM_INP_DEF_43S,               ITM_INP_DEF_DP,             ITM_INP_DEF_CPXDP,        ITM_INP_DEF_LI,        ITM_NULL,                    ITM_NULL,                          //JM

                                             ITM_FGLNOFF,                   ITM_FGLNLIM,                ITM_FGLNFUL,              ITM_G_DOUBLETAP,       ITM_SHTIM,                   ITM_SAFERESET,             
                                             ITM_M14,                       ITM_M124,                   ITM_M1234,                ITM_NULL,              ITM_BASE_MYM,                ITM_BASE_HOME,             
                                             ITM_F14,                       ITM_F124,                   ITM_F1234,                ITM_NULL,              ITM_MYMx3,                   ITM_HOMEx3         };

// D47 vv
TO_QSPI const int16_t menu_SETUP[]       = { ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_HPRP,              ITM_RECT,                    ITM_POLAR,
                                             ITM_SYS,                       ITM_SYS2,                   ITM_DMCP,                 ITM_ERPN,              ITM_NULL,                    ITM_CFG,              //JM
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,                                       //JM

                                             ITM_SSIZE4,                    ITM_SSIZE8,                 ITM_CB_CPXRES,            ITM_CB_SPCRES,         ITM_DENMAX2,                 ITM_CFG,                           //JM
                                             ITM_SETSIG2,                   ITM_RMODE,                  ITM_IRFRAC,               ITM_DENANY,            ITM_DENFIX,                  ITM_PROPFR,        //JM
                                             ITM_INP_DEF_43S,               ITM_INP_DEF_DP,             ITM_INP_DEF_CPXDP,        ITM_INP_DEF_LI,        ITM_NULL,                    ITM_NULL,                          //JM

                                             ITM_FGLNOFF,                   ITM_FGLNLIM,                ITM_FGLNFUL,              ITM_G_DOUBLETAP,       ITM_SHTIM,                   ITM_SAFERESET,             
                                             ITM_M14,                       ITM_M124,                   ITM_M1234,                ITM_NULL,              ITM_BASE_MYM,                ITM_BASE_HOME,             
                                             ITM_F14,                       ITM_F124,                   ITM_F1234,                ITM_NULL,              ITM_MYMx3,                   ITM_HOMEx3         };
// D47 ^^


TO_QSPI const int16_t menu_PARTS[]       = { ITM_IP,                        ITM_FP,                     ITM_MANT,                 ITM_EXPT,              ITM_SIGN,                    ITM_DECOMP,
                                             ITM_SDL,                       ITM_SDR,                    ITM_ROUND2,               ITM_ROUNDI2,           ITM_RDP,                     ITM_RSD,                            //JM
                                             ITM_FLOOR,                     ITM_CEIL,                   ITM_MAGNITUDE,            ITM_ARG,               ITM_RE,                      ITM_IM                        };

/*      Menu name                           <----------------------------------------------------------------------------- 6 functions ---------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 f shifted functions ------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 g shifted functions ------------------------------------------------------------------------->  */
TO_QSPI const int16_t menu_PROB[]        = {
#if !defined(SAVE_SPACE_DM42_15)
                                             -MNU_NORML,                    -MNU_T,                     ITM_COMB,                 ITM_PERM,              -MNU_F,                      -MNU_CHI2,
                                             -MNU_LGNRM,                    -MNU_CAUCH,                 ITM_XFACT,                -MNU_EXPON,            -MNU_LOGIS,                  -MNU_WEIBL,                         //JM Added x! where it belongs, directly above Cyx
                                             -MNU_STDNORML,                 -MNU_NBIN,                  -MNU_GEOM,                -MNU_HYPER,            -MNU_BINOM,                  -MNU_POISS,
                                             ITM_RAN,                       ITM_SEED,                   ITM_RANI,                 ITM_NULL,              ITM_LNGAMMA,                 ITM_GAMMAX
#else // SAVE_SPACE_DM42_15
                                             ITM_RAN,                       ITM_SEED,                   ITM_RANI,                 ITM_COMB,              ITM_PERM,                    -MNU_NORML
#endif // !SAVE_SPACE_DM42_15
                                           };

TO_QSPI const int16_t menu_t[]           = { ITM_TPX,                       ITM_NULL,                   ITM_TX,                   ITM_TUX,               ITM_NULL,                    ITM_TM1P                      };
TO_QSPI const int16_t menu_F[]           = { ITM_FPX,                       ITM_NULL,                   ITM_FX,                   ITM_FUX,               ITM_NULL,                    ITM_FM1P                      };
TO_QSPI const int16_t menu_chi2[]        = { ITM_chi2Px,                    ITM_NULL,                   ITM_chi2x,                ITM_chi2ux,            ITM_NULL,                    ITM_chi2M1                    };
TO_QSPI const int16_t menu_StdNorml[]    = { ITM_STDNORMLP,                 ITM_NULL,                   ITM_STDNORML,             ITM_STDNORMLU,         ITM_NULL,                    ITM_STDNORMLM1                };
TO_QSPI const int16_t menu_Norml[]       = { ITM_NORMLP,                    ITM_NULL,                   ITM_NORML,                ITM_NORMLU,            ITM_NULL,                    ITM_NORMLM1                   };
TO_QSPI const int16_t menu_LgNrm[]       = { ITM_LGNRMP,                    ITM_NULL,                   ITM_LGNRM,                ITM_LGNRMU,            ITM_NULL,                    ITM_LGNRMM1                   };
TO_QSPI const int16_t menu_Cauch[]       = { ITM_CAUCHP,                    ITM_NULL,                   ITM_CAUCH,                ITM_CAUCHU,            ITM_NULL,                    ITM_CAUCHM1                   };
TO_QSPI const int16_t menu_Expon[]       = { ITM_EXPONP,                    ITM_NULL,                   ITM_EXPON,                ITM_EXPONU,            ITM_NULL,                    ITM_EXPONM1                   };
TO_QSPI const int16_t menu_Logis[]       = { ITM_LOGISP,                    ITM_NULL,                   ITM_LOGIS,                ITM_LOGISU,            ITM_NULL,                    ITM_LOGISM1                   };
TO_QSPI const int16_t menu_Weibl[]       = { ITM_WEIBLP,                    ITM_NULL,                   ITM_WEIBL,                ITM_WEIBLU,            ITM_NULL,                    ITM_WEIBLM1                   };
TO_QSPI const int16_t menu_Binom[]       = { ITM_BINOMP,                    ITM_NULL,                   ITM_BINOM,                ITM_BINOMU,            ITM_NULL,                    ITM_BINOMM1                   };
TO_QSPI const int16_t menu_Geom[]        = { ITM_GEOMP,                     ITM_NULL,                   ITM_GEOM,                 ITM_GEOMU,             ITM_NULL,                    ITM_GEOMM1                    };
TO_QSPI const int16_t menu_Hyper[]       = { ITM_HYPERP,                    ITM_NULL,                   ITM_HYPER,                ITM_HYPERU,            ITM_NULL,                    ITM_HYPERM1                   };
TO_QSPI const int16_t menu_Nbin[]        = { ITM_NBINP,                     ITM_NULL,                   ITM_NBIN,                 ITM_NBINU,             ITM_NULL,                    ITM_NBINM1                    };
TO_QSPI const int16_t menu_Poiss[]       = { ITM_POISSP,                    ITM_NULL,                   ITM_POISS,                ITM_POISSU,            ITM_NULL,                    ITM_POISSM1                   };

/*      Menu name                  <----------------------------------------------------------------------------- 6 functions ---------------------------------------------------------------------------->  */
/*                                 <---------------------------------------------------------------------- 6 f shifted functions ------------------------------------------------------------------------->  */
/*                                 <---------------------------------------------------------------------- 6 g shifted functions ------------------------------------------------------------------------->  */

TO_QSPI const int16_t menu_PFN[]         = { ITM_LBL,                       ITM_GTO,                    ITM_XEQ,                  ITM_RTN,               ITM_END,                    -MNU_PFN_MORE,
                                             ITM_SKIP,                      ITM_BACK,                   ITM_XEQP1,                ITM_RTNP1,             ITM_CASE,                    ITM_LocR,
                                             ITM_INPUT,                     ITM_MSG,                    ITM_ERR,                  ITM_TICKS,             ITM_PAUSE,                   ITM_POPLR                     };

TO_QSPI const int16_t menu_PFN_MORE[]    = { ITM_AGRAPH,                    ITM_PIXEL,                  ITM_POINT,                ITM_VOL,              -MNU_IO,                     -MNU_PFN,
                                             ITM_CLMENU,                    ITM_R_COPY,                 ITM_R_SORT,               ITM_R_SWAP,            ITM_R_CLR,                   ITM_EXITALL,
                                             ITM_MENU,                      ITM_KEYG,                   ITM_KEYX,                 ITM_VARMNU,            ITM_MVAR,                    ITM_PUTK                      };

TO_QSPI const int16_t menu_STAT[]        = { ITM_SIGMAPLUS,                 ITM_XBAR,                   ITM_STDDEVWEIGHTED,       ITM_STDDEV,            ITM_SM,                      ITM_XRMS,
                                             ITM_SIGMAMINUS,                ITM_XW,                     ITM_SW,                   ITM_STDDEVPOP,         ITM_SMW,                     ITM_XH,
                                             ITM_NSIGMA,                    ITM_XG,                     ITM_SCATTFACT,            ITM_SCATTFACTp,        ITM_SCATTFACTm,              ITM_CLSIGMA,

                                             ITM_XMIN,                      ITM_LOWER_QUARTILE,         ITM_MEDIAN,               ITM_UPPER_QUARTILE,    ITM_XMAX,                    ITM_SUM,
                                             ITM_NULL,                      ITM_PERCENTILE,             ITM_MAD,                  ITM_IQR,               ITM_NULL,                    ITM_SIGMARANGE,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };


TO_QSPI const int16_t menu_REGR[]        = { ITM_LR,                        ITM_CORR,                   ITM_SXY,                  ITM_COV,               ITM_XCIRC,                   ITM_YCIRC,
                                             ITM_SA,                        ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 -MNU_MODEL,            ITM_PLOT_LR,                 ITM_PLOT                      };

TO_QSPI const int16_t menu_MODEL[]       = { ITM_T_LINF,                    ITM_T_EXPF,                ITM_T_LOGF,                ITM_T_POWERF,          ITM_T_ROOTF,                 ITM_PLOT_LR,
                                             ITM_T_HYPF,                    ITM_T_PARABF,              ITM_T_CAUCHF,              ITM_T_GAUSSF,          ITM_T_ORTHOF,                ITM_LR,
                                             ITM_RSTF,                      ITM_SETALLF,               ITM_BESTF,                 ITM_BESTFQ,            ITM_NULL,                    ITM_NULL                      };


TO_QSPI const int16_t menu_PLOTTING[]    = { ITM_SIGMAPLUS,                 ITM_SIGMAx,                ITM_SIGMAx2,               ITM_SIGMAy,            ITM_SIGMAy2,                 ITM_SIGMAxy,               
                                             ITM_SIGMAMINUS,                ITM_SIGMA1onx,             ITM_SIGMA1onx2,            ITM_SIGMA1ony,         ITM_SIGMA1ony2,              ITM_SIGMAxony,             
                                             ITM_NSIGMA,                    ITM_SIGMAx3,               ITM_SIGMAx4,               -MNU_REGR,             ITM_PLOT_STAT,              -MNU_HIST,                 
    
                                             ITM_SIGMAPLUS,                 ITM_SIGMAlnx,              ITM_SIGMAln2x,             ITM_SIGMAlny,          ITM_SIGMAln2y,               ITM_SIGMAx2y,              
                                             ITM_SIGMAMINUS,                ITM_SIGMAylnx,             ITM_SIGMAlnxy,             ITM_SIGMAxlny,         ITM_SIGMAx2lny,              ITM_SIGMAx2ony,            
                                             ITM_NSIGMA,                    ITM_NULL,                  ITM_NULL,                  ITM_SIGMAlnyonx,       ITM_NULL,                    ITM_CLSIGMA                     };

TO_QSPI const int16_t menu_GRAPH[]   = {
                                             ITM_REPLT,                     ITM_PLOTZOOM,               ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };

TO_QSPI const int16_t menu_PLOT_STAT[]   = {
                                             ITM_PLOT_CENTRL,               ITM_SMI,                    ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };

TO_QSPI const int16_t menu_PLOT_LR[]   = {
                                             ITM_PLOT_NXT,                  ITM_PLOTZOOM,               ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };

TO_QSPI const int16_t menu_HIST[]   = {
                                             ITM_HISTOX,                    ITM_HISTOY,                 ITM_LOBIN,                ITM_nBINS,             ITM_HIBIN,                   ITM_HPLOT,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };

TO_QSPI const int16_t menu_HPLOT[]   = {
                                             ITM_HNORM,                     ITM_PLOTZOOM,               ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };

TO_QSPI const int16_t menu_STK[]         = { ITM_Rdown,                     ITM_DROP,                   ITM_DROPY,                ITM_LASTX,             ITM_FILL,                    ITM_CLSTK,
                                             ITM_Rup,                       ITM_Xex,                    ITM_Yex,                  ITM_Zex,               ITM_Tex,                     ITM_SHUFFLE                   };

/*      Menu name                           <----------------------------------------------------------------------------- 6 functions ---------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 f shifted functions ------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 g shifted functions ------------------------------------------------------------------------->  */
TO_QSPI const int16_t menu_TEST[]        = { ITM_XLT,                       ITM_XLE,                    ITM_XEQU,                 ITM_XNE,               ITM_XGE,                     ITM_XGT,
                                             ITM_INT,                       ITM_EVEN,                   ITM_ODD,                  ITM_PRIME,             ITM_LEAP,                    ITM_FPQ,
                                             ITM_ENTRY,                     ITM_KEYQ,                   ITM_LBLQ,                 ITM_STRI,              ITM_CONVG,                   ITM_TOP,
                                             ITM_XEQUP0,                    ITM_XEQUM0,                 ITM_XAEQU,                ITM_MATR,              ITM_CPX,                     ITM_REAL,
                                             ITM_SPEC,                      ITM_NAN,                    ITM_NULL,                 ITM_M_SQR,             ITM_NULL,                    ITM_NULL                      };

TO_QSPI const int16_t menu_XFN[]         = { ITM_AGM,                       ITM_BN,                     ITM_BNS,                  ITM_ERF,              -MNU_ELLIPT,                 -MNU_ORTHOG,
                                             ITM_ERFC,                      ITM_FIB,                    ITM_GD,                   ITM_GDM1,              ITM_IXYZ,                    ITM_IGAMMAP,
                                             ITM_IGAMMAQ,                   ITM_JYX,                    ITM_LNBETA,               ITM_LNGAMMA,           ITM_MAX,                     ITM_MIN,
                                             ITM_NEXTP,                     ITM_WM,                     ITM_WP,                   ITM_WM1,               ITM_YYX,                     ITM_BETAXY,
                                             ITM_gammaXY,                   ITM_GAMMAXY,                ITM_zetaX,                ITM_M1X,               ITM_LINPOL,                  ITM_PARALLEL,
                                             ITM_EE_EXP_TH,                 ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };

TO_QSPI const int16_t menu_Orthog[]      = { ITM_HN,                        ITM_Lm,                     ITM_LmALPHA,              ITM_Pn,                ITM_Tn,                      ITM_Un,
                                             ITM_HNP,                       ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };

TO_QSPI const int16_t menu_Ellipt[]      = { ITM_sn,                        ITM_cn,                     ITM_dn,                   ITM_Kk,                ITM_Ek,                      ITM_PInk,
                                             ITM_am,                        ITM_NULL,                   ITM_NULL,                 ITM_Fphik,             ITM_Ephik,                   ITM_ZETAphik                                        };

/*      Menu name                           <----------------------------------------------------------------------------- 6 functions ---------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 f shifted functions ------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 g shifted functions ------------------------------------------------------------------------->  */
TO_QSPI const int16_t menu_CATALOG[]     = { -MNU_FCNS,                    -MNU_CONST,                  -MNU_CHARS,               -MNU_PROGS,            -MNU_VARS,                   -MNU_MENUS                    };

TO_QSPI const int16_t menu_CHARS[]       = { -MNU_ALPHAINTL,               -MNU_ALPHA_OMEGA,            ITM_NULL,                 -MNU_ALPHAMATH,        -MNU_MyAlpha,                -MNU_ALPHAMISC                  };

TO_QSPI const int16_t menu_VARS[]        = { -MNU_LINTS,                    -MNU_SINTS,                 -MNU_REALS,               -MNU_CPXS,             -MNU_STRINGS,                -MNU_MATRS,
                                             -MNU_DATES,                    -MNU_TIMES,                 -MNU_ANGLES,              ITM_NULL,              ITM_NULL,                    ITM_NULL                      };

TO_QSPI const int16_t menu_DELITM[]      = { ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 -MNU_PROGS,            -MNU_VARS,                   -MNU_MENUS                    };

/*      Menu name                           <----------------------------------------------------------------------------- 6 functions ---------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 f shifted functions ------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 g shifted functions ------------------------------------------------------------------------->  */
// Following menu is UPPER CASE for lower case: +(ITM_alpha - ITM_ALPHA)
TO_QSPI const int16_t menu_ALPHA_OMEGA[] = { ITM_ALPHA,                     ITM_BETA,                   ITM_GAMMA,                ITM_DELTA,             ITM_EPSILON,                 ITM_DIGAMMA,
                                             ITM_ZETA,                      ITM_ETA,                    ITM_THETA,                ITM_IOTA,              ITM_KAPPA,                   ITM_LAMBDA,
                                             ITM_MU,                        ITM_NU,                     ITM_XI,                   ITM_OMICRON,           ITM_PI,                      ITM_QOPPA,

                                             ITM_RHO,                       ITM_SIGMA,                  ITM_TAU,                  ITM_UPSILON,           ITM_PHI,                     ITM_CHI,
                                             ITM_PSI,                       ITM_OMEGA,                  ITM_SAMPI,                ITM_NULL,              ITM_NULL,                    ITM_NULL,                           //JM modified greek sequence
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,

                                             ITM_IOTA_DIALYTIKA,            ITM_NULL,                   ITM_NULL,                 ITM_UPSILON_DIALYTIKA, ITM_NULL,                    ITM_NULL                      };

TO_QSPI const int16_t menu_alpha_omega[] = { ITM_alpha,                     ITM_beta,                   ITM_gamma,                ITM_delta,             ITM_epsilon,                 ITM_digamma,
                                             ITM_zeta,                      ITM_eta,                    ITM_theta,                ITM_iota,              ITM_kappa,                   ITM_lambda,
                                             ITM_mu,                        ITM_nu,                     ITM_xi,                   ITM_omicron,           ITM_pi,                      ITM_qoppa,

                                             ITM_rho,                       ITM_sigma,                  ITM_tau,                  ITM_upsilon,           ITM_phi,                     ITM_chi,
                                             ITM_psi,                       ITM_omega,                  ITM_sampi,                ITM_NULL,              ITM_NULL,                    ITM_NULL,
                                             ITM_alpha_TONOS,               ITM_epsilon_TONOS,          ITM_eta_TONOS,            ITM_iotaTON,           ITM_iota_DIALYTIKA_TONOS,    ITM_NULL,                           //JM modified greek sequence

                                             ITM_iota_DIALYTIKA,            ITM_omicron_TONOS,          ITM_upsilon_TONOS,        ITM_upsilon_DIALYTIKA, ITM_upsilon_DIALYTIKA_TONOS, ITM_omega_TONOS               };

TO_QSPI const int16_t menu_AngleConv_43S[]= {ITM_DEG2,                      ITM_RAD2,                   ITM_GRAD2,                ITM_DMS2,              ITM_MULPI2,                 -MNU_TRI,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_dotD,                    ITM_msTo,
                                             ITM_DEG,                       ITM_RAD,                    ITM_GRAD,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };



/*      Menu name                           <----------------------------------------------------------------------------- 6 functions ---------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 f shifted functions ------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 g shifted functions ------------------------------------------------------------------------->  */




//This Section is generated by UNIT and Submenu Changes documenb  0
TO_QSPI const int16_t menu_UnitConv[]        = {
                                                    -MNU_CONVE,               -MNU_CONVM,               -MNU_MISC,                -MNU_CONVX,               -MNU_CONVA,               -MNU_CONVV,
                                                    -MNU_CONVP,               -MNU_CONVYMMV,            -MNU_CONVANG,             -MNU_CONVS,               -MNU_CONVFP,              -MNU_CONVHUM,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL};
TO_QSPI const int16_t menu_ConvA[]        = {
                                                    ITM_ACtoHA,               ITM_HAtoAC,               ITM_HECTAREtoM2,          ITM_M2toHECTARE,          ITM_MI2toKM2,             ITM_KM2toMI2,
                                                    ITM_ACUStoHA,             ITM_HAtoACUS,             ITM_MUtoM2,               ITM_M2toMU,               ITM_NMI2toKM2,            ITM_KM2toNMI2,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL};
TO_QSPI const int16_t menu_ConvE[]        = {
                                                    ITM_WHtoJ,                ITM_JtoWH,                ITM_CALtoJ,               ITM_JtoCAL,               ITM_BTUtoJ,               ITM_JtoBTU,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL};
TO_QSPI const int16_t menu_ConvFP[]        = {
                                                    ITM_MMHGtoPA,             ITM_PAtoMMHG,             ITM_INCHHGtoPA,           ITM_PAtoINCHHG,           ITM_LBFtoN,               ITM_NtoLBF,
                                                    ITM_ATMtoPA,              ITM_PAtoATM,              ITM_PSItoPA,              ITM_PAtoPSI,              ITM_NULL,                 ITM_NULL,
                                                    ITM_BARtoPA,              ITM_PAtoBAR,              ITM_TORtoPA,              ITM_PAtoTOR,              ITM_NULL,                 ITM_NULL};
TO_QSPI const int16_t menu_ConvM[]        = {
                                                    ITM_LBStoKG,              ITM_KGtoLBS,              ITM_CWTtoKG,              ITM_KGtoCWT,              ITM_OZtoG,                ITM_GtoOZ,
                                                    ITM_STOtoKG,              ITM_KGtoSTO,              ITM_SCWtoKG,              ITM_KGtoSCW,              ITM_TRZtoG,               ITM_GtoTRZ,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,
                                                    ITM_TONtoKG,              ITM_KGtoTON,              ITM_STtoKG,               ITM_KGtoST,               ITM_CARATtoG,             ITM_GtoCARAT,
                                                    ITM_JINtoKG,              ITM_KGtoJIN,              ITM_LIANGtoKG,            ITM_KGtoLIANG,            ITM_NULL,                 ITM_NULL,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL};
TO_QSPI const int16_t menu_Misc[]        = {
                                                    ITM_YEARtoS,              ITM_StoYEAR,              ITM_CtoF,                 ITM_FtoC,                 ITM_FRtoDB,               ITM_DBtoFR,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_PRtoDB,               ITM_DBtoPR,
                                                    ITM_NMtoLBFFT,            ITM_LBFFTtoNM,            ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL};
TO_QSPI const int16_t menu_ConvP[]        = {
                                                    ITM_HPEtoW,               ITM_WtoHPE,               ITM_HPUKtoW,              ITM_WtoHPUK,              ITM_HPMtoW,               ITM_WtoHPM,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL};
TO_QSPI const int16_t menu_ConvX[]        = {
                                                    ITM_MItoKM,               ITM_KMtoMI,               ITM_YDtoM,                ITM_MtoYD,                ITM_PCtoM,                ITM_MtoPC,
                                                    ITM_NMItoKM,              ITM_KMtoNMI,              ITM_FTtoM,                ITM_MtoFT,                ITM_LYtoM,                ITM_MtoLY,
                                                    ITM_NMItoMI,              ITM_MItoNMI,              ITM_INCHtoMM,             ITM_MMtoINCH,             ITM_AUtoM,                ITM_MtoAU,
                                                    ITM_LItoM,                ITM_MtoLI,                ITM_YINtoM,               ITM_MtoYIN,               ITM_NULL,                 ITM_NULL,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_ZHANGtoM,             ITM_MtoZHANG,             ITM_CUNtoM,               ITM_MtoCUN,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_CHItoM,               ITM_MtoCHI,               ITM_FENtoM,               ITM_MtoFEN,
                                                    ITM_MILEtoM,              ITM_MtoMILE,              ITM_FTUStoM,              ITM_MtoFTUS,              ITM_POINTtoMM,            ITM_MMtoPOINT,
                                                    ITM_NMItoM,               ITM_MtoNMI,               ITM_FATHOMtoM,            ITM_MtoFATHOM,            ITM_NULL,                 ITM_NULL,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL};
TO_QSPI const int16_t menu_ConvV[]        = {
                                                    ITM_GLUKtoL,              ITM_LtoGLUK,              ITM_GLUStoL,              ITM_LtoGLUS,              ITM_QTtoL,                ITM_LtoQT,
                                                    ITM_FZUKtoML,             ITM_MLtoFZUK,             ITM_FZUStoML,             ITM_MLtoFZUS,             ITM_BARRELtoM3,           ITM_M3toBARREL,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL};
TO_QSPI const int16_t menu_ConvS[]        = {
                                                    ITM_KNOTtoKMH,            ITM_KMHtoKNOT,            ITM_KMHtoMPS,             ITM_MPStoKMH,             ITM_RPMtoDEGPS,           ITM_DEGPStoRPM,
                                                    ITM_MPHtoKMH,             ITM_KMHtoMPH,             ITM_MPHtoMPS,             ITM_MPStoMPH,             ITM_RPMtoRADPS,           ITM_RADPStoRPM,
                                                    ITM_FPStoKMH,             ITM_KMHtoFPS,             ITM_FTPtoMPS,             ITM_MPStoFPS,             ITM_NULL,                 ITM_NULL};
TO_QSPI const int16_t menu_ConvAng[]        = {
                                                    ITM_DEGtoRAD,             ITM_RADtoDEG,             ITM_DEGtoGRAD,            ITM_GRADtoDEG,            ITM_GRADtoRAD,            ITM_RADtoGRAD,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,
                                                    ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL,                 ITM_NULL};

TO_QSPI const int16_t menu_ConvHum[]        = {
                                                    ITM_FURtoM  ,             ITM_MtoFUR  ,             ITM_FTNtoS ,              ITM_StoFTN ,              ITM_FPFtoMPS,             ITM_MPStoFPF,
                                                    ITM_BRDStoM ,             ITM_MtoBRDS ,             ITM_FIRtoKG,              ITM_KGtoFIR,              ITM_FPFtoKPH,             ITM_KPHtoFPF,
                                                    ITM_BRDStoIN,             ITM_INtoBRDS,             ITM_FIRtoLB,              ITM_LBtoFIR,              ITM_FPFtoMPH,             ITM_MPHtoFPF};

TO_QSPI const int16_t menu_ConvYmmv[]       = {
                                                    ITM_L100toKML,            ITM_KMLtoL100,            ITM_KMLEtoK100K,          ITM_K100KtoKMLE,          ITM_K100KtoKMK,           ITM_KMKtoK100K,            
                                                    ITM_L100toMGUS,           ITM_MGUStoL100,           ITM_MGEUStoK100M,         ITM_K100MtoMGEUS,         ITM_K100MtoK100K,         ITM_K100KtoK100M,          
                                                    ITM_L100toMGUK,           ITM_MGUKtoL100,           ITM_MGEUKtoK100M,         ITM_K100MtoMGEUK,         ITM_K100MtoMIK,           ITM_MIKtoK100M};

//---------//---------//---------//---------//---------



TO_QSPI const int16_t menu_alphaFN[]     = { ITM_XtoALPHA,                  ITM_ALPHARL,                ITM_ALPHARR,              ITM_ALPHASL,           ITM_ALPHASR,                 ITM_ALPHAtoX,
                                             ITM_FBR,                       ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_ALPHALENG,               ITM_ALPHAPOS,
                                             ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };

/*      Menu name                           <----------------------------------------------------------------------------- 6 functions ---------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 f shifted functions ------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 g shifted functions ------------------------------------------------------------------------->  */


TO_QSPI const int16_t menu_alphaMATH[]   = { ITM_LESS_THAN,             ITM_LESS_EQUAL,            ITM_EQUAL,                 ITM_NOT_EQUAL,             ITM_GREATER_EQUAL,         ITM_GREATER_THAN,          
                                             ITM_LEFT_CURLY_BRACKET,    ITM_LEFT_SQUARE_BRACKET,   ITM_LEFT_PARENTHESIS,      ITM_RIGHT_PARENTHESIS,     ITM_RIGHT_SQUARE_BRACKET,  ITM_RIGHT_CURLY_BRACKET,   
                                             ITM_BACK_SLASH,            ITM_SLASH,                 ITM_OBELUS,                ITM_CROSS,                 ITM_MINUS,                 ITM_PLUS,                  

                                             ITM_CIRCUMFLEX,            ITM_SQUARE_ROOT,           ITM_CUBE_ROOT,             ITM_xTH_ROOT,              ITM_x_UNDER_ROOT,          ITM_y_UNDER_ROOT,          
                                             ITM_NOT,                   ITM_AND,                   ITM_OR,                    ITM_XOR,                   ITM_NAND,                  ITM_NOR,                   
                                             ITM_TILDE,                 ITM_ALMOST_EQUAL,          ITM_ASYMPOTICALLY_EQUAL,   ITM_IDENTICAL_TO,          ITM_COLON_EQUALS,          ITM_PLUS_MINUS,            

                                             ITM_POLAR_char,            ITM_RIGHT_ANGLE,           ITM_MEASURED_ANGLE,        ITM_ANGLE,                 ITM_AMPERSAND,             ITM_PIPE,                  
                                             ITM_DEGREE,                ITM_RIGHT_SINGLE_QUOTE,    ITM_RIGHT_DOUBLE_QUOTE,    ITM_RIGHT_TACK,            ITM_PERPENDICULAR,         ITM_PARALLEL_SIGN,              
                                             ITM_x_BAR,                 ITM_y_BAR,                 ITM_x_CIRC,                ITM_y_CIRC,                ITM_BULLET,                ITM_RING,                  

                                             ITM_EulerE,                ITM_pi,                    ITM_op_i_char,             ITM_op_j_char,             ITM_PLANCK,                ITM_PLANCK_2PI,                
                                             ITM_SUM_char,              ITM_PRODUCT_char,          ITM_MICRO,                 ITM_OMEGA,                 ITM_DIRECT_CURRENT,        ITM_ALTERN_CURRENT,        
                                             ITM_INTEGRAL_SIGN,         ITM_DOUBLE_INTEGRAL,       ITM_PARTIAL_DIFF,          ITM_INCREMENT,             ITM_NABLA,                 ITM_GAMMA,                 

                                             ITM_FOR_ALL,               ITM_THERE_EXISTS,          ITM_THERE_DOES_NOT_EXIST,  ITM_ELEMENT_OF,            ITM_NOT_ELEMENT_OF,        ITM_CONTAINS,              
                                             ITM_EMPTY_SET,             ITM_UNION,                 ITM_INTERSECTION,          ITM_SUBSET_OF,             ITM_NOT_SUBSET_OF,         ITM_COMPLEMENT,            
                                             ITM_COMPLEX_C,             ITM_IRRATIONAL_I,          ITM_NATURAL_N,             ITM_RATIONAL_Q,            ITM_REAL_R,                ITM_INTEGER_Z,

                                             ITM_MAT_BL,                ITM_MAT_BR,                ITM_ONE_QUARTER,           ITM_ONE_HALF,              ITM_PROPORTIONAL,          ITM_INFINITY,              
                                             ITM_MAT_ML,                ITM_MAT_MR,                ITM_SUP_T,                 ITM_SUB_MINUS,             ITM_SUB_PLUS,              ITM_SUB_INFINITY,          
                                             ITM_MAT_TL,                ITM_MAT_TR,                ITM_SUP_MINUS_1,           ITM_SUP_MINUS,             ITM_SUP_PLUS,              ITM_SUP_INFINITY        };




/*      Menu name                           <----------------------------------------------------------------------------- 6 functions ---------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 f shifted functions ------------------------------------------------------------------------->  */
/*                                          <---------------------------------------------------------------------- 6 g shifted functions ------------------------------------------------------------------------->  */

TO_QSPI const int16_t menu_alphaMisc[]    = { ITM_NUMBER_SIGN,          ITM_AT,                    ITM_AMPERSAND,             ITM_PERCENT,               ITM_QUOTE,                 ITM_DOUBLE_QUOTE,          
                                             ITM_DOLLAR,                ITM_EURO,                  ITM_POUND,                 ITM_YEN,                   ITM_INVERTED_EXCLAMATION_MARK,       ITM_INVERTED_QUESTION_MARK,
                                             ITM_PERIOD,                ITM_COMMA,                 ITM_SEMICOLON,             ITM_COLON,                 ITM_EXCLAMATION_MARK,      ITM_QUESTION_MARK,         

                                             ITM_UP_ARROW,              ITM_DOWN_ARROW,            ITM_SERIAL_IO,             ITM_LEFT_RIGHT_ARROWS,     ITM_LEFT_ARROW,            ITM_RIGHT_ARROW,           
                                             ITM_UP_DASHARROW,          ITM_DOWN_DASHARROW,        ITM_RIGHT_DOUBLE_ARROW,    ITM_LEFT_RIGHT_DOUBLE_ARROW,ITM_LEFT_DASHARROW,        ITM_RIGHT_DASHARROW,       
                                             ITM_LEFT_DOUBLE_QUOTE,     ITM_RIGHT_DOUBLE_QUOTE,    ITM_RIGHT_SHORT_ARROW,     ITM_ex,                    ITM_LEFT_DOUBLE_ANGLE,     ITM_RIGHT_DOUBLE_ANGLE,    

                                             ITM_SECTION,               ITM_CHECK_MARK,            ITM_BULLET,                ITM_ASTERISK,              ITM_SUP_ASTERISK,          ITM_TILDE,                 
                                             ITM_HOURGLASS,             ITM_WATCH,                 ITM_TIMER_SYMBOL,          ITM_NEG_EXCLAMATION_MARK,  ITM_USER_MODE,             ITM_BATTERY,               
                                             ITM_PRINTER,               ITM_HAMBURGER,             ITM_BST_char,              ITM_SST_char,              ITM_CYCLIC,                ITM_USB_SYMBOL,            

                                             ITM_SUB_SUN,               ITM_SUB_EARTH,             ITM_NULL,                  ITM_NULL,                  ITM_US,                    ITM_UK,                    
                                             ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  
                                             ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL     };


TO_QSPI const int16_t menu_1stDeriv[]    = { ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };
TO_QSPI const int16_t menu_2ndDeriv[]    = { ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };
TO_QSPI const int16_t menu_Sf[]          = { ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };
TO_QSPI const int16_t menu_Solver[]      = { ITM_NULL,                      ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };
TO_QSPI const int16_t menu_IO[]          = { ITM_WRITEP,                    ITM_SAVEST,                 ITM_SAVE,                 ITM_LOADP,             ITM_LOADR,                   ITM_LOADV,
                                             ITM_READP,                     ITM_LOADST,                 ITM_LOAD,                 ITM_LOADSIGMA,         ITM_LOADSS,                  ITM_VOLMINUS,
                                             ITM_EXPORTP,                   ITM_BEEP,                   ITM_TONE,                 ITM_BUZZ,              ITM_PLAY,                    ITM_VOLPLUS                   };   //DL
TO_QSPI const int16_t menu_PRINT[]       = { ITM_PRINTERX,                  ITM_PRINTERR,               ITM_PRINTERSIGMA,         ITM_PRINTERADV,        ITM_PRINTERLCD,              ITM_PRINTERPROG,
                                             ITM_PRINTERSTK,                ITM_PRINTERREGS,            ITM_PRINTERUSER,          ITM_PRINTERTAB,        ITM_PRINTERHASH,             ITM_PRINTERCHAR,
                                             ITM_PRTACT,                    ITM_P_ALLREGS,              ITM_NULL,                 ITM_PRINTERWIDTH,      ITM_PRINTERDLAY,             ITM_PRINTERMODE               };
TO_QSPI const int16_t menu_Tam[]         = { ITM_INDIRECTION,               -MNU_VAR,                   ITM_REG_X,                ITM_REG_Y,             ITM_REG_Z,                   ITM_REG_T                     };
TO_QSPI const int16_t menu_TamAlpha[] =    { ITM_INDIRECTION,               -MNU_VAR,                   ITM_REG_X,                ITM_REG_Y,             ITM_REG_Z,                   ITM_REG_T,
                                             ITM_NULL,                      ITM_NULL,                   CHR_num,                  CHR_case,              ITM_NULL,                    ITM_NULL,                          //JM
                                             ITM_NULL,                      ITM_NULL,                  -MNU_MyAlpha,             -MNU_ALPHA_OMEGA,      -MNU_ALPHAMISC,               -MNU_ALPHAMATH                 };   //JM
TO_QSPI const int16_t menu_TamCmp[]      = { ITM_INDIRECTION,               -MNU_VAR,                   ITM_REG_X,                ITM_REG_Y,             ITM_REG_Z,                   ITM_REG_T,
                                             ITM_0P,                        ITM_1P,                     ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };
TO_QSPI const int16_t menu_TamCmpAlpha[] = { ITM_INDIRECTION,               -MNU_VAR,                   ITM_REG_X,                ITM_REG_Y,             ITM_REG_Z,                   ITM_REG_T,
                                             ITM_0P,                        ITM_1P,                     CHR_num,                  CHR_case,              ITM_NULL,                    ITM_NULL,                          //JM
                                             ITM_NULL,                      ITM_NULL,                  -MNU_MyAlpha,             -MNU_ALPHA_OMEGA,      -MNU_ALPHAMISC,               -MNU_ALPHAMATH                 };   //JM
TO_QSPI const int16_t menu_TamFlag[]     = { ITM_INDIRECTION,               -MNU_SYSFL,                 ITM_REG_X,                ITM_REG_Y,             ITM_REG_Z,                   ITM_REG_T                     };
TO_QSPI const int16_t menu_TamNonReg[]   = { ITM_INDIRECTION,               ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };
TO_QSPI const int16_t menu_TamNonRegInd[]= { ITM_NULL,                      -MNU_VAR,                   ITM_REG_X,                ITM_REG_Y,             ITM_REG_Z,                   ITM_REG_T                     };

TO_QSPI const int16_t menu_TamStoRcl[]   = { ITM_INDIRECTION,               -MNU_VAR,                   ITM_REG_X,                ITM_REG_Y,             ITM_REG_Z,                   ITM_REG_T,
                                             ITM_Config,                    ITM_Stack,                  ITM_NULL,                 ITM_NULL,              ITM_Max,                     ITM_Min,
                                             ITM_dddEL,                     ITM_dddIJ,                  ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL                      };
TO_QSPI const int16_t menu_TamStoRclAlpha[]={ITM_INDIRECTION,               -MNU_VAR,                   ITM_REG_X,                ITM_REG_Y,             ITM_REG_Z,                   ITM_REG_T,
                                             ITM_Config,                    ITM_Stack,                  CHR_num,                  CHR_case,              ITM_Max,                     ITM_Min,
                                             ITM_dddEL,                     ITM_dddIJ,                 -MNU_MyAlpha,             -MNU_ALPHA_OMEGA,      -MNU_ALPHAMISC,               -MNU_ALPHAMATH                 };

TO_QSPI const int16_t menu_TamShuffle[]  = { ITM_NULL,                      ITM_NULL,                   ITM_REG_X,                ITM_REG_Y,             ITM_REG_Z,                   ITM_REG_T                     };

TO_QSPI const int16_t menu_TamLabel[]    = { ITM_INDIRECTION,               -MNU_PROG,                  ITM_REG_X,                ITM_REG_Y,             ITM_REG_Z,                   ITM_REG_T                     };
TO_QSPI const int16_t menu_TamLblAlpha[] = { ITM_INDIRECTION,               -MNU_PROG,                  ITM_REG_X,                ITM_REG_Y,             ITM_REG_Z,                   ITM_REG_T,
                                             ITM_NULL,                      ITM_NULL,                   CHR_num,                  CHR_case,              ITM_NULL,                    ITM_NULL,                          //JM
                                             ITM_NULL,                      ITM_NULL,                  -MNU_MyAlpha,             -MNU_ALPHA_OMEGA,      -MNU_ALPHAMISC,               -MNU_ALPHAMATH                 };   //JM



TO_QSPI const int16_t menu_Eim[]         = { 
                                             ITM_LEFT_PARENTHESIS,      ITM_RIGHT_PARENTHESIS,     ITM_CIRCUMFLEX,            ITM_ROOT_SIGN,             ITM_EQ_LEFT,               ITM_EQ_RIGHT,              
                                             ITM_ALOG_SYMBOL,           ITM_EQUAL,                 ITM_SCR,                   CHR_num,                   CHR_case,                  ITM_COLON,                 
                                             ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  

                                             ITM_sin,                   ITM_cos,                   ITM_tan,                   ITM_pi,                    ITM_EQ_LEFT,               ITM_EQ_RIGHT,              
                                             ITM_arcsin,                ITM_arccos,                ITM_arctan,                ITM_op_j_SIGN,             ITM_atan2,                 ITM_XSWAP,                 
                                             ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  

                                             ITM_VERTICAL_BAR,          ITM_ARG,                   ITM_RE,                    ITM_IM,                    ITM_EQ_LEFT,               ITM_EQ_RIGHT,              
                                             ITM_FLOOR,                 ITM_CEIL,                  ITM_MAX,                   ITM_MIN,                   -MNU_CONST,                ITM_XSWAP,                 
                                             ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  

                                             ITM_LOGXY,                 ITM_LOG10,                 ITM_LN,                    ITM_LOG2,                  ITM_EQ_LEFT,               ITM_EQ_RIGHT,              
                                             ITM_FIB,                   ITM_COMB,                  ITM_PERM,                  ITM_EXCLAMATION_MARK,      ITM_sinc,                  ITM_sincpi,                
                                             ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  

                                             ITM_sinh,                  ITM_cosh,                  ITM_tanh,                  ITM_IDIV,                  ITM_EQ_LEFT,               ITM_EQ_RIGHT,              
                                             ITM_arsinh,                ITM_arcosh,                ITM_artanh,                ITM_MOD,                   ITM_RMD,                   ITM_XSWAP,                 
                                             ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  

                                             ITM_GAMMAX,                ITM_HN,                    ITM_Lm,                    ITM_Pn,                    ITM_EQ_LEFT,               ITM_EQ_RIGHT,              
                                             ITM_LNGAMMA,               ITM_HNP,                   ITM_Un,                    ITM_Tn,                    ITM_poly_SIGN,             ITM_XSWAP,                 
                                             ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  

                                             ITM_BN,                    ITM_ERF,                   ITM_WP,                    ITM_zetaX,                 ITM_EQ_LEFT,               ITM_EQ_RIGHT,              
                                             ITM_BNS,                   ITM_ERFC,                  ITM_WM1,                   ITM_WM,                    -MNU_CHARS,                ITM_XSWAP,                 
                                             ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  

                                            };



TO_QSPI const int16_t menu_Timer[]       = { ITM_TIMER_ADD,                 ITM_NULL,                   ITM_NULL,                 ITM_TIMER_0_1S,        ITM_NULL,                    ITM_TIMER_RESET               };



TO_QSPI const int16_t menu_BASE[]        = { ITM_2HEX,                      ITM_2DEC,                   ITM_2OCT,                 ITM_2BIN,              ITM_HASH_JM,                 ITM_LINT,                                   //JM BASE MENU ADDED
                                             ITM_LOGICALAND,                ITM_LOGICALOR,              ITM_LOGICALXOR,           ITM_LOGICALNOT,        ITM_CB_LEADING_ZERO,         ITM_HPBASE,
                                             ITM_WS64,                      ITM_WS32,                   ITM_WS16,                 ITM_WS8,               ITM_WSIZE,                   ITM_BCD,

                                             ITM_SL1,                       ITM_SR1,                    ITM_RL1,                  ITM_RR1,               ITM_RL,                      ITM_RR,
                                             ITM_S64,                       ITM_S32,                    ITM_S16,                  ITM_S08,               ITM_S06,                     ITM_FWORD,
                                             ITM_U64,                       ITM_U32,                    ITM_U16,                  ITM_U08,               ITM_U06,                     ITM_FBYTE,

                                             ITM_A,                         ITM_B,                      ITM_C,                    ITM_D,                 ITM_E,                       ITM_F,
                                             ITM_1COMPL,                    ITM_2COMPL,                 ITM_UNSIGN,               ITM_SIGNMT,            -MNU_BITS,                   -MNU_INTS,
                                             ITM_BCD9,                      ITM_BCD10,                  ITM_BCDU,                 ITM_TOPHEX,            ITM_NULL,                    ITM_NULL                  };    //JM BASE MENU ADDED


TO_QSPI const int16_t menu_EE[]          = { ITM_op_j_pol,                  ITM_op_j,                   ITM_SQUARE,               ITM_op_a,              ITM_op_a2,                   ITM_CLSTK,                          //JM EE
                                             ITM_M_INV,                     ITM_STKTO3x1,               ITM_3x1TOSTK,             ITM_MATX_A,            ITM_PARALLEL,                -MNU_CPX,                           //JM EE
                                             ITM_DEG,                       ITM_DEG2,                   ITM_RAD,                  ITM_RAD2,              ITM_RECT,                    ITM_POLAR,                          //JM EE

                                             ITM_EE_D2Y,                    ITM_EE_Y2D,                 ITM_EE_A2S,               ITM_EE_S2A,            ITM_NULL,                    ITM_CLSTK,                         //JM EE
                                             ITM_EE_STO_V_I,                ITM_EE_STO_IR,              ITM_EE_STO_V_Z,           ITM_EE_X2BAL,          ITM_PARALLEL,                -MNU_CPX,                           //JM EE
                                             ITM_EE_STO_Z,                  ITM_EE_RCL_Z,               ITM_EE_STO_V,             ITM_EE_RCL_V,          ITM_EE_STO_I,                ITM_EE_RCL_I                  };    //JM EE

//#if defined(INLINE_TEST)
TO_QSPI const int16_t menu_Inl_Tst[]     = { ITM_TEST,                      ITM_NULL,                   ITM_NULL,                 ITM_SYS_FREE_RAM,      ITM_GET_TEST_BS,             ITM_SET_TEST_BS               };    //dr
//#endif // INLINE_TEST


#undef DEBUGASN
#if defined(DEBUGASN)
  #define DD_GET_SIGMAPLUS   ITM_GET_NORM_E
  #define DD_SET_SIGMAPLUS   ITM_SH_NORM_E
#else
  #define DD_GET_SIGMAPLUS   ITM_NULL
  #define DD_SET_SIGMAPLUS   ITM_NULL
#endif


TO_QSPI const int16_t menu_ASN_N[]       = { ITM_N_KEY_SIGMA,           ITM_N_KEY_GSH,             ITM_N_KEY_ALPHA,           ITM_N_KEY_HOME,            ITM_N_KEY_MM,              ITM_N_KEY_SNAP,            
                                             ITM_N_KEY_DRG,             ITM_N_KEY_TGLFRT,          ITM_N_KEY_CC,              ITM_N_KEY_PRGM,            ITM_N_KEY_USER,            ITM_USER_COPY,             
                                             ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL,                  ITM_NULL             };

#if defined(DMCP_BUILD)
  #define CC_V47  ITM_NULL
  #define CC_E47  ITM_NULL
  #define CC_D47  ITM_NULL
  #define CC_N47  ITM_NULL
#else // !DMCP_BUILD
  #define CC_V47  ITM_USER_V47
  #define CC_E47  ITM_USER_E47
  #define CC_D47  ITM_USER_D47
  #define CC_N47  ITM_USER_N47
#endif // !DMCP_BUILD


TO_QSPI const int16_t menu_ASN[]       =  { ITM_ASNVIEWER ,                 ITM_USER_C47  ,             ITM_USER_DM42   ,         ITM_USER_WP43S  ,      ITM_ASSIGN      ,            ITM_USERMODE   ,
                                            ITM_BASE_CPX  ,                 ITM_BASE_ENG  ,             ITM_BASE_FIN    ,         ITM_USER_MRESET ,      ITM_USER_ARESET ,            ITM_USER_KRESET ,
                                           -MNU_ASN_N,                      CC_D47,                     CC_E47,                   CC_N47,                CC_V47,                      ITM_NULL                       };


TO_QSPI const int16_t menu_XEQ[]         = { ITM_X_P1,                      ITM_X_P2,                   ITM_X_P3,                 ITM_X_P4,              ITM_X_P5,                    ITM_X_P6,
                                             ITM_X_f1,                      ITM_X_f2,                   ITM_X_f3,                 ITM_X_f4,              ITM_X_f5,                    ITM_X_f6,
                                             ITM_X_g1,                      ITM_X_g2,                   ITM_X_g3,                 ITM_X_g4,              ITM_X_g5,                    ITM_X_g6   };


TO_QSPI const int16_t menu_BLUE_C47[]    = { ITM_MAGNITUDE,       -MNU_CPX,         -MNU_STK,         -MNU_TRG_C47,     -MNU_EXP,         ITM_UNDO,
                                             ITM_ARG,             ITM_DELTAPC,      ITM_XTHROOT,      ITM_op_j,         ITM_toREC2,       ITM_toPOL2,
                                             ITM_TGLFRT,          ITM_HASH_JM,      ITM_ms,           ITM_dotD,         ITM_LBL,          ITM_RTN,

                                             ITM_RI,              ITM_VIEW,         ITM_USERMODE,     ITM_NULL,         ITM_NULL,         ITM_NULL,
                                             ITM_SNAP,            ITM_TIMER,       -MNU_INFO,        -MNU_TEST,        -MNU_CONST,        ITM_NULL,
                                             ITM_NULL,            ITM_NULL,         ITM_NULL,         ITM_NULL,         ITM_NULL,         ITM_NULL,

                                             ITM_NULL,            -MNU_ASN,         -MNU_ALPHAFN,     -MNU_LOOP,        -MNU_IO,          ITM_NULL,
                                             ITM_FLGSV,           -MNU_BITS,        -MNU_CLK,         -MNU_PARTS,       -MNU_INTS,        ITM_NULL,
                                             ITM_RBR,             -MNU_HOME,        -MNU_FIN,         -MNU_XFN,         -MNU_PLOTTING,    ITM_NULL };

#if defined(SAVE_SPACE_DM42_6)
  #define CC_EE  ITM_NULL
#else // !SAVE_SPACE_DM42_6
  #define CC_EE  -MNU_EE
#endif // SAVE_SPACE_DM42_6

TO_QSPI const int16_t menu_HOME[]        = { ITM_DRG,                       ITM_YX,                     ITM_SQUARE,               ITM_10x,               ITM_EXP,                     ITM_op_j,                          //JM HOME
                                             ITM_MOD,                       ITM_RMD,                    ITM_IDIV,                 ITM_XFACT,             ITM_EE_EXP_TH,               ITM_LINPOL,                    //JM HOME
                                             ITM_FP,                        ITM_IP,                     ITM_DEG2,                 ITM_RAD2,              ITM_RECT,                    ITM_POLAR,                          //JM HOME

                                             ITM_SI_k,                      ITM_SI_M,                   ITM_SI_G,                 ITM_SI_T,              ITM_SI_P,                    ITM_DSPCYCLE,
                                             ITM_SI_f,                      ITM_SI_p,                   ITM_SI_n,                 ITM_SI_u,              ITM_SI_m,                    ITM_DSP,
                                            -MNU_EE,                        ITM_PARALLEL,               ITM_DEG2,                 ITM_RAD2,              ITM_RECT,                    ITM_POLAR      };                                                                                                                                                                                   //JM HOME

TO_QSPI const int16_t menu_PLOT[]        = { ITM_PLINE,                     ITM_SCALE,                  ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,                           //JM GRAPH
                                             ITM_DIFF,                      ITM_INTG,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,                           //JM GRAPH
                                             ITM_RMS,                       ITM_SHADE,                  ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,                           //JM GRAPH

                                             ITM_PCROS,                     ITM_PBOX,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,                           //JM GRAPH
                                             ITM_NVECT,                     ITM_VECT,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,                           //JM GRAPH
                                             ITM_EXTY,                      ITM_EXTX,                   ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,                           //JM GRAPH

                                             ITM_PZOOMX,                    ITM_PZOOMY,                 ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,
                                             ITM_SNAP,                      ITM_LISTXY,                 ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL,                           //JM GRAPH
                                             ITM_NULL,                      ITM_PLOTRST,                ITM_NULL,                 ITM_NULL,              ITM_NULL,                    ITM_NULL};                          //JM GRAPH

TO_QSPI const int16_t menu_ALPHA[]       = { ITM_T_UP_ARROW,                ITM_T_DOWN_ARROW,           ITM_T_LLEFT_ARROW,        ITM_T_RRIGHT_ARROW,    ITM_T_LEFT_ARROW,            ITM_T_RIGHT_ARROW,
                                             -MNU_MyAlpha,                 -MNU_ALPHA_OMEGA,           -MNU_ALPHAMATH,            -MNU_ALPHAMISC,        -MNU_ALPHAINTL,              ITM_ASSIGN,                           //JM
                                             ITM_XSWAP,                     ITM_XPARSE,                 ITM_SCR,                  CHR_num,               CHR_case,                    ITM_USERMODE                     };   //JM

TO_QSPI const int16_t menu_XXEQ[]        = { ITM_XSAVE,                     ITM_XLOAD,                  ITM_XSWAP,                ITM_XNEW,              ITM_XXEQ,                     -MNU_XEQ                        };   //JM


TO_QSPI const int16_t menu_GAP_L[]       = { ITM_GAPPER_L,                  ITM_GAPCOM_L,               ITM_GAPDOT_L,             ITM_GAPNARAPO_L,       ITM_GAPSPC_L,                ITM_GAPNIL_L,
                                             ITM_GAPWIDPER_L,               ITM_GAPWIDCOM_L,            ITM_GAPWIDDOT_L,          ITM_GAPAPO_L,          ITM_GAPDBLSPC_L,             ITM_GAPUND_L,
                                             ITM_GRP_L,                     ITM_GRP1_L,                 ITM_GRP1_L_OF,            ITM_NULL,              ITM_GAPNARSPC_L,             ITM_NULL                         };

TO_QSPI const int16_t menu_GAP_RX[]      = { ITM_GAPPER_RX,                 ITM_GAPCOM_RX,              ITM_GAPDOT_RX,            ITM_GAPWIDPER_RX,      ITM_GAPWIDCOM_RX,            ITM_GAPWIDDOT_RX };


TO_QSPI const int16_t menu_GAP_R[]       = { ITM_GAPPER_R,                  ITM_GAPCOM_R,               ITM_GAPDOT_R,             ITM_GAPNARAPO_R,       ITM_GAPSPC_R,                ITM_GAPNIL_R,
                                             ITM_GAPWIDPER_R,               ITM_GAPWIDCOM_R,            ITM_GAPWIDDOT_R,          ITM_GAPAPO_R,          ITM_GAPDBLSPC_R,             ITM_GAPUND_R,
                                             ITM_GRP_R,                     ITM_NULL,                   ITM_NULL,                 ITM_NULL,              ITM_GAPNARSPC_R,             ITM_NULL                         };




#include "softmenuCatalogs.h"

TO_QSPI const softmenu_t softmenu[] = {
/*   0 */  {.menuItem = -MNU_MyMenu,      .numItems = 0,                                        .softkeyItem = NULL             }, // MyMenu must be the 1st
/*   1 */  {.menuItem = -MNU_MyAlpha,     .numItems = 0,                                        .softkeyItem = NULL             }, // Myalpha must be the 2nd
/*   2 */  {.menuItem = -MNU_PROGS,       .numItems = 0,                                        .softkeyItem = NULL             },
/*   3 */  {.menuItem = -MNU_VAR,         .numItems = 0,                                        .softkeyItem = NULL             }, // variable softmenus and
/*   4 */  {.menuItem = -MNU_PROG,        .numItems = 0,                                        .softkeyItem = NULL             }, // MUST be in the same
/*   5 */  {.menuItem = -MNU_MATRS,       .numItems = 0,                                        .softkeyItem = NULL             }, // order as the
/*   6 */  {.menuItem = -MNU_STRINGS,     .numItems = 0,                                        .softkeyItem = NULL             }, // dynamicSoftmenu area.
/*   7 */  {.menuItem = -MNU_DATES,       .numItems = 0,                                        .softkeyItem = NULL             }, //
/*   8 */  {.menuItem = -MNU_TIMES,       .numItems = 0,                                        .softkeyItem = NULL             }, // If you add or remove one:
/*   9 */  {.menuItem = -MNU_ANGLES,      .numItems = 0,                                        .softkeyItem = NULL             }, // don't forget to adjust
/*  10 */  {.menuItem = -MNU_SINTS,       .numItems = 0,                                        .softkeyItem = NULL             }, // NUMBER_OF_DYNAMIC_SOFTMENUS
/*  11 */  {.menuItem = -MNU_LINTS,       .numItems = 0,                                        .softkeyItem = NULL             }, // in defines.h
/*  12 */  {.menuItem = -MNU_REALS,       .numItems = 0,                                        .softkeyItem = NULL             },
/*  13 */  {.menuItem = -MNU_CPXS,        .numItems = 0,                                        .softkeyItem = NULL             },
/*  14 */  {.menuItem = -MNU_MVAR,        .numItems = 0,                                        .softkeyItem = NULL             },
/*  15 */  {.menuItem = -MNU_MENUS,       .numItems = 0,                                        .softkeyItem = NULL             },
/*  16 */  {.menuItem = -MNU_DYNAMIC,     .numItems = 0,                                        .softkeyItem = NULL             },
/*  17 */  {.menuItem = -ITM_MENU,        .numItems = 0,                                        .softkeyItem = NULL             },
/*  18 */  {.menuItem = -MNU_TAMFLAG,     .numItems = sizeof(menu_TamFlag       )/sizeof(int16_t), .softkeyItem = menu_TamFlag        },
/*  19 */  {.menuItem = -MNU_SYSFL,       .numItems = sizeof(menu_SYSFL         )/sizeof(int16_t), .softkeyItem = menu_SYSFL          },
/*  20 */  {.menuItem = -MNU_ALPHAINTL,   .numItems = sizeof(menu_alpha_INTL    )/sizeof(int16_t), .softkeyItem = menu_alpha_INTL     },
/*  21 */  {.menuItem = -MNU_ALPHAintl,   .numItems = sizeof(menu_alpha_intl    )/sizeof(int16_t), .softkeyItem = menu_alpha_intl     },
/*  22 */  {.menuItem = -MNU_ADV,         .numItems = sizeof(menu_ADV           )/sizeof(int16_t), .softkeyItem = menu_ADV            },
/*  23 */  {.menuItem = -MNU_Sfdx,        .numItems = sizeof(menu_Sfdx          )/sizeof(int16_t), .softkeyItem = menu_Sfdx           },
/*  24 */  {.menuItem = -MNU_BITS,        .numItems = sizeof(menu_BITS          )/sizeof(int16_t), .softkeyItem = menu_BITS           },
/*  25 */  {.menuItem = -MNU_CLK,         .numItems = sizeof(menu_CLK           )/sizeof(int16_t), .softkeyItem = menu_CLK            },
/*  26 */  {.menuItem = -MNU_CLR,         .numItems = sizeof(menu_CLR           )/sizeof(int16_t), .softkeyItem = menu_CLR            },
/*  27 */  {.menuItem = -MNU_CPX,         .numItems = sizeof(menu_CPX           )/sizeof(int16_t), .softkeyItem = menu_CPX            },
/*  28 */  {.menuItem = -MNU_DISP,        .numItems = sizeof(menu_DISP          )/sizeof(int16_t), .softkeyItem = menu_DISP           },
/*  29 */  {.menuItem = -MNU_EQN,         .numItems = sizeof(menu_EQN           )/sizeof(int16_t), .softkeyItem = menu_EQN            },
/*  30 */  {.menuItem = -MNU_1STDERIV,    .numItems = sizeof(menu_1stDeriv      )/sizeof(int16_t), .softkeyItem = menu_1stDeriv       },
/*  31 */  {.menuItem = -MNU_2NDDERIV,    .numItems = sizeof(menu_2ndDeriv      )/sizeof(int16_t), .softkeyItem = menu_2ndDeriv       },
/*  32 */  {.menuItem = -MNU_Sf,          .numItems = sizeof(menu_Sf            )/sizeof(int16_t), .softkeyItem = menu_Sf             },
/*  33 */  {.menuItem = -MNU_Solver,      .numItems = sizeof(menu_Solver        )/sizeof(int16_t), .softkeyItem = menu_Solver         },
/*  34 */  {.menuItem = -MNU_EXP,         .numItems = sizeof(menu_EXP           )/sizeof(int16_t), .softkeyItem = menu_EXP            },
/*  35 */  {.menuItem = -MNU_TRI,         .numItems = sizeof(menu_TRI           )/sizeof(int16_t), .softkeyItem = menu_TRI            },
/*  36 */  {.menuItem = -MNU_FIN,         .numItems = sizeof(menu_FIN           )/sizeof(int16_t), .softkeyItem = menu_FIN            },
/*  37 */  {.menuItem = -MNU_TVM,         .numItems = sizeof(menu_TVM           )/sizeof(int16_t), .softkeyItem = menu_TVM            },
/*  38 */  {.menuItem = -MNU_FLAGS,       .numItems = sizeof(menu_FLAGS         )/sizeof(int16_t), .softkeyItem = menu_FLAGS          },
/*  39 */  {.menuItem = -MNU_INFO,        .numItems = sizeof(menu_INFO          )/sizeof(int16_t), .softkeyItem = menu_INFO           },
/*  40 */  {.menuItem = -MNU_INTS,        .numItems = sizeof(menu_INTS          )/sizeof(int16_t), .softkeyItem = menu_INTS           },
/*  41 */  {.menuItem = -MNU_LOOP,        .numItems = sizeof(menu_LOOP          )/sizeof(int16_t), .softkeyItem = menu_LOOP           },
/*  42 */  {.menuItem = -MNU_MATX,        .numItems = sizeof(menu_MATX          )/sizeof(int16_t), .softkeyItem = menu_MATX           },
/*  43 */  {.menuItem = -MNU_SIMQ,        .numItems = sizeof(menu_M_SIM_Q       )/sizeof(int16_t), .softkeyItem = menu_M_SIM_Q        },
/*  44 */  {.menuItem = -MNU_M_EDIT,      .numItems = sizeof(menu_M_EDIT        )/sizeof(int16_t), .softkeyItem = menu_M_EDIT         },
/*  45 */  {.menuItem = -MNU_MODE,        .numItems = sizeof(menu_MODE          )/sizeof(int16_t), .softkeyItem = menu_MODE           },
/*  46 */  {.menuItem = -MNU_PARTS,       .numItems = sizeof(menu_PARTS         )/sizeof(int16_t), .softkeyItem = menu_PARTS          },

/*  48 */  {.menuItem = -MNU_PROB,        .numItems = sizeof(menu_PROB          )/sizeof(int16_t), .softkeyItem = menu_PROB           },
/*  49 */  {.menuItem = -MNU_T,           .numItems = sizeof(menu_t             )/sizeof(int16_t), .softkeyItem = menu_t              },
/*  50 */  {.menuItem = -MNU_F,           .numItems = sizeof(menu_F             )/sizeof(int16_t), .softkeyItem = menu_F              },
/*  51 */  {.menuItem = -MNU_CHI2,        .numItems = sizeof(menu_chi2          )/sizeof(int16_t), .softkeyItem = menu_chi2           },
/*  52 */  {.menuItem = -MNU_NORML,       .numItems = sizeof(menu_Norml         )/sizeof(int16_t), .softkeyItem = menu_Norml          },
/*  53 */  {.menuItem = -MNU_LGNRM,       .numItems = sizeof(menu_LgNrm         )/sizeof(int16_t), .softkeyItem = menu_LgNrm          },
/*  54 */  {.menuItem = -MNU_CAUCH,       .numItems = sizeof(menu_Cauch         )/sizeof(int16_t), .softkeyItem = menu_Cauch          },
/*  55 */  {.menuItem = -MNU_EXPON,       .numItems = sizeof(menu_Expon         )/sizeof(int16_t), .softkeyItem = menu_Expon          },
/*  56 */  {.menuItem = -MNU_LOGIS,       .numItems = sizeof(menu_Logis         )/sizeof(int16_t), .softkeyItem = menu_Logis          },
/*  57 */  {.menuItem = -MNU_WEIBL,       .numItems = sizeof(menu_Weibl         )/sizeof(int16_t), .softkeyItem = menu_Weibl          },
/*  58 */  {.menuItem = -MNU_BINOM,       .numItems = sizeof(menu_Binom         )/sizeof(int16_t), .softkeyItem = menu_Binom          },
/*  59 */  {.menuItem = -MNU_GEOM,        .numItems = sizeof(menu_Geom          )/sizeof(int16_t), .softkeyItem = menu_Geom           },
/*  60 */  {.menuItem = -MNU_HYPER,       .numItems = sizeof(menu_Hyper         )/sizeof(int16_t), .softkeyItem = menu_Hyper          },
/*  61 */  {.menuItem = -MNU_NBIN,        .numItems = sizeof(menu_Nbin          )/sizeof(int16_t), .softkeyItem = menu_Nbin           },
/*  62 */  {.menuItem = -MNU_POISS,       .numItems = sizeof(menu_Poiss         )/sizeof(int16_t), .softkeyItem = menu_Poiss          },
/*  63 */  {.menuItem = -MNU_PFN,         .numItems = sizeof(menu_PFN           )/sizeof(int16_t), .softkeyItem = menu_PFN            },
/*  64 */  {.menuItem = -MNU_PFN_MORE,    .numItems = sizeof(menu_PFN_MORE      )/sizeof(int16_t), .softkeyItem = menu_PFN_MORE       },
/*  65 */  {.menuItem = -MNU_STAT,        .numItems = sizeof(menu_STAT          )/sizeof(int16_t), .softkeyItem = menu_STAT           },
/*  66 */  {.menuItem = -MNU_PLOTTING,    .numItems = sizeof(menu_PLOTTING      )/sizeof(int16_t), .softkeyItem = menu_PLOTTING       },

/*  68 */  {.menuItem = -MNU_GRAPH,       .numItems = sizeof(menu_GRAPH         )/sizeof(int16_t), .softkeyItem = menu_GRAPH          },
/*  69 */  {.menuItem = -MNU_PLOT_STAT,   .numItems = sizeof(menu_PLOT_STAT     )/sizeof(int16_t), .softkeyItem = menu_PLOT_STAT      },
/*  70 */  {.menuItem = -MNU_PLOT_LR,     .numItems = sizeof(menu_PLOT_LR       )/sizeof(int16_t), .softkeyItem = menu_PLOT_LR        },
/*  71 */  {.menuItem = -MNU_HPLOT,       .numItems = sizeof(menu_HPLOT         )/sizeof(int16_t), .softkeyItem = menu_HPLOT          },
/*  72 */  {.menuItem = -MNU_HIST,        .numItems = sizeof(menu_HIST          )/sizeof(int16_t), .softkeyItem = menu_HIST           },
/*  73 */  {.menuItem = -MNU_STK,         .numItems = sizeof(menu_STK           )/sizeof(int16_t), .softkeyItem = menu_STK            },
/*  74 */  {.menuItem = -MNU_TEST,        .numItems = sizeof(menu_TEST          )/sizeof(int16_t), .softkeyItem = menu_TEST           },
/*  75 */  {.menuItem = -MNU_XFN,         .numItems = sizeof(menu_XFN           )/sizeof(int16_t), .softkeyItem = menu_XFN            },
/*  76 */  {.menuItem = -MNU_ORTHOG,      .numItems = sizeof(menu_Orthog        )/sizeof(int16_t), .softkeyItem = menu_Orthog         },
/*  77 */  {.menuItem = -MNU_ELLIPT,      .numItems = sizeof(menu_Ellipt        )/sizeof(int16_t), .softkeyItem = menu_Ellipt         },
/*  78 */  {.menuItem = -MNU_CATALOG,     .numItems = sizeof(menu_CATALOG       )/sizeof(int16_t), .softkeyItem = menu_CATALOG        },
/*  79 */  {.menuItem = -MNU_CHARS,       .numItems = sizeof(menu_CHARS         )/sizeof(int16_t), .softkeyItem = menu_CHARS          },
/*  80 */  {.menuItem = -MNU_VARS,        .numItems = sizeof(menu_VARS          )/sizeof(int16_t), .softkeyItem = menu_VARS           },
/*  81 */  {.menuItem = -MNU_ALPHA_OMEGA, .numItems = sizeof(menu_ALPHA_OMEGA   )/sizeof(int16_t), .softkeyItem = menu_ALPHA_OMEGA    },
/*  82 */  {.menuItem = -MNU_alpha_omega, .numItems = sizeof(menu_alpha_omega   )/sizeof(int16_t), .softkeyItem = menu_alpha_omega    },
/*  83 */  {.menuItem = -MNU_FCNS,        .numItems = sizeof(menu_FCNS          )/sizeof(int16_t), .softkeyItem = menu_FCNS           },
/*  84 */  {.menuItem = -MNU_ALPHAMATH,   .numItems = sizeof(menu_alphaMATH     )/sizeof(int16_t), .softkeyItem = menu_alphaMATH      },
/*  85 */  {.menuItem = -MNU_ALPHAMISC,    .numItems = sizeof(menu_alphaMisc      )/sizeof(int16_t), .softkeyItem = menu_alphaMisc       },
/*  86 */  {.menuItem = -MNU_ALPHAFN,     .numItems = sizeof(menu_alphaFN       )/sizeof(int16_t), .softkeyItem = menu_alphaFN        },

/*  88 */  {.menuItem = -MNU_ANGLECONV_43S,.numItems = sizeof(menu_AngleConv_43S)/sizeof(int16_t), .softkeyItem = menu_AngleConv_43S  },
/*  89 */  {.menuItem = -MNU_UNITCONV,    .numItems = sizeof(menu_UnitConv      )/sizeof(int16_t), .softkeyItem = menu_UnitConv       },

/*  91 */  {.menuItem = -MNU_CONVE,       .numItems = sizeof(menu_ConvE         )/sizeof(int16_t), .softkeyItem = menu_ConvE          },
/*  92 */  {.menuItem = -MNU_CONVP,       .numItems = sizeof(menu_ConvP         )/sizeof(int16_t), .softkeyItem = menu_ConvP          },
/*  93 */  {.menuItem = -MNU_CONVFP,      .numItems = sizeof(menu_ConvFP        )/sizeof(int16_t), .softkeyItem = menu_ConvFP         },
/*  94 */  {.menuItem = -MNU_CONVM,       .numItems = sizeof(menu_ConvM         )/sizeof(int16_t), .softkeyItem = menu_ConvM          },
/*  95 */  {.menuItem = -MNU_CONVX,       .numItems = sizeof(menu_ConvX         )/sizeof(int16_t), .softkeyItem = menu_ConvX          },
/*  96 */  {.menuItem = -MNU_CONVV,       .numItems = sizeof(menu_ConvV         )/sizeof(int16_t), .softkeyItem = menu_ConvV          },
/*  97 */  {.menuItem = -MNU_CONVA,       .numItems = sizeof(menu_ConvA         )/sizeof(int16_t), .softkeyItem = menu_ConvA          },
/*  98 */  {.menuItem = -MNU_CONVS,       .numItems = sizeof(menu_ConvS         )/sizeof(int16_t), .softkeyItem = menu_ConvS          },
/*  99 */  {.menuItem = -MNU_CONVANG,     .numItems = sizeof(menu_ConvAng       )/sizeof(int16_t), .softkeyItem = menu_ConvAng        },
/* 100 */  {.menuItem = -MNU_CONVHUM,     .numItems = sizeof(menu_ConvHum       )/sizeof(int16_t), .softkeyItem = menu_ConvHum        },
/* 101 */  {.menuItem = -MNU_CONVYMMV,    .numItems = sizeof(menu_ConvYmmv      )/sizeof(int16_t), .softkeyItem = menu_ConvYmmv       },
/* 102 */  {.menuItem = -MNU_CONST,       .numItems = sizeof(menu_CONST         )/sizeof(int16_t), .softkeyItem = menu_CONST          },
/* 103 */  {.menuItem = -MNU_IO,          .numItems = sizeof(menu_IO            )/sizeof(int16_t), .softkeyItem = menu_IO             },
/* 104 */  {.menuItem = -MNU_PRINT,       .numItems = sizeof(menu_PRINT         )/sizeof(int16_t), .softkeyItem = menu_PRINT          },
/* 105 */  {.menuItem = -MNU_TAM,         .numItems = sizeof(menu_Tam           )/sizeof(int16_t), .softkeyItem = menu_Tam            },
/* 106 */  {.menuItem = -MNU_TAMCMP,      .numItems = sizeof(menu_TamCmp        )/sizeof(int16_t), .softkeyItem = menu_TamCmp         },
/* 107 */  {.menuItem = -MNU_TAMSTORCL,   .numItems = sizeof(menu_TamStoRcl     )/sizeof(int16_t), .softkeyItem = menu_TamStoRcl      },
/* 108 */  {.menuItem = -MNU_TAMSHUFFLE,  .numItems = sizeof(menu_TamShuffle    )/sizeof(int16_t), .softkeyItem = menu_TamShuffle     },
/* 109 */  {.menuItem = -MNU_TAMLABEL,    .numItems = sizeof(menu_TamLabel      )/sizeof(int16_t), .softkeyItem = menu_TamLabel       },
/* 110 */  {.menuItem = -MNU_EQ_EDIT,     .numItems = sizeof(menu_Eim           )/sizeof(int16_t), .softkeyItem = menu_Eim            },
/* 111 */  {.menuItem = -MNU_TIMERF,      .numItems = sizeof(menu_Timer         )/sizeof(int16_t), .softkeyItem = menu_Timer          },
/* 112 */  {.menuItem = -ITM_DELITM,      .numItems = sizeof(menu_DELITM        )/sizeof(int16_t), .softkeyItem = menu_DELITM         },
/* 113 */  {.menuItem = -MNU_ASN_N,       .numItems = sizeof(menu_ASN_N         )/sizeof(int16_t), .softkeyItem = menu_ASN_N          },  //JM USER NORMAL
/* 114 */  {.menuItem = -MNU_ASN,         .numItems = sizeof(menu_ASN           )/sizeof(int16_t), .softkeyItem = menu_ASN            },  //JM USER
/* 115 */  {.menuItem = -MNU_XEQ,         .numItems = sizeof(menu_XEQ           )/sizeof(int16_t), .softkeyItem = menu_XEQ            },  //JM EXEC
/* 116 */  {.menuItem = -MNU_HOME,        .numItems = sizeof(menu_HOME          )/sizeof(int16_t), .softkeyItem = menu_HOME           },  //JM HOME
/* 117 */  {.menuItem = -MNU_PLOT,        .numItems = sizeof(menu_PLOT          )/sizeof(int16_t), .softkeyItem = menu_PLOT           },  //JM GRAPH
/* 118 */  {.menuItem = -MNU_ALPHA,       .numItems = sizeof(menu_ALPHA         )/sizeof(int16_t), .softkeyItem = menu_ALPHA          },  //JM ALPHA
/* 119 */  {.menuItem = -MNU_BASE,        .numItems = sizeof(menu_BASE          )/sizeof(int16_t), .softkeyItem = menu_BASE           },  //JM BASE
/* 120 */  {.menuItem = -MNU_EE,          .numItems = sizeof(menu_EE            )/sizeof(int16_t), .softkeyItem = menu_EE             },  //JM EE
/* 121 */  {.menuItem = -MNU_XXEQ,        .numItems = sizeof(menu_XXEQ          )/sizeof(int16_t), .softkeyItem = menu_XXEQ           },  //JM TEXTEDIT
/* 122 */  {.menuItem = -MNU_TRG,         .numItems = sizeof(menu_TRG           )/sizeof(int16_t), .softkeyItem = menu_TRG            },
/* 123 */  {.menuItem = -MNU_SETUP,       .numItems = sizeof(menu_SETUP         )/sizeof(int16_t), .softkeyItem = menu_SETUP          },
/* 124 */  {.menuItem = -MNU_REGR,        .numItems = sizeof(menu_REGR          )/sizeof(int16_t), .softkeyItem = menu_REGR           },
/* 125 */  {.menuItem = -MNU_MODEL,       .numItems = sizeof(menu_MODEL         )/sizeof(int16_t), .softkeyItem = menu_MODEL          },
/* 126 */  {.menuItem = -MNU_MISC,        .numItems = sizeof(menu_Misc          )/sizeof(int16_t), .softkeyItem = menu_Misc           },
/* 127 */  {.menuItem = -MNU_STDNORML,    .numItems = sizeof(menu_StdNorml      )/sizeof(int16_t), .softkeyItem = menu_StdNorml       },
/* 128 */  {.menuItem = -MNU_TAMALPHA,    .numItems = sizeof(menu_TamAlpha      )/sizeof(int16_t), .softkeyItem = menu_TamAlpha       },
/* 129 */  {.menuItem = -MNU_TAMCMPALPHA, .numItems = sizeof(menu_TamCmpAlpha   )/sizeof(int16_t), .softkeyItem = menu_TamCmpAlpha    },
/* 130 */  {.menuItem = -MNU_TAMLBLALPHA, .numItems = sizeof(menu_TamLblAlpha   )/sizeof(int16_t), .softkeyItem = menu_TamLblAlpha    },
/* 131 */  {.menuItem = -MNU_TAMSRALPHA,  .numItems = sizeof(menu_TamStoRclAlpha)/sizeof(int16_t), .softkeyItem = menu_TamStoRclAlpha },
/* 132 */  {.menuItem = -MNU_TRG_C47,     .numItems = sizeof(menu_TRG_C47       )/sizeof(int16_t), .softkeyItem = menu_TRG_C47        },
/* 133 */  {.menuItem = -MNU_TRG_C47_MORE,.numItems = sizeof(menu_TRG_C47_MORE  )/sizeof(int16_t), .softkeyItem = menu_TRG_C47_MORE   },
/* 134 */  {.menuItem = -MNU_TAMNONREG,   .numItems = sizeof(menu_TamNonReg     )/sizeof(int16_t), .softkeyItem = menu_TamNonReg      },
/* 135 */  {.menuItem = -MNU_TAMNONREGIND,.numItems = sizeof(menu_TamNonRegInd  )/sizeof(int16_t), .softkeyItem = menu_TamNonRegInd   },
/* 136 */  {.menuItem = -MNU_BLUE_C47,    .numItems = sizeof(menu_BLUE_C47      )/sizeof(int16_t), .softkeyItem = menu_BLUE_C47       },
/* 137 */  {.menuItem = -MNU_GAP_L,       .numItems = sizeof(menu_GAP_L         )/sizeof(int16_t), .softkeyItem = menu_GAP_L          },
/* 138 */  {.menuItem = -MNU_GAP_RX,      .numItems = sizeof(menu_GAP_RX        )/sizeof(int16_t), .softkeyItem = menu_GAP_RX         },
/* 139 */  {.menuItem = -MNU_GAP_R,       .numItems = sizeof(menu_GAP_R         )/sizeof(int16_t), .softkeyItem = menu_GAP_R          },
/* 140 */  {.menuItem = -MNU_INL_TST,     .numItems = sizeof(menu_Inl_Tst       )/sizeof(int16_t), .softkeyItem = menu_Inl_Tst        },
/* 141 */  {.menuItem =  0,               .numItems = 0,                                           .softkeyItem = NULL                }
};


dynamicSoftmenu_t dynamicSoftmenu[NUMBER_OF_DYNAMIC_SOFTMENUS] = {
/*   0 */  {.menuItem = -MNU_MyMenu,  .numItems = 0, .menuContent = NULL},
/*   1 */  {.menuItem = -MNU_MyAlpha, .numItems = 0, .menuContent = NULL},
/*   2 */  {.menuItem = -MNU_PROGS,   .numItems = 0, .menuContent = NULL},
/*   3 */  {.menuItem = -MNU_VAR,     .numItems = 0, .menuContent = NULL},
/*   4 */  {.menuItem = -MNU_PROG,    .numItems = 0, .menuContent = NULL},
/*   5 */  {.menuItem = -MNU_MATRS,   .numItems = 0, .menuContent = NULL},
/*   6 */  {.menuItem = -MNU_STRINGS, .numItems = 0, .menuContent = NULL},
/*   7 */  {.menuItem = -MNU_DATES,   .numItems = 0, .menuContent = NULL},
/*   8 */  {.menuItem = -MNU_TIMES,   .numItems = 0, .menuContent = NULL},
/*   9 */  {.menuItem = -MNU_ANGLES,  .numItems = 0, .menuContent = NULL},
/*  10 */  {.menuItem = -MNU_SINTS,   .numItems = 0, .menuContent = NULL},
/*  11 */  {.menuItem = -MNU_LINTS,   .numItems = 0, .menuContent = NULL},
/*  12 */  {.menuItem = -MNU_REALS,   .numItems = 0, .menuContent = NULL},
/*  13 */  {.menuItem = -MNU_CPXS,    .numItems = 0, .menuContent = NULL},
/*  14 */  {.menuItem = -MNU_MVAR,    .numItems = 0, .menuContent = NULL},
/*  15 */  {.menuItem = -MNU_MENUS,   .numItems = 0, .menuContent = NULL},
/*  16 */  {.menuItem = -MNU_DYNAMIC, .numItems = 0, .menuContent = NULL},
/*  17 */  {.menuItem = -ITM_MENU   , .numItems = 0, .menuContent = NULL},
};



uint8_t *getNthString(uint8_t *ptr, int16_t n) { // Starting with string 0 (the 1st string is returned for n=0)
  while(n) {
    ptr += stringByteLength((char *)ptr) + 1;
    n--;
  }

  return ptr;
}



void fnDynamicMenu(uint16_t unusedButMandatoryParameter) {
  printf("fnDynamicMenu:\n       softmenuId = %d\n  dynamicMenuItem = %d\n", softmenuStack[0].softmenuId, dynamicMenuItem);
}



#if !defined(TESTSUITE_BUILD)
  static int sortMenu(void const *a, void const *b) {
    return compareString(a, b, CMP_EXTENSIVE);
  }



  static bool_t _filterDataType(calcRegister_t regist, dataType_t typeFilter, bool_t isAngular) {
    dataType_t dt = getRegisterDataType(regist);
    if(dt != dtReal34 && dt == typeFilter) {
      return true;
    }
    if(typeFilter == dtReal34Matrix && dt == dtComplex34Matrix) {
      return true;
    }
    if(typeFilter == dtReal34 && dt == dtReal34) {
      if(isAngular) {
        return getRegisterAngularMode(regist) != amNone;
      }
      if(!isAngular) {
        return getRegisterAngularMode(regist) == amNone;
      }
    }
    return false;
  }



  static void _dynmenuConstructVars(int16_t menu, bool_t applyFilter, dataType_t typeFilter, bool_t isAngular) {
    uint16_t numberOfBytes, numberOfVars;
    uint8_t *ptr;
    numberOfBytes = 1;
    numberOfVars = 0;
    memset(tmpString, 0, TMP_STR_LENGTH);
    for(int i=0; i<numberOfNamedVariables; i++) {
      calcRegister_t regist = i+FIRST_NAMED_VARIABLE;
      if(!applyFilter || _filterDataType(regist, typeFilter, isAngular)) {
        xcopy(tmpString + 15 * numberOfVars, allNamedVariables[i].variableName + 1, allNamedVariables[i].variableName[0]);
        numberOfVars++;
        numberOfBytes += 1 + allNamedVariables[i].variableName[0];
      }
    }
    for(int i=12; i<NUMBER_OF_RESERVED_VARIABLES; i++) {
      calcRegister_t regist = i+FIRST_RESERVED_VARIABLE;
      if((!applyFilter || _filterDataType(regist, typeFilter, isAngular))) {
        xcopy(tmpString + 15 * numberOfVars, allReservedVariables[i].reservedVariableName + 1, allReservedVariables[i].reservedVariableName[0]);
        numberOfVars++;
        numberOfBytes += 1 + allReservedVariables[i].reservedVariableName[0];
      }
    }

    if(numberOfVars != 0) {
      qsort(tmpString, numberOfVars, 15, sortMenu);
    }

    ptr = malloc(numberOfBytes);
    dynamicSoftmenu[menu].menuContent = ptr;
    for(int i=0; i<numberOfVars; i++) {
      int16_t len = stringByteLength(tmpString + 15*i) + 1;
      xcopy(ptr, tmpString + 15*i, len);
      ptr += len;
    }

    dynamicSoftmenu[menu].numItems = numberOfVars;
  }



  static void _dynmenuConstructMVarsFromPgm(uint16_t label, uint16_t *numberOfBytes, uint16_t *numberOfVars) {
    uint8_t *step;
    step = labelList[label].instructionPointer;
    while((*numberOfVars < 18) && checkOpCodeOfStep(step, ITM_MVAR) && *(step + 2) == STRING_LABEL_VARIABLE) {
      xcopy(tmpString + *numberOfBytes, step + 4, *(step + 3));
      (void)findOrAllocateNamedVariable(tmpString + *numberOfBytes);
      *numberOfBytes += *(step + 3) + 1;
      (*numberOfVars)++;
      step = findNextStep(step);
    }
  }



  static void _dynmenuConstructMVars(int16_t menu) {
    uint16_t numberOfBytes = 0;
    uint16_t numberOfVars = 0;
    memset(tmpString, 0, TMP_STR_LENGTH);

    if(currentMvarLabel != INVALID_VARIABLE) {
      _dynmenuConstructMVarsFromPgm(currentMvarLabel - FIRST_LABEL, &numberOfBytes, &numberOfVars);
    }
    else if(currentSolverStatus & SOLVER_STATUS_USES_FORMULA) {
      char *bufPtr = tmpString;
      uint8_t errorCode = lastErrorCode;
      lastErrorCode = ERROR_NONE;
      parseEquation(currentFormula, EQUATION_PARSER_MVAR, tmpString + TMP_STR_LENGTH - AIM_BUFFER_LENGTH, tmpString);
      while(*bufPtr != 0 || numberOfVars < 6) {
        numberOfVars += 1;
        numberOfBytes += stringByteLength(bufPtr) + 1;
        bufPtr += stringByteLength(bufPtr) + 1;
      }
      lastErrorCode = errorCode;
    }
    else {
      _dynmenuConstructMVarsFromPgm(currentSolverProgram, &numberOfBytes, &numberOfVars);
    }

    dynamicSoftmenu[menu].menuContent = malloc(numberOfBytes);
    xcopy(dynamicSoftmenu[menu].menuContent, tmpString, numberOfBytes);
    dynamicSoftmenu[menu].numItems = numberOfVars;
  }



  static void _dynmenuConstructUser(int16_t menu) {
    userMenuItem_t *menuData = (dynamicSoftmenu[menu].menuItem == -MNU_DYNAMIC) ? userMenus[currentUserMenu].menuItem : (dynamicSoftmenu[menu].menuItem == -MNU_MyAlpha) ? userAlphaItems : userMenuItems;
    int16_t i, numberOfBytes = 1;
    uint8_t *ptr;

    for(i = 0; i < 18; i++) {
      if(menuData[i].argumentName[0] != 0) {
        numberOfBytes += stringByteLength(menuData[i].argumentName) + 1;
      }
      else if(menuData[i].item == ITM_NOP || menuData[i].item == ITM_NULL) {
        numberOfBytes += 1;
      }
      else if( indexOfItems[abs(menuData[i].item)].itemCatalogName[0] == 0 || (menuData[i].item == ITM_op_j || menuData[i].item == ITM_op_j_pol || menuData[i].item == ITM_op_a || menuData[i].item == ITM_op_a2)) {
        numberOfBytes += stringByteLength(indexOfItems[abs(menuData[i].item)].itemSoftmenuName) + 1;
      }
      else {
        numberOfBytes += stringByteLength(indexOfItems[abs(menuData[i].item)].itemCatalogName) + 1;
      }
    }
    ptr = malloc(numberOfBytes);
    dynamicSoftmenu[menu].menuContent = ptr;
    for(i = 0; i < 18; i++) {
      const char *lbl;
      if(menuData[i].argumentName[0] != 0) {
        lbl = menuData[i].argumentName;
      }
      else if(menuData[i].item == ITM_NULL) {
        lbl = "";
      }
      else if(indexOfItems[abs(menuData[i].item)].itemCatalogName[0] == 0 || (menuData[i].item == ITM_op_j || menuData[i].item == ITM_op_j_pol || menuData[i].item == ITM_op_a || menuData[i].item == ITM_op_a2)) {
        lbl = indexOfItems[abs(menuData[i].item)].itemSoftmenuName;
      }
      else {
        lbl = indexOfItems[abs(menuData[i].item)].itemCatalogName;
      }
      int16_t len = stringByteLength(lbl) + 1;
      xcopy(ptr, lbl, len);
      ptr += len;
    }
    dynamicSoftmenu[menu].numItems = (numberOfBytes <= 19) ? 0 : 18;
  }



  static void initVariableSoftmenu(int16_t menu) {
    int16_t i, numberOfBytes, numberOfGlobalLabels;
    uint8_t *ptr;

    #if defined(PC_BUILD)
      //printf("initvariableSoftMenu (cachedDynamicMenu=%i)",cachedDynamicMenu);
    #endif // PC_BUILD
    free(dynamicSoftmenu[menu].menuContent);

    switch(-dynamicSoftmenu[menu].menuItem) {
      case MNU_MyAlpha: {
        _dynmenuConstructUser(menu);
                        break;
      }

      case MNU_MyMenu: {
        _dynmenuConstructUser(menu);
        break;
      }

      case MNU_VAR: {
        _dynmenuConstructVars(menu, false, 0, false);
        break;
      }

      case MNU_PROG:
      case MNU_PROGS: {
        numberOfBytes = 1;
                        numberOfGlobalLabels = 0;
                        memset(tmpString, 0, TMP_STR_LENGTH);
                        for(i=0; i<numberOfLabels; i++) {
                          if(labelList[i].step > 0) { // Global label
                            xcopy(tmpString + 15 * numberOfGlobalLabels, labelList[i].labelPointer + 1, labelList[i].labelPointer[0]);
                            numberOfGlobalLabels++;
                            numberOfBytes += 1 + labelList[i].labelPointer[0];
                          }
                        }

                        if(numberOfGlobalLabels != 0) {
                          qsort(tmpString, numberOfGlobalLabels, 15, sortMenu);
                        }

                        ptr = malloc(numberOfBytes);
                        dynamicSoftmenu[menu].menuContent = ptr;
                        for(i=0; i<numberOfGlobalLabels; i++) {
                          int16_t len = stringByteLength(tmpString + 15*i) + 1;
                          xcopy(ptr, tmpString + 15*i, len);
                          ptr += len;
                        }

                        dynamicSoftmenu[menu].numItems = numberOfGlobalLabels;
                        break;
      }

      case MNU_MATRS: {
        _dynmenuConstructVars(menu, true, dtReal34Matrix, false);
        break;
      }

      case MNU_STRINGS: {
        _dynmenuConstructVars(menu, true, dtString, false);
        break;
      }

      case MNU_DATES: {
        _dynmenuConstructVars(menu, true, dtDate, false);
        break;
      }

      case MNU_TIMES: {
        _dynmenuConstructVars(menu, true, dtTime, false);
        break;
      }

      case MNU_ANGLES: {
        _dynmenuConstructVars(menu, true, dtReal34, true);
        break;
      }

      case MNU_SINTS: {
        _dynmenuConstructVars(menu, true, dtShortInteger, false);
        break;
      }

      case MNU_LINTS: {
        _dynmenuConstructVars(menu, true, dtLongInteger, false);
        break;
      }

      case MNU_REALS: {
        _dynmenuConstructVars(menu, true, dtReal34, false);
        break;
      }

      case MNU_CPXS: {
        _dynmenuConstructVars(menu, true, dtComplex34, false);
        break;
      }

      case MNU_MVAR: {
        _dynmenuConstructMVars(menu);
        break;
      }

      case MNU_MENUS: {
        numberOfBytes = 1;
                        numberOfGlobalLabels = 0;
                        memset(tmpString, 0, TMP_STR_LENGTH);
                        for(i=0; i<LAST_ITEM; i++) {
                          if((indexOfItems[i].status & CAT_STATUS) == CAT_MENU && indexOfItems[i].itemCatalogName[0] != 0 && i != MNU_CATALOG && i != MNU_MENUS) {
                            int16_t len = stringByteLength(indexOfItems[i].itemCatalogName);
                            xcopy(tmpString + 15 * numberOfGlobalLabels, indexOfItems[i].itemCatalogName, len);
                            numberOfGlobalLabels++;
                            numberOfBytes += 1 + len;
                          }
                        }
                        for(i=0; i<numberOfUserMenus; i++) {
                          int16_t len = stringByteLength(userMenus[i].menuName);
                          xcopy(tmpString + 15 * numberOfGlobalLabels, userMenus[i].menuName, len);
                          numberOfGlobalLabels++;
                          numberOfBytes += 1 + len;
                        }

                        if(numberOfGlobalLabels != 0) {
                          qsort(tmpString, numberOfGlobalLabels, 15, sortMenu);
                        }

                        ptr = malloc(numberOfBytes);
                        dynamicSoftmenu[menu].menuContent = ptr;
                        for(i=0; i<numberOfGlobalLabels; i++) {
                          int16_t len = stringByteLength(tmpString + 15*i) + 1;
                          xcopy(ptr, tmpString + 15*i, len);
                          ptr += len;
                        }

                        dynamicSoftmenu[menu].numItems = numberOfGlobalLabels;
                        break;
      }

      case MNU_DYNAMIC: {
        _dynmenuConstructUser(menu);
                        break;
      }

      case ITM_MENU: {
        numberOfBytes = 0;
                        numberOfGlobalLabels = 0;
                        memset(tmpString, 0, TMP_STR_LENGTH);
                        for(i=0; i<18; i++) {
                          xcopy(tmpString + numberOfBytes, programmableMenu.itemName[i], stringByteLength(programmableMenu.itemName[i]) + 1);
                          numberOfBytes += stringByteLength(programmableMenu.itemName[i]) + 1;
                        }

                        ptr = malloc(numberOfBytes);
                        dynamicSoftmenu[menu].menuContent = ptr;
                        xcopy(ptr, tmpString, numberOfBytes);

                        dynamicSoftmenu[menu].numItems = 18;
                        break;
      }

      default: {
        sprintf(errorMessage, "In function initVariableSoftmenu: unexpected variable softmenu %" PRId16 "!", (int16_t)(-dynamicSoftmenu[menu].menuItem));
                        displayBugScreen(errorMessage);
    }
  }
  }


void greyOutBox(int16_t x1, int16_t x2, int16_t y1, int16_t y2) {
  // Grey out standard function names
  int16_t yStroke;
  for(int16_t xStroke=x1 + 2; xStroke < x2 - 2; xStroke++) {
    for(yStroke = y1 + 2; yStroke < y2 - 2; yStroke++){
      if(xStroke%2 == 0 && yStroke%2 == 0) {
        flipPixel(xStroke, yStroke);
      }
    }
  }
}



static void showKey2(const char *label0, const char *label1, int16_t x1, int16_t x2, int16_t y1, int16_t y2, bool_t rightMostSlot, videoMode_t videoMode, bool_t topLine, bool_t bottomLine, int8_t showCb, int16_t showValue, const char *showText);
char label0[30];
int16_t xx1;
int16_t xx2;

int8_t maxfLines = 0;
int8_t maxgLines = 0;

bool_t maxfgLines(int16_t y) {
  if(((maxfLines & 1) == 1) && ((maxgLines & 1) == 1)) {
    return (2 == y) || (1 == y);  //if any bit set in the f and g-line, allow fgline on f and g
  }
  else if(((maxfLines & 1) == 1) && ((maxgLines & 1) == 0)) {
    return (1 == y);              //if any bit set in the f-line, allow fgline on f
  }
  else {
    return false;
  }
}

  /********************************************//**
   * \brief Displays one softkey
   *
   * \param[in] l const char*         Text to display
   * \param[in] xSoftkey int16_t      x location of softkey: from 0 (left) to 5 (right)
   * \param[in] ySoftKey int16_t      y location of softkey: from 0 (bottom) to 2 (top)
   * \param[in] videoMode videoMode_t Video mode normal or reverse
   * \param[in] topLineDotted bool_t  Is the item's top line dotted
   * \param[in] topLine bool_t        Draw a top line
   * \param[in] bottomLine bool_t     Draw a bottom line
   * \return void
   ***********************************************/
  void showSoftkey(const char *label, int16_t xSoftkey, int16_t ySoftKey, videoMode_t videoMode, bool_t topLine, bool_t bottomLine, int8_t showCb, int16_t showValue, const char *showText) {     //dr
    int16_t x1, y1;
    int16_t x2, y2;

    if(label[0] !=0 ) {
      if(ySoftKey==1) {
        maxfLines |= 1; //set bit 0 for any non-blank softkey in f
      }
      if(ySoftKey == 2) {
        maxgLines |= 1; //set bit 0 for any non-blank softkey in g
        maxfLines |= 1; //set bit 0 for any non-blank softkey in g (add f, for a g softkey otherwise g cannot be reached)
      }
    }

    if((calcMode == CM_PLOT_STAT || calcMode == CM_GRAPH) && xSoftkey >= 2) {           //prevent softkeys columns 3-6 from displaying over the graph
      return;
    }

    if(0 <= xSoftkey && xSoftkey <= 5) {
      x1 = max(0,67 * xSoftkey - 1);
      x2 = x1 + 67;
    }
    else {
      sprintf(errorMessage, "In function showSoftkey: xSoftkey=%" PRId16 " must be from 0 to 5" , xSoftkey);
      displayBugScreen(errorMessage);
      return;
    }

    if(0 <= ySoftKey && ySoftKey <= 2) {
      y1 = 217 - SOFTMENU_HEIGHT * ySoftKey;
      y2 = y1 + SOFTMENU_HEIGHT;
    }
    else {
      sprintf(errorMessage, "In function showSoftkey: ySoftKey=%" PRId16 " but must be from 0 to 2!" , ySoftKey);
      displayBugScreen(errorMessage);
      return;
    }

    showKey(label, x1, x2, y1, y2, xSoftkey == 5, videoMode, topLine, bottomLine, showCb, showValue, showText);
  }


  void showSoftkey2(const char *labelSM1, int16_t xSoftkey, int16_t ySoftKey, videoMode_t videoMode, bool_t topLine, bool_t bottomLine, int8_t showCb, int16_t showValue, const char *showText) {     //dr
    int16_t x1, y1;
    int16_t x2, y2;

    if(labelSM1[0] !=0 ) {
      if(ySoftKey==1) {
        maxfLines |= 1; //set bit 0 for any non-blank softkey in f
      }
      if(ySoftKey == 2) {
        maxgLines |= 1; //set bit 0 for any non-blank softkey in g
        maxfLines |= 1; //set bit 0 for any non-blank softkey in g (add f, for a g softkey otherwise g cannot be reached)
      }
    }

    if((calcMode == CM_PLOT_STAT || calcMode == CM_GRAPH) && xSoftkey >= 2) {           //prevent softkeys columns 3-6 from displaying over the graph
      return;
    }

    if(0 <= xSoftkey && xSoftkey <= 5) {
      x1 = max(0,67 * xSoftkey - 1);
      x2 = x1 + 67;
    }
    else {
      sprintf(errorMessage, "In function showSoftkey: xSoftkey=%" PRId16 " must be from 0 to 5" , xSoftkey);
      displayBugScreen(errorMessage);
      return;
    }

    if(0 <= ySoftKey && ySoftKey <= 2) {
      y1 = 217 - SOFTMENU_HEIGHT * ySoftKey;
      y2 = y1 + SOFTMENU_HEIGHT;
    }
    else {
      sprintf(errorMessage, "In function showSoftkey: ySoftKey=%" PRId16 " but must be from 0 to 2!" , ySoftKey);
      displayBugScreen(errorMessage);
      return;
    }

//    showKey(label, x1, x2, y1, y2, xSoftkey == 5, videoMode, topLine, bottomLine, showCb, showValue, showText);



char label1[30];

if(xSoftkey == 0 || xSoftkey == 2 || xSoftkey == 4) {
  xx1 = x1; xx2 = x2;
  label0[0]=0;
  stringAppend(label0 + stringByteLength(label0),labelSM1);
  compressConversionName(label0);

}
  char sample[4];
  stringAppend(sample, STD_RIGHT_ARROW);
  int16_t i = 0;
  while(label0[i+1] != 0) {
    if(sample[0] == label0[i] && sample[1] == label0[i+1]) {
      label0[i] = 0;
      break;
    }
    i++;
  }

  stringAppend(sample, STD_LEFT_ARROW);
  i = 0;
  while(label0[i+1] != 0) {
    if(sample[0] == label0[i] && sample[1] == label0[i+1]) {
      label0[i] = 0;
      break;
    }
    i++;
  }


if(xSoftkey == 1 || xSoftkey == 3 || xSoftkey == 5) {
  label1[0]=0;
  stringAppend(label1 + stringByteLength(label1), labelSM1);
  compressConversionName(label1);


  stringAppend(sample, STD_RIGHT_ARROW);
  i = 0;
  while(label1[i+1] != 0) {
    if(sample[0] == label1[i] && sample[1] == label1[i+1]) {
      label1[i] = 0;
      break;
    }
    i++;
  }


  stringAppend(sample, STD_LEFT_ARROW);
  i = 0;
  while(label1[i+1] != 0) {
    if(sample[0] == label1[i] && sample[1] == label1[i+1]) {
      label1[i] = 0;
      break;
    }
    i++;
  }

  showKey2(label0, label1, xx1, x2, y1, y2, xSoftkey == 5, videoMode, topLine, bottomLine, showCb, showValue, showText);

  }
}


void showKey2(const char *label0, const char *label1, int16_t x1, int16_t x2, int16_t y1, int16_t y2, bool_t rightMostSlot, videoMode_t videoMode, bool_t topLine, bool_t bottomLine, int8_t showCb, int16_t showValue, const char *showText) {
  #define YY -100
  int16_t Text0   ;
  int16_t Arr0    ;
  int16_t midpoint;
  int16_t Arr1    ;
  int16_t Text1   ;
  float   space   ;
  float   space0=0;
  float   space1=0;


  int16_t w1 = showStringEnhanced(label0,          &standardFont, 0, y1+YY, videoMode, false, false, DO_compress, NO_raise, NO_Show, NO_LF);
  int16_t w2 = showStringEnhanced(STD_RIGHT_ARROW, &standardFont, 0, y1+YY, videoMode, false, false, DO_compress, NO_raise, NO_Show, NO_LF);
  int16_t w3 = showStringEnhanced(STD_LEFT_ARROW,  &standardFont, 0, y1+YY, videoMode, false, false, DO_compress, NO_raise, NO_Show, NO_LF);
  int16_t w4 = showStringEnhanced(label1,          &standardFont, 0, y1+YY, videoMode, false, false, DO_compress, NO_raise, NO_Show, NO_LF);


  midpoint = (x2 - x1) / 2;
  space0   = ((x2 - x1)/2.0f - w1 - w2 - 10) / 2.0f;   //###
  Text0    = x1 + midpoint - 10 - w2 - space0 - w1;
  Arr0     = x1 + midpoint - 10 - w2;
  space1   = ((x2 - x1)/2.0f - w3 - w4 - 10) / 2.0f;   //###
  Arr1     = x1 + midpoint + 10;
  Text1    = x1 + midpoint + 10 + w3 + space1;
  // s w1 s w2 10 | 10 w3 s w4 s

  //printf("@@@@ %f %f\n",space0, space1);

  if(space0 < 10 || space1 < 10) {
    space    = ((x2 - x1) - w1 - w2 - w3 - w4) / 7.0f;   //###
    Text0    = x1 + space;
    Arr0     = x1 + space + w1 + space;
    midpoint = 3.5 * space + w1 + w2;
    Arr1     = x2 - space - w3 - w4 - space;
    Text1    = x2 - space - w4;
    // s w1 s w2 s. | .s w3 s w4 s

  }
  //printf(">>>> |%s|%s| Space %f, w1 %d, w2 %d, w3 %d, w4 %d\n", label0, label1, space, w1, w2, w3, w4);

  // Clear inside the frame
  lcd_fill_rect(x1 + 1, y1 + 1, min(x2, SCREEN_WIDTH) - x1 - 1, min(y2, SCREEN_HEIGHT) - y1 - 1, (videoMode == vmNormal ? LCD_SET_VALUE : LCD_EMPTY_VALUE));

  showStringEnhanced(label0,          &standardFont, Text0 + (rightMostSlot ? 0 : 1), y1 + 1, videoMode, false, false, DO_compress, NO_raise, DO_Show, NO_LF);
  showStringEnhanced(STD_RIGHT_ARROW, &standardFont, Arr0 +  (rightMostSlot ? 0 : 1), y1 + 1, videoMode, false, false, DO_compress, NO_raise, DO_Show, NO_LF);
  showStringEnhanced(label1,          &standardFont, Text1 + (rightMostSlot ? 0 : 1), y1 + 1, videoMode, false, false, DO_compress, NO_raise, DO_Show, NO_LF);
  showStringEnhanced(STD_LEFT_ARROW,  &standardFont, Arr1 +  (rightMostSlot ? 0 : 1), y1 + 1, videoMode, false, false, DO_compress, NO_raise, DO_Show, NO_LF);


  // Draw the frame
  //   Top line
  if(topLine) {
    lcd_fill_rect(max(0, x1), y1, min(x2, SCREEN_WIDTH) - max(0, x1), 1, (videoMode == vmNormal ? LCD_EMPTY_VALUE : LCD_SET_VALUE));
  }

  //   Bottom line
  if(y1 + SOFTMENU_HEIGHT <= min(y2, 239) && bottomLine) {
    lcd_fill_rect(max(0, x1), y1 + SOFTMENU_HEIGHT, min(x2, SCREEN_WIDTH) - max(0, x1), 1, (videoMode == vmNormal ? LCD_EMPTY_VALUE : LCD_SET_VALUE));
  }

  //   Left line
  if(x1 >= 0) {
    lcd_fill_rect(x1, y1, 1, min(y2, SCREEN_HEIGHT - 1) + 1 - y1, (videoMode == vmNormal ? LCD_EMPTY_VALUE : LCD_SET_VALUE));
  }

  //   Right line
  if(x2 < SCREEN_WIDTH) {
    lcd_fill_rect(x2, y1, 1, min(y2, SCREEN_HEIGHT - 1) + 1 - y1, (videoMode == vmNormal ? LCD_EMPTY_VALUE : LCD_SET_VALUE));
  }

  //   Mid line
  if(x1 >= 0) {
    lcd_fill_rect(x1 + midpoint, y1+5, 1, min(y2, SCREEN_HEIGHT - 1) + 1 - y1 - 2*5, (videoMode == vmNormal ? LCD_EMPTY_VALUE : LCD_SET_VALUE));
  }
}


void showKey(const char *label, int16_t x1, int16_t x2, int16_t y1, int16_t y2, bool_t rightMostSlot, videoMode_t videoMode, bool_t topLine, bool_t bottomLine, int8_t showCb, int16_t showValue, const char *showText) {
    int16_t w;
    char l[16];

    // Draw the frame
    //   Top line
    if(topLine) {
      lcd_fill_rect(max(0, x1), y1, min(x2, SCREEN_WIDTH) - max(0, x1), 1, (videoMode == vmNormal ? LCD_EMPTY_VALUE : LCD_SET_VALUE));
    }

    //   Bottom line
    if(y1 + SOFTMENU_HEIGHT <= min(y2, 239) && bottomLine) {
      lcd_fill_rect(max(0, x1), y1 + SOFTMENU_HEIGHT, min(x2, SCREEN_WIDTH) - max(0, x1), 1, (videoMode == vmNormal ? LCD_EMPTY_VALUE : LCD_SET_VALUE));
    }

    //   Left line
    if(x1 >= 0) {
      lcd_fill_rect(x1, y1, 1, min(y2, SCREEN_HEIGHT - 1) + 1 - y1, (videoMode == vmNormal ? LCD_EMPTY_VALUE : LCD_SET_VALUE));
    }

    //   Right line
    if(x2 < SCREEN_WIDTH) {
      lcd_fill_rect(x2, y1, 1, min(y2, SCREEN_HEIGHT - 1) + 1 - y1, (videoMode == vmNormal ? LCD_EMPTY_VALUE : LCD_SET_VALUE));
    }

    // Clear inside the frame
    lcd_fill_rect(x1 + 1, y1 + 1, min(x2, SCREEN_WIDTH) - x1 - 1, min(y2, SCREEN_HEIGHT) - y1 - 1, (videoMode == vmNormal ? LCD_SET_VALUE : LCD_EMPTY_VALUE));

    xcopy(l, label, stringByteLength(label) + 1);
    //    char *lw = stringAfterPixels(l, &standardFont, (rightMostSlot ? 65 : 66), false, false);
    //    *lw = 0;
    //continue with trimmed label
    w = stringWidthC43(figlabel(l, showText, showValue), stdNoEnlarge, 0, false, false);
    if((showCb >= 0) || (w >= ((min(x2, SCREEN_WIDTH) - max(0, x1))*3)/4 )) {
      w = stringWidthC43(figlabel(l, showText, showValue), stdNoEnlarge, 1, false, false);
      if(showCb >= 0) { w = w + 8; }
      //    char *lw = stringAfterPixelsC43(l, stdNoEnlarge, compressString, rightMostSlot ? 65 : 66, false, false);
      //    *lw = 0;
    compressString = 1;       //JM compressString
    showString(figlabel(l, showText, showValue), &standardFont, x1 + (rightMostSlot ? 33 : 34) - w/2, y1 + 2, videoMode, false, false);
    compressString = 0;       //JM compressString
  }
  else {
     //clearly short enough so no trimming was needed anyway
     showString(figlabel(l, showText, showValue), &standardFont, x1 + (rightMostSlot ? 33 : 34) - w/2, y1 + 2, videoMode, false, false);
  }                                                                                              //JM & dr ^^

#if defined(JM_LINE2_DRAW)
  if(showCb >= 0) {
    if(videoMode == vmNormal) {
      JM_LINE2(x2, y2);
    }
  }
#endif // JM_LINE2_DRAW

  //vv EXTRA DRAWINGS FOR RADIO_BUTTON AND CHECK_BOX
  if(showCb >= 0) {
    if(videoMode == vmNormal) {
      if(showCb == RB_FALSE) {
        RB_UNCHECKED(x2-11, y2-16);
      }
      else if(showCb == RB_TRUE) {
        RB_CHECKED(x2-11, y2-16);
      }
      else if(showCb == CB_TRUE) {
        CB_CHECKED(x2-11, y2-16);
      }
      else {
        CB_UNCHECKED(x2-11, y2-16);
      }
    }
  }
  //^^
}


bool_t isFunctionItemAMenu(int16_t item) {
  return item == ITM_PLOT      ||
         item == ITM_PLOT_LR   ||
         item == ITM_HPLOT     ||
         item == ITM_DRAW      ||
         item == ITM_CFG       ||
         item == ITM_GAP_L     ||
         item == ITM_GAP_RX    ||
         item == ITM_GAP_R     ||
         item == ITM_PLOT_STAT ||
         item == ITM_EQ_NEW    ||
         item == ITM_VARMNU    ||
         item == ITM_SIM_EQ    ||
         item == ITM_DELITM    ||
         item == ITM_M_EDI;
         /*item == ITM_PLOT_CENTRL ||  CENTRL does not bring up a new menu - it is the same menu therefore not inverted */
         /*|| (item == ITM_TIMER)*/       //JMvv colour PLOT in reverse font to appear to be menus
}


static  char FF[16];
static char *changeItoJ(int16_t item) {
  stringAppend(FF,indexOfItems[item%10000].itemSoftmenuName);
  //printf(">>>> changeItoJ: %i %u %u %u %u %u %s %u %u\n", item, (uint8_t)(FF[0]), (uint8_t)(FF[1]), (uint8_t)(FF[2]), (uint8_t)(FF[3]), (uint8_t)(FF[4]), FF , (uint8_t)(STD_SUP_i[0]), (uint8_t)(STD_SUP_i[1]));
  if(getSystemFlag(FLAG_CPXj)) {
    if((item == ITM_op_j || item == ITM_op_j_pol || item == ITM_op_j_SIGN) && FF[1] == STD_op_i[1]) {
      //printf(">>>> changed: %u %u %u %u %u %s %u %u\n", (uint8_t)(FF[0]), (uint8_t)(FF[1]), (uint8_t)(FF[2]), (uint8_t)(FF[3]), (uint8_t)(FF[4]), FF , (uint8_t)(STD_SUP_i[0]), (uint8_t)(STD_SUP_i[1]));
      FF[1]++;
    }
    if(item == ITM_EE_EXP_TH && FF[3] == STD_SUP_i[1]) {
      FF[3]++;
    }
  }
  return FF;
}



void changeSoftKey(int16_t menuNr, int16_t itemNr, char * itemName, videoMode_t * vm, int8_t * showCb, int16_t * showValue, char * showText) {
  * vm = (itemNr < 0) || (isFunctionItemAMenu(itemNr%10000)) ? vmReverse : vmNormal;
  * showCb = NOVAL;
  * showValue = NOVAL;
  stringAppend(itemName,NOTEXT);
  showText[0]=0;

  if(itemNr > 0) {
    * showCb = fnCbIsSet(itemNr%10000);
    * showValue = fnItemShowValue(itemNr%10000);

    switch(itemNr%10000) {

      case ITM_DSPCYCLE:switch(*showValue) {
                          case 32700 : stringAppend(showText + stringByteLength(showText), "ALL" ); *showValue = NOVAL; break;
                          case 32701 : stringAppend(showText + stringByteLength(showText), "FIX" ); *showValue = NOVAL; break;
                          case 32702 : stringAppend(showText + stringByteLength(showText), "SCI" ); *showValue = NOVAL; break;
                          case 32703 : stringAppend(showText + stringByteLength(showText), "ENG" ); *showValue = NOVAL; break;
                          case 32704 : stringAppend(showText + stringByteLength(showText), "SIG" ); *showValue = NOVAL; break;
                          case 32705 : stringAppend(showText + stringByteLength(showText), "UNIT"); *showValue = NOVAL; break;
                          default: ;
                        }
                        break;
      case ITM_SCR    :switch(*showValue) {
                          case NC_NORMAL      : *showValue = NOVAL; break;
                          case NC_SUBSCRIPT   : stringAppend(showText + stringByteLength(showText), alphaCase == AC_LOWER ? STD_SUB_s STD_SUB_u STD_SUB_b : alphaCase == AC_UPPER ? STD_SUB_S STD_SUB_U STD_SUB_B : ""); *showValue = NOVAL; 
                                                stringAppend(itemName,indexOfItems[itemNr%10000].itemSoftmenuName);
                                                itemName[0]=STD_alpha[0];
                                                itemName[1]=STD_alpha[1];
                                                itemName[2]=0;
                                                return;
                                                break;
                          case NC_SUPERSCRIPT : stringAppend(showText + stringByteLength(showText), alphaCase == AC_LOWER ? STD_SUP_s STD_SUP_u STD_SUP_p : alphaCase == AC_UPPER ? STD_SUP_S STD_SUP_U STD_SUP_P : ""); *showValue = NOVAL;
                                                stringAppend(itemName,indexOfItems[itemNr%10000].itemSoftmenuName);
                                                itemName[0]=STD_alpha[0];
                                                itemName[1]=STD_alpha[1];
                                                itemName[2]=0;
                                                return;
                                                break;
                          default: ;
                        }
                        break;
      case ITM_GAP_L  : if(gapItemLeft == ITM_NULL) stringAppend(showText + stringByteLength(showText), "\1\1");
                        else stringAppend(showText + stringByteLength(showText),  indexOfItems[gapItemLeft].itemSoftmenuName);  //  gapCharLeft);
                        *showValue = NOVAL;
                        break;
      case ITM_GAP_RX : stringAppend(showText + stringByteLength(showText),  indexOfItems[gapItemRadix].itemSoftmenuName);  //  gapCharRadix);
                        *showValue = NOVAL;
                        break;
      case ITM_GAP_R  : if(gapItemRight == ITM_NULL) stringAppend(showText + stringByteLength(showText), "\1\1");
                        else stringAppend(showText + stringByteLength(showText), indexOfItems[gapItemRight].itemSoftmenuName);  //  gapCharRight);
                        *showValue = NOVAL;
                        break;
      case ITM_GRP_L  : *showValue = grpGroupingLeft;
                        break;
      case ITM_GRP1_L : *showValue = grpGroupingGr1Left;
                        break;
      case ITM_GRP1_L_OF:*showValue = grpGroupingGr1LeftOverflow;
                        break;
      case ITM_GRP_R  : *showValue = grpGroupingRight;
                        break;
      default: ;
      }


    if(itemNr%10000 == 9999) {
      stringAppend(itemName, indexOfItems[!getSystemFlag(FLAG_MULTx) ? ITM_DOT : ITM_CROSS].itemSoftmenuName);
      //printf("WWW1: itemName=%s, 0:%i 1:%i, ItemNr=%i \n",itemName, (uint8_t) itemName[0], (uint8_t) itemName[1], itemNr);
      return;
    }
    else if((indexOfItems[itemNr%10000].status & CAT_STATUS) == CAT_CNST) {
      stringAppend(itemName, indexOfItems[itemNr%10000].itemCatalogName);    
    }
    else {
      if(itemNr%10000 >= ITM_X_P1 && itemNr%10000 <= ITM_X_g6) {
        stringAppend(itemName, indexOfItemsXEQM + 8*(itemNr%10000-fnXEQMENUpos));
      }
      else {
        stringAppend(itemName, changeItoJ(itemNr));
      }
      //printf("WWW2: itemName=%s, ItemNr=%i \n",itemName,itemNr);
      return;
    }
  }
  else if(itemNr < 0) { //itemNr >= 0
    stringAppend(itemName, indexOfItems[-itemNr%10000].itemSoftmenuName);
    //printf("WWW3: itemName=%s, ItemNr=%i \n",itemName,itemNr);
    return;
  }
}


void fnStrikeOutIfNotCoded(int16_t itemNr, int16_t x, int16_t y) {
  if(itemNr > 0 && indexOfItems[itemNr%10000].func == itemToBeCoded) {
    // Strike out non coded functions
    int16_t yStroke = SCREEN_HEIGHT - y*23 - 1;
    for(int16_t xStroke=x*67 + 1 +9 ; xStroke<x*67 + 66 -10; xStroke++) {      //JM mod stroke slash cross out
      if(xStroke%3 == 0) {
        yStroke--;
      }
      setBlackPixel(xStroke, yStroke -3);                                      //JM mod
    }
  }
}


bool_t BASE_OVERRIDEONCE = false;

  void showSoftmenuCurrentPart(void) {

//JMTOCHECK: Removed exceptions for underline removal.

  maxfLines = 0;
  maxgLines = 0;
  char tmp1[16];
  int16_t x, y, yDotted=0, currentFirstItem, item, numberOfItems, m = softmenuStack[0].softmenuId;
  bool_t dottedTopLine;
  #if defined(PC_BUILD)
    char tmp[200]; sprintf(tmp,"^^^^showSoftmenuCurrentPart: Showing Softmenu id=%d\n",m); jm_show_comment(tmp);
    printf("==>%s\n",tmp);
  #endif // PC_BUILD

  if((!IS_BASEBLANK_(m) || BASE_OVERRIDEONCE) && calcMode != CM_FLAG_BROWSER && calcMode != CM_ASN_BROWSER && calcMode != CM_FONT_BROWSER && calcMode != CM_REGISTER_BROWSER && calcMode != CM_BUG_ON_SCREEN) {           //JM: Added exclusions, as this procedure is not only called from refreshScreen, but from various places due to underline
    clearScreen_old(false, false, true); //JM, added to ensure the f/g underlines are deleted
    BASE_OVERRIDEONCE = false;
    if(tam.mode == TM_KEY && !tam.keyInputFinished) {
      for(y=0; y<=2; y++) {
        for(x=0; x<6; x++) {
          stringAppend(tmp1," ");
          if(1+x+y*6>9) {
            tmp1[0]='1';
            stringAppend(tmp1 + stringByteLength(tmp1), " ");
            tmp1[1] = (int)(48+(1+x+y*6) % 10);
          }
          else {
            tmp1[0] = (int)((48+1+x+y*6));
          }
          showSoftkey(tmp1, x, y, vmReverse, true, true, NOVAL, NOVAL, NOTEXT);
        }
      }
      return;
    }

    if(m < NUMBER_OF_DYNAMIC_SOFTMENUS) { // Dynamic softmenu
      #if defined(PC_BUILD)
        //printf("Dynamic menu: m=%i cachedDynamicMenu=%i softmenu[m].menuItem= %i \n",m, cachedDynamicMenu, softmenu[m].menuItem);
      #endif // PC_BUILD
      if(softmenu[m].menuItem != cachedDynamicMenu || softmenu[m].menuItem == -MNU_DYNAMIC) {
        initVariableSoftmenu(m);
        cachedDynamicMenu = softmenu[m].menuItem;
      }
      numberOfItems = dynamicSoftmenu[m].numItems;
    }
    else if(softmenu[m].menuItem == -MNU_EQN && numberOfFormulae == 0) {
      numberOfItems = 1;
    }
    else { // Static softmenu
      numberOfItems = softmenu[m].numItems;
    }
    currentFirstItem = softmenuStack[0].firstItem;

/*
    //JMvv Temporary method to ensure AIM is active if the 3 ALPHA menus are shown //JM TOCHECK
    if((softmenuStackPointer > 0) && (calcMode != CM_AIM && (softmenu[m].menuId == -MNU_ALPHA || softmenu[m].menuId == -MNU_T_EDIT || softmenu[m].menuId == -MNU_MyAlpha))) {
      calcMode = CM_AIM;
      cursorFont = &standardFont;
      cursorEnabled = true;
      setSystemFlag(FLAG_ALPHA);
      refreshRegisterLine(AIM_REGISTER_LINE);
    } //JM ^^
*/
    ULFL = false;                                   //JM Underline
    ULGL = false;                                   //JM Underline


    if(numberOfItems <= 18) {
      dottedTopLine = false;
      if(catalog != CATALOG_NONE) {
        currentFirstItem = softmenuStack[0].firstItem = 0;
        setCatalogLastPos();
      }
    }
    else {
      dottedTopLine = true;
      yDotted = min(3, (numberOfItems + modulo(currentFirstItem - numberOfItems, 6))/6 - currentFirstItem/6) - 1;

      if(m >= NUMBER_OF_DYNAMIC_SOFTMENUS) { // Static softmenu
        item = 6 * (currentFirstItem / 6 + yDotted);
        if(                softmenu[m].softkeyItem[item]==0 && softmenu[m].softkeyItem[item+1]==0 && softmenu[m].softkeyItem[item+2]==0 && softmenu[m].softkeyItem[item+3]==0 && softmenu[m].softkeyItem[item+4]==0 && softmenu[m].softkeyItem[item+5]==0) {
          yDotted--;
        }

        item = 6 * (currentFirstItem / 6 + yDotted);
        if(yDotted >= 0 && softmenu[m].softkeyItem[item]==0 && softmenu[m].softkeyItem[item+1]==0 && softmenu[m].softkeyItem[item+2]==0 && softmenu[m].softkeyItem[item+3]==0 && softmenu[m].softkeyItem[item+4]==0 && softmenu[m].softkeyItem[item+5]==0) {
          yDotted--;
        }

        item = 6 * (currentFirstItem / 6 + yDotted);
        if(yDotted >= 0 && softmenu[m].softkeyItem[item]==0 && softmenu[m].softkeyItem[item+1]==0 && softmenu[m].softkeyItem[item+2]==0 && softmenu[m].softkeyItem[item+3]==0 && softmenu[m].softkeyItem[item+4]==0 && softmenu[m].softkeyItem[item+5]==0) {
          yDotted--;
        }
      }
    }

    char itemName[16]; itemName[0]=0;
    char showText[16]; showText[0]=0;
    showText[0]=0;
    videoMode_t vm = vmNormal;
    int8_t showCb = NOVAL;
    int16_t showValue = NOVAL;

    if(m < NUMBER_OF_DYNAMIC_SOFTMENUS) { // Dynamic softmenu
      #if defined(PC_BUILD)
        //printf("Dynamic menu: m=%i cachedDynamicMenu=%i softmenu[m].menuItem= %i \n",m, cachedDynamicMenu, softmenu[m].menuItem);
      #endif // PC_BUILD
      if(numberOfItems == 0) {
        for(x=0; x<6; x++) {
          showSoftkey("", x, 0, vmNormal, true, true, NOVAL, NOVAL, NOTEXT);
        }
      }
      else {
        #if defined(PC_BUILD)
          //printf("Dynamic menu: populate\n");
        #endif // PC_BUILD
        uint8_t *ptr = getNthString(dynamicSoftmenu[m].menuContent, currentFirstItem);
        for(y=0; y<3; y++) {
          for(x=0; x<6; x++) {
            if(x + 6*y + currentFirstItem < numberOfItems) {
              if(*ptr != 0) {
                vm = vmNormal;
                showCb = NOVAL;
                showValue = NOVAL;
                int16_t itemNr = userMenuItems[x + 6*y].item;
                stringAppend(itemName,(char *)ptr);
                //printf(">>>> %u %u %s %s \n", x, y, itemName, userMenuItems[x + 6*y].argumentName);
                switch(-softmenu[m].menuItem) {
                  case MNU_MENUS: {
                    vm = vmReverse;
                    break;
                  }
                  case MNU_MyMenu: {
                    //printf(">>>> MyMenu: %i %s : %s\n",itemNr, itemName, userMenuItems[x + 6*y].argumentName);
                    if(itemNr < 0) {
                     vm = vmReverse;       //No item name changes available for menu names
                    }
                    else {
                      if(userMenuItems[x + 6*y].argumentName[0] == 0) {
                        changeSoftKey(softmenu[m].menuItem, itemNr, itemName, &vm, &showCb, &showValue, showText);
                      }
                    }
                    break;
                  }
                  case MNU_MyAlpha: {
                    vm = (userAlphaItems[x + 6*y].item < 0) ? vmReverse : vmNormal;
                    break;
                  }
                  case MNU_DYNAMIC: {
                    vm = (userMenus[currentUserMenu].menuItem[x + 6*y].item < 0) ? vmReverse : vmNormal;
                    break;
                  }
                  case MNU_1STDERIV:
                  case MNU_2NDDERIV:
                  case MNU_MVAR: {
                    if(!compareString((char *)getNthString(dynamicSoftmenu[m].menuContent, x+6*y), indexOfItems[ITM_DRAW].itemSoftmenuName, CMP_NAME)) {
                       vm = vmReverse;
                    }
                    break;
                  }
                  default: {
                    vm = vmNormal;
                    break;
                  }
                }
                showSoftkey(itemName, x, y, vm, true, true, showCb, showValue, showText);
                fnStrikeOutIfNotCoded(itemNr, x, y);
              }
              ptr += stringByteLength((char *)ptr) + 1;
            }
          }
        }
      }
      if(softmenu[m].menuItem == -MNU_MVAR && (currentSolverStatus & SOLVER_STATUS_USES_FORMULA) && (currentSolverStatus & SOLVER_STATUS_INTERACTIVE)) {
        showEquation(currentFormula, 0, EQUATION_NO_CURSOR, false, NULL, NULL);
      }
    }
    else {  //normal (not Dynamic) softmenu
      const int16_t *softkeyItem = softmenu[m].softkeyItem + currentFirstItem;
      char itemName[16];
      for(y=currentFirstItem/6; y<=min(currentFirstItem/6+2, numberOfItems/6); y++, softkeyItem+=6) {
        for(x=0; x<6; x++) {
          if(softkeyItem + x >= softmenu[m].softkeyItem + numberOfItems) {
            item = ITM_NULL;
          }
          else {
            item = softkeyItem[x];
          }
          changeSoftKey(softmenu[m].menuItem, item, itemName, &vm, &showCb, &showValue, showText);


          if(item < 0) { // item is softmenu name
            int16_t menu = 0;
            while(softmenu[menu].menuItem != 0) {
              if(softmenu[menu].menuItem == item) {
                break;
              }
              menu++;
            }
            if(softmenu[menu].menuItem == 0) {
              sprintf(errorMessage, "In function showSoftmenuCurrentPart: softmenu ID %" PRId16 " not found!", item);
              displayBugScreen(errorMessage);
            }
            else if(softmenu[menu].menuItem == -MNU_ALPHA_OMEGA && alphaCase == AC_UPPER) {
                showSoftkey(indexOfItems[MNU_ALPHA_OMEGA].itemSoftmenuName, x, y-currentFirstItem/6, vmReverse, true, true, NOVAL, NOVAL, NOTEXT);
            }
            else if(softmenu[menu].menuItem == -MNU_ALPHA_OMEGA && alphaCase == AC_LOWER) {
                showSoftkey(indexOfItems[MNU_alpha_omega].itemSoftmenuName, x, y-currentFirstItem/6, vmReverse, true, true, NOVAL, NOVAL, NOTEXT);
            }
            else if(softmenu[menu].menuItem == -MNU_ALPHAINTL && alphaCase == AC_UPPER) {
                showSoftkey(indexOfItems[MNU_ALPHAINTL].itemSoftmenuName, x, y-currentFirstItem/6, vmReverse, true, true, NOVAL, NOVAL, NOTEXT);
            }
            else if(softmenu[menu].menuItem == -MNU_ALPHAINTL && alphaCase == AC_LOWER) {
                showSoftkey(indexOfItems[MNU_ALPHAintl].itemSoftmenuName, x, y-currentFirstItem/6, vmReverse, true, true, NOVAL, NOVAL, NOTEXT);
            }
            else {
              #if defined(INLINE_TEST)
                if(softmenu[menu].menuItem == -MNU_INL_TST) {
                  showSoftkey(/*STD_omicron*/STD_SPACE_3_PER_EM, x, y-currentFirstItem/6, vmNormal, false, false, NOVAL, NOVAL, NOTEXT);
                }
                else {
              #endif // INLINE_TEST
              //MAIN SOFTMENU DISPLAY
              showSoftkey(indexOfItems[-softmenu[menu].menuItem].itemSoftmenuName, x, y-currentFirstItem/6, vmReverse, true, true, NOVAL, NOVAL, NOTEXT);
              #if defined(INLINE_TEST)
                }
              #endif // INLINE_TEST

            }
          } //softmenu


          else if(softmenu[m].menuItem == -MNU_SYSFL) {                                         //JMvv add radiobuttons to standard flags
            if(indexOfItems[item%10000].itemCatalogName[0] != 0) {
              if(isSystemFlagWriteProtected(indexOfItems[item%10000].param)) {
                showSoftkey(indexOfItems[item%10000].itemCatalogName,  x, y-currentFirstItem/6, vmNormal, (item/10000)==0 || (item/10000)==2, (item/10000)==0 || (item/10000)==1, showCb, getSystemFlag(indexOfItems[item%10000].param) ?  1 : 0, NOTEXT);
              }
              else {
                showSoftkey(indexOfItems[item%10000].itemCatalogName,  x, y-currentFirstItem/6, vmNormal, (item/10000)==0 || (item/10000)==2, (item/10000)==0 || (item/10000)==1, getSystemFlag(indexOfItems[item%10000].param) ?  CB_TRUE : CB_FALSE, NOVAL, NOTEXT);
              }
            }
          }                                                                      //JM^^

          else if(softmenu[m].menuItem == -MNU_ALPHA && calcMode == CM_PEM && item%10000 == ITM_ASSIGN) {
            // do nothing
          }

          else if(item > 0 && indexOfItems[item%10000].itemSoftmenuName[0] != 0) { // softkey
            // item : +10000 -> no top line
            //        +20000 -> no bottom line
            //        +30000 -> neither top nor bottom line

            if( softmenu[m].menuItem  == -MNU_CONVS  || softmenu[m].menuItem  == -MNU_CONVANG  ||
                softmenu[m].menuItem  == -MNU_CONVE  || softmenu[m].menuItem  == -MNU_CONVP    ||
                softmenu[m].menuItem  == -MNU_CONVFP || softmenu[m].menuItem  == -MNU_CONVM    ||
                softmenu[m].menuItem  == -MNU_CONVX  || softmenu[m].menuItem  == -MNU_CONVV    ||
                softmenu[m].menuItem  == -MNU_CONVA  || softmenu[m].menuItem  == -MNU_UNITCONV ||
                softmenu[m].menuItem  == -MNU_MISC   || softmenu[m].menuItem  == -MNU_CONVHUM  ||
                softmenu[m].menuItem  == -MNU_CONVYMMV) {
              showSoftkey2(indexOfItems[item%10000].itemSoftmenuName, x, y-currentFirstItem/6, vmNormal, (item/10000)==0 || (item/10000)==2, (item/10000)==0 || (item/10000)==1, showCb, showValue, showText);
            }

            else {
              if( (softmenu[m].menuItem == -MNU_FCNS || softmenu[m].menuItem  == -MNU_CONST) || //CONST is a normal menu not a catalog, but we expect the catalog to be treated as a catalog. //The same could be a problem with any of the generated catalogs (MNU_SYSFL, MNU_alpha_INTL, MNU_alpha_intl, )
                 ((softmenu[m].menuItem == -MNU_IO   || softmenu[m].menuItem  == -MNU_PFN  ) && (item == ITM_STOCFG || item == ITM_RCLCFG))) { //do not display "Config"
                stringAppend(itemName,indexOfItems[item%10000].itemCatalogName);
              }
              showSoftkey(itemName, x, y-currentFirstItem/6, vm, (item/10000)==0 || (item/10000)==2, (item/10000)==0 || (item/10000)==1, showCb, showValue, showText);
            }


            //softkey modifications

            if(jm_G_DOUBLETAP && ( BLOCK_DOUBLEPRESS_MENU(m, x, y))) {  // Indicate disabled double tap
              int16_t yStrokeA = SCREEN_HEIGHT - (y-currentFirstItem/6)*23 - 1;
              int16_t xStrokeA=x*67 + 66 -12;
              plotline(xStrokeA +2+4, yStrokeA -16-3-1, xStrokeA +2+4+5-1, yStrokeA -16-3+5);
            }
            fnStrikeOutIfNotCoded(item%10000, x, y-currentFirstItem/6);

          }
        }
      }


      if(softmenu[m].menuItem == -MNU_EQN) {
        showEquation(currentFormula, 0, EQUATION_NO_CURSOR, false, NULL, NULL);
        dottedTopLine = (numberOfFormulae >= 2);
        yDotted = 2;
      }
      if(softmenu[m].menuItem == -MNU_EQ_EDIT) {
        bool_t cursorShown;
        bool_t rightEllipsis;
        while(1) {
          showEquation(EQUATION_AIM_BUFFER, yCursor, xCursor, true, &cursorShown, &rightEllipsis);
          if(cursorShown) {
            break;
          }
          if(yCursor > xCursor) {
            --yCursor;
          }
          else {
            ++yCursor;
          }
        }
        if(!rightEllipsis && yCursor > 0) {
          do {
            --yCursor;
            showEquation(EQUATION_AIM_BUFFER, yCursor, xCursor, true, &cursorShown, &rightEllipsis);
            if((!cursorShown) || rightEllipsis) {
              ++yCursor;
              break;
            }
          } while(yCursor > 0);
        }
        showEquation(EQUATION_AIM_BUFFER, yCursor, xCursor, false, NULL, NULL);
      }
    }

    if(0 <= yDotted && yDotted <= 2) {
      yDotted = 217 - SOFTMENU_HEIGHT * yDotted;

      if(dottedTopLine) {
        for(x=0; x<SCREEN_WIDTH; x++) {
          if(x%8 < 4) {
            setBlackPixel(x, yDotted);
          }
          else {
            setWhitePixel(x, yDotted);
          }
        }


                                         //JMvv    //triangle centre point  // Triangles indicating more menus
        #define t 5
        #define t_o 1.6*t                                                             //offset
        #define tt_o 2                                                             //total offset
        lcd_fill_rect(0,(uint32_t)(yDotted-t), 20,t+1, 0);
        uint32_t xx;
        for(xx=0; xx<=t; xx++) {
          if(!catalog) {
            lcd_fill_rect(xx,       (uint32_t)(tt_o-t + yDotted-xx+t),   2*(t-xx), 1 ,true );
            lcd_fill_rect(xx + t_o, (uint32_t)(tt_o-t + yDotted-t+xx+t), 2*(t-xx), 1 ,true );
          }
          else {
            if(xx!=t) {
              lcd_fill_rect(xx,                 (uint32_t)(tt_o-t + yDotted-xx+t),   2, 1 ,true );
              lcd_fill_rect(xx+ 2*(t-xx)-1,     (uint32_t)(tt_o-t + yDotted-xx+t),   2, 1 ,true );
              lcd_fill_rect(xx+ t_o,               (uint32_t)(tt_o-t + yDotted-t+xx+t),   2, 1 ,true );
              lcd_fill_rect(xx+ t_o+ 2*(t-xx)-1,   (uint32_t)(tt_o-t + yDotted-t+xx+t),   2, 1 ,true );
            }
          }
                                                                            //JM ^^
        }
      }
    }
    showShiftState(); //JM
  }
}





                                                              //JM ^^



  /* Pushes a new softmenu on the softmenu stack.
   *
   * \param[in] softmenuId Softmenu ID
   */
  static void pushSoftmenu(int16_t softmenuId) {
    int i;
//    if(running_program_jm) return;                             //JM

    #if defined(PC_BUILD)
      char tmp[300]; sprintf(tmp,">>> ...... pushing id:%d name:%s\n",softmenuId, indexOfItems[-softmenu[softmenuId].menuItem].itemSoftmenuName); jm_show_comment(tmp);
    #endif // PC_BUILD
    if(softmenuStack[0].softmenuId == softmenuId) { // The menu to push on the stack is already displayed
      return;
    }

    for(i=0; i<SOFTMENU_STACK_SIZE; i++) { // Searching the stack for the menu to push on the stack
      if(softmenuStack[i].softmenuId == softmenuId) { // if found, remove it
        xcopy(softmenuStack + 1, softmenuStack, i * sizeof(softmenuStack_t));
        break;
      }
    }

    if(i == SOFTMENU_STACK_SIZE) { // The menu to push was not found on the stack
      xcopy(softmenuStack + 1, softmenuStack, (SOFTMENU_STACK_SIZE - 1) * sizeof(softmenuStack_t)); // shifting the entire stack
    }


    softmenuStack[0].softmenuId = softmenuId;
    softmenuStack[0].firstItem = lastCatalogPosition[catalog];

      doRefreshSoftMenu = true;     //dr
  }



  void popSoftmenu(void) {
//    if(running_program_jm) return;                             //JM
    screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;

    xcopy(softmenuStack, softmenuStack + 1, (SOFTMENU_STACK_SIZE - 1) * sizeof(softmenuStack_t)); // shifting the entire stack
    memset(softmenuStack + SOFTMENU_STACK_SIZE - 1, 0, sizeof(softmenuStack_t)); // Put MyMenu in the last stack element

    doRefreshSoftMenu = true;     //dr

    if(softmenuStack[0].softmenuId == 0 && calcMode == CM_AIM) { // MyMenu displayed and in AIM
      softmenuStack[0].softmenuId = 1; // MyAlpha
    }
    else if(softmenuStack[0].softmenuId == 1 && calcMode != CM_AIM) { // MyAlpha displayed and not in AIM
      softmenuStack[0].softmenuId = 0; // MyMenu
    }
    if(softmenuStack[0].softmenuId == 0 && BASE_HOME && calcMode != CM_AIM) {
      softmenuStack[0].softmenuId = mm_MNU_HOME;
    }
    else if(softmenuStack[0].softmenuId == 0 && BASE_MYM && calcMode != CM_AIM) {
      //softmenuStack[0].softmenuId = 0;                                                       //already 0, not needed to change
    }
    else if(softmenuStack[0].softmenuId == 1 && calcMode == CM_AIM) {
      softmenuStack[0].softmenuId = mm_MNU_ALPHA;
    }

                                                              //JM ^^
    if(softmenuStack[0].softmenuId != mm_MNU_HOME && softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_MODE && softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_DISP) {          //JM reset menu base point only if not HOME, MODE & DISP menus
      softmenuStack[0].firstItem = 0;
    }

    enterAsmModeIfMenuIsACatalog(softmenu[softmenuStack[0].softmenuId].menuItem);

    if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_MVAR) {
      setSystemFlag(FLAG_VMDISP);
    }
    else {
      clearSystemFlag(FLAG_VMDISP);
    }

    #if defined(PC_BUILD)
      jm_show_calc_state("popped");
      char tmp[300]; sprintf(tmp,">>> ...... popped into [0]: Id:%d Name:%s\n",softmenuStack[0].softmenuId, indexOfItems[-softmenu[softmenuStack[0].softmenuId].menuItem].itemSoftmenuName); jm_show_comment(tmp);
    #endif // PC_BUILD
  }



  void showSoftmenu(int16_t id) {
//    if(running_program_jm) return;                             //JM
    int16_t m;
    #if defined(PC_BUILD)
      char tmp[200]; sprintf(tmp,"^^^^showSoftmenu: Showing Softmenu id=%d\n",id); jm_show_comment(tmp);
    #endif // PC_BUILD

    #if !defined(INLINE_TEST)
      if(id == -MNU_INL_TST) {
        return;
      }
    #endif // !INLINE_TEST

    enterAsmModeIfMenuIsACatalog(id);

    if(id == 0) {
      displayBugScreen(bugScreenIdMustNotBe0);
      return;
    }

    screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;

    if(id == -MNU_ALPHAINTL && alphaCase == AC_LOWER) { // alphaINTL
      id = -MNU_ALPHAintl;
    }
    else if(id == -MNU_ALPHA_OMEGA && alphaCase == AC_LOWER) { // alpha...omega
      id = -MNU_alpha_omega;
    }
    else if(id == -MNU_Solver || id == -MNU_Sf || id == -MNU_1STDERIV || id == -MNU_2NDDERIV) {
      int32_t numberOfVars = -1;
      currentSolverStatus = SOLVER_STATUS_USES_FORMULA | SOLVER_STATUS_INTERACTIVE;
      switch(-id) {
        case MNU_Solver: {
          currentSolverStatus |= SOLVER_STATUS_EQUATION_SOLVER;
          break;
        }
        case MNU_Sf: {
          currentSolverStatus |= SOLVER_STATUS_EQUATION_INTEGRATE;
          break;
        }
        case MNU_1STDERIV: {
          currentSolverStatus |= SOLVER_STATUS_EQUATION_1ST_DERIVATIVE;
          break;
        }
        case MNU_2NDDERIV: {
          currentSolverStatus |= SOLVER_STATUS_EQUATION_2ND_DERIVATIVE;
          break;
        }
      }
      cachedDynamicMenu = 0;
      parseEquation(currentFormula, EQUATION_PARSER_MVAR, aimBuffer, tmpString);
      id = -MNU_MVAR;
      while((getNthString((uint8_t *)tmpString, ++numberOfVars))[0] != 0) {
      }
      if(numberOfVars > 12) {
        displayCalcErrorMessage(ERROR_EQUATION_TOO_COMPLEX, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function showSoftmenu:", "there are more than 11 variables in this equation!", NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      }
      else if((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE || (currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_2ND_DERIVATIVE) {
        if((getNthString((uint8_t *)tmpString, 1))[0] == 0) {
          currentSolverVariable = findOrAllocateNamedVariable((char *)getNthString((uint8_t *)tmpString, 0));
          reallyRunFunction(ITM_STO, currentSolverVariable);
          if((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE) {
            fn1stDerivEq(NOPARAM);
          }
          else {
            fn2ndDerivEq(NOPARAM);
          }
        }
      }
    }
    else if(id == -MNU_ADV || id == -MNU_EQN) {
      currentSolverStatus &= ~SOLVER_STATUS_INTERACTIVE;
      for(int i=0; i<SOFTMENU_STACK_SIZE; i++) { // Searching the stack for MNU_MVAR
        if(softmenu[softmenuStack[i].softmenuId].menuItem == -MNU_MVAR) { // if found, remove it
          xcopy(softmenuStack + i, softmenuStack + i + 1, (SOFTMENU_STACK_SIZE - i - 1) * sizeof(softmenuStack_t));
          memset(softmenuStack + SOFTMENU_STACK_SIZE - 1, 0, sizeof(softmenuStack_t)); // Put MyMenu in the last stack element
          --i; // redo
        }
      }
    }

    m = 0;
    while(softmenu[m].menuItem != 0) {
      if(softmenu[m].menuItem == id) {
       if(!tam.mode) softmenuStack[0].firstItem = lastCatalogPosition[catalog];
       break;
      }
      m++;
    }

    if(softmenu[m].menuItem == 0) {
      sprintf(errorMessage, "In function showSoftmenu: softmenu %" PRId16 " not found!", id);
      displayBugScreen(errorMessage);
    }
    else {
      if(tam.mode || (calcMode == CM_ASSIGN && tam.alpha)) {
        numberOfTamMenusToPop++;
      }
      pushSoftmenu(m);
      if(id == -MNU_MVAR) {
        setSystemFlag(FLAG_VMDISP);
      }
      else {
        clearSystemFlag(FLAG_VMDISP);
      }
    }
  }



  void setCatalogLastPos(void) {
    lastCatalogPosition[catalog] = (catalog ? softmenuStack[0].firstItem : 0);

    if(catalog == CATALOG_AINT) {
      lastCatalogPosition[CATALOG_aint] = softmenuStack[0].firstItem;
    }
    else if(catalog == CATALOG_aint) {
      lastCatalogPosition[CATALOG_AINT] = softmenuStack[0].firstItem;
    }
  }

  bool_t currentSoftmenuScrolls(void) {
    int16_t menuId = softmenuStack[0].softmenuId;
    return (menuId > 1 &&
      (   (menuId <  NUMBER_OF_DYNAMIC_SOFTMENUS && dynamicSoftmenu[menuId].numItems > 18)
       || (menuId >= NUMBER_OF_DYNAMIC_SOFTMENUS &&        softmenu[menuId].numItems > 18)));
  }

  bool_t isAlphabeticSoftmenu(void) {
    int16_t menuItem = softmenu[softmenuStack[0].softmenuId].menuItem;
    switch(menuItem) {
      case -MNU_ALPHAINTL:
      case -MNU_ALPHAintl:
      case -MNU_ALPHA_OMEGA:
      case -MNU_alpha_omega:
      case -MNU_ALPHAMATH:
      case -MNU_MyAlpha:
      case -MNU_ALPHAMISC:
        return true;
      default:
        return false;
    }
  }

  bool_t isJMAlphaSoftmenu(int16_t menuId) {                   //JM
    int16_t menuItem = softmenu[menuId].menuItem;
    switch(menuItem) {
      case -MNU_MyAlpha:
      case -MNU_ALPHA:   //JM
        return true;
      default:
        return false;
    }
  }

  bool_t isJMAlphaOnlySoftmenu(void) {                    //JM
    if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_ALPHA) return true;
    else return false;
  }


#endif // !TESTSUITE_BUILD


char *dynmenuGetLabel(int16_t menuitem) {
  return dynmenuGetLabelWithDup(menuitem, NULL);
}



char *dynmenuGetLabelWithDup(int16_t menuitem, int16_t *dupNum) {
  if(dupNum) {
    *dupNum = 0;
  }
  if(menuitem < 0 || menuitem >= dynamicSoftmenu[softmenuStack[0].softmenuId].numItems) {
    return "";
  }
  char *labelName = (char *)dynamicSoftmenu[softmenuStack[0].softmenuId].menuContent;
  char *prevLabelName = labelName;
  while(menuitem > 0) {
    labelName += stringByteLength(labelName) + 1;
    menuitem--;
    if(dupNum) {
      if(compareString(labelName, prevLabelName, CMP_BINARY) == 0) {
        ++(*dupNum);
      }
      else {
        prevLabelName = labelName;
        *dupNum = 0;
      }
    }
  }
  return labelName;
}


void fnBaseMenu(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    BASE_OVERRIDEONCE = true;
    showSoftmenu(-MNU_MyMenu);
  #endif // !TESTSUITE_BUILD
}


void fnExitAllMenus(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
  uint16_t cnt = SOFTMENU_STACK_SIZE - 1;
  while((softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_MyMenu && softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_MyAlpha) || (softmenu[softmenuStack[1].softmenuId].menuItem != -MNU_MyMenu)) {
    popSoftmenu();
    if(cnt-- == 0) break;
  }
  softmenuStack[1].softmenuId = 0;
  popSoftmenu();    

  //fnDumpMenus(0);   //Easy place to access the Dump Menus: PFN / More / ExitAll
#endif // !TESTSUITE_BUILD
}



void fnMenuDump(uint16_t menu, uint16_t item) {                              //JMvv procedure to dump all menus. First page only. To mod todump all pages
#if defined(PC_BUILD)
  doRefreshSoftMenu = true;
  showSoftmenu(softmenu[menu].menuItem);
  softmenuStack[0].firstItem += item;
  showSoftmenuCurrentPart();

  FILE *bmp;
  char bmpFileName[100];
  int32_t x, y;
  uint32_t uint32;
  uint16_t uint16;
  uint8_t  uint8;

  gtk_widget_queue_draw(screen);
  while(gtk_events_pending()) {
    gtk_main_iteration();
  }

  //printf(">>> %s\n",indexOfItems[-softmenu[menu].menuItem].itemSoftmenuName);
  char asciiString[448];
  char asciiString1[448];
  stringToASCII(indexOfItems[-softmenu[menu].menuItem].itemSoftmenuName, asciiString1);
  //printf(">>> Menustring:%s|",asciiString1);
  stringToFileNameChars(asciiString1, asciiString);
  //printf(">>> Menustring:%s|",asciiString);

  sprintf(bmpFileName,"Menu_%s_%4d p%d.bmp",asciiString, menu, (int)(item/18)+1);
  printf(">>> filename:%s|\n",bmpFileName);

  bmp = fopen(bmpFileName, "wb");

  fwrite("BM", 1, 2, bmp);        // Offset 0x00  0  BMP header

  uint32 = (SCREEN_WIDTH/8 * (SCREEN_HEIGHT-171)) + 610;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x02  2  File size

  uint32 = 0;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x06  6  unused

  uint32 = 0x00000082;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x0a 10  Offset where the bitmap data can be found

  uint32 = 0x0000006c;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x0e 14  Number of bytes in DIB header

  uint32 = SCREEN_WIDTH;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x12 18  Bitmap width

  uint32 = SCREEN_HEIGHT-171;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x16 22  Bitmap height

  uint16 = 0x0001;
  fwrite(&uint16, 1, 2, bmp);     // Offset 0x1a 26  Number of planes

  uint16 = 0x0001;
  fwrite(&uint16, 1, 2, bmp);     // Offset 0x1c 28  Number of bits per pixel

  uint32 = 0;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x1e 30  Compression

  uint32 = 0x000030c0;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x22 34  Size of bitmap data (including padding)

  uint32 = 0x00001a7c; // 6780 pixels/m
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x26 38  Horizontal print resolution

  uint32 = 0x00001a7c; // 6780 pixels/m
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x2a 42  Vertical print resolution

  uint32 = 0x00000002;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x2e 46  Number of colors in the palette

  uint32 = 0x00000002;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x32 50  Number of important colors

  uint32 = 0x73524742;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x36  ???

  uint32 = 0;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x3a  ???
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x3e  ???
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x42  ???
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x46  ???
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x4a  ???
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x4e  ???
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x52  ???
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x56  ???
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x5a  ???
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x5e  ???
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x62  ???
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x66  ???

  uint32 = 0x00000002;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x6a  ???

  uint32 = 0;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x6e  ???
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x72  ???
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x76  ???

  uint32 = 0x00dff5cc; // light green
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x7a  RGB color for 0

  uint32 = 0;
  fwrite(&uint32, 1, 4, bmp);     // Offset 0x7e  RGB color for 1

  // Offset 0x82  bit map data
  uint16 = 0;
  uint32 = 0;
  for(y=SCREEN_HEIGHT-1; y>=171; y--) {
    for(x=0; x<SCREEN_WIDTH; x++) {
      uint8 <<= 1;
      if(*(screenData + y*screenStride + x) == ON_PIXEL) {
        uint8 |= 1;
      }

      if((x % 8) == 7) {
        fwrite(&uint8, 1, 1, bmp);
        uint8 = 0;
      }
    }
    fwrite(&uint16, 1, 2, bmp); // Padding
  }


  fclose(bmp);
  popSoftmenu();
#endif // PC_BUILD
}


void fnDumpMenus(uint16_t unusedButMandatoryParameter) {                      //JM
#if defined(PC_BUILD)
  int16_t m,n;
  m = 0;
    while(softmenu[m].menuItem != 0) {
      n=0;
      while(n <= softmenu[m].numItems && softmenu[m].numItems != 0) {
        printf("m=%d n=%d\n",m,n );
        switch(m) {
          case 30:
          case 31:
          case 32:
          case 33:
            break;      
          default:
           fnMenuDump(m, n);
         }
        n += 18;
      }
      m++;
    }
#endif // PC_BUILD
}                                                                            //JM^^


