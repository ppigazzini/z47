// SPDX-License-Identifier: GPL-3.0-only
// Auto-generated link stubs for the calc-state parity harness.
// The calc-state Zig owner references C symbols (register/matrix codec leaves,
// gmp, and many calc-state globals) that the minimal fake-surface parity build
// does not provide. The parity fixture is a header-only state file, so these
// code paths are linked but NOT exercised; the definitions exist only to make
// the link succeed and not crash. Pointer globals point at real backing storage
// (so reads through them don't fault); array/scalar globals get exact-size
// storage; functions are ABI-matched no-ops. gmp itself is linked (-lgmp).
#include <stdint.h>
#include <stdalign.h>

// --- pointer globals (point at backing storage) ---
static alignas(16) unsigned char aimBuffer__stg[8192]; void *aimBuffer = aimBuffer__stg;
static alignas(16) unsigned char allFormulae__stg[8192];
static alignas(16) unsigned char allNamedVariables__stg[8192];
static alignas(16) unsigned char beginOfCurrentProgram__stg[8192]; void *beginOfCurrentProgram = beginOfCurrentProgram__stg;
static alignas(16) unsigned char beginOfProgramMemory__stg[8192];
static alignas(16) unsigned char currentLocalFlags__stg[8192]; void *currentLocalFlags = currentLocalFlags__stg;
static alignas(16) unsigned char currentLocalRegisters__stg[8192]; void *currentLocalRegisters = currentLocalRegisters__stg;
static alignas(16) unsigned char currentStep__stg[8192]; void *currentStep = currentStep__stg;
static alignas(16) unsigned char currentSubroutineLevelData__stg[8192];
static alignas(16) unsigned char endOfCurrentProgram__stg[8192]; void *endOfCurrentProgram = endOfCurrentProgram__stg;
static alignas(16) unsigned char errorMessage__stg[8192];
static alignas(16) unsigned char firstDisplayedStep__stg[8192]; void *firstDisplayedStep = firstDisplayedStep__stg;
static alignas(16) unsigned char firstFreeProgramByte__stg[8192];
static alignas(16) unsigned char programList__stg[8192]; void *programList = programList__stg;
static alignas(16) unsigned char ram__stg[8192];
static alignas(16) unsigned char statisticalSumsPointer__stg[8192];
static alignas(16) unsigned char userKeyLabel__stg[8192]; void *userKeyLabel = userKeyLabel__stg;
static alignas(16) unsigned char userMenus__stg[8192]; void *userMenus = userMenus__stg;

// --- relocated pointer globals: the symbol now links from the core kernel
// (engine/kernel/scratch_buffers.zig, ...); keep the backing here and point the
// core-owned symbol at it before the header-only fixture dereferences it. ---
static alignas(16) unsigned char tmpString__stg[8192];
extern void *tmpString;
extern void *errorMessage;
extern void *ram;
extern void *statisticalSumsPointer;
extern void *allNamedVariables;
extern void *currentSubroutineLevelData;
extern void *firstFreeProgramByte;
extern void *beginOfProgramMemory;
extern void *allFormulae;
__attribute__((constructor)) static void z47_init_relocated_pointer_globals(void) {
    tmpString = tmpString__stg;
    errorMessage = errorMessage__stg;
    ram = ram__stg;
    statisticalSumsPointer = statisticalSumsPointer__stg;
    allNamedVariables = allNamedVariables__stg;
    currentSubroutineLevelData = currentSubroutineLevelData__stg;
    firstFreeProgramByte = firstFreeProgramByte__stg;
    beginOfProgramMemory = beginOfProgramMemory__stg;
    allFormulae = allFormulae__stg;
}

// --- storage globals (exact size + alignment) ---
alignas(1) unsigned char LongPressF[1];
alignas(2) unsigned char Norm_Key_00[20];
alignas(1) unsigned char PLOT_AXIS[1];
alignas(1) unsigned char PLOT_ZMY[1];
alignas(1) unsigned char calcModel[1];
alignas(1) unsigned char cancelFilename[1];
alignas(1) unsigned char displayStack[1];
alignas(1) unsigned char displayStackSHOIDISP[1];
alignas(2) unsigned char exponentHideLimit[2];
alignas(2) unsigned char exponentLimit[2];
alignas(2) unsigned char freeProgramBytes[2];
alignas(2) unsigned char gapItemLeft[2];
alignas(2) unsigned char gapItemRadix[2];
alignas(2) unsigned char gapItemRight[2];
alignas(2) unsigned char globalFlags[16];
alignas(4) unsigned char graph_dx[4];
alignas(4) unsigned char graph_dy[4];
alignas(1) unsigned char grpGroupingGr1Left[1];
alignas(1) unsigned char grpGroupingGr1LeftOverflow[1];
alignas(1) unsigned char grpGroupingLeft[1];
alignas(1) unsigned char grpGroupingRight[1];
alignas(1) unsigned char hourGlassIconEnabled[1];
alignas(2) unsigned char kbd_std_C47[666];
alignas(2) unsigned char kbd_std_DM42[666];
alignas(2) unsigned char kbd_std_R47bk_fg[666];
alignas(2) unsigned char kbd_std_R47f_g[666];
alignas(2) unsigned char kbd_std_R47fg_bk[666];
alignas(2) unsigned char kbd_std_R47fg_g[666];
alignas(2) unsigned char kbd_usr[666];
alignas(2) unsigned char numberOfUserMenus[2];
alignas(8) unsigned char pcg32_global[16];
alignas(4) unsigned char printerState[16];
alignas(1) unsigned char roundedTicks[1];
alignas(1) unsigned char updateOldConstants[1];
alignas(2) unsigned char userAlphaItems[360];
alignas(2) unsigned char userKeyLabelSize[2];
alignas(2) unsigned char userMenuItems[360];

// --- functions (ABI-matched no-ops; unexercised by the header-only fixture) ---
void * allocC47Blocks(int64_t a0) { return 0; }
void allocateLocalRegisters(int16_t a0) {}
int8_t checkOpCodeOfStep(void *a0, int16_t a1) { return 0; }
void clearSystemFlag(int32_t a0) {}
int32_t compareString(void *a0, void *a1, int32_t a2) { return 0; }
void configCommon(int16_t a0) {}
void createMenu(void *a0) {}
void * decNumberFromString(void *a0, void *a1, void *a2) { return 0; }
void * decimal128FromNumber(void *a0, void *a1, void *a2) { return a0; }
void * decNumberToIntegralValue(void *a0, void *a1, void *a2) { return a0; }
void * decimal128ToNumber(void *a0, void *a1) { return a1; }
unsigned int decQuadIsZero(void *a0) { (void)a0; return 1; }
void * decNumberFromUInt32(void *a0, unsigned int a1) { (void)a1; return a0; }
void * decNumberFMA(void *a0, void *a1, void *a2, void *a3, void *a4) { return a0; }
void roundToSignificantDigits(void *a0, void *a1, int16_t a2, void *a3) {}
void * decNumberToString(void *a0, void *a1) { return 0; }
void * decQuadFromString(void *a0, void *a1, void *a2) { return 0; }
void * decQuadToString(void *a0, void *a1) { return 0; }
void defaultStatusBar(void) {}
void deleteEquation(int16_t a0) {}
void displayBugScreen(void *a0) {}
int16_t findOrAllocateNamedVariable(void *a0) { return 0; }
void forceSystemFlag(int32_t a0, int32_t a1) {}
void freeC47Blocks(void *a0, int64_t a1) {}
void * getNthString(void *a0, int16_t a1) { return 0; }
// assign.c's NULL-tolerant userKeyLabel reader, taken by doSave since the 6559a9c59 pin.
void * getUserKeyLabelString(int16_t a0) { return 0; }
int8_t getRegisterAsRawShortInt(int16_t a0, uint64_t *a1, uint32_t *a2) { return 0; }
void * getRegisterDataPointer(int16_t a0) { return 0; }
int32_t getRegisterDataType(int16_t a0) { return 0; }
int32_t getRegisterTag(int16_t a0) { return 0; }
int8_t getSystemFlag(int32_t a0) { return 0; }
void initStatisticalSums(void) {}
void ioFileWrite(void *a0, int32_t a1) {}
void parseEquation(int16_t a0, int16_t a1, void *a2, void *a3) {}
void reLoadStatisticalSums(void) {}
void reallocateRegister(int16_t a0, int32_t a1, int16_t a2, int32_t a3) {}
void resetOtherConfigurationStuff(int8_t a0) {}
void resizeProgramMemory(int16_t a0) {}
void scanLabelsAndPrograms(void) {}
uint8_t boundShortIntegerWordSize(uint8_t a0) { return a0; }
void setRegisterDataType(int16_t a0, int32_t a1, int32_t a2) {}
void setEquation(int16_t a0, void *a1) {}
void setLineDelay(int16_t a0) {}
void setLongPressFg(int32_t a0, int16_t a1) {}
void setSystemFlag(int32_t a0) {}
void setUserKeyArgument(int16_t a0, void *a1) {}
void stringToUtf8(void *a0, void *a1) {}
void utf8ToString(void *a0, void *a1) {}
void utf8ToStringWithLength(void *a0, void *a1, uintptr_t a2) {}
_Bool programMemoryHasOverlongLabelName(void *a0) { (void)a0; return 0; }
void fnClPAll(uint16_t a0) { (void)a0; }

// gmp stubs — the register codec references these but the header-only fixture
// never invokes it, so no-ops satisfy the link without a system gmp (which the
// Windows/macOS CI runners cannot resolve via linkSystemLibrary).
void __gmpz_init(void *x) { (void)x; }
int __gmpz_set_str(void *r, const char *s, int b) { (void)r; (void)s; (void)b; return 0; }
void __gmpz_clear(void *x) { (void)x; }
unsigned short getRegisterMaxDataLengthInBlocks(short a0) { (void)a0; return 0; }
unsigned char constants[65536];
unsigned long __gmpz_sizeinbase(const void *op, int base) { (void)op; (void)base; return 1; }
void __gmpz_init2(void *op, unsigned long n) { (void)op; (void)n; }
void __gmpz_add_ui(void *rop, const void *op1, unsigned long op2) { (void)rop; (void)op1; (void)op2; }
unsigned long __gmpz_tdiv_ui(const void *n, unsigned long d) { (void)n; (void)d; return 0; }
unsigned long __gmpz_tdiv_q_ui(void *q, const void *n, unsigned long d) { (void)q; (void)n; (void)d; return 0; }

// --- XFN register data-file save/load family (M10.4) externs ---
// Referenced by the calc-state save/codec/io-flow owners but never invoked by
// the header-only parity fixture; ABI-matched no-ops to satisfy the link.
int8_t registerFMAOutputPlainString(int16_t a0, void *a1, void *a2) { (void)a0; (void)a1; (void)a2; return 0; }
int8_t getAngleModeForRegister3r(int16_t a0, void *a1) { (void)a0; (void)a1; return 0; }
void copySourceRegisterToDestRegister(int16_t a0, int16_t a1) { (void)a0; (void)a1; }
void fnFrom_msRegister(int16_t a0) { (void)a0; }
void convertDateRegisterToReal34Register(int16_t a0, int16_t a1) { (void)a0; (void)a1; }
void convertReal34RegisterToDateRegister(int16_t a0, int16_t a1, int8_t a2) { (void)a0; (void)a1; (void)a2; }
void hmmssInRegisterToSeconds(int16_t a0) { (void)a0; }
int ioFileOpen(int a0, int a1) { (void)a0; (void)a1; return 0; }
void ioFileClose(void) {}
void liftStack(void) {}
void show_warning(void *a0) { (void)a0; }
void refreshScreen(uint16_t a0) { (void)a0; }
/* displayCalcErrorMessage now links from engine/kernel/error_report.zig. */
void showHideHourGlass(void) {}
int16_t findNamedVariable(void *a0) { (void)a0; return 0; }
/* --- bulk register-conversion leaves (linked but not exercised in calc_state) --- */
void * decQuadFromUInt32(void *r, unsigned int v) { (void)v; return r; }
int decQuadGetCoefficient(const void *r, unsigned char *bcd) { (void)r; (void)bcd; return 0; }
int decQuadGetExponent(const void *r) { (void)r; return 0; }
void * decQuadZero(void *r) { return r; }
void * decQuadDivide(void *r, const void *a, const void *b, void *ctx) { (void)a;(void)b;(void)ctx; return r; }
void * decQuadMultiply(void *r, const void *a, const void *b, void *ctx) { (void)a;(void)b;(void)ctx; return r; }
void * decQuadFMA(void *r, const void *a, const void *b, const void *c, void *ctx) { (void)a;(void)b;(void)c;(void)ctx; return r; }
void * decQuadToIntegralValue(void *r, const void *a, void *ctx, int round) { (void)a;(void)ctx;(void)round; return r; }
unsigned long decNumberToUInt64(const void *r, void *ctx) { (void)r;(void)ctx; return 0; }
void * decNumberGetBCD(const void *r, unsigned char *bcd) { (void)r; return bcd; }
void * decNumberPlus(void *r, const void *a, void *ctx) { (void)a;(void)ctx; return r; }
void * decNumberQuantize(void *r, const void *a, const void *b, void *ctx) { (void)a;(void)b;(void)ctx; return r; }
void __gmpz_set_ui(void *r, unsigned long v) { (void)r;(void)v; }
void __gmpz_mul_ui(void *r, const void *a, unsigned long v) { (void)r;(void)a;(void)v; }
void __gmpz_mul_2exp(void *r, const void *a, unsigned long v) { (void)r;(void)a;(void)v; }
unsigned long __gmpz_fdiv_ui(const void *n, unsigned long d) { (void)n;(void)d; return 0; }
char * __gmpz_get_str(char *str, int base, const void *op) { (void)base;(void)op; return str; }
void setRegisterTag(short r, unsigned int tag) { (void)r;(void)tag; }
void adjustResult(short a, signed char b, signed char c, short d, short e, short f) { (void)a;(void)b;(void)c;(void)d;(void)e;(void)f; }
signed char saveLastX(void) { return 0; }
void WP34S_Mod(const void *x, const void *y, void *res, void *ctx) { (void)x;(void)y;(void)res;(void)ctx; }
signed char realIsAnInteger(const void *x) { (void)x; return 0; }
signed char realCompareGreaterEqual(const void *a, const void *b) { (void)a;(void)b; return 0; }
signed char realCompareGreaterThan(const void *a, const void *b) { (void)a;(void)b; return 0; }
signed char realMatrixInit(void *m, unsigned short r, unsigned short c) { (void)m;(void)r;(void)c; return 0; }
signed char complexMatrixInit(void *m, unsigned short r, unsigned short c) { (void)m;(void)r;(void)c; return 0; }
void complexMatrixFree(void *m) { (void)m; }
void linkToRealMatrixRegister(short r, void *linked) { (void)r;(void)linked; }
void moreInfoOnError(const char *m1, const char *m2, const char *m3, const char *m4) { (void)m1;(void)m2;(void)m3;(void)m4; }
void elementwiseRema(void *f) { (void)f; }
void elementwiseCxma(void *f) { (void)f; }
void elementwiseRemaRema(void *f) { (void)f; }
void elementwiseCxmaRema(void *f) { (void)f; }
void elementwiseCplxRema(void *f) { (void)f; }
void elementwiseRealRema(void *f) { (void)f; }
void elementwiseRemaCxma(void *f) { (void)f; }
void elementwiseCxmaCxma(void *f) { (void)f; }
void elementwiseCplxCxma(void *f) { (void)f; }
void elementwiseRemaReal(void *f) { (void)f; }
void elementwiseRemaCplx(void *f) { (void)f; }
void elementwiseCxmaCplx(void *f) { (void)f; }
short lastFunc;
