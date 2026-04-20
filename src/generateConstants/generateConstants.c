// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file generateConstants.c
 ***********************************************/

#define NUMBER_OF_CONSTANTS_IN_CNST_CATALOG 78

#include "c47.h"

#define EXACT true
#define APPROX false

realContext_t ctxtReal34, ctxtReal;

char whiteSpace[50];
char externalDeclarations[1000000]; // .h file
char realArray[1000000];            // .c file
char realTConstantArray[1000000];   // added to .c file
FILE *constantsC, *constantsH;
int32_t  idx, cntRealt;


void *xcopy(void *dest, const void *source, uint32_t n) {
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

static void emitConstantHeader(const char *name, const char *type, const char *prefix) {
  char *b = strchr(externalDeclarations, '\0');

  sprintf(b, "  #define %s%s%s ((%s *)(constants + %" PRId32 "))\n", prefix, name, whiteSpace, type, idx);
}

static void emitRealArray(const char *name, const void *vptr, int32_t len, const char *prefix) {
  char *b = strchr(realArray, '\0');
  const uint8_t *p = (const uint8_t *)vptr;
  int n, i;

  strcpy(whiteSpace, "                                              ");
  whiteSpace[21 - strlen(name) - strlen(prefix)] = 0;

  n = sprintf(b, "  /* %s%s%s */  ", prefix, name, whiteSpace);
  for(i=0; i<len; i++) {
    n += sprintf(b + n, "0x%02x,%s", p[i], (i==3 || i==7 || i==8 || i==9) ? " " : "");
  }
  sprintf(b + n, "\n");
}

static void emitConstant(const char *name, const char *type, const void *vptr, int32_t len, const char *prefix) {
  emitConstantHeader(name, type, prefix);
  emitRealArray(name, vptr, len, prefix);
  idx += len;
}

void generateConstant(char *name, int32_t digits, bool_t exact, char *value) {
  real12321_t real;
  char temp[20];

  #if defined(DEBUG)
    printf("generateConstant: %-10.10s = %s %s (%" PRId32 " digits)\n", name, value, exact ? "exact" : "approx", digits);
  #endif // DEBUG

  #if DECDPUN != 3
    #error DECDPUN must be 3
  #endif

  int32_t maxDigits = ((digits + 2) / 6) * 6 + 3; // Assuming DECDPUN = 3 and memory alignment is 4 bytes
  ctxtReal.digits = maxDigits;

  memset(&real, 0, sizeof(real12321_t));
  stringToReal(value, &real, &ctxtReal);
  realReduce(&real, &real, &ctxtReal);

  if(exact) {
    strcpy(temp, "const_");
    real.C47Bits = REAL_EXACT;
  }
  else {
    sprintf(temp, "const%" PRId32 "_", maxDigits);
    real.C47Bits = REAL_NONE;
  }

  strcpy(whiteSpace, "                                              ");
  whiteSpace[25 - strlen(name) - strlen(temp)] = 0;

  int32_t lenInBytes = 10 + sizeof(decNumberUnit) * (maxDigits / DECDPUN);
  emitConstant(name, "real_t", &real, lenInBytes, temp);

  cntRealt++;

  if(cntRealt <= NOUC) {
    strcat(realTConstantArray, "  ");
    strcat(realTConstantArray, temp);
    strcat(realTConstantArray, name);
    strcat(realTConstantArray, ",\n");
  }
}

void generateConstant34(char *name, char *value) {
  real34_t real34;

  #if defined(DEBUG)
    printf("generateConstant34: %-10.10s = %s\n", name, value);
  #endif // DEBUG

  memset(&real34, 0, REAL34_SIZE_IN_BYTES);
  stringToReal34(value, &real34);
  real34Reduce(&real34, &real34);

  strcpy(whiteSpace, "                                        ");
  whiteSpace[15 - strlen(name)] = 0;

  emitConstant(name, "real34_t", &real34, REAL34_SIZE_IN_BYTES, "const34_");
}


void generateAllConstants(void) {
  // constants used by the program
  idx = 0;

  strcat(realArray, "TO_QSPI const uint8_t constants[] = {\n");

         // Physical and mathematical constants
         // Remember to change NOUC (number of user constants) in define.h when a constant is added or removed
/*000*/  generateConstant("a",              7, EXACT,  "+365.2425"                                                    ); // per definition
/*001*/  generateConstant("a0",            12, EXACT,  "+5.29177210544e-11"                                           ); // a_0 = 5.29177210544(82)E−11 m, CODATA 2022
/*002*/  generateConstant("aMoon",          4, EXACT,  "+384.4e+6"                                                    );
/*003*/  generateConstant("aEarth",         7, EXACT,  "+149.5979e+9"                                                 );
/*004*/  generateConstant("c",              9, EXACT,  "+299792458"                                                   ); // c = 299792458 m/s, exact per definition, SI 2019 (NIST.SP.330-2019)
/*005*/  generateConstant("c1",            39, APPROX, "+3.741771852192758011367155555929985138219953097124061418e-16");
/*006*/  generateConstant("c2",            39, APPROX, "+1.438776877503933802146671601543911595199069423148099191e-02");
/*007*/  generateConstant("e",             10, EXACT,  "+1.602176634e-19"                                             ); // e = 1.602176634E−19 C, exact per definition, CODATA 2017, SI 2019 (NIST.SP.330-2019)
/*008*/  generateConstant("eE",            39, APPROX, "+2.718281828459045235360287471352662497757247093699959575"    ); // math constant e
/*009*/  generateConstant("F",             18, EXACT,  "+96485.3321233100184"                                         );
/*010*/  generateConstant("Falpha",        39, APPROX, "+2.502907875095892822283902873218215786381271376727149977"    ); // math constant Falpha
/*011*/  generateConstant("Fdelta",        39, APPROX, "+4.669201609102990671853203820466201617258185577475768633"    ); // math constant Fdelta
/*012*/  generateConstant("G",              5, EXACT,  "+6.6743e-11"                                                  );
/*013*/  generateConstant("G0",            39, APPROX, "+7.748091729863650646680823323308763943587286047673370920e-05");
/*014*/  generateConstant("GC",            39, APPROX, "+9.159655941772190150546035149323841107741493742816721343e-01"); // math constant Catalan
/*015*/  generateConstant("ge",            15, EXACT,  "-2.00231930436092"                                            ); // g_e− = −2.00231930436092(36), CODATA 2022
/*016*/  generateConstant("GM",            10, EXACT,  "+3.986004418e+14"                                             );
/*017*/  generateConstant("gEarth",         6, EXACT,  "+9.80665"                                                     ); // per definition
/*018*/  generateConstant("Planck",         9, EXACT,  "+6.62607015e-34"                                              ); // h = 6.62607015E−34 J⋅s, exact per definition, CODATA 2017, SI 2019 (NIST.SP.330-2019)
/*019*/  generateConstant("PlanckOn2pi",   39, APPROX, "+1.054571817646156391262428003302280744722826330020413122e-34");
/*020*/  generateConstant("k",              7, EXACT,  "+1.380649e-23"                                                ); // k = 1.380649E−23 J/K, exact per definition, CODATA 2017, SI 2019 (NIST.SP.330-2019)
/*021*/  generateConstant("KJ",            39, APPROX, "+4.835978484169836324476582850545281353533511866004014461e+14");
/*022*/  generateConstant("lPL",            7, EXACT,  "+1.616255e-35"                                                ); // l_P = 1.616255(18)E−35 m, CODATA 2022
/*023*/  generateConstant("me",            11, EXACT,  "+9.1093837139e-31"                                            ); // m_e = 9.1093837139(28)E−31 kg, CODATA 2022
/*024*/  generateConstant("MMoon",          4, EXACT,  "+7.349e+22"                                                   );
/*025*/  generateConstant("mn",            12, EXACT,  "+1.67492750056e-27"                                           ); // m_n = 1.67492750056(85)E−27 kg, CODATA 2022
/*026*/  generateConstant("mnOnmp",        12, EXACT,  "+1.00137841946"                                               ); // m_n/m_p = 1.00137841946(40), CODATA 2022
/*027*/  generateConstant("mp",            12, EXACT,  "+1.67262192595e-27"                                           ); // m_p = 1.67262192595(52)E−27 kg, CODATA 2022
/*028*/  generateConstant("mPL",            7, EXACT,  "+2.176434e-08"                                                ); // m_P = 2.176434(24)E−8 kg, CODATA 2022
/*029*/  generateConstant("mpOnme",        13, EXACT,  "+1836.152673426"                                              ); // m_p/⁠m_e = 1836.152673426(32), CODATA 2022
/*030*/  generateConstant("mu",            12, EXACT,  "+1.66053906892e-27"                                           ); // mu = 1.66053906892(52)E−27 kg, CODATA 2022
/*031*/  generateConstant("muc2",          12, EXACT,  "+1.49241808768e-10"                                           ); // muc2 = 1.49241808768(46)E−10 J, CODATA 2022
/*032*/  generateConstant("mmu",           10, EXACT,  "+1.883531627e-28"                                             ); // m_μ = 1.883531627(42)E−28 kg, CODATA 2022
/*033*/  generateConstant("mSun",           5, EXACT,  "+1.9891e+30"                                                  );
/*034*/  generateConstant("mEarth",         5, EXACT,  "+5.9736e+24"                                                  );
/*035*/  generateConstant("NA",             9, EXACT,  "+6.02214076e+23"                                              ); // N_A = 6.02214076E23 1/mol, exact per definition, CODATA 2017, SI 2019 (NIST.SP.330-2019)
/*036*/  generateConstant("NaN",            1, EXACT,  "Not a number"                                                 );
/*037*/  generateConstant("p0",             6, EXACT,  "+101325"                                                      ); // per definition
/*038*/  generateConstant("R",             15, EXACT,  "+8.31446261815324"                                            );
/*039*/  generateConstant("re",            11, EXACT,  "+2.8179403205e-15"                                            ); // r_e = 2.8179403205(13)E−15 m, CODATA 2022
/*040*/  generateConstant("RK",            39, APPROX, "+25812.80745930450666004551670608744304245727322140342177"    );
/*041*/  generateConstant("RMoon",          6, EXACT,  "+1.73753e+06"                                                 );
/*042*/  generateConstant("RInfinity",     14, EXACT,  "+10973731.568157"                                             ); // R_∞ = 10973731.568157(12) 1/m, CODATA 2022
/*043*/  generateConstant("RSun",           3, EXACT,  "+6.96e+08"                                                    );
/*044*/  generateConstant("REarth",         6, EXACT,  "+6.37101e+06"                                                 );
/*045*/  generateConstant("Sa",            39, EXACT,  "+6378137"                                                     ); // per definition
/*046*/  generateConstant("Sb",            11, EXACT,  "+6356752.3142"                                                );
/*047*/  generateConstant("Se2",           12, EXACT,  "+6.69437999014e-03"                                           );
/*048*/  generateConstant("Sep2",          12, EXACT,  "+6.73949674228e-03"                                           );
/*049*/  generateConstant("Sfm1",          12, EXACT,  "+298.257223563"                                               ); // per definition
/*050*/  generateConstant("T0",             5, EXACT,  "+273.15"                                                      ); // per definition
/*051*/  generateConstant("TP",             7, EXACT,  "+1.416784e+32"                                                ); // T_P = 1.416784(16)E32 K, CODATA 2022
/*052*/  generateConstant("tPL",            7, EXACT,  "+5.391247e-44"                                                ); // t_P = 5.391247(60)×10−44 s, CODATA 2022
/*053*/  generateConstant("Vm",            39, APPROX, "+2.241396954501413773501110288675055514433752775721687639e-02");
/*054*/  generateConstant("Z0",            12, EXACT,  "+3.76730313412e+02"                                           ); // Z0 = 376.730313412(59) Ω, CODATA 2022
/*055*/  generateConstant("alpha",         11, EXACT,  "+7.2973525643e-03"                                            ); // α = 0.0072973525643(11), CODATA 2022
/*056*/  generateConstant("K0",            39, APPROX, "+2.685452001065306445309714835481795693820382293994462953"    ); // math constant Khinchin
/*057*/  generateConstant("gammaEM",       39, APPROX, "+5.772156649015328606065120900824024310421593359399235988e-01"); // math constant Euler-Mascheroni
/*058*/  generateConstant("gammap",        11, EXACT,  "+2.6752218708e+08"                                            ); // γ_p = 2.6752218708(11)E8 1/(s⋅T), CODATA 2022
/*059*/  generateConstant("DELTAvcs",       9, EXACT,  "+9.19263177e+09"                                              ); // Δν(133Cs)hfs = 9192631770 Hz, exact per definition, SI 2019 (NIST.SP.330-2019)
/*060*/  generateConstant("epsilon0",      11, EXACT,  "+8.8541878188e-12"                                            ); // ε_0 = 8.8541878188(14)E−12 F/m, CODATA 2022
/*061*/  generateConstant("lambdaC",       12, EXACT,  "+2.42631023538e-12"                                           ); // λ_C = 2.42631023538(76)E−12 m, CODATA 2022
/*062*/  generateConstant("lambdaCn",      12, EXACT,  "+1.31959090382e-15"                                           ); // λ_C,n = 1.31959090382(67)E-15 m, CODATA 2022
/*063*/  generateConstant("lambdaCp",      11, EXACT,  "+1.3214098536e-15"                                            ); // λ_C,p = 1.32140985360(41)E-15
/*064*/  generateConstant("mu0",           12, EXACT,  "+1.25663706127e-06"                                           ); // μ_0 = 1.25663706127(20)E−6 N/A^2, CODATA 2022
/*065*/  generateConstant("muB",           11, EXACT,  "+9.2740100657e-24"                                            ); // μ_B = 9.2740100657(29)E-24 J/T, CODATA 2022
/*066*/  generateConstant("mue",           11, EXACT,  "-9.2847646917e-24"                                            ); // μ_e = -9.2847646917(29)E−24 J/T, CODATA 2022
/*067*/  generateConstant("mueOnmuB",      15, EXACT,  "-1.00115965218046"                                            ); // μ_e/⁠μ_B = -1.00115965218046(18), CODATA 2022
/*068*/  generateConstant("mun",            8, EXACT,  "-9.6623653e-27"                                               ); // μ_n = -9.6623653(23)E−27 J/T, CODATA 2022
/*069*/  generateConstant("mup",           12, EXACT,  "+1.41060679545e-26"                                           ); // μ_p = 1.41060679545(60)E−26 J/T, CODATA 2022
/*070*/  generateConstant("muu",           11, EXACT,  "+5.0507837393e-27"                                            ); // μ_N = 5.0507837393(16)E−27 J/T, CODATA 2022
/*071*/  generateConstant("mumu",           8, EXACT,  "-4.4904483e-26"                                               ); // μ_μ = -4.49044830(18)E−26 J/T, CODATA 2022
/*072*/  generateConstant("sigmaB",        39, APPROX, "+5.670374419184429453970996731889230875840122970291303682e-08");
/*073*/  generateConstant("PHI",           39, APPROX, "+1.618033988749894848204586834365638117720309179805762862"    ); // math constant phi = (1 + sqrt(5)) / 2
/*074*/  generateConstant("PHI0",          39, APPROX, "+2.067833848461929323081115412147497340171545654934323552e-15");
/*075*/  generateConstant("omega",          7, EXACT,  "+7.292115e-05"                                                );
/*076*/  generateConstant("minusInfinity",  1, EXACT,  "-9e+9999"                                                     ); // math "constant"
/*077*/  generateConstant("plusInfinity",   1, EXACT,  "+9e+9999"                                                     ); // math "constant"
/*078*/  generateConstant("0",              1, EXACT,  "0"                                                            );
/*079*/  generateConstant("BB",            39, APPROX, "+3.566668367128895828373073810012662699038701534076244140e-01"); //  solution to equation 1.2 in https://arxiv.org/pdf/2309.05050.pdf : sqrt(36x+3) / 4 + sin(2 pi sqrt(12x+1) / 3) = 0
/*080*/  generateConstant("DeltaS",        39, APPROX, "+2.414213562373095048801688724209698078569671875376948073"    ); //  1+√2
/*081*/  generateConstant("movSofa",       15, EXACT,  "+2.21953166887197"                                            ); //  https://mathworld.wolfram.com/MovingSofaProblem.html. The moving sofa number is the result of a lot of equation solving
/*082*/  generateConstant("tau",           39, APPROX, "+6.283185307179586476925286766559005768394338798750211642"    ); //  circle constant
/*083*/  generateConstant("pi",            39, APPROX, "+3.141592653589793238462643383279502884197169399375105821"    );
         // Remember to change NOUC (number of user constants) in define.h when a constant is added or removed



         // All the formulas are 100% exact conversion formulas
         generateConstant("PointToMm",     39, APPROX, "+3.527777777777777777777777777777777777777777777777777778e-01"); // mm     = pt × 0.0254 / 72 × 1000
         generateConstant("InchToMm",       3, EXACT,  "+25.4"                                                        ); // mm     = inch × 0.0254 × 1000
         generateConstant("FtToM",          4, EXACT,  "+3.048e-01"                                                   ); // m      = ft × 12 × 0.0254
         generateConstant("Ft2ToHa",        7, EXACT,  "+9.290304e-06"                                                ); // Ha     = ft2 × (12 × 0.0254)^2 / 10000
         generateConstant("Ft2ToM2",        7, EXACT,  "+9.290304e-02"                                                ); // m2     = ft2 × (12 × 0.0254)^2
         generateConstant("SfeetToM",      39, APPROX, "+3.048006096012192024384048768097536195072390144780289561e-01"); // m      = sfeetus × (1200 / 3937)
         generateConstant("YardToM",        4, EXACT,  "+9.144e-01"                                                   ); // m      = yard × 3 × 12 × 0.0254
         generateConstant("FathomToM",      5, EXACT,  "+1.8288"                                                      ); // m      = fathom × 6 × 12 × 0.0254
         generateConstant("MiToKm",         7, EXACT,  "+1.609344"                                                    ); // km     = mile × 63360 × 0.0254 / 1000
         generateConstant("MiSqToKmSq",    13, EXACT,  "+2.589988110336"                                              ); // km     = mile^2 × (63360 × 0.0254 / 1000)^2
         generateConstant("NmiToKm",        4, EXACT,  "+1.852"                                                       ); // km     = nmi × 1852 / 1000
         generateConstant("NmiToMi",       39, APPROX, "+1.150779448023542511731488109440865346377157400779448024"    ); // km     = nmi × 1852 / 1609.344
         generateConstant("NmiSqToKmSq",    7, EXACT,  "+3.429904"                                                    ); // km     = nmi^2 × (1852 / 1000)^2
         generateConstant("AuToM",         10, EXACT,  "+1.495978707e+11"                                             ); // m      = au × 149597870700
         generateConstant("LyToM",         14, EXACT,  "+9.4607304725808e+15"                                         ); // m      = ly × 299792458 × 3600 × 24 × 365.25
         generateConstant("PcToM",         39, APPROX, "+30856775814913672.78913937957796471610731921160409179801"    ); // m      = pc × 149597870700 × 648000 / pi
         generateConstant("LiToM",         39, EXACT,  "+5e+02"                                                       ); // m      = lǐ × 500
         generateConstant("YinToM",         1, EXACT,  "+3e-02"                                                       ); // m      = yǐn / 0.03
         generateConstant("CunToM",         1, EXACT,  "+3e+01"                                                       ); // m      = cùn / 30
         generateConstant("ZhangToM",       1, EXACT,  "+3e-01"                                                       ); // m      = zhàng / 0.3
         generateConstant("FenToM",         1, EXACT,  "+3e+02"                                                       ); // m      = fēn / 300
         generateConstant("MiToM",          7, EXACT,  "+1.609344e+03"                                                ); // m      = mile × 63360 × 0.0254
         generateConstant("NmiToM",         4, EXACT,  "+1.852e+03"                                                   ); // m      = nmi × 1852

         generateConstant("Kmphmps",       39, APPROX, "+2.777777777777777777777777777777777777777777777777777777e-01"); // mps      =  Kmph  * 0.277...   // 2.5/9
         generateConstant("RpmDegps",       1, EXACT,  "+6"                                                           ); // Degps    =  Rpm * 6
         generateConstant("Mphmps",         5, EXACT,  "+4.4704e-01"                                                  ); // mps      =  Mph  * 0.44704     //11.176/25
         generateConstant("RpmRadps",      39, APPROX, "+0.1047197551196597746154214461093167628065723133125035274"   ); // Radps    =  Rpm  * 0.1047   // pi/30

         generateConstant("AccreToHa",     11, EXACT,  "+4.0468564224e-01"                                            ); // ha     = acre × 0.0254² × 12² × 43560 / 10000
         generateConstant("AccreusToHa",   39, APPROX, "+4.046872609874252006568529266090790246096621225500515517e-01"); // ha     = acreus × (1200 / 3937)² × 43560 / 10000
         generateConstant("MuToM2",         2, EXACT,  "+1.5e-03"                                                     ); // m²     = mǔ / 0.0015
         generateConstant("FlozukToMl",     9, EXACT,  "+28.4130625"                                                  ); // ml     = flozuk × 4.54609e-3 / 160 × 1000000
         generateConstant("FlozusToMl",    12, EXACT,  "+29.5735295625"                                               ); // ml     = flozus × 231 × 0.0254³ / 128 × 1000000

         generateConstant("FlozukToIn3",   33, EXACT,  "+1.73387145494763430471742833249446"                          ); // in³    = flozuk × 4.54609e-3 / 160 × 1000000     / 2.54³
         generateConstant("FlozusToIn3",    8, EXACT,  "+1.8046875"                                                   ); // in³    = flozus × 231 × 0.0254³ / 128 × 1000000  / 2.54³
         generateConstant("Ft3ToGalUS",    33, EXACT,  "+7.48051948051948051948051948051948"                          ); // galus  = feet3 * (1/(231 × 0.0254³ × 1000)) * (12*0.254)³

         generateConstant("GalusToL",      10, EXACT,  "+3.785411784"                                                 ); // l      = galus × 231 × 0.0254³ × 1000
         generateConstant("GalukToL",       6, EXACT,  "+4.54609"                                                     ); // l      = galuk × 4.54609e-3 × 1000
         generateConstant("QuartToL",       8, EXACT,  "+1.1365225"                                                   ); // l      = quart × 4.54609e-3 / 4 × 1000
         generateConstant("BarrelToM3",    12, EXACT,  "+1.58987294928e-01"                                           ); // m³     = barrel × 42 × 231 × 0.0254³

         generateConstant("CaratToG",       1, EXACT,  "+2e-01"                                                       ); // g      = carat × 0.0002 × 1000
         generateConstant("OzToG",         11, EXACT,  "+28.349523125"                                                ); // g      = oz × (0.45359237 / 16) × 1000
         generateConstant("TrozToG",        9, EXACT,  "+31.1034768"                                                  ); // g      = tr.oz × 0.45359237 × 175 / 12 × 1000
         generateConstant("LbToKg",         8, EXACT,  "+4.5359237e-01"                                               ); // kg     = lb × 0.45359237     (1 lb (pound) = 16 oz)
         generateConstant("StoneToKg",      9, EXACT,  "+6.35029318"                                                  ); // kg     = stone × 14 × 0.45359237
         generateConstant("ShortcwtToKg",   8, EXACT,  "+45.359237"                                                   ); // kg     = short cwt × 100 × 0.45359237 (short cwt = short hundredweight)
         generateConstant("CwtToKg",       10, EXACT,  "+50.80234544"                                                 ); // kg     = cwt × 112 × 0.45359237       (cwt = long hundredweight)
         generateConstant("ShorttonToKg",   8, EXACT,  "+907.18474"                                                   ); // kg     = short ton × 2000 × 0.45359237
         generateConstant("TonToKg",       11, EXACT,  "+1016.0469088"                                                ); // kg     =2240 × 0.4535923 39, EXACT,7

         generateConstant("CalToJ",         5, EXACT,  "+4.1868"                                                      ); // joule  = calorie × 4.1868
         generateConstant("BtuToJ",        12, EXACT,  "+1055.05585262"                                               ); // joule  = Btu × 1055.05585262
         generateConstant("WhToJ",          2, EXACT,  "+3.6e+03"                                                     ); // joule  = Wh × 3600
         generateConstant("ErgToJ",         1, EXACT,  "+1e+07"                                                       ); // joule  = 10^-7
         generateConstant("FoeToJ",         1, EXACT,  "+1e-44"                                                       ); // joule  = 10^44

         generateConstant("LbfToN",        14, EXACT,  "+4.4482216152605"                                             ); // newton = lbf × 9.80665 × 0.45359237

         generateConstant("TorrToPa",      39, APPROX, "+133.3223684210526315789473684210526315789473684210526316"    ); // pascal = torr × 101325 / 760
         #if (MMHG_PA_133_3224 == 1)
           generateConstant("MmhgToPa",     7, EXACT,  "+133.3224"                                                    ); // pascal = mm.Hg × 133.3224                   // BS 350:2004 p51, 13.595 1 × 9.806 65       , approx used as per BS. This is NOT 'superceded' by american NIST; NPL:1998, p13 footnote
           generateConstant("InhgToPa",     9, EXACT,  "+3386.38896"                                                  ); // pascal = in.Hg × 133.3224 × 25.4            // BS 350:2004 p51, 13.595 1 × 9.806 65 x 25.4, approx used as per BS. This is NOT 'superceded' by american NIST; NPL:1998, p13 footnote
         #else // (MMHG_PA_133_3224 == 0)
           generateConstant("MmhgToPa",    39, EXACT,  "+1.333223874150e+02"                                          ); // pascal = mm.Hg × 13.5951 × 9.80665          // non-abbreviated
           generateConstant("InhgToPa",    39, EXACT,  "+3.386388640341e+03"                                          ); // pascal = in.Hg × 13.5951 × 9.80665 × 2.54   // non-abbreviated
         #endif // (MMHG_PA_133_3224 == 1)
         generateConstant("PsiToPa",       39, APPROX, "+6894.757293168361336722673445346890693781387562775125550"    ); // pascal = psi × 0.45359237 × 9.80665 / 0.0254²
         generateConstant("BarToPa",        1, EXACT,  "+1e+05"                                                       ); // pascal = bar  × 100000
         generateConstant("AtmToPa",        6, EXACT,  "+101325"                                                      ); // pascal = atm × 101325

         generateConstant("HpmToW",         8, EXACT,  "+735.49875"                                                   ); // watt   = HPM × 75 × 9.80665
         generateConstant("HpukToW",       17, EXACT,  "+745.69987158227022"                                          ); // watt   = HPUK × 550 × 0.3048 × 9.80665 × 0.45359237
         generateConstant("HpeToW",         3, EXACT,  "+746"                                                         ); // watt   = HPE × 746

         generateConstant("YearToS",        8, EXACT,  "+31556952"                                                    ); // second = year  × (365.2425 × 24 × 3600)

         generateConstant("LbfftToNm",     17, EXACT,  "+1.3558179483314004"                                          ); // Nm = lbf×ft × 9.80665 × 0.45359237 × 12 × 0.0254

         generateConstant("furToM",         6, EXACT,  "+201.168"                                                     ); // fff menu: Convert furlong to meter
         generateConstant("ftnToS",         5, EXACT,  "+1.2096e+06"                                                  ); // fff menu: Convert fortnight to second
         generateConstant("fpfToMps",      15, EXACT,  "+1.66309523809524e-04"                                        ); // fff menu: Convert furlong per fortnight to meter per second
         generateConstant("brdsTom",        1, EXACT,  "+1e-08"                                                       ); // fff menu: Convert beardsecond to meter
         generateConstant("firToKg",        9, EXACT,  "+40.8233133"                                                  ); // fff menu: Convert firkin to kilogram
         generateConstant("fpfToKph",      15, EXACT,  "+5.98714285714286e-04"                                        ); // fff menu: Convert furlong per fortnight to kilometer per hour
         generateConstant("brdsToIn",      15, EXACT,  "+3.93700787401575e-07"                                        ); // fff menu: Convert beardsecond to inch
         generateConstant("firToLb",       16, EXACT,  "+90.00000734139932"                                           ); // fff menu: Convert firkin to pound
         generateConstant("fpfToMph",      14, EXACT,  "+3.7202473418562e-04"                                         ); // fff menu: Convert furlong per fortnight to mile per hour

         generateConstant("fpsToKph",       6, EXACT,  "+1.09728"                                                     ); // foot per second to kilometer per hour
         generateConstant("fpsToMps",       4, EXACT,  "+3.048e-01"                                                   ); // foot per second to meter per second


         //// Chef menu
         generateConstant("CupcFzus",       1, EXACT,  "+8"                                                           ); // ratio us c       : 8     x
         generateConstant("CupcMl",        10, EXACT,  "+236.5882365"                                                 ); // defined us c     : GallonUS / 768 x 48
         generateConstant("CupukFzuk",      2, EXACT,  "+10"                                                          ); // ratio uk         : 10    x
         generateConstant("CupukMl",        9, EXACT,  "+284.130625"                                                  ); // defined uk       : GallonUK / 768 x 48
         generateConstant("FzukTbspuk",     2, EXACT,  "+1.6"                                                         ); // ratio uk         : 4.8/3 x
         generateConstant("FzukTspuk",      2, EXACT,  "+4.8"                                                         ); // ratio uk         : 4.8   x
         generateConstant("FzusTbspc",      1, EXACT,  "+2"                                                           ); // ratio us         : 6 / 3 x
         generateConstant("FzusTspc",       1, EXACT,  "+6"                                                           ); // ratio us         : 6     x
         generateConstant("PintlqMl",       9, EXACT,  "+473.176473"                                                  ); // defined us c     : GallonUS / 768 x 96   x
         generateConstant("PintukMl",       8, EXACT,  "+568.26125"                                                   ); // defined uk       : GallonUK / 768 x 96   x
         generateConstant("QtMl",           8, EXACT,  "+1136.5225"                                                   ); // defined uk       : GallonUK / 768 x 192  x
         generateConstant("QtusMl",         9, EXACT,  "+946.352946"                                                  ); // defined us       : GallonUS / 768 x 192  x
         generateConstant("TbspcMl",       13, EXACT,  "+14.78676478125"                                              ); // defined us       : GallonUS / 768 x 3    x
         generateConstant("TbspukMl",      12, EXACT,  "+17.7581640625"                                               ); // defined uk       : GallonUK / 768 x 3    x
         generateConstant("TspcMl",        12, EXACT,  "+4.92892159375"                                               ); // defined us       : GallonUS / 768        x
         generateConstant("TspukMl",       39, APPROX, "+5.919388020833333333333333333333333333333333333333333333"    ); // defined uk       : GallonUK / 768        x
         generateConstant("In3Ml",          8, EXACT,  "+16.387064"                                                   ); // defined          :  (     in x 2.54)^3   x
         generateConstant("Ft3Gluk",       34, EXACT,  "+6.228835459042825812951349401353691"                         ); // defined uk       : ((ft × 12 × 2.54)^3 / 1000) / (4.54609e-3 × 1000, definition UK) x
         generateConstant("Ft3L",          11, EXACT,  "+28.316846592"                                                ); // defined          :  (ft × 12 × 2.54)^3 / 1000
         generateConstant("LQtus",         15, EXACT,  "+1.05668820943259"                                            ); // defined us       : 1000 / (GallonUK / 768 x 192) x
         generateConstant("GlukFzuk",       3, EXACT,  "+160"                                                         ); // defined uk       : 1600 x
         generateConstant("GlusFzus",       3, EXACT,  "+128"                                                         ); // defined uz       : 1200 x
         generateConstant("bananamm",       3, EXACT,  "+178"                                                         );
         generateConstant("bananaInch",    39, APPROX, "+7.007874015748031496062992125984251968503937007874015748"    );
         generateConstant("InchToCm",       3, EXACT,  "+2.54"                                                        ); // cm     = inch × 0.0254 × 1000 / 10
         generateConstant("273p15",         5, EXACT,  "+273.15"                                                      ); // defined Temperature : 273.15                                // SI exact
         generateConstant("459p67",         5, EXACT,  "+459.67"                                                      ); // defined Temperature : 459.67                                // 273.15 × 9/5 − 32 = 459.67 exactly
         generateConstant("kBeVK",         39, APPROX, "+8.617333262145177433663659334080639201233039577582555108e-05"); // defined Temperature : exact: 1380649/16021766340            // both kB (J/K) = 1.380649×10⁻²³ and 1 eV = 1.602176634×10⁻¹⁹ J are SI-defined exact values

         generateConstant("_108",           3, EXACT,  "-108"                                                         );
         generateConstant("_4",             1, EXACT,  "-4"                                                           );
         generateConstant("_1",             1, EXACT,  "-1"                                                           );
         generateConstant("1oneE",         39, APPROX, "+3.678794411714423215955237701614608674458111310317678345e-01");
         generateConstant("1e_49",          1, EXACT,  "+1e-49"                                                       );
         generateConstant("1e_37",          1, EXACT,  "+1e-37"                                                       );
         generateConstant("1e_24",          1, EXACT,  "+1e-24"                                                       );
         generateConstant("1e_6",           1, EXACT,  "+1e-06"                                                       );
         generateConstant("1e_16",          1, EXACT,  "+1e-16"                                                       );
         generateConstant("1on10",          1, EXACT,  "+1e-01"                                                       );
         generateConstant("1on4",           2, EXACT,  "+0.25"                                                        );
         generateConstant("1on3",          39, APPROX, "+3.333333333333333333333333333333333333333333333333333333e-01");
         generateConstant("1on2",           1, EXACT,  "+0.5"                                                         );
         generateConstant("egamma",        39, APPROX, "+5.772156649015328606065120900824024310421593359399235988e-01");
         generateConstant("ln2",           39, APPROX, "+6.931471805599453094172321214581765680755001343602552541e-01");
         generateConstant("root2",         39, APPROX, "+1.414213562373095048801688724209698078569671875376948073"    );
         generateConstant("root2on2",      39, APPROX, "+7.071067811865475244008443621048490392848359376884740366e-01");
         generateConstant("piOn4",         39, APPROX, "+7.853981633974483096156608458198757210492923498437764552e-01");
         generateConstant("root3on2",      39, APPROX, "+8.660254037844386467637231707529361834714026269051903140e-01");
         generateConstant("9on10",          1, EXACT,  "+0.9"                                                         );
         generateConstant("ln2piOn2",      39, APPROX, "+9.189385332046727417803297364056176398613974736377834128e-01");
         generateConstant("1",              1, EXACT,  "+1"                                                           );
         generateConstant("3on2",           2, EXACT,  "+1.5"                                                         );
         generateConstant("piOn2",         39, APPROX, "+1.570796326794896619231321691639751442098584699687552910"    );
         generateConstant("9on5",           2, EXACT,  "+1.8"                                                         );
         generateConstant("2",              1, EXACT,  "+2"                                                           );
         generateConstant("ln10",          39, APPROX, "+2.302585092994045684017991454684364207601101488628772976"    );
         generateConstant("3piOn4",        39, APPROX, "+2.356194490192344928846982537459627163147877049531329366"    );
         generateConstant("3",              1, EXACT,  "+3"                                                           );
         generateConstant("4",              1, EXACT,  "+4"                                                           );
         generateConstant("3piOn2",        39, APPROX, "+4.712388980384689857693965074919254326295754099062658731"    );
         generateConstant("5",              1, EXACT,  "+5"                                                           );
         generateConstant("6",              1, EXACT,  "+6"                                                           );
         generateConstant("2pi",           39, APPROX, "+6.283185307179586476925286766559005768394338798750211642"    );
         generateConstant("7",              1, EXACT,  "+7"                                                           );
         generateConstant("8",              1, EXACT,  "+8"                                                           );
         generateConstant("9",              1, EXACT,  "+9"                                                           );
         generateConstant("10",             2, EXACT,  "+10"                                                          );
         generateConstant("12",             2, EXACT,  "+12"                                                          );
         generateConstant("20",             2, EXACT,  "+20"                                                          );
         generateConstant("24",             2, EXACT,  "+24"                                                          );
         generateConstant("27",             2, EXACT,  "+27"                                                          );
         generateConstant("29",             2, EXACT,  "+29"                                                          ); // used for Lanczos N=30
         generateConstant("30",             2, EXACT,  "+30"                                                          );
         generateConstant("gammaR",        31, EXACT,  "+31.43188335932791233062744140625"                            ); // used for Lanczos N=30
         generateConstant("32",             1, EXACT,  "+32"                                                          );
         generateConstant("36",             1, EXACT,  "+36"                                                          );
         generateConstant("47",             1, EXACT,  "+47"                                                          );
         generateConstant("54",             1, EXACT,  "+54"                                                          );
         generateConstant("180onPi",       39, APPROX, "+57.29577951308232087679815481410517033240547246656432155"    );
         generateConstant("60",             1, EXACT,  "+60"                                                          );
         generateConstant("200onPi",       39, APPROX, "+63.6619772367581343075535053490057448137838582961825795"     );
         generateConstant("125",            3, EXACT,  "+125"                                                         );
         generateConstant("150",            3, EXACT,  "+150"                                                         );
         generateConstant("205",            3, EXACT,  "+205"                                                         );
         generateConstant("360",            3, EXACT,  "+360"                                                         );
         generateConstant("400",            3, EXACT,  "+400"                                                         );
         generateConstant("600",            3, EXACT,  "+600"                                                         );
         generateConstant("1000",           1, EXACT,  "+1e+03"                                                       );
         generateConstant("1024",           4, EXACT,  "+1024"                                                        );
         generateConstant("1260",           3, EXACT,  "+1.26e+03"                                                    );
         generateConstant("1680",           3, EXACT,  "+1.68e+03"                                                    );
         generateConstant("2100",           2, EXACT,  "+2.1e+03"                                                     );
         generateConstant("2520",           3, EXACT,  "+2.52e+03"                                                    );
         generateConstant("2916",           4, EXACT,  "+2916"                                                        );
         generateConstant("3600",           2, EXACT,  "+3.6e+03"                                                     );
         generateConstant("6000",           1, EXACT,  "+6e+03"                                                       );
         generateConstant("9000",          39, EXACT,  "+9e+03"                                                       );
         generateConstant("9999",           4, EXACT,  "+9999"                                                        );
         generateConstant("10000",          1, EXACT,  "+1e+04"                                                       );
         generateConstant("25200",          3, EXACT,  "+2.52e+04"                                                    );
         generateConstant("42000",          2, EXACT,  "+4.2e+04"                                                     );
         generateConstant("73766",          5, EXACT,  "+73766"                                                       );
         generateConstant("86400",          3, EXACT,  "+8.64e+04"                                                    );
         generateConstant("2e6",            1, EXACT,  "+2e+06"                                                       );
         generateConstant("2p32",          10, EXACT,  "+4294967296"                                                  );
         generateConstant("1e32",           1, EXACT,  "+1e+32"                                                       );
         generateConstant("2p31__1",       10, EXACT,  "+2147483647"                                                  );
         generateConstant("10p9__1",        9, EXACT,  "+999999999"                                                   );
         generateConstant("2p63",          19, EXACT,  "+9223372036854775808"                                         );
         generateConstant("2p64",          20, EXACT,  "+18446744073709551616"                                        );
         generateConstant("1e_10000",       1, EXACT,  "+1e-10000"                                                    );
         generateConstant("995on1000",      3, EXACT,  "+9.95e-01"                                                    );
         generateConstant("1e_32",          1, EXACT,  "+1e-32"                                                       );
         generateConstant("rt3",           39, APPROX, "+1.732050807568877293527446341505872366942805253810380628"    );
         generateConstant("rt5",           39, APPROX, "+2.236067977499789696409173668731276235440618359611525724"    );
         generateConstant("rt7",           39, APPROX, "+2.645751311064590590501615753639260425710259183082450180"    );
         generateConstant("GaluseqE",       3, EXACT,  "+33.7"                                                        );
         generateConstant("1e_6143",        1, EXACT,  "+1e-6143"                                                     );
         generateConstant("rtpi",          39, APPROX, "+1.772453850905516027298167483341145182797549456122387128"    );
         generateConstant("1onpi",         39, APPROX, "+3.183098861837906715377675267450287240689192914809128975e-01");
         generateConstant("pisq",          39, APPROX, "+9.869604401089358618834490999876151135313699407240790626"    );
         generateConstant("eEsq",          39, APPROX, "+7.389056098930650227230427460575007813180315570551847324"    );
         generateConstant("1onpisq",       39, APPROX, "+1.013211836423377714438794632097276389043587746722465488e-01");
         generateConstant("1oneEsq",       39, APPROX, "+1.353352832366126918939994949724844034076315459095758815e-01");


         // A better set of Lanczos constants?
         // https://www.boost.org/doc/libs/1_71_0/boost/math/special_functions/lanczos.hpp
         // https://www.boost.org/doc/libs/1_71_0/libs/math/doc/html/math_toolkit/lanczos.html
         // Lanczos's coefficients calculated for N=30 and G=30.9318857491016387939453125 using Toth's program: https://www.vttoth.com/CMS/projects/41
         // source: https://www.vttoth.com/FILES/lanczos.tgz
         generateConstant("gammaC00",      51, APPROX, "+2.506628274631000502415765284811045253006986740036318756703152698088652909808141644264478158114643");
         generateConstant("gammaC01",      51, APPROX, "+90795313438554.12585760728412902207185494121818510422990562390199419594778421509725059250660477478");
         generateConstant("gammaC02",      51, APPROX, "-966788810976616.3165238613163922965882171247384377771690792930892852741666385482155753752741846215");
         generateConstant("gammaC03",      51, APPROX, "+4800584619652903.130520636355077553806266769741879659498830407152738371167934130745600044623388068");
         generateConstant("gammaC04",      51, APPROX, "-14765868961297540.27064904092821149556100711736690133148186310232345861145647352272488652687903457");
         generateConstant("gammaC05",      51, APPROX, "+31520009430682538.17457937985920649010992386050798974102315423368438398460245896094052856122203775");
         generateConstant("gammaC06",      51, APPROX, "-49582365010416661.09326008795178786489253227385559918969410907133030684376335533671631031226780693");
         generateConstant("gammaC07",      51, APPROX, "+59568927402677002.04904143939675965126139196724493177865501398609411221897535112902272116361691451");
         generateConstant("gammaC08",      51, APPROX, "-55906342816448463.66899438215049258933959227649607458054232171494476786360919120606779433224203661");
         generateConstant("gammaC09",      51, APPROX, "+41579705761882718.81836872026846865595091094440150772658809279820390684724850793073271091274939857");
         generateConstant("gammaC10",      51, APPROX, "-24720590950576683.15802797249415999638807846332716128189191944706094647468094435934791589404852933");
         generateConstant("gammaC11",      51, APPROX, "+11801286985635343.58575847383935274746074763562173560062003882605616928057523864988435228756829000");
         generateConstant("gammaC12",      51, APPROX, "-4528196760270806.995369621666200554735964133084677928395568191894066774034949226537269118163329489");
         generateConstant("gammaC13",      51, APPROX, "+1393637064384668.917157722908202033726675908093527246704252104958408303381715387740313008845141904");
         generateConstant("gammaC14",      51, APPROX, "-342325016766888.5479936955467723387327600568400337988293619211103486673308239810777313598627315000");
         generateConstant("gammaC15",      51, APPROX, "+66578560073752.67246403368251720854813222816576859988564202476567602534436134110254400104404942690");
         generateConstant("gammaC16",      51, APPROX, "-10138544793022.41604607361389789580035078467043905508354626409172360042771928364449573017241522124");
         generateConstant("gammaC17",      51, APPROX, "+1190960562789.022438954352946350698116714288406439572882388541923119338089933765849690628214181895");
         generateConstant("gammaC18",      51, APPROX, "-105857166683.4123935373722836022279857082446927458625016646619942749346232137590435016079220044575");
         generateConstant("gammaC19",      51, APPROX, "+6945291327.796451124796820522079456356395826950647769057580507091796596412483352351183618549540841");
         generateConstant("gammaC20",      51, APPROX, "-325841232.8464260929688459624630603325071713695605050282752915466327762939975965122976740632863654");
         generateConstant("gammaC21",      51, APPROX, "+10491089.04183867431328778246866673594812558539972730107563825597306012268992151854201423652554125");
         generateConstant("gammaC22",      51, APPROX, "-219652.9521075940388150629624539015343302845601375714110391179944415326942002537588845815284375311");
         generateConstant("gammaC23",      51, APPROX, "+2782.640500292405732331071582785081107276742114500310058012342169019346915906467717358069437084413");
         generateConstant("gammaC24",      51, APPROX, "-19.31769482393126228999283928711817461826517031491190754697778125203682359806685621504868658022287");
         generateConstant("gammaC25",      51, APPROX, "+0.063813226038364736490677427053094184825560153837400637303741419820260651820063721448175876091640");
         generateConstant("gammaC26",      51, APPROX, "-0.000081213345051388882076245151519040492731624505633194015094047296992491188162952243561414155660");
         generateConstant("gammaC27",      51, APPROX, "+0.000000028425884712306176285600873249949436913248124688912080334562388569408577988201187292514310");
         generateConstant("gammaC28",      51, APPROX, "-0.000000000001515686855682081535390179935440192138970398946754350022046202956603870401666503058594");
         generateConstant("gammaC29",      51, APPROX, "+0.000000000000000003727184110478268994444830355775133199862144652804253659035860755294511160286895");

         // Array angle180
         generateConstant("pi",            75, APPROX, "+3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825"   );
         generateConstant("200",            3, EXACT,  "+200");
         generateConstant("180",            3, EXACT,  "+180");

         // Array angle90
         generateConstant("piOn2",         75, APPROX, "+1.570796326794896619231321691639751442098584699687552910487472296153908203143104499314017412"   );
         generateConstant("100",            3, EXACT,  "+100");
         generateConstant("90",             2, EXACT,  "+90");

         // Array angle45
         generateConstant("piOn4",         75, APPROX, "+7.85398163397448309615660845819875721049292349843776455243736148076954101571552249657008706e-01");
         generateConstant("50",             2, EXACT,  "+50");
         generateConstant("45",             2, EXACT,  "+45");

         generateConstant("2pi",           75, APPROX, "+6.2831853071795864769252867665590057683943387987502116419498891846156328125724");
         generateConstant("3piOn4",        75, APPROX, "+2.3561944901923449288469825374596271631478770495313293657312084442308623047147");

         generateConstant("3piOn4",      1071, APPROX, "+2.3561944901923449288469825374596271631478770495313293657312084442308623047146567489710261190065878009" //   101
                                                          "8661106488496172998532038345716293667379401955609636083808771307702645389082916973346721171619778647" //   201
                                                          "3321608231749450084596356736175340087373953401431859236425192595261457840744986160045205445186855955" //   301
                                                          "2934402549547366911311611406907221219405687865232759194427700084978979116153498910381102139561337070" //   401
                                                          "7479295277431969396481913958803644945884482883891105584678497206217551391431454366842095363725896184" //   501
                                                          "7375255021830492482314516046209796418552893026634895707777077904412882219882564288506113850752053849" //   601
                                                          "0004260953589476706208393285070683422068802278840411013306759187150726099121890282880942097669441926" //   701
                                                          "5651496708409676647064802581361986022233107848247038903040851249999877973353746329479879961207223894" //   801
                                                          "6268344591510181226981891731190008513776446448391128257502353379064664940649906286065462883251860477" //   901
                                                          "6986901178215666015483696721479117653406953139683363933353991284201049597514459074583969319123151492" //  1001
                                                          "0357144290079911439745914945211503637097617272646402647638972674683021694956041843729133146260934863" //  1101
                         );

         generateConstant("piOn4",       1071, APPROX, "+0.7853981633974483096156608458198757210492923498437764552437361480769541015715522496570087063355292669" //   101
                                                          "9553702162832057666177346115238764555793133985203212027936257102567548463027638991115573723873259549" //   201
                                                          "1107202743916483361532118912058446695791317800477286412141730865087152613581662053348401815062285318" //   301
                                                          "4311467516515788970437203802302407073135229288410919731475900028326326372051166303460367379853779023" //   401
                                                          "5826431759143989798827304652934548315294827627963701861559499068739183797143818122280698454575298728" //   501
                                                          "2458418340610164160771505348736598806184297675544965235925692634804294073294188096168704616917351283" //   601
                                                          "0001420317863158902069464428356894474022934092946803671102253062383575366373963427626980699223147308" //   701
                                                          "8550498902803225549021600860453995340744369282749012967680283749999959324451248776493293320402407964" //   801
                                                          "8756114863836727075660630577063336171258815482797042752500784459688221646883302095355154294417286825" //   901
                                                          "8995633726071888671827898907159705884468984379894454644451330428067016532504819691527989773041050497" //  1001
                                                          "3452381430026637146581971648403834545699205757548800882546324224894340564985347281243044382086978287" //  1101
                         );

         generateConstant("piOn2",       1071, APPROX, "+1.5707963267948966192313216916397514420985846996875529104874722961539082031431044993140174126710585339" //   101
                                                          "9107404325664115332354692230477529111586267970406424055872514205135096926055277982231147447746519098" //   201
                                                          "2214405487832966723064237824116893391582635600954572824283461730174305227163324106696803630124570636" //   301
                                                          "8622935033031577940874407604604814146270458576821839462951800056652652744102332606920734759707558047" //   401
                                                          "1652863518287979597654609305869096630589655255927403723118998137478367594287636244561396909150597456" //   501
                                                          "4916836681220328321543010697473197612368595351089930471851385269608588146588376192337409233834702566" //   601
                                                          "0002840635726317804138928856713788948045868185893607342204506124767150732747926855253961398446294617" //   701
                                                          "7100997805606451098043201720907990681488738565498025935360567499999918648902497552986586640804815929" //   801
                                                          "7512229727673454151321261154126672342517630965594085505001568919376443293766604190710308588834573651" //   901
                                                          "7991267452143777343655797814319411768937968759788909288902660856134033065009639383055979546082100994" //  1001
                                                          "6904762860053274293163943296807669091398411515097601765092648449788681129970694562486088764173956575" //  1101
                         );

         generateConstant("pi",          1071, APPROX, "+3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679" //   101
                                                          "8214808651328230664709384460955058223172535940812848111745028410270193852110555964462294895493038196" //   201
                                                          "4428810975665933446128475648233786783165271201909145648566923460348610454326648213393607260249141273" //   301
                                                          "7245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094" //   401
                                                          "3305727036575959195309218611738193261179310511854807446237996274956735188575272489122793818301194912" //   501
                                                          "9833673362440656643086021394946395224737190702179860943702770539217176293176752384674818467669405132" //   601
                                                          "0005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235" //   701
                                                          "4201995611212902196086403441815981362977477130996051870721134999999837297804995105973173281609631859" //   801
                                                          "5024459455346908302642522308253344685035261931188171010003137838752886587533208381420617177669147303" //   901
                                                          "5982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989" //  1001
                                                          "3809525720106548586327886593615338182796823030195203530185296899577362259941389124972177528347913151" //  1101
                         );

         generateConstant("2pi",         1071, APPROX, "+6.2831853071795864769252867665590057683943387987502116419498891846156328125724179972560696506842341359" //   101
                                                          "6429617302656461329418768921910116446345071881625696223490056820540387704221111928924589790986076392" //   201
                                                          "8857621951331866892256951296467573566330542403818291297133846920697220908653296426787214520498282547" //   301
                                                          "4491740132126311763497630418419256585081834307287357851807200226610610976409330427682939038830232188" //   401
                                                          "6611454073151918390618437223476386522358621023709614892475992549913470377150544978245587636602389825" //   501
                                                          "9667346724881313286172042789892790449474381404359721887405541078434352586353504769349636935338810264" //   601
                                                          "0011362542905271216555715426855155792183472743574429368818024499068602930991707421015845593785178470" //   701
                                                          "8403991222425804392172806883631962725954954261992103741442269999999674595609990211946346563219263719" //   801
                                                          "0048918910693816605285044616506689370070523862376342020006275677505773175066416762841234355338294607" //   901
                                                          "1965069808575109374623191257277647075751875039155637155610643424536132260038557532223918184328403978" //  1001
                                                          "7619051440213097172655773187230676365593646060390407060370593799154724519882778249944355056695826303" //  1101
                         );

         generateConstant("2pi",         2139, APPROX, "+6.2831853071795864769252867665590057683943387987502116419498891846156328125724179972560696506842341359" //   101
                                                          "6429617302656461329418768921910116446345071881625696223490056820540387704221111928924589790986076392" //   201
                                                          "8857621951331866892256951296467573566330542403818291297133846920697220908653296426787214520498282547" //   301
                                                          "4491740132126311763497630418419256585081834307287357851807200226610610976409330427682939038830232188" //   401
                                                          "6611454073151918390618437223476386522358621023709614892475992549913470377150544978245587636602389825" //   501
                                                          "9667346724881313286172042789892790449474381404359721887405541078434352586353504769349636935338810264" //   601
                                                          "0011362542905271216555715426855155792183472743574429368818024499068602930991707421015845593785178470" //   701
                                                          "8403991222425804392172806883631962725954954261992103741442269999999674595609990211946346563219263719" //   801
                                                          "0048918910693816605285044616506689370070523862376342020006275677505773175066416762841234355338294607" //   901
                                                          "1965069808575109374623191257277647075751875039155637155610643424536132260038557532223918184328403978" //  1001
                                                          "7619051440213097172655773187230676365593646060390407060370593799154724519882778249944355056695826303" //  1101
                                                          "1149714484908301391901659066233723455711778150196763509274929878638510120801855403342278019697648025" //  1201
                                                          "7167232071274153202094203638859111923978935356748988965107595494536942080950692924160933685181389825" //  1301
                                                          "8662735405797830420950432411393204811607630038702250676486007117528049499294652782839854520853984559" //  1401
                                                          "3564709563272018683443282439849172630060572365949111413499677010989177173853991381854421595018605910" //  1501
                                                          "6423306899744055119204729613309982397636695955071327396148530850557251036368351493457819555455876001" //  1601
                                                          "6329412003229049838434643442954470028288394713709632272231470510426695148369893687704664781478828666" //  1701
                                                          "9095524833725037967138971124198438444368545100508513775343580989203306933609977254465583572171568767" //  1801
                                                          "6559359533629082019077675727219013601284502504102347859697921682569772538912084839305700444213223726" //  1901
                                                          "1348855724407838989009424742757392191272874383457493552931514792482778173166529199162678095605518019" //  2001
                                                          "8931528157902538936796705191419651645241044978815453438956536965202953981805280272788874910610136406" //  2101
                                                          "9925049034987993028628596183813185018744433929230314197167748211957719195459509978603235078569362765" //  2201
                         );

         generateConstant("2pi",         6147, APPROX, "+6.2831853071795864769252867665590057683943387987502116419498891846156328125724179972560696506842341359" //   101
                                                          "6429617302656461329418768921910116446345071881625696223490056820540387704221111928924589790986076392" //   201
                                                          "8857621951331866892256951296467573566330542403818291297133846920697220908653296426787214520498282547" //   301
                                                          "4491740132126311763497630418419256585081834307287357851807200226610610976409330427682939038830232188" //   401
                                                          "6611454073151918390618437223476386522358621023709614892475992549913470377150544978245587636602389825" //   501
                                                          "9667346724881313286172042789892790449474381404359721887405541078434352586353504769349636935338810264" //   601
                                                          "0011362542905271216555715426855155792183472743574429368818024499068602930991707421015845593785178470" //   701
                                                          "8403991222425804392172806883631962725954954261992103741442269999999674595609990211946346563219263719" //   801
                                                          "0048918910693816605285044616506689370070523862376342020006275677505773175066416762841234355338294607" //   901
                                                          "1965069808575109374623191257277647075751875039155637155610643424536132260038557532223918184328403978" //  1001
                                                          "7619051440213097172655773187230676365593646060390407060370593799154724519882778249944355056695826303" //  1101
                                                          "1149714484908301391901659066233723455711778150196763509274929878638510120801855403342278019697648025" //  1201
                                                          "7167232071274153202094203638859111923978935356748988965107595494536942080950692924160933685181389825" //  1301
                                                          "8662735405797830420950432411393204811607630038702250676486007117528049499294652782839854520853984559" //  1401
                                                          "3564709563272018683443282439849172630060572365949111413499677010989177173853991381854421595018605910" //  1501
                                                          "6423306899744055119204729613309982397636695955071327396148530850557251036368351493457819555455876001" //  1601
                                                          "6329412003229049838434643442954470028288394713709632272231470510426695148369893687704664781478828666" //  1701
                                                          "9095524833725037967138971124198438444368545100508513775343580989203306933609977254465583572171568767" //  1801
                                                          "6559359533629082019077675727219013601284502504102347859697921682569772538912084839305700444213223726" //  1901
                                                          "1348855724407838989009424742757392191272874383457493552931514792482778173166529199162678095605518019" //  2001
                                                          "8931528157902538936796705191419651645241044978815453438956536965202953981805280272788874910610136406" //  2101
                                                          "9925049034987993028628596183813185018744433929230314197167748211957719195459509978603235078569362765" //  2201
                                                          "3736773788554831198371185049190791886209994504936169197454728939169730767347244525219824921610248776" //  2301
                                                          "8780902488273099525561595431382871995400259232178883389737111696812706844144451656977296316912057012" //  2401
                                                          "0336854789045349353577905042770450999093334556479729131922327097724611549129960711872691363486482250" //  2501
                                                          "3015213895890219319218805045775942178629133827373445749788112020300661723585736184174952183564987717" //  2601
                                                          "8019429819351970522731099563786259569643365997897445317609715128028540955110264759282903047492468729" //  2701
                                                          "0857168895905317356421022827094714790462268543322042719390724628859049698743742202915308071805598688" //  2801
                                                          "0748401462115707812439677489561695697936664289142773750388701286043690638209696201074122936134983855" //  2901
                                                          "6382395879904122839326857508881287490247436384359996782031839123629350285382479497881814372988463923" //  3001
                                                          "1358904161902931004504632077638602841875242757119132778755741660781395841546934443651251993230028430" //  3101
                                                          "0613607689546909840521082933185040299488570146503733200426486817638142097266346929930290781159253712" //  3201
                                                          "2011016213317593996327149472768105142918205794128280221942412560878079519031354315400840675739872014" //  3301
                                                          "4611175263527188437462502942410658563836523722517346431583968296976583289412191505413914441835134233" //  3401
                                                          "4458219633818305603470134254971664457436704187079314502421671583027397641828884201350206693422062825" //  3501
                                                          "3422273981731703279663003940330302337034287531523670311301769819979719964774691056663271015295837071" //  3601
                                                          "7864523709792642658661797141284093505181418309628330997189232743605419639886198489779151425657811846" //  3701
                                                          "4665219459942416886714653097876478238651949273346116720828562776606407649807517970487488340582655312" //  3801
                                                          "3618754688806141493842240382604066076039524220220089858643032168488971927533967790457369566247105316" //  3901
                                                          "4262899153714524866883786079372852486821546453956056146378308822020893646505432402105304544223320793" //  4001
                                                          "3311461850942211157075269336413062197930538372411295386251411727132403711620145872131975297223582090" //  4101
                                                          "6697700692227315373506498883336079253159575437112169105930825330817061228688863717353950291322813601" //  4201
                                                          "4004757553182688034254989408411244610779891226281422540008157094665398781629093292917615945416533661" //  4301
                                                          "2686571757139661047161786613151481359091432755050840422991152316280050025245718826043294310195851846" //  4401
                                                          "1981593094752251035313502715035659332909558349002259922978060927989426592421468087503791471922917803" //  4501
                                                          "8779426223580859565712950064063973830280574161719809602188242944426358952955452448285097090806643143" //  4601
                                                          "7061228457627517008612664350365959732447434431832154333850949747797330989890022930812568673278758007" //  4701
                                                          "9538531344292770613472193142418361527665433283254977760157385120580456944208063442372164083800084593" //  4801
                                                          "2342392755842675150229919003132099263725894530947285046163540735031813470047014567081134080773487027" //  4901
                                                          "2444495431783009906196889786661926817561538651987956108386828947548836852625972161997773748265209443" //  5001
                                                          "1390324793172914604326319638639033470762594833545895734484584930873360196135385647656137992800964870" //  5101
                                                          "8074028326299317958818486475793814139558844725016443377914767597246003187552943302457871572031763235" //  5201
                                                          "1156594704668920856302525440746862930639555483206398133108375279585866883904308268379897088946913476" //  5301
                                                          "6324998683826362961855554207727754686354415091309064415541842403810332192560981852720395197656322664" //  5401
                                                          "6333273057238653372672125471352607089552560700901554471094211719097405581628712480290343612492872535" //  5501
                                                          "8912255063626815666067250846556788995076487441167062295423985212762669355375939194061966782615421974" //  5601
                                                          "0817182674928288564554526931894094917569557440385543056146353581541431442688946121140146698487386227" //  5701
                                                          "6700986326256808502438513035961388227056026294026095632875770370581857090402331678683931242698286831" //  5801
                                                          "9125173173114110538099304197160677014448529658794571695663261155551213777528924964937158520790705546" //  5901
                                                          "9606096058011752151650209494183287922725352089851254840841664171322381250908674426307191690137544920" //  6001
                                                          "5803237533590481232685045154390858325983861291075598280746808657505257779279917589514583492852714910" //  6101
                                                          "5081581829027142227388218238786503821520416504052375970637754116859451833556262993980180384233943474" //  6201
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
                                                          //"4077130781982095518828264308656881250060360551433930164192854696829391452795768512016906242813187161" // 20101
                         );


         generateConstant34("0",           "+0.000000000000000000000000000000000e+00"); // 0 must be the 1st const34 constant
         generateConstant34("_4712",       "-4.712000000000000000000000000000000e+03");
         generateConstant34("1e_32",       "+1.000000000000000000000000000000000e-32");
         generateConstant34("1e_24",       "+1.000000000000000000000000000000000e-24");
         generateConstant34("1e_4",        "+1.000000000000000000000000000000000e-04");
         generateConstant34("1on10",       "+1.000000000000000000000000000000000e-01");
         generateConstant34("1on2",        "+5.000000000000000000000000000000000e-01");
         generateConstant34("1",           "+1.000000000000000000000000000000000e+00");
         generateConstant34("2",           "+2.000000000000000000000000000000000e+00");
         generateConstant34("3",           "+3.000000000000000000000000000000000e+00");
         generateConstant34("4",           "+4.000000000000000000000000000000000e+00");
         generateConstant34("5",           "+5.000000000000000000000000000000000e+00");
         generateConstant34("7",           "+7.000000000000000000000000000000000e+00");
         generateConstant34("9",           "+9.000000000000000000000000000000000e+00");
         generateConstant34("10",          "+1.000000000000000000000000000000000e+01");
         generateConstant34("12",          "+1.200000000000000000000000000000000e+01");
         generateConstant34("14",          "+1.400000000000000000000000000000000e+01");
         generateConstant34("24",          "+2.400000000000000000000000000000000e+01");
         generateConstant34("28",          "+2.800000000000000000000000000000000e+01");
         generateConstant34("31",          "+3.100000000000000000000000000000000e+01");
         generateConstant34("38",          "+3.800000000000000000000000000000000e+01");
         generateConstant34("60",          "+6.000000000000000000000000000000000e+01");
         generateConstant34("100",         "+1.000000000000000000000000000000000e+02");
         generateConstant34("153",         "+1.530000000000000000000000000000000e+02");
         generateConstant34("275",         "+2.750000000000000000000000000000000e+02");
         generateConstant34("367",         "+3.670000000000000000000000000000000e+02");
         generateConstant34("400",         "+4.000000000000000000000000000000000e+02");
         generateConstant34("1000",        "+1.000000000000000000000000000000000e+03");
         generateConstant34("1401",        "+1.401000000000000000000000000000000e+03");
         generateConstant34("1461",        "+1.461000000000000000000000000000000e+03");
         generateConstant34("3600",        "+3.600000000000000000000000000000000e+03");
         generateConstant34("4716",        "+4.716000000000000000000000000000000e+03");
         generateConstant34("4800",        "+4.800000000000000000000000000000000e+03");
         generateConstant34("4900",        "+4.900000000000000000000000000000000e+03");
         generateConstant34("5001",        "+5.001000000000000000000000000000000e+03");
         generateConstant34("32075",       "+3.207500000000000000000000000000000e+04");
         generateConstant34("43200",       "+4.320000000000000000000000000000000e+04");
         generateConstant34("65535",       "+6.553500000000000000000000000000000e+04");
         generateConstant34("86400",       "+8.640000000000000000000000000000000e+04");
         generateConstant34("146097",      "+1.460970000000000000000000000000000e+05");
         generateConstant34("274277",      "+2.742770000000000000000000000000000e+05");
         generateConstant34("1e6",         "+1.000000000000000000000000000000000e+06");
         generateConstant34("1729777",     "+1.729777000000000000000000000000000e+06");
         generateConstant34("2p32",        "+4.294967296000000000000000000000000e+09");
         generateConstant34("maxDate",     "+3.155695348699627200000000000000000e+18");
         generateConstant34("maxTime",     "+3.600000000000000000000000000000000e+19");

         strcat(realArray, "};\n");
}


int main(int argc, char* argv[]) {
  if(argc < 3) {
    printf("Usage: generateConstants <c file> <h file>\n");
    return 1;
  }

  decContextDefault(&ctxtReal34, DEC_INIT_DECQUAD);
  decContextDefault(&ctxtReal,   DEC_INIT_DECQUAD);

  ctxtReal.traps  = 0;

  strcpy(externalDeclarations, "  extern const uint8_t constants[];\n");
  realArray[0] = 0;
  sprintf(realTConstantArray, "\nTO_QSPI const real_t *realtConstants[%" PRId32 "] = {\n", NOUC);
  cntRealt = 0;

  generateAllConstants();


  constantsH = fopen(argv[2], "wb");
  if(constantsH == NULL) {
    fprintf(stderr, "Cannot create file %s\n", argv[2]);
    exit(1);
  }

  fprintf(constantsH, "// SPDX-License-Identifier: GPL-3.0-only\n");
  fprintf(constantsH, "// SPDX-FileCopyrightText: Copyright The C47 Authors\n\n");

  fprintf(constantsH, "/*************************************************************************************************\n");
  fprintf(constantsH, " * Do not edit this file manually! It's automagically generated by the program generateConstants *\n");
  fprintf(constantsH, " *************************************************************************************************/\n\n");

  fprintf(constantsH, "/**\n");
  fprintf(constantsH, " * \\file constantPointers.h\n");
  fprintf(constantsH, " */\n");

  fprintf(constantsH, "#if !defined(CONSTANTPOINTERS_H)\n");
  fprintf(constantsH, "  #define CONSTANTPOINTERS_H\n\n");

  fprintf(constantsH, "%s\n", externalDeclarations);
  fprintf(constantsH, "  #define NUMBER_OF_REAL_T_CONSTANTS %" PRId32 "\n", cntRealt);

  fprintf(constantsH, "#endif // !CONSTANTPOINTERS_H\n");

  fclose(constantsH);



  constantsC = fopen(argv[1], "wb");
  if(constantsC == NULL) {
    fprintf(stderr, "Cannot create file %s\n", argv[1]);
    exit(1);
  }

  fprintf(constantsC, "// SPDX-License-Identifier: GPL-3.0-only\n");
  fprintf(constantsC, "// SPDX-FileCopyrightText: Copyright The C47 Authors\n\n");

  fprintf(constantsC, "/*************************************************************************************************\n");
  fprintf(constantsC, " * Do not edit this file manually! It's automagically generated by the program generateConstants *\n");
  fprintf(constantsC, " *************************************************************************************************/\n\n");

  fprintf(constantsC, "#include \"c47.h\"\n\n");

  fprintf(constantsC, "%s\n", realArray);

  fprintf(constantsC, "%s};\n", realTConstantArray);

  fclose(constantsC);

  return 0;
}
