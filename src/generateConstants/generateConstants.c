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
 * \file generateConstants.c
 ***********************************************/

#define NUMBER_OF_CONSTANTS_IN_CNST_CATALOG 78

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "defines.h"

#include "realType.h"

realContext_t ctxtReal34, ctxtReal39, ctxtReal51, ctxtReal75, ctxtReal1071;

char whiteSpace[50], temp[10000];
char defines[1000000], externalDeclarations[1000000]; // .h file
char realArray[1000000], realPointerDeclarations[1000000], real34PointerDeclarations[1000000], real51PointerDeclarations[1000000], real75PointerDeclarations[1000000], real1071PointerDeclarations[1000000]; // .c file
FILE *constantsC, *constantsH;
int  idx, c;


void *xcopy(void *dest, const void *source, int n) {
  char       *pDest   = (char *)dest;
  const char *pSource = (char *)source;

  if(pSource > pDest) {
    while(n--) {
      *pDest++ = *pSource++;
    }
  }
  else {
    if(pSource < pDest) {
      while(n--) {
        pDest[n] = pSource[n];
      }
    }
  }

  return dest;
}


void generateConstantArray(char *name, char *value) {
  real39_t real39;

  #if defined(DEBUG)
    printf("generateConstantArray: %-10.10s = %s\n", name, value);
  #endif // DEBUG

  memset(&real39, 0, sizeof(real39_t));
  stringToReal(value, (real_t *)&real39, &ctxtReal39);

  strcpy(whiteSpace, "                                        ");
  whiteSpace[13 - strlen(name)] = 0;

  strcat(externalDeclarations, "  extern const real_t * const const_");
  strcat(externalDeclarations, name);
  strcat(externalDeclarations, ";\n");

  if(c <= NUMBER_OF_CONSTANTS_IN_CNST_CATALOG) {
    sprintf(temp, "  #define CONST_%02d %4d\n", c, idx);
    strcat(defines, temp);
  }

  strcat(realPointerDeclarations, "TO_QSPI const real_t * const const_");
  strcat(realPointerDeclarations, name);
  strcat(realPointerDeclarations, whiteSpace);
  strcat(realPointerDeclarations, " = (real_t *)(constants + ");
  sprintf(temp, "%5d)", idx);
  idx += sizeof(real39_t);
  strcat(realPointerDeclarations, temp);
  strcat(realPointerDeclarations, ";\n");

  strcat(realArray, "  ");
  for(uint32_t i=0; i<sizeof(real39_t); i++) {
    sprintf(temp, "0x%02x,", *(((uint8_t *)(&real39)) + i));
    strcat(realArray, temp);
  }

  strcat(realArray, "  // const_");
  strcat(realArray, name);
  strcat(realArray, "\n");
}


void generateConstantArray34(char *name, char *value) {
  real34_t real34;

  #if defined(DEBUG)
    printf("generateConstantArray34: %-10.10s = %s\n", name, value);
  #endif // DEBUG

  memset(&real34, 0, sizeof(real34_t));
  stringToReal34(value, &real34);

  strcpy(whiteSpace, "                                        ");
  whiteSpace[9 - strlen(name)] = 0;

  strcat(externalDeclarations, "  extern const real34_t * const const34_");
  strcat(externalDeclarations, name);
  strcat(externalDeclarations, ";\n");

  strcat(real34PointerDeclarations, "TO_QSPI const real34_t * const const34_");
  strcat(real34PointerDeclarations, name);
  strcat(real34PointerDeclarations, whiteSpace);
  strcat(real34PointerDeclarations, " = (real34_t *)(constants + ");
  sprintf(temp, "%5d)", idx);
  idx += sizeof(real34_t);
  strcat(real34PointerDeclarations, temp);
  strcat(real34PointerDeclarations, ";\n");

  strcat(realArray, "  ");
  for(uint32_t i=0; i<sizeof(real34_t); i++) {
    sprintf(temp, "0x%02x,", *(((uint8_t *)(&real34)) + i));
    strcat(realArray, temp);
  }

  strcat(realArray, "  // const_");
  strcat(realArray, name);
  strcat(realArray, "\n");
}


void generateConstantArray51(char *name, char *value) {
  real51_t real51;

  #if defined(DEBUG)
    printf("generateConstantArray51: %-10.10s = %s\n", name, value);
  #endif // DEBUG

  memset(&real51, 0, sizeof(real51_t));
  stringToReal(value, (real_t *)&real51, &ctxtReal51);

  strcpy(whiteSpace, "                                        ");
  whiteSpace[13 - strlen(name)] = 0;

  strcat(externalDeclarations, "  extern const real_t * const const_");
  strcat(externalDeclarations, name);
  strcat(externalDeclarations, ";\n");

  strcat(real51PointerDeclarations, "TO_QSPI const real_t * const const_");
  strcat(real51PointerDeclarations, name);
  strcat(real51PointerDeclarations, whiteSpace);
  strcat(real51PointerDeclarations, " = (real_t *)(constants + ");
  sprintf(temp, "%5d)", idx);
  idx += sizeof(real51_t);
  strcat(real51PointerDeclarations, temp);
  strcat(real51PointerDeclarations, ";\n");

  strcat(realArray, "  ");
  for(uint32_t i=0; i<sizeof(real51_t); i++) {
    sprintf(temp, "0x%02x,", *(((uint8_t *)(&real51)) + i));
    strcat(realArray, temp);
  }

  strcat(realArray, "  // const_");
  strcat(realArray, name);
  strcat(realArray, "\n");
}


void generateConstantArray75(char *name, char *value) {
  real_t real75;

  #if defined(DEBUG)
    printf("generateConstantArray75: %-10.10s = %s\n", name, value);
  #endif // DEBUG

  memset(&real75, 0, sizeof(real_t));
  stringToReal(value, (real_t *)&real75, &ctxtReal75);

  strcpy(whiteSpace, "                                        ");
  whiteSpace[13 - strlen(name)] = 0;

  strcat(externalDeclarations, "  extern const real_t * const const_");
  strcat(externalDeclarations, name);
  strcat(externalDeclarations, ";\n");

  strcat(real75PointerDeclarations, "TO_QSPI const real_t * const const_");
  strcat(real75PointerDeclarations, name);
  strcat(real75PointerDeclarations, whiteSpace);
  strcat(real75PointerDeclarations, " = (real_t *)(constants + ");
  sprintf(temp, "%5d)", idx);
  idx += sizeof(real_t);
  strcat(real75PointerDeclarations, temp);
  strcat(real75PointerDeclarations, ";\n");

  strcat(realArray, "  ");
  for(uint32_t i=0; i<sizeof(real_t); i++) {
    sprintf(temp, "0x%02x,", *(((uint8_t *)(&real75)) + i));
    strcat(realArray, temp);
  }

  strcat(realArray, "  // const_");
  strcat(realArray, name);
  strcat(realArray, "\n");
}


void generateConstantArray1071(char *name, char *value) {
  real1071_t real1071;

  #if defined(DEBUG)
    printf("generateConstantArray1071: %-9.9s = %s\n", name, value);
  #endif // DEBUG

  memset(&real1071, 0, sizeof(real1071_t));
  stringToReal(value, (real_t *)&real1071, &ctxtReal1071);

  strcpy(whiteSpace, "                                        ");
  whiteSpace[9 - strlen(name)] = 0;

  strcat(externalDeclarations, "  extern const real_t * const const1071_");
  strcat(externalDeclarations, name);
  strcat(externalDeclarations, ";\n");

  strcat(real1071PointerDeclarations, "TO_QSPI const real_t * const const1071_");
  strcat(real1071PointerDeclarations, name);
  strcat(real1071PointerDeclarations, whiteSpace);
  strcat(real1071PointerDeclarations, " = (real_t *)(constants + ");
  sprintf(temp, "%5d)", idx);
  idx += sizeof(real1071_t);
  strcat(real1071PointerDeclarations, temp);
  strcat(real1071PointerDeclarations, ";\n");

  strcat(realArray, "  ");
  for(uint32_t i=0; i<sizeof(real1071_t); i++) {
    sprintf(temp, "0x%02x,", *(((uint8_t *)(&real1071)) + i));
    strcat(realArray, temp);
  }

  strcat(realArray, "  // const_");
  strcat(realArray, name);
  strcat(realArray, "\n");
}


void generateAllConstants(void) {
  // constants used by the program
  idx = 0;

  strcat(realArray, "TO_QSPI const uint8_t constants[] = {\n");

  // Physical and mathematical constants
  // each constant has 55 significant digits
  c = 0;
  generateConstantArray("a",             "+3.652425000000000000000000000000000000000000000000000000e+02"); c++;   // cnst000 per definition
  generateConstantArray("a0",            "+5.291772109030000000000000000000000000000000000000000000e-11"); c++;   // cnst001
  generateConstantArray("aMoon",         "+3.844000000000000000000000000000000000000000000000000000e+08"); c++;   // cnst002
  generateConstantArray("aEarth",        "+1.495979000000000000000000000000000000000000000000000000e+11"); c++;   // cnst003
  generateConstantArray("c",             "+2.997924580000000000000000000000000000000000000000000000e+08"); c++;   // cnst004 per definition
  generateConstantArray("c1",            "+3.741771852192758011367155555929985138219953097124061418e-16"); c++;   // cnst005

  generateConstantArray("c2",            "+1.438776877503933802146671601543911595199069423148099191e-02"); c++;   // cnst006
  generateConstantArray("e",             "+1.602176634000000000000000000000000000000000000000000000e-19"); c++;   // cnst007 per definition
  generateConstantArray("eE",            "+2.718281828459045235360287471352662497757247093699959575e+00"); c++;   // cnst008 math constant e
  generateConstantArray("F",             "+9.648533212331001840000000000000000000000000000000000000e+04"); c++;   // cnst009
  generateConstantArray("Falpha",        "+2.502907875095892822283902873218215786381271376727149977e+00"); c++;   // cnst010 math constant Falpha
  generateConstantArray("Fdelta",        "+4.669201609102990671853203820466201617258185577475768633e+00"); c++;   // cnst011 math constant Fdelta

  generateConstantArray("G",             "+6.674300000000000000000000000000000000000000000000000000e-11"); c++;   // cnst012
  generateConstantArray("G0",            "+7.748091729863650646680823323308763943587286047673370920e-05"); c++;   // cnst013
  generateConstantArray("GC",            "+9.159655941772190150546035149323841107741493742816721343e-01"); c++;   // cnst014 math constant Catalan
  generateConstantArray("ge",            "-2.002319304362560000000000000000000000000000000000000000e+00"); c++;   // cnst015
  generateConstantArray("GM",            "+3.986004418000000000000000000000000000000000000000000000e+14"); c++;   // cnst016
  generateConstantArray("gEarth",        "+9.806650000000000000000000000000000000000000000000000000e+00"); c++;   // cnst017 per definition


  generateConstantArray("Planck",        "+6.626070150000000000000000000000000000000000000000000000e-34"); c++;   // cnst018
  generateConstantArray("PlanckOn2pi",   "+1.054571817646156391262428003302280744722826330020413122e-34"); c++;   // cnst019
  generateConstantArray("k",             "+1.380649000000000000000000000000000000000000000000000000e-23"); c++;   // cnst020 per definition
  generateConstantArray("KJ",            "+4.835978484169836324476582850545281353533511866004014461e+14"); c++;   // cnst021
  generateConstantArray("lPL",           "+1.616255000000000000000000000000000000000000000000000000e-35"); c++;   // cnst022
  generateConstantArray("me",            "+9.109383701500000000000000000000000000000000000000000000e-31"); c++;   // cnst023

  generateConstantArray("MMoon",         "+7.349000000000000000000000000000000000000000000000000000e+22"); c++;   // cnst024
  generateConstantArray("mn",            "+1.674927498040000000000000000000000000000000000000000000e-27"); c++;   // cnst025
  generateConstantArray("mnOnmp",        "+1.001378418980000000000000000000000000000000000000000000e+00"); c++;   // cnst026
  generateConstantArray("mp",            "+1.672621923690000000000000000000000000000000000000000000e-27"); c++;   // cnst027
  generateConstantArray("mPL",           "+2.176435000000000000000000000000000000000000000000000000e-08"); c++;   // cnst028
  generateConstantArray("mpOnme",        "+1.836152673430000000000000000000000000000000000000000000e+03"); c++;   // cnst029

  generateConstantArray("mu",            "+1.660539066600000000000000000000000000000000000000000000e-27"); c++;   // cnst030
  generateConstantArray("muc2",          "+1.492418085600000000000000000000000000000000000000000000e-10"); c++;   // cnst031
  generateConstantArray("mmu",           "+1.883531627000000000000000000000000000000000000000000000e-28"); c++;   // cnst032
  generateConstantArray("mSun",          "+1.989100000000000000000000000000000000000000000000000000e+30"); c++;   // cnst033
  generateConstantArray("mEarth",        "+5.973600000000000000000000000000000000000000000000000000e+24"); c++;   // cnst034
  generateConstantArray("NA",            "+6.022140760000000000000000000000000000000000000000000000e+23"); c++;   // cnst035 per definition


  generateConstantArray("NaN",           "Not a number"                                                 ); c++;   // cnst036
  generateConstantArray("p0",            "+1.013250000000000000000000000000000000000000000000000000e+05"); c++;   // cnst037 per definition
  generateConstantArray("R",             "+8.314462618153240000000000000000000000000000000000000000e+00"); c++;   // cnst038
  generateConstantArray("re",            "+2.817940326200000000000000000000000000000000000000000000e-15"); c++;   // cnst039
  generateConstantArray("RK",            "+2.581280745930450666004551670608744304245727322140342177e+04"); c++;   // cnst040
  generateConstantArray("RMoon",         "+1.737530000000000000000000000000000000000000000000000000e+06"); c++;   // cnst041

  generateConstantArray("RInfinity",     "+1.097373156816000000000000000000000000000000000000000000e+07"); c++;   // cnst042
  generateConstantArray("RSun",          "+6.960000000000000000000000000000000000000000000000000000e+08"); c++;   // cnst043
  generateConstantArray("REarth",        "+6.371010000000000000000000000000000000000000000000000000e+06"); c++;   // cnst044
  generateConstantArray("Sa",            "+6.378137000000000000000000000000000000000000000000000000e+06"); c++;   // cnst045 per definition
  generateConstantArray("Sb",            "+6.356752314200000000000000000000000000000000000000000000e+06"); c++;   // cnst046
  generateConstantArray("Se2",           "+6.694379990140000000000000000000000000000000000000000000e-03"); c++;   // cnst047


  generateConstantArray("Sep2",          "+6.739496742280000000000000000000000000000000000000000000e-03"); c++;   // cnst048
  generateConstantArray("Sfm1",          "+2.982572235630000000000000000000000000000000000000000000e+02"); c++;   // cnst049 per definition
  generateConstantArray("T0",            "+2.731500000000000000000000000000000000000000000000000000e+02"); c++;   // cnst050 per definition
  generateConstantArray("TP",            "+1.416785000000000000000000000000000000000000000000000000e+32"); c++;   // cnst051
  generateConstantArray("tPL",           "+5.391245000000000000000000000000000000000000000000000000e-44"); c++;   // cnst052
  generateConstantArray("Vm",            "+2.241396954501413773501110288675055514433752775721687639e-02"); c++;   // cnst053

  generateConstantArray("Z0",            "+3.767303134617706554681984004203193082686235083524186552e+02"); c++;   // cnst054 mu0 * c
  generateConstantArray("alpha",         "+7.297352569300000000000000000000000000000000000000000000e-03"); c++;   // cnst055
  generateConstantArray("gamma",         "+6.674300000000000000000000000000000000000000000000000000e-11"); c++;   // cnst056 gamma = gEarth --> is this duplicate constant needed?
  generateConstantArray("gammaEM",       "+5.772156649015328606065120900824024310421593359399235988e-01"); c++;   // cnst057 math constant Euler-Mascheroni
  generateConstantArray("gammap",        "+2.675221874400000000000000000000000000000000000000000000e+08"); c++;   // cnst058
  generateConstantArray("DELTAvcs",      "+9.192631770000000000000000000000000000000000000000000000e+09"); c++;   // cnst059 per definition

  generateConstantArray("epsilon0",      "+8.854187812800000000000000000000000000000000000000000000e-12"); c++;   // cnst060
  generateConstantArray("lambdaC",       "+2.426310238670000000000000000000000000000000000000000000e-12"); c++;   // cnst061
  generateConstantArray("lambdaCn",      "+1.319590905810000000000000000000000000000000000000000000e-15"); c++;   // cnst062
  generateConstantArray("lambdaCp",      "+1.321409855390000000000000000000000000000000000000000000e-15"); c++;   // cnst063
  generateConstantArray("mu0",           "+1.256637062120000000000000000000000000000000000000000000e-06"); c++;   // cnst064
  generateConstantArray("muB",           "+9.274010078000000000000000000000000000000000000000000000e-24"); c++;   // cnst065

  generateConstantArray("mue",           "-9.284764704300000000000000000000000000000000000000000000e-24"); c++;   // cnst066
  generateConstantArray("mueOnmuB",      "-1.001159652181280000000000000000000000000000000000000000e+00"); c++;   // cnst067
  generateConstantArray("mun",           "-9.662365000000000000000000000000000000000000000000000000e-27"); c++;   // cnst068
  generateConstantArray("mup",           "+1.410606797360000000000000000000000000000000000000000000e-26"); c++;   // cnst069
  generateConstantArray("muu",           "+5.050783746100000000000000000000000000000000000000000000e-27"); c++;   // cnst070
  generateConstantArray("mumu",          "-4.490448300000000000000000000000000000000000000000000000e-26"); c++;   // cnst071


  generateConstantArray("sigmaB",        "+5.670374419184429453970996731889230875840122970291303682e-08"); c++;   // cnst072
  generateConstantArray("PHI",           "+1.618033988749894848204586834365638117720309179805762862e+00"); c++;   // cnst073 math constant phi = (1 + sqrt(5)) / 2
  generateConstantArray("PHI0",          "+2.067833848461929323081115412147497340171545654934323552e-15"); c++;   // cnst074
  generateConstantArray("omega",         "+7.292115000000000000000000000000000000000000000000000000e-05"); c++;   // cnst075
  generateConstantArray("minusInfinity", "-9.999999999999999999999999999999999999999999999999999999e+9999"); c++; // cnst076 math "constant"
  generateConstantArray("plusInfinity",  "+9.999999999999999999999999999999999999999999999999999999e+9999"); c++; // cnst077 math "constant"

  generateConstantArray("0",             "0"); c++;                                                               // cnst078

  // All the formulas are 100% exact conversion formulas
  generateConstantArray("PointToMm",     "+3.527777777777777777777777777777777777777777777777777778e-01");        // cnst079       mm     = pt × 0.0254 / 72 × 1000
  generateConstantArray("InchToMm",      "+2.540000000000000000000000000000000000000000000000000000e+01");        // cnst080       mm     = inch × 0.0254 × 1000
  generateConstantArray("FtToM",         "+3.048000000000000000000000000000000000000000000000000000e-01");        // cnst081       m      = ft × 12 × 0.0254
  generateConstantArray("SfeetToM",      "+3.048006096012192024384048768097536195072390144780289561e-01");        // cnst082       m      = sfeetus × (1200 / 3937)
  generateConstantArray("YardToM",       "+9.144000000000000000000000000000000000000000000000000000e-01");        // cnst083       m      = yard × 3 × 12 × 0.0254
  generateConstantArray("FathomToM",     "+1.828800000000000000000000000000000000000000000000000000e+00");        // cnst084       m      = fathom × 6 × 12 × 0.0254
  generateConstantArray("MiToKm",        "+1.609344000000000000000000000000000000000000000000000000e+00");        // cnst085       km     = mile × 63360 × 0.0254 / 1000
  generateConstantArray("MiSqToKmSq",    "+2.589988110336000000000000000000000000000000000000000000e+00");        // cnst086       km     = mile^2 × (63360 × 0.0254 / 1000)^2
  generateConstantArray("NmiToKm",       "+1.852000000000000000000000000000000000000000000000000000e+00");        // cnst087       km     = nmi × 1852 / 1000
  generateConstantArray("NmiToMi",       "+1.150779448023542511731488109440865346377157400779448024e+00");        // cnst088       km     = nmi × 1852 / 1609.344
  generateConstantArray("NmiSqToKmSq",   "+3.429904000000000000000000000000000000000000000000000000e+00");        // cnst089       km     = nmi^2 × (1852 / 1000)^2
  generateConstantArray("AuToM",         "+1.495978707000000000000000000000000000000000000000000000e+11");        // cnst090       m      = au × 149597870700
  generateConstantArray("LyToM",         "+9.460730472580800000000000000000000000000000000000000000e+15");        // cnst091       m      = ly × 299792458 × 3600 × 24 × 365.25
  generateConstantArray("PcToM",         "+3.085677581491367278913937957796471610731921160409179801e+16");        // cnst092       m      = pc × 149597870700 × 648000 / pi
  generateConstantArray("LiToM",         "+5.000000000000000000000000000000000000000000000000000000e+02");        // cnst093       m      = lǐ × 500
  generateConstantArray("YinToM",        "+3.000000000000000000000000000000000000000000000000000000e-02");        // cnst094       m      = yǐn / 0.03
  generateConstantArray("CunToM",        "+3.000000000000000000000000000000000000000000000000000000e+01");        // cnst095       m      = cùn / 30
  generateConstantArray("ZhangToM",      "+3.000000000000000000000000000000000000000000000000000000e-01");        // cnst096       m      = zhàng / 0.3
  generateConstantArray("FenToM",        "+3.000000000000000000000000000000000000000000000000000000e+02");        // cnst097       m      = fēn / 300
  generateConstantArray("MiToM",         "+1.609344000000000000000000000000000000000000000000000000e+03");        // cnst098       m      = mile × 63360 × 0.0254
  generateConstantArray("NmiToM",        "+1.852000000000000000000000000000000000000000000000000000e+03");        // cnst099       m      = nmi × 1852

  generateConstantArray("Kmphmps",       "+2.777777777777777777777777777777777777777777777777777777e-01");        // cnst100      mps      =  Kmph  * 0.277...   // 2.5/9
  generateConstantArray("RpmDegps",      "+6.000000000000000000000000000000000000000000000000000000e+00");        // cnst101     Degps    =  Rpm * 6
  generateConstantArray("Mphmps",        "+4.470400000000000000000000000000000000000000000000000000e-01");        // cnst102     mps      =  Mph  * 0.44704     //11.176/25
  generateConstantArray("RpmRadps",      "+1.047197551196597746154214461093167628065723133125035274e-01");        // cnst103     Radps    =  Rpm  * 0.1047   // pi/30
  generateConstantArray("DegRad",        "+1.745329251994329576923690768488612713442871888541725456e-02");        // cnst104     Rad      =  Deg  * pi / 180
  generateConstantArray("DegGrad",       "+1.111111111111111111111111111111111111111111111111111111e+00");        // cnst105     Grad     =  Deg  * 10 / 9
  generateConstantArray("GradRad",       "+1.570796326794896619231321691639751442098584699687552910e-02");        // cnst106     Rad      =  Grad * pi / 200

  generateConstantArray("AccreToHa",     "+4.046856422400000000000000000000000000000000000000000000e-01");        // cnst107      ha     = acre × 0.0254² × 12² × 43560 / 10000
  generateConstantArray("AccreusToHa",   "+4.046872609874252006568529266090790246096621225500515517e-01");        // cnst108      ha     = acreus × (1200 / 3937)² × 43560 / 10000
  generateConstantArray("MuToM2",        "+1.500000000000000000000000000000000000000000000000000000e-03");        // cnst109      m²     = mǔ / 0.0015
  generateConstantArray("FlozukToMl",    "+2.841306250000000000000000000000000000000000000000000000e+01");        // cnst110      ml     = flozuk × 4.54609e-3 / 160 × 1000000
  generateConstantArray("FlozusToMl",    "+2.957352956250000000000000000000000000000000000000000000e+01");        // cnst111      ml     = flozus × 231 × 0.0254³ / 128 × 1000000
  generateConstantArray("GalusToL",      "+3.785411784000000000000000000000000000000000000000000000e+00");        // cnst112      l      = galus × 231 × 0.0254³ × 1000
  generateConstantArray("GalukToL",      "+4.546090000000000000000000000000000000000000000000000000e+00");        // cnst113      l      = galuk × 4.54609e-3 × 1000
  generateConstantArray("QuartToL",      "+1.136522500000000000000000000000000000000000000000000000e+00");        // cnst114      l      = quart × 4.54609e-3 / 4 × 1000
  generateConstantArray("BarrelToM3",    "+1.589872949280000000000000000000000000000000000000000000e-01");        // cnst115      m³     = barrel × 42 × 231 × 0.0254³

  generateConstantArray("CaratToG",      "+2.000000000000000000000000000000000000000000000000000000e-01");        // cnst116      g      = carat × 0.0002 × 1000
  generateConstantArray("OzToG",         "+2.834952312500000000000000000000000000000000000000000000e+01");        // cnst117      g      = oz × (0.45359237 / 16) × 1000
  generateConstantArray("TrozToG",       "+3.110347680000000000000000000000000000000000000000000000e+01");        // cnst118      g      = tr.oz × 0.45359237 × 175 / 12 × 1000
  generateConstantArray("LbToKg",        "+4.535923700000000000000000000000000000000000000000000000e-01");        // cnst119      kg     = lb × 0.45359237     (1 lb (pound) = 16 oz)
  generateConstantArray("StoneToKg",     "+6.350293180000000000000000000000000000000000000000000000e+00");        // cnst120      kg     = stone × 14 × 0.45359237
  generateConstantArray("ShortcwtToKg",  "+4.535923700000000000000000000000000000000000000000000000e+01");        // cnst121      kg     = short cwt × 100 × 0.45359237 (short cwt = short hundredweight)
  generateConstantArray("CwtToKg",       "+5.080234544000000000000000000000000000000000000000000000e+01");        // cnst122      kg     = cwt × 112 × 0.45359237       (cwt = long hundredweight)
  generateConstantArray("ShorttonToKg",  "+9.071847400000000000000000000000000000000000000000000000e+02");        // cnst123      kg     = short ton × 2000 × 0.45359237
  generateConstantArray("TonToKg",       "+1.016046908800000000000000000000000000000000000000000000e+03");        // cnst124      kg     = ton × 2240 × 0.45359237

  generateConstantArray("CalToJ",        "+4.186800000000000000000000000000000000000000000000000000e+00");        // cnst125      joule  = calorie × 4.1868
  generateConstantArray("BtuToJ",        "+1.055055852620000000000000000000000000000000000000000000e+03");        // cnst126      joule  = Btu × 1055.05585262
  generateConstantArray("WhToJ",         "+3.600000000000000000000000000000000000000000000000000000e+03");        // cnst127      joule  = Wh × 3600

  generateConstantArray("LbfToN",        "+4.448221615260500000000000000000000000000000000000000000e+00");        // cnst128      newton = lbf × 9.80665 × 0.45359237

  generateConstantArray("TorrToPa",      "+1.333223684210526315789473684210526315789473684210526316e+02");        // cnst129      pascal = torr × 101325 / 760
  #if(MMHG_PA_133_3224 == 1)
    generateConstantArray("MmhgToPa",    "+1.333224000000000000000000000000000000000000000000000000e+02");        // cnst130      pascal = mm.Hg × 133.3224
    generateConstantArray("InhgToPa",    "+3.386388960000000000000000000000000000000000000000000000e+03");        // cnst131      pascal = in.Hg × 133.3224 × 25.4
  #else // (MMHG_PA_133_3224 == 0)
    generateConstantArray("MmhgToPa",    "+1.333223874150000000000000000000000000000000000000000000e+02");// cnst              pascal = mm.Hg × 13.5951 × 9.80665
    generateConstantArray("InhgToPa",    "+3.386388640341000000000000000000000000000000000000000000e+03");// cnst              pascal = in.Hg × 13.5951 × 9.80665 × 2.54
  #endif // (MMHG_PA_133_3224 == 1)
  generateConstantArray("PsiToPa",       "+6.894757293168361336722673445346890693781387562775125550e+03");        // cnst132      pascal = psi × 0.45359237 × 9.80665 / 0.0254²
  generateConstantArray("BarToPa",       "+1.000000000000000000000000000000000000000000000000000000e+05");        // cnst133      pascal = bar  × 100000
  generateConstantArray("AtmToPa",       "+1.013250000000000000000000000000000000000000000000000000e+05");        // cnst134      pascal = atm × 101325

  generateConstantArray("HpmToW",        "+7.354987500000000000000000000000000000000000000000000000e+02");        // cnst135      watt   = HPM × 75 × 9.80665
  generateConstantArray("HpukToW",       "+7.456998715822702200000000000000000000000000000000000000e+02");        // cnst136      watt   = HPUK × 550 × 0.3048 × 9.80665 × 0.45359237
  generateConstantArray("HpeToW",        "+7.460000000000000000000000000000000000000000000000000000e+02");        // cnst137      watt   = HPE × 746

  generateConstantArray("YearToS",       "+3.155695200000000000000000000000000000000000000000000000e+07");        // cnst138      second = year  × (365.2425 × 24 × 3600)

  generateConstantArray("LbfftToNm",     "+1.355817948331400400000000000000000000000000000000000000e+00");        // cnst139      Nm = lbf×ft × 9.80665 × 0.45359237 × 12 × 0.0254

  generateConstantArray("furToM",        "+2.011680000000000000000000000000000000000000000000000000e+02");        // cnst140      fff menu: Convert furlong to meter
  generateConstantArray("ftnToS",        "+1.209600000000000000000000000000000000000000000000000000e+06");        // cnst141      fff menu: Convert fortnight to second
  generateConstantArray("fpfToMps",      "+1.663095238095240000000000000000000000000000000000000000e-04");        // cnst142      fff menu: Convert furlong per fortnight to meter per second
  generateConstantArray("brdsTom",       "+1.000000000000000000000000000000000000000000000000000000e-08");        // cnst143      fff menu: Convert beardsecond to meter
  generateConstantArray("firToKg",       "+4.082331330000000000000000000000000000000000000000000000e+01");        // cnst144      fff menu: Convert firkin to kilogram
  generateConstantArray("fpfToKph",      "+5.987142857142860000000000000000000000000000000000000000e-04");        // cnst145      fff menu: Convert furlong per fortnight to kilometer per hour
  generateConstantArray("brdsToIn",      "+3.937007874015750000000000000000000000000000000000000000e-07");        // cnst146      fff menu: Convert beardsecond to inch
  generateConstantArray("firToLb",       "+9.000000734139932000000000000000000000000000000000000000e+01");        // cnst147      fff menu: Convert firkin to pound
  generateConstantArray("fpfToMph",      "+3.720247341856200000000000000000000000000000000000000000e-04");        // cnst148      fff menu: Convert furlong per fortnight to mile per hour

  generateConstantArray("fpsToKph",      "+1.097280000000000000000000000000000000000000000000000000e+00");        // cnst149      foot per second to kilometer per hour
  generateConstantArray("fpsToMps",      "+3.048000000000000000000000000000000000000000000000000000e-01");        // cnst150      foot per second to meter per second


  generateConstantArray("_108",          "-1.080000000000000000000000000000000000000000000000000000e+02");        // cnst151
  generateConstantArray("_4",            "-4.000000000000000000000000000000000000000000000000000000e+00");        // cnst152
  generateConstantArray("_1",            "-1.000000000000000000000000000000000000000000000000000000e+00");        // cnst153
  generateConstantArray("_1oneE",        "-3.678794411714423215955237701614608674458111310317678345e-01");        // cnst154
  generateConstantArray("1e_49",         "+1.000000000000000000000000000000000000000000000000000000e-49");        // cnst155
  generateConstantArray("1e_37",         "+1.000000000000000000000000000000000000000000000000000000e-37");        // cnst156
  generateConstantArray("1e_24",         "+1.000000000000000000000000000000000000000000000000000000e-24");        // cnst157
  generateConstantArray("1e_6",          "+1.000000000000000000000000000000000000000000000000000000e-06");        // cnst158
  generateConstantArray("1e_4",          "+1.000000000000000000000000000000000000000000000000000000e-04");        // cnst159
  generateConstantArray("1on10",         "+1.000000000000000000000000000000000000000000000000000000e-01");        // cnst160
  generateConstantArray("1on4",          "+2.500000000000000000000000000000000000000000000000000000e-01");        // cnst161
  generateConstantArray("1on3",          "+3.333333333333333333333333333333333333333333333333333333e-01");        // cnst162
  generateConstantArray("1on2",          "+5.000000000000000000000000000000000000000000000000000000e-01");        // cnst163
  generateConstantArray("egamma",        "+5.772156649015328606065120900824024310421593359399235988e-01");        // cnst164
  generateConstantArray("ln2",           "+6.931471805599453094172321214581765680755001343602552541e-01");        // cnst165
  generateConstantArray("root2on2",      "+7.071067811865475244008443621048490392848359376884740366e-01");        // cnst166
  generateConstantArray("piOn4",         "+7.853981633974483096156608458198757210492923498437764552e-01");        // cnst167
  generateConstantArray("root3on2",      "+8.660254037844386467637231707529361834714026269051903140e-01");        // cnst168
  generateConstantArray("9on10",         "+9.000000000000000000000000000000000000000000000000000000e-01");        // cnst169
  generateConstantArray("ln2piOn2",      "+9.189385332046727417803297364056176398613974736377834128e-01");        // cnst170
  generateConstantArray("1",             "+1.000000000000000000000000000000000000000000000000000000e+00");        // cnst171
  generateConstantArray("3on2",          "+1.500000000000000000000000000000000000000000000000000000e+00");        // cnst172
  generateConstantArray("piOn2",         "+1.570796326794896619231321691639751442098584699687552910e+00");        // cnst173
  generateConstantArray("9on5",          "+1.800000000000000000000000000000000000000000000000000000e+00");        // cnst174
  generateConstantArray("2",             "+2.000000000000000000000000000000000000000000000000000000e+00");        // cnst175
  generateConstantArray("ln10",          "+2.302585092994045684017991454684364207601101488628772976e+00");        // cnst176
  generateConstantArray("3piOn4",        "+2.356194490192344928846982537459627163147877049531329366e+00");        // cnst177
  generateConstantArray("3",             "+3.000000000000000000000000000000000000000000000000000000e+00");        // cnst178
  generateConstantArray("pi",            "+3.141592653589793238462643383279502884197169399375105821e+00");        // cnst179

  generateConstantArray("4",             "+4.000000000000000000000000000000000000000000000000000000e+00");        // cnst180
  generateConstantArray("3piOn2",        "+4.712388980384689857693965074919254326295754099062658731e+00");        // cnst181
  generateConstantArray("5",             "+5.000000000000000000000000000000000000000000000000000000e+00");        // cnst182
  generateConstantArray("6",             "+6.000000000000000000000000000000000000000000000000000000e+00");        // cnst183
  generateConstantArray("2pi",           "+6.283185307179586476925286766559005768394338798750211642e+00");        // cnst184
  generateConstantArray("8",             "+8.000000000000000000000000000000000000000000000000000000e+00");        // cnst185
  generateConstantArray("9",             "+9.000000000000000000000000000000000000000000000000000000e+00");        // cnst186
  generateConstantArray("10",            "+1.000000000000000000000000000000000000000000000000000000e+01");        // cnst187
  generateConstantArray("12",            "+1.200000000000000000000000000000000000000000000000000000e+01");        // cnst188
  generateConstantArray("16",            "+1.600000000000000000000000000000000000000000000000000000e+01");        // cnst189
  generateConstantArray("20",            "+2.000000000000000000000000000000000000000000000000000000e+01");        // cnst190
  //generateConstantArray("21",            "+2.100000000000000000000000000000000000000000000000000000e+01"); // cnst         used for Lanczos N=22
  //generateConstantArray("gammaR",        "+2.311891000000000000000000000000000000000000000000000000e+01"); // cnst         used for Lanczos N=22
  generateConstantArray("25",            "+2.500000000000000000000000000000000000000000000000000000e+01");        // cnst191
  generateConstantArray("27",            "+2.700000000000000000000000000000000000000000000000000000e+01");        // cnst192
  generateConstantArray("29",            "+2.900000000000000000000000000000000000000000000000000000e+01");        // cnst193     used for Lanczos N=30
  generateConstantArray("30",            "+3.000000000000000000000000000000000000000000000000000000e+01");        // cnst194
  generateConstantArray("gammaR",        "+3.143188335932791233062744140625000000000000000000000000e+01");        // cnst195     used for Lanczos N=30
  generateConstantArray("32",            "+3.200000000000000000000000000000000000000000000000000000e+01");        // cnst196
  generateConstantArray("36",            "+3.600000000000000000000000000000000000000000000000000000e+01");        // cnst197
  generateConstantArray("47",            "+4.700000000000000000000000000000000000000000000000000000e+01");        // cnst198
  generateConstantArray("180onPi",       "+5.729577951308232087679815481410517033240547246656432155e+01");        // cnst199
  generateConstantArray("60",            "+6.000000000000000000000000000000000000000000000000000000e+01");        // cnst200
  generateConstantArray("200onPi",       "+6.366197723675813430755350534900574481378385829618257950e+01");        // cnst201
  generateConstantArray("125",           "+1.250000000000000000000000000000000000000000000000000000e+02");        // cnst202
  generateConstantArray("150",           "+1.500000000000000000000000000000000000000000000000000000e+02");        // cnst203
  generateConstantArray("205",           "+2.050000000000000000000000000000000000000000000000000000e+02");        // cnst204
  generateConstantArray("360",           "+3.600000000000000000000000000000000000000000000000000000e+02");        // cnst205
  generateConstantArray("400",           "+4.000000000000000000000000000000000000000000000000000000e+02");        // cnst206
  generateConstantArray("600",           "+6.000000000000000000000000000000000000000000000000000000e+02");        // cnst207
  generateConstantArray("1000",          "+1.000000000000000000000000000000000000000000000000000000e+03");        // cnst208
  generateConstantArray("1260",          "+1.260000000000000000000000000000000000000000000000000000e+03");        // cnst209
  generateConstantArray("1680",          "+1.680000000000000000000000000000000000000000000000000000e+03");        // cnst210
  generateConstantArray("2100",          "+2.100000000000000000000000000000000000000000000000000000e+03");        // cnst211
  generateConstantArray("2520",          "+2.520000000000000000000000000000000000000000000000000000e+03");        // cnst212
  generateConstantArray("3600",          "+3.600000000000000000000000000000000000000000000000000000e+03");        // cnst213
  generateConstantArray("6000",          "+6.000000000000000000000000000000000000000000000000000000e+03");        // cnst214
  generateConstantArray("9999",          "+9.999000000000000000000000000000000000000000000000000000e+03");        // cnst215
  generateConstantArray("10000",         "+1.000000000000000000000000000000000000000000000000000000e+04");        // cnst216
  generateConstantArray("25200",         "+2.520000000000000000000000000000000000000000000000000000e+04");        // cnst217
  generateConstantArray("42000",         "+4.200000000000000000000000000000000000000000000000000000e+04");        // cnst218
  generateConstantArray("73766",         "+7.376600000000000000000000000000000000000000000000000000e+04");        // cnst219
  generateConstantArray("1e6",           "+1.000000000000000000000000000000000000000000000000000000e+06");        // cnst220
  generateConstantArray("1e8",           "+1.000000000000000000000000000000000000000000000000000000e+08");        // cnst221
  generateConstantArray("1e9",           "+1.000000000000000000000000000000000000000000000000000000e+09");        // cnst222
  generateConstantArray("2p32",          "+4.294967296000000000000000000000000000000000000000000000e+09");        // cnst223
  generateConstantArray("1e32",          "+1.000000000000000000000000000000000000000000000000000000e+32");        // cnst224
  generateConstantArray("1e_10000",      "+1.000000000000000000000000000000000000000000000000000000e-10000");     // cnst225
  generateConstantArray("995on1000",     "+9.950000000000000000000000000000000000000000000000000000e-01");        // cnst226
  generateConstantArray("1e_32",         "+1.000000000000000000000000000000000000000000000000000000e-32");        // cnst227
  generateConstantArray("rt3",           "+1.732050807568877293527446341505872366942805253810380628e+00");        // cnst228
  generateConstantArray("GaluseqE",      "+3.370000000000000000000000000000000000000000000000000000e+01");        // cnst229 if the number of constants changes: don't forget to update NUMBER_OF_CONSTANTS_* in defines.h 


  // Lanczos's coefficients calculated for N=22 and G=22.61891 using Toth's program: https://www.vttoth.com/CMS/projects/41
  // source: https://www.vttoth.com/FILES/lanczos.tgz
  //                                                   1    1    2    2    3    3    4    4    5    5
  //                                         1    5    0    5    0    5    0    5    0    5    0    5
  //generateConstantArray51("gammaC00",      "+2.506628274631000502415765284811045253330102106110384424e+00");
  //generateConstantArray51("gammaC01",      "+1.898901420935934892121516421489444871166098343657373978e+10");
  //generateConstantArray51("gammaC02",      "-1.441562000905355882360184024174589398850864438036062023e+11");
  //generateConstantArray51("gammaC03",      "+4.960354542573828137004589453751102249851958972199579195e+11");
  //generateConstantArray51("gammaC04",      "-1.023780406198473219243634817725018714004771971677300816e+12");
  //generateConstantArray51("gammaC05",      "+1.413597258976513273633654064270589122622864275842333381e+12");
  //generateConstantArray51("gammaC06",      "-1.379067427882918397935921608473380694063139188889206483e+12");
  //generateConstantArray51("gammaC07",      "+9.788204370638776727185550760418500178668333538359412666e+11");
  //generateConstantArray51("gammaC08",      "-5.128994840924296233163734159755732045598563235099171971e+11");
  //generateConstantArray51("gammaC09",      "+1.993214894537074020805536689671109703586865664821761460e+11");
  //generateConstantArray51("gammaC10",      "-5.724477320502851934636585458046006238313974208001884541e+10");
  //generateConstantArray51("gammaC11",      "+1.201655806354758157534702159196092100664925734696554628e+10");
  //generateConstantArray51("gammaC12",      "-1.809010182477543231013601186822450869655092323236977417e+09");
  //generateConstantArray51("gammaC13",      "+1.898547541983866894247096477096985200814067754731731207e+08");
  //generateConstantArray51("gammaC14",      "-1.334263251277484954309331237987833882618884749172456742e+07");
  //generateConstantArray51("gammaC15",      "+5.933439303341291714746800542914306113010567634244078777e+05");
  //generateConstantArray51("gammaC16",      "-1.540327280024945239058720773875327176489146552268675093e+04");
  //generateConstantArray51("gammaC17",      "+2.074489944028394118495377261887808208026742582699496038e+02");
  //generateConstantArray51("gammaC18",      "-1.209628455273316629072046046890209041606257952008366823e+00");
  //generateConstantArray51("gammaC19",      "+2.269611174611951432929578313072997499699731150734389541e-03");
  //generateConstantArray51("gammaC20",      "-7.988885865727861701217352063783045960010829242532606098e-07");
  //generateConstantArray51("gammaC21",      "+1.657343879782420104047477447896382420026771040379552772e-11");

  // A better set of Lanczos constants?
  // https://www.boost.org/doc/libs/1_71_0/boost/math/special_functions/lanczos.hpp
  // https://www.boost.org/doc/libs/1_71_0/libs/math/doc/html/math_toolkit/lanczos.html
  // Lanczos's coefficients calculated for N=30 and G=30.9318857491016387939453125 using Toth's program: https://www.vttoth.com/CMS/projects/41
  // source: https://www.vttoth.com/FILES/lanczos.tgz
  generateConstantArray51("gammaC00",      "+2.506628274631000502415765284811045253006986740036318756703152698088652909808141644264478158114643"); // cnst207
  generateConstantArray51("gammaC01",      "+90795313438554.12585760728412902207185494121818510422990562390199419594778421509725059250660477478"); // cnst208
  generateConstantArray51("gammaC02",      "-966788810976616.3165238613163922965882171247384377771690792930892852741666385482155753752741846215"); // cnst209
  generateConstantArray51("gammaC03",      "+4800584619652903.130520636355077553806266769741879659498830407152738371167934130745600044623388068"); // cnst210
  generateConstantArray51("gammaC04",      "-14765868961297540.27064904092821149556100711736690133148186310232345861145647352272488652687903457"); // cnst211
  generateConstantArray51("gammaC05",      "+31520009430682538.17457937985920649010992386050798974102315423368438398460245896094052856122203775"); // cnst212
  generateConstantArray51("gammaC06",      "-49582365010416661.09326008795178786489253227385559918969410907133030684376335533671631031226780693"); // cnst213
  generateConstantArray51("gammaC07",      "+59568927402677002.04904143939675965126139196724493177865501398609411221897535112902272116361691451"); // cnst214
  generateConstantArray51("gammaC08",      "-55906342816448463.66899438215049258933959227649607458054232171494476786360919120606779433224203661"); // cnst215
  generateConstantArray51("gammaC09",      "+41579705761882718.81836872026846865595091094440150772658809279820390684724850793073271091274939857"); // cnst216
  generateConstantArray51("gammaC10",      "-24720590950576683.15802797249415999638807846332716128189191944706094647468094435934791589404852933"); // cnst217
  generateConstantArray51("gammaC11",      "+11801286985635343.58575847383935274746074763562173560062003882605616928057523864988435228756829000"); // cnst218
  generateConstantArray51("gammaC12",      "-4528196760270806.995369621666200554735964133084677928395568191894066774034949226537269118163329489"); // cnst219
  generateConstantArray51("gammaC13",      "+1393637064384668.917157722908202033726675908093527246704252104958408303381715387740313008845141904"); // cnst220
  generateConstantArray51("gammaC14",      "-342325016766888.5479936955467723387327600568400337988293619211103486673308239810777313598627315000"); // cnst221
  generateConstantArray51("gammaC15",      "+66578560073752.67246403368251720854813222816576859988564202476567602534436134110254400104404942690"); // cnst222
  generateConstantArray51("gammaC16",      "-10138544793022.41604607361389789580035078467043905508354626409172360042771928364449573017241522124"); // cnst223
  generateConstantArray51("gammaC17",      "+1190960562789.022438954352946350698116714288406439572882388541923119338089933765849690628214181895"); // cnst224
  generateConstantArray51("gammaC18",      "-105857166683.4123935373722836022279857082446927458625016646619942749346232137590435016079220044575"); // cnst225
  generateConstantArray51("gammaC19",      "+6945291327.796451124796820522079456356395826950647769057580507091796596412483352351183618549540841"); // cnst226
  generateConstantArray51("gammaC20",      "-325841232.8464260929688459624630603325071713695605050282752915466327762939975965122976740632863654"); // cnst227
  generateConstantArray51("gammaC21",      "+10491089.04183867431328778246866673594812558539972730107563825597306012268992151854201423652554125"); // cnst228
  generateConstantArray51("gammaC22",      "-219652.9521075940388150629624539015343302845601375714110391179944415326942002537588845815284375311"); // cnst229
  generateConstantArray51("gammaC23",      "+2782.640500292405732331071582785081107276742114500310058012342169019346915906467717358069437084413"); // cnst230
  generateConstantArray51("gammaC24",      "-19.31769482393126228999283928711817461826517031491190754697778125203682359806685621504868658022287"); // cnst231
  generateConstantArray51("gammaC25",      "+0.063813226038364736490677427053094184825560153837400637303741419820260651820063721448175876091640"); // cnst232
  generateConstantArray51("gammaC26",      "-0.000081213345051388882076245151519040492731624505633194015094047296992491188162952243561414155660"); // cnst233
  generateConstantArray51("gammaC27",      "+0.000000028425884712306176285600873249949436913248124688912080334562388569408577988201187292514310"); // cnst234
  generateConstantArray51("gammaC28",      "-0.000000000001515686855682081535390179935440192138970398946754350022046202956603870401666503058594"); // cnst235
  generateConstantArray51("gammaC29",      "+0.000000000000000003727184110478268994444830355775133199862144652804253659035860755294511160286895"); // cnst236

  // Array angle180
  generateConstantArray75("pi_75",         "+3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825e+00"); // cnst237
  generateConstantArray75("200",           "+2.000000000000000000000000000000000000000000000000000000e+02"); // cnst238
  generateConstantArray75("180",           "+1.800000000000000000000000000000000000000000000000000000e+02"); // cnst239

  // Array angle90
  generateConstantArray75("piOn2_75",      "+1.570796326794896619231321691639751442098584699687552910487472296153908203143104499314017412e+00"); // cnst240
  generateConstantArray75("100",           "+1.000000000000000000000000000000000000000000000000000000e+02"); // cnst241
  generateConstantArray75("90",            "+9.000000000000000000000000000000000000000000000000000000e+01"); // cnst242

  // Array angle45
  generateConstantArray75("piOn4_75",      "+7.85398163397448309615660845819875721049292349843776455243736148076954101571552249657008706e-01"); // cnst243
  generateConstantArray75("50",            "+5.000000000000000000000000000000000000000000000000000000e+01"); // cnst244
  generateConstantArray75("45",            "+4.500000000000000000000000000000000000000000000000000000e+01"); // cnst245

  generateConstantArray1071("2pi",       "+6.2831853071795864769252867665590057683943387987502116419498891846156328125724179972560696506842341359" //   101
                                            "6429617302656461329418768921910116446345071881625696223490056820540387704221111928924589790986076392" //   201
                                            "8857621951331866892256951296467573566330542403818291297133846920697220908653296426787214520498282547" //   301
                                            "4491740132126311763497630418419256585081834307287357851807200226610610976409330427682939038830232188" //   401
                                            "6611454073151918390618437223476386522358621023709614892475992549913470377150544978245587636602389825" //   501
                                            "9667346724881313286172042789892790449474381404359721887405541078434352586353504769349636935338810264" //   601
                                            "0011362542905271216555715426855155792183472743574429368818024499068602930991707421015845593785178470" //   701
                                            "8403991222425804392172806883631962725954954261992103741442269999999674595609990211946346563219263719" //   801
                                            "0048918910693816605285044616506689370070523862376342020006275677505773175066416762841234355338294607" //   901
                                            "1965069808575109374623191257277647075751875039155637155610643424536132260038557532223918184328403978" //  1001
                                            "7619051440213097172655773187230676365593646060390407060370593799154724519882778249944355056695826303");// 1101
                                            //"1149714484908301391901659066233723455711778150196763509274929878638510120801855403342278019697648025" //  1201
                                            //"7167232071274153202094203638859111923978935356748988965107595494536942080950692924160933685181389825" //  1301
                                            //"8662735405797830420950432411393204811607630038702250676486007117528049499294652782839854520853984559" //  1401
                                            //"3564709563272018683443282439849172630060572365949111413499677010989177173853991381854421595018605910" //  1501
                                            //"6423306899744055119204729613309982397636695955071327396148530850557251036368351493457819555455876001" //  1601
                                            //"6329412003229049838434643442954470028288394713709632272231470510426695148369893687704664781478828666" //  1701
                                            //"9095524833725037967138971124198438444368545100508513775343580989203306933609977254465583572171568767" //  1801
                                            //"6559359533629082019077675727219013601284502504102347859697921682569772538912084839305700444213223726" //  1901
                                            //"1348855724407838989009424742757392191272874383457493552931514792482778173166529199162678095605518019" //  2001
                                            //"8931528157902538936796705191419651645241044978815453438956536965202953981805280272788874910610136406" //  2101
                                            //"9925049034987993028628596183813185018744433929230314197167748211957719195459509978603235078569362765" //  2201
                                            //"3736773788554831198371185049190791886209994504936169197454728939169730767347244525219824921610248776" //  2301
                                            //"8780902488273099525561595431382871995400259232178883389737111696812706844144451656977296316912057012" //  2401
                                            //"0336854789045349353577905042770450999093334556479729131922327097724611549129960711872691363486482250" //  2501
                                            //"3015213895890219319218805045775942178629133827373445749788112020300661723585736184174952183564987717" //  2601
                                            //"8019429819351970522731099563786259569643365997897445317609715128028540955110264759282903047492468729" //  2701
                                            //"0857168895905317356421022827094714790462268543322042719390724628859049698743742202915308071805598688" //  2801
                                            //"0748401462115707812439677489561695697936664289142773750388701286043690638209696201074122936134983855" //  2901
                                            //"6382395879904122839326857508881287490247436384359996782031839123629350285382479497881814372988463923" //  3001
                                            //"1358904161902931004504632077638602841875242757119132778755741660781395841546934443651251993230028430" //  3101
                                            //"0613607689546909840521082933185040299488570146503733200426486817638142097266346929930290781159253712" //  3201
                                            //"2011016213317593996327149472768105142918205794128280221942412560878079519031354315400840675739872014" //  3301
                                            //"4611175263527188437462502942410658563836523722517346431583968296976583289412191505413914441835134233" //  3401
                                            //"4458219633818305603470134254971664457436704187079314502421671583027397641828884201350206693422062825" //  3501
                                            //"3422273981731703279663003940330302337034287531523670311301769819979719964774691056663271015295837071" //  3601
                                            //"7864523709792642658661797141284093505181418309628330997189232743605419639886198489779151425657811846" //  3701
                                            //"4665219459942416886714653097876478238651949273346116720828562776606407649807517970487488340582655312" //  3801
                                            //"3618754688806141493842240382604066076039524220220089858643032168488971927533967790457369566247105316" //  3901
                                            //"4262899153714524866883786079372852486821546453956056146378308822020893646505432402105304544223320793" //  4001
                                            //"3311461850942211157075269336413062197930538372411295386251411727132403711620145872131975297223582090" //  4101
                                            //"6697700692227315373506498883336079253159575437112169105930825330817061228688863717353950291322813601" //  4201
                                            //"4004757553182688034254989408411244610779891226281422540008157094665398781629093292917615945416533661" //  4301
                                            //"2686571757139661047161786613151481359091432755050840422991152316280050025245718826043294310195851846" //  4401
                                            //"1981593094752251035313502715035659332909558349002259922978060927989426592421468087503791471922917803" //  4501
                                            //"8779426223580859565712950064063973830280574161719809602188242944426358952955452448285097090806643143" //  4601
                                            //"7061228457627517008612664350365959732447434431832154333850949747797330989890022930812568673278758007" //  4701
                                            //"9538531344292770613472193142418361527665433283254977760157385120580456944208063442372164083800084593" //  4801
                                            //"2342392755842675150229919003132099263725894530947285046163540735031813470047014567081134080773487027" //  4901
                                            //"2444495431783009906196889786661926817561538651987956108386828947548836852625972161997773748265209443" //  5001
                                            //"1390324793172914604326319638639033470762594833545895734484584930873360196135385647656137992800964870" //  5101
                                            //"8074028326299317958818486475793814139558844725016443377914767597246003187552943302457871572031763235" //  5201
                                            //"1156594704668920856302525440746862930639555483206398133108375279585866883904308268379897088946913476" //  5301
                                            //"6324998683826362961855554207727754686354415091309064415541842403810332192560981852720395197656322664" //  5401
                                            //"6333273057238653372672125471352607089552560700901554471094211719097405581628712480290343612492872535" //  5501
                                            //"8912255063626815666067250846556788995076487441167062295423985212762669355375939194061966782615421974" //  5601
                                            //"0817182674928288564554526931894094917569557440385543056146353581541431442688946121140146698487386227" //  5701
                                            //"6700986326256808502438513035961388227056026294026095632875770370581857090402331678683931242698286831" //  5801
                                            //"9125173173114110538099304197160677014448529658794571695663261155551213777528924964937158520790705546" //  5901
                                            //"9606096058011752151650209494183287922725352089851254840841664171322381250908674426307191690137544920" //  6001
                                            //"5803237533590481232685045154390858325983861291075598280746808657505257779279917589514583492852714910" //  6101
                                            //"5081581829027142227388218238786503821520416504052375970637754116859451833556262993980180384233943474" //  6201
                                            //"5569536945372169800675404848583302601001033664672870077903405978784466903444027625613930023568817490" //  6301
                                            //"3920242457198743246260342288969281807781289908880123973815097032052655010596698374815733617636677020" //  6401
                                            //"4566690170097216500786042664394310368612709100153365658986082755310558795035092279079693667872766094" //  6501
                                            //"9223993307716307684113706772437345046680566174224656557842501542525892645912797979787164233491254020" //  6601
                                            //"4367129244026993430376381946076239600994681447922073708132863879019580381399279104906010901161371003" //  6701
                                            //"9134604584382786783713606898079641191020045270707238408398949107718762046879108991955675580474843234" //  6801
                                            //"5422344728687087895644363705724817028013320886651777139734108630941393149491710066464668421460309188" //  6901
                                            //"1033107581373254667599170231251568645976547446397975142831915622392716660118817461362432057529925734" //  7001
                                            //"8920954929831990109947485125380209807556397367187629314825360985129759711229074469573466078093767668" //  7101
                                            //"7269310758997283854112774586349744664167520224605982273587725417887759872403259030826742849785661444" //  7201
                                            //"0253802950933695307152329547589350400981514311055639307242647852812320272716311814844040406374555210" //  7301
                                            //"5544380111229685110375850606870279688506446831524672212850127809950017312542190718389317950282620696" //  7401
                                            //"4553861249487072651383215630956362305687335914122217230663008904254947849089890847365772122681682972" //  7501
                                            //"7553401922414302498280860545077215296472682866924703795153290432827535938062990038217151968847839725" //  7601
                                            //"8328438798981447246929368823478806531836808875610266778905148479901659318245701711164314500621425140" //  7701
                                            //"2533660480585905044023745353512440830841032368326969513033999623228202005992156773818583206057680053" //  7801
                                            //"8208281585772430156849033418174001398564241320836743613071134505065135065722582084975523651659530315" //  7901
                                            //"9196940712445258697200683174459610699793004525834975764054684184444906797125295338298111256850078255" //  8001
                                            //"1542056805599613273165097785297605091322034593405328153118085819891363013053061074365882540673862757" //  8101
                                            //"0357218081417334229931166868695386771563422772911747356246029175374253206978278191240198787220620583" //  8201
                                            //"2323057627687581980846349467278960915186298628105952695149623871341822027550344201606311804970618133" //  8301
                                            //"8407534384406645818866935370284428954758787503406887323982080675022347094383710092898052731025632457" //  8401
                                            //"6489251518326660782144507674843642817670173147835430193657749565313991991489813235166882750447941936" //  8501
                                            //"6816010711969835083476376799889394973525310331655316967176906285551375800581903405670594326891242592" //  8601
                                            //"8087046235201330202482401319511702552357167658408394968847216014386091523786469845855930039750374425" //  8701
                                            //"4535015962510941917809112715842442066693394998471260509895604980228390424765630618228158147720503045" //  8801
                                            //"4859916361449432518333709026662478960989415823830653468605648837208285272790960008960053409924964035" //  8901
                                            //"8579295339516636654262850340593846977925533688064652185504992071599293851300987363672180064761858691" //  9001
                                            //"9177941390730698812068043330887511780091265764501090511281128964930303750942392436887931650675087771" //  9101
                                            //"3818822606301905235875600594824153302958788518059793918939911315224373123934675724725122504326417257" //  9201
                                            //"3844420654977843730872960459356141153123028926409385581364241477675562846712564721792641613644493602" //  9301
                                            //"4496522354371792762818367807347344441776643027511200745596788008305940057566153341888949120269112834" //  9401
                                            //"5087418139587922451428597893430871569375772288916246291871439698450569432100984424849402824295611469" //  9501
                                            //"1021001603817399206605526957416216350900238614282446781732787667905885157381015286201276703966877868" //  9601
                                            //"3192263708695092991139562076586194329302876814014147208224747199686904503221014054112470532025529696" //  9701
                                            //"6168152236602610558641085492573080720734906573021141317497645139631587357953394844115011936688173947" //  9801
                                            //"0040282041344717004014490451265302682111848038054843249687828071997907078918188814093824182818774002" //  9901
                                            //"5291200324748576042185529158621315845910499774551692202529673999784513919376318411200203310512751357" // 10001
                                            //"1334455932397715655896977116687950374890910259312688696079328411159658736087044055419685884650660451" // 10101
                                            //"5268361407895398831958318906013950429658673311132313574728010733312833094643408780704265908705833882" // 10201
                                            //"9198083217506403736758740469777378958302143275705804690584881547318991261020148421742852269949191230" // 10301
                                            //"2769974275140942035759146208459381333404289972749291905616487388915795446600975295304826781518408680" // 10401
                                            //"3926807822946404676143019044402136512685494329204867088010304253386498683934795408319136750711033346" // 10501
                                            //"0547801499459472709929066577739688122392992325546899036547391176441514710353303179710381973330787098" // 10601
                                            //"9621377464137198150815846848046018518014034639207245095129578812950966932955208229264678113026866136" // 10701
                                            //"8990795814180604692092294192339377377002816694081092148591739827659336493637142063775813057407330166" // 10801
                                            //"4863948809543711357869646178862136574054456194724961879925412149452910798507988856162274738867774588" // 10901
                                            //"1261585231919909252492594141251896911380694239459928181788361190687865024724710162698980087285570542" // 11001
                                            //"7663182513797859039285457514789382854506873388306472200907460976397103413188243470492517909746033520" // 11101
                                            //"0597731851573257122499331047067658857570850680966166614033074457127118305069568919636626822580039984" // 11201
                                            //"1196270441023467317128156529698855288227527877338496062367289073971783508852947997645692436898017555" // 11301
                                            //"3955262559144534531112519256508553063660026814184466873155832025618635880343719719986769847099128011" // 11401
                                            //"4199117122269960504998133968466034700716088162337105306234199141798854657418516975788872920100821784" // 11501
                                            //"5338356705174157190259668834590703907577106914748521718058163530311560781189281747012246452224018746" // 11601
                                            //"2160970970527144565153640683210096932555009000625240160159960985097069388293955032986541900986927876" // 11701
                                            //"4864454377031948109404296579422355584752245157746954376393650925962537371634101480545100526658089952" // 11801
                                            //"5557888472433482383725388793013430315591735129647987835208520352677409099803522872824093843647415297" // 11901
                                            //"7566839379372236311631747212587720762034243171054533660164766809312951760810276160326727774843274281" // 12001
                                            //"2870991123737928224564281506605310200848209793567057176580487341809774236381818989066288436575323620" // 12101
                                            //"6201470954109963193615440189493922687218572296988357003436155861362170938001889179905588487962784270" // 12201
                                            //"1117284439296698302527802560766400219547736132575584794360292268648914528019474851401471842006308301" // 12301
                                            //"7873586016339961073040552014554993491680056724810692074526833108518055203669680613622763710211959411" // 12401
                                            //"3280150188521757714715920746490282935734073761976121943285169951902761386188988030308444438865826043" // 12501
                                            //"4782507671183006200666065022349831393834900542988663031177080784432819445820225807104363152564656636" // 12601
                                            //"4685096652223825601856505123804105260327822954494662971478215551748850775223493157342338829552842882" // 12701
                                            //"2225271671077427220220465359755128204936480645296692835327396132757153626984090604481639455712943967" // 12801
                                            //"9261756308644233382449283182355346450652867137229237309044536253774536891936884832215708033536284161" // 12901
                                            //"7700560108287226292461642051883475124779884151427255033491463783789125670514088267087517150685397398" // 13001
                                            //"9450940633132279839993652564945412826724443578478063521708578874678712377833025008488080179054396757" // 13101
                                            //"4772961169453790924877646875035770402879120114209623899768478121227391468463118159340692298286895772" // 13201
                                            //"7208206364701473005557181795156545462610097787978019847827006746501711965311734178485224858947340387" // 13301
                                            //"8154542614137383418529250968464814971007321602720933790236801873372190926500042917058619000018143021" // 13401
                                            //"1647253458652907476420987744999339867884937103296652226829222136053489327466875068152858805336594773" // 13501
                                            //"0441871403252769297057029807258640398399376570343679073382690444889416091847932056343131031313322227" // 13601
                                            //"1964622450125781170982901943151078004878630703818042142389146004877603532300705417252050757635950389" // 13701
                                            //"5612202743000897983442004440267002621203278308317915607423558555045195748578383583104483437917072336" // 13801
                                            //"1189482468386796840437491298512886924785063906270206622952789823990145716861316723870738659398579675" // 13901
                                            //"8298838788121714497279376738065311287284332885152158294217399686314674992976705855386564415258945647" // 14001
                                            //"6307481992309119759651978218743425243656605169622477802393644285891533516143730761301297405226778564" // 14101
                                            //"5989945149060665677927636878895415588045687197668200716770847794708487912951113681904496891082784788" // 14201
                                            //"2000324153872736935528260356393187599431149370838926697874968782594847828673187208200704687554131777" // 14301
                                            //"3556227899723295749428158652771747724946577929128719754933527695893300814822365131675775690971629792" // 14401
                                            //"5922547996826885452172123744910904721286307420225493619557408928189516560697539517896656482478585921" // 14501
                                            //"1658972383933418379161796664024206368606802569902324070685602882552345716604871196600640840490241457" // 14601
                                            //"4507116239168029836193850679015155680013493105206289233410165536554444706838220526832631429481224770" // 14701
                                            //"0851691976839815222574516118227871379202863336566352647134650834146841634664460925975985609817028189" // 14801
                                            //"5807377573757898610939114061452380190041528669867182120490901729072578709137259170626306743677365312" // 14901
                                            //"3572454727433951548366047972013182963232809889930023464262779149412417694960473074206230179685598550" // 15001
                                            //"8853706555948622790287148344439519598719370504571490527592579225383144715973241146816751533747768532" // 15101
                                            //"8119819870100016267508649092719350096884705697494028870908391525169471284323962681469370822353376623" // 15201
                                            //"7308978755395913303455932465342962067728782750373189346004886900108999079948474465742498966941208812" // 15301
                                            //"6943212651661299659591020219083672470060618906194671668925678952609551290030017015157899097862787889" // 15401
                                            //"7984322510511954028737178871717550527592511941633552876002508730047428255669358522039911704494344403" // 15501
                                            //"5544740083561683884789745081360311207199678109797144709349128478117170043343806279052588910878263326" // 15601
                                            //"2690617878124093568775570108478781049462724025895383749950382022944630578653545067836293214600178055" // 15701
                                            //"5379262296218044194490415183345940157011614343727621099359462003357417013884141844658161407665269069" // 15801
                                            //"0407605572198111380026827436473674198389903297920151009868253575287349276980412792803953337118467130" // 15901
                                            //"9278276726371491396294392421682161923769210912078076910687458282893026949881569768847544350308668520" // 16001
                                            //"6133976635366620022662173808438780621602875686683027418487060273552621698270323128453969501486065943" // 16101
                                            //"3493928133306305407065093422533504492110239916366392752741523598383840715916401519121060469253551588" // 16201
                                            //"7872614926113802160229885428201878273827621451627562715788011199000367085023683442721114550442070536" // 16301
                                            //"0747145305584483474721150225577443638168980123560277794215416458620055953318716775178187913762971205" // 16401
                                            //"2644878745312494555207578162891767571003940568755872481565010540975163294064916258175679046490647579" // 16501
                                            //"2059683338450979299431213962384373169853540807912962556204359826434832611621109197602600969125995302" // 16601
                                            //"2424830727490300112701402556318534284826842066031323307120494676156860573105144455060999976740306975" // 16701
                                            //"8601612520361924763032273380668222277307702183873478767045869177664510177412901507894790408793615813" // 16801
                                            //"4173612890193973097603365748687572252907631668561506123690971807596435989199362308839485072688799205" // 16901
                                            //"8050200317765443294900136414083875231690942463669201452586791010964791142745136804645364260249535890" // 17001
                                            //"4528964182047129550544616416212703779830538577821691114225320793006879579255650003222030647032103931" // 17101
                                            //"1808423689899815579984014658953811737155757441965802705913227957769721019572171914035462596310629903" // 17201
                                            //"3629343539195219884200723671182775556353969175162089325679976120123245969723387067477315754719667232" // 17301
                                            //"2676826770736842395787780037059138393560910896571696740234193442507067751724316462026620775533654423" // 17401
                                            //"1453899036359179509387985284395831046771532463352550951407093988297858082603727722388783925677741087" // 17501
                                            //"3554864485536182647308989707335360000021305249709461117231979982803415396770966377500285877817990137" // 17601
                                            //"0906153023360667464453035132441505390358288450561633034333553345586070970308408047634921784656783406" // 17701
                                            //"5508515017353102357187900055867791841153365579355289063680808371080208702696779062402652756738567161" // 17801
                                            //"6543875662530992349199411349014366641300691132880689809072551200225003686712147224455318985567874129" // 17901
                                            //"5685291352677637615131224337921008322278078127920324044307369882185210775377429675979119998224198329" // 18001
                                            //"2928823837136554009148486868043344552891178660255563173739050138998729220351370120334290708631629602" // 18101
                                            //"1091772112910026640751729097168064805974341869618211124233430936969556078895139596085263619835128456" // 18201
                                            //"1974799753394647539147403161613645809198424732337805192546086135863306229880352947538774702818672366" // 18301
                                            //"6432285604299526798379670969751250597504847746155119111910930392788803643681996824979652473475429344" // 18401
                                            //"5212326728659281267145621415775163280876297003768228637719765538898023864259365431776826773886936571" // 18501
                                            //"8013328161262815551545141126145880098588060484099683313095947341097116089173144045527568093364675970" // 18601
                                            //"5654211568639507083590022694547251548160426953652090045703159591595294934045681999123203138217807691" // 18701
                                            //"6490053585318841110079175845963705296014136753008367312418911086922702683051401319497638326827191134" // 18801
                                            //"3929930806437454320529718609807957497917813225450158965655387790704350724370159259557029237686543844" // 18901
                                            //"6447620317488901057330476045065687782750547691784768845070945306196343156895668431644654041380574464" // 19001
                                            //"6601077243269597701893909440095904622403008658645325654552643558176801757229604429507531562116394044" // 19101
                                            //"5261943499014425449695895633914592284731719156418166146646712069693063746058605331929002743675085779" // 19201
                                            //"5115942899849308077363598427786938489483970194669253586642145373741536125279838723930088199084335255" // 19301
                                            //"6818293397138514301486314815876106478504789551148831836916431250363843104674192149666584698420690292" // 19401
                                            //"5287489961119220661598829069556914939998425719999879922456323043862977753877604456216600397203309883" // 19501
                                            //"3085233937173576745219175491352365014551985901786361043745849221735279917832291710116794548419618195" // 19601
                                            //"6345864786021353277364808022260804940147017156574492542698927370636309393809339373878509450388279858" // 19701
                                            //"2930484771552510009497059095362959093401410069599917773539003224994456408060799092655766139195249872" // 19801
                                            //"3020204873110704461381225898777198031469322047424470957822585095392352010095949856121442536078453822" // 19901
                                            //"0555445220508829844315300901624135434714240543604859362124075531576743338182188361489756280981510356" // 20001
                                            //"4077130781982095518828264308656881250060360551433930164192854696829391452795768512016906242813187161");//20101

  generateConstantArray34("_4712",       "-4.712000000000000000000000000000000000000000000000000000e+03"); // cnst247
  generateConstantArray34("0",           "+0.000000000000000000000000000000000000000000000000000000e+00"); // cnst248
  generateConstantArray34("1e_32",       "+1.000000000000000000000000000000000000000000000000000000e-32"); // cnst249
  generateConstantArray34("1e_6",        "+1.000000000000000000000000000000000000000000000000000000e-06"); // cnst250
  generateConstantArray34("1e_4",        "+1.000000000000000000000000000000000000000000000000000000e-04"); // cnst251
  generateConstantArray34("1on2",        "+5.000000000000000000000000000000000000000000000000000000e-01"); // cnst252
  generateConstantArray34("1",           "+1.000000000000000000000000000000000000000000000000000000e+00"); // cnst253
  generateConstantArray34("2",           "+2.000000000000000000000000000000000000000000000000000000e+00"); // cnst254
  generateConstantArray34("3",           "+3.000000000000000000000000000000000000000000000000000000e+00"); // cnst255
  generateConstantArray34("4",           "+4.000000000000000000000000000000000000000000000000000000e+00"); // cnst256
  generateConstantArray34("5",           "+5.000000000000000000000000000000000000000000000000000000e+00"); // cnst257
  generateConstantArray34("2pi",         "+6.283185307179586476925286766559005768394338798750211642e+00"); // cnst258
  generateConstantArray34("7",           "+7.000000000000000000000000000000000000000000000000000000e+00"); // cnst259
  generateConstantArray34("9",           "+9.000000000000000000000000000000000000000000000000000000e+00"); // cnst260
  generateConstantArray34("12",          "+1.200000000000000000000000000000000000000000000000000000e+01"); // cnst261
  generateConstantArray34("14",          "+1.400000000000000000000000000000000000000000000000000000e+01"); // cnst262
  generateConstantArray34("24",          "+2.400000000000000000000000000000000000000000000000000000e+01"); // cnst263
  generateConstantArray34("28",          "+2.800000000000000000000000000000000000000000000000000000e+01"); // cnst264
  generateConstantArray34("31",          "+3.100000000000000000000000000000000000000000000000000000e+01"); // cnst265
  generateConstantArray34("38",          "+3.800000000000000000000000000000000000000000000000000000e+01"); // cnst266
  generateConstantArray34("60",          "+6.000000000000000000000000000000000000000000000000000000e+01"); // cnst267
  generateConstantArray34("100",         "+1.000000000000000000000000000000000000000000000000000000e+02"); // cnst268
  generateConstantArray34("153",         "+1.530000000000000000000000000000000000000000000000000000e+02"); // cnst269
  generateConstantArray34("275",         "+2.750000000000000000000000000000000000000000000000000000e+02"); // cnst270
  generateConstantArray34("367",         "+3.670000000000000000000000000000000000000000000000000000e+02"); // cnst271
  generateConstantArray34("400",         "+4.000000000000000000000000000000000000000000000000000000e+02"); // cnst272
  generateConstantArray34("1401",        "+1.401000000000000000000000000000000000000000000000000000e+03"); // cnst273
  generateConstantArray34("1461",        "+1.461000000000000000000000000000000000000000000000000000e+03"); // cnst274
  generateConstantArray34("3600",        "+3.600000000000000000000000000000000000000000000000000000e+03"); // cnst275
  generateConstantArray34("4716",        "+4.716000000000000000000000000000000000000000000000000000e+03"); // cnst276
  generateConstantArray34("4800",        "+4.800000000000000000000000000000000000000000000000000000e+03"); // cnst277
  generateConstantArray34("4900",        "+4.900000000000000000000000000000000000000000000000000000e+03"); // cnst278
  generateConstantArray34("5001",        "+5.001000000000000000000000000000000000000000000000000000e+03"); // cnst279
  generateConstantArray34("32075",       "+3.207500000000000000000000000000000000000000000000000000e+04"); // cnst280
  generateConstantArray34("43200",       "+4.320000000000000000000000000000000000000000000000000000e+04"); // cnst281
  generateConstantArray34("65535",       "+6.553500000000000000000000000000000000000000000000000000e+04"); // cnst282
  generateConstantArray34("86400",       "+8.640000000000000000000000000000000000000000000000000000e+04"); // cnst283
  generateConstantArray34("146097",      "+1.460970000000000000000000000000000000000000000000000000e+05"); // cnst284
  generateConstantArray34("274277",      "+2.742770000000000000000000000000000000000000000000000000e+05"); // cnst285
  generateConstantArray34("1e6",         "+1.000000000000000000000000000000000000000000000000000000e+06"); // cnst286
  generateConstantArray34("1729777",     "+1.729777000000000000000000000000000000000000000000000000e+06"); // cnst287
  generateConstantArray34("2p32",        "+4.294967296000000000000000000000000000000000000000000000e+09"); // cnst288
  generateConstantArray34("maxDate",     "+3.155695348699627200000000000000000000000000000000000000e+18"); // cnst289
  generateConstantArray34("maxTime",     "+3.600000000000000000000000000000000000000000000000000000e+19"); // cnst290  if the number of constants changes: don't forget to update NUMBER_OF_CONSTANTS_* in defines.h

  strcat(realArray, "};\n");
}


int main(int argc, char* argv[]) {
  if(argc < 3) {
    printf("Usage: generateConstants <c file> <h file>\n");
    return 1;
  }

  decContextDefault(&ctxtReal34,   DEC_INIT_DECQUAD);
  decContextDefault(&ctxtReal39,   DEC_INIT_DECQUAD);
  decContextDefault(&ctxtReal51,   DEC_INIT_DECQUAD);
  decContextDefault(&ctxtReal75,   DEC_INIT_DECQUAD);
  decContextDefault(&ctxtReal1071, DEC_INIT_DECQUAD);
  ctxtReal39.digits = 39;
  ctxtReal39.traps  = 0;
  ctxtReal51.digits = 51;
  ctxtReal51.traps  = 0;
  ctxtReal75.digits = 75;
  ctxtReal75.traps  = 0;
  ctxtReal1071.digits  = 1071;
  ctxtReal1071.traps   = 0;

  defines[0] = 0;
  externalDeclarations[0] = 0;
  strcat(externalDeclarations, "  extern const uint8_t constants[];\n");
  realArray[0] = 0;
  realPointerDeclarations[0]     = 0;
  real34PointerDeclarations[0]   = 0;
  real1071PointerDeclarations[0] = 0;

  generateAllConstants();


  constantsH = fopen(argv[2], "wb");
  if(constantsH == NULL) {
    fprintf(stderr, "Cannot create file %s\n", argv[2]);
    exit(1);
  }

  fprintf(constantsH, "// SPDX-License-Identifier: GPL-3.0-only\n");
  fprintf(constantsH, "// SPDX-FileCopyrightText: Copyright The WP43 Authors\n\n");

  fprintf(constantsH, "/*************************************************************************************************\n");
  fprintf(constantsH, " * Do not edit this file manually! It's automagically generated by the program generateConstants *\n");
  fprintf(constantsH, " *************************************************************************************************/\n\n");

  fprintf(constantsH, "/**\n");
  fprintf(constantsH, " * \\file constantPointers.h\n");
  fprintf(constantsH, " */\n");

  fprintf(constantsH, "#if !defined(CONSTANTPOINTERS_H)\n");
  fprintf(constantsH, "  #define CONSTANTPOINTERS_H\n\n");

  fprintf(constantsH, "  #include \"realType.h\"\n");
  fprintf(constantsH, "  #include <stdint.h>\n\n");

  fprintf(constantsH, "%s", defines);
  fprintf(constantsH, "\n");
  fprintf(constantsH, "%s", externalDeclarations);

  fprintf(constantsH, "#endif // !CONSTANTPOINTERS_H\n");

  fclose(constantsH);



  constantsC = fopen(argv[1], "wb");
  if(constantsC == NULL) {
    fprintf(stderr, "Cannot create file %s\n", argv[1]);
    exit(1);
  }

  fprintf(constantsC, "// SPDX-License-Identifier: GPL-3.0-only\n");
  fprintf(constantsC, "// SPDX-FileCopyrightText: Copyright The WP43 Authors\n\n");

  fprintf(constantsC, "/*************************************************************************************************\n");
  fprintf(constantsC, " * Do not edit this file manually! It's automagically generated by the program generateConstants *\n");
  fprintf(constantsC, " *************************************************************************************************/\n\n");

  fprintf(constantsC, "#include \"constantPointers.h\"\n\n");
  fprintf(constantsC, "#include \"wp43.h\"\n\n");

  fprintf(constantsC, "%s", realArray);
  fprintf(constantsC, "\n");
  fprintf(constantsC, "%s", realPointerDeclarations);
  fprintf(constantsC, "\n");
  fprintf(constantsC, "%s", real51PointerDeclarations);
  fprintf(constantsC, "\n");
  fprintf(constantsC, "%s", real75PointerDeclarations);
  fprintf(constantsC, "\n");
  fprintf(constantsC, "%s", real1071PointerDeclarations);
  fprintf(constantsC, "\n");
  fprintf(constantsC, "%s", real34PointerDeclarations);

  fclose(constantsC);

  return 0;
}
