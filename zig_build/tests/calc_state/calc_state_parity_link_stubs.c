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
static alignas(16) unsigned char allFormulae__stg[8192]; void *allFormulae = allFormulae__stg;
static alignas(16) unsigned char allNamedVariables__stg[8192];
static alignas(16) unsigned char beginOfCurrentProgram__stg[8192]; void *beginOfCurrentProgram = beginOfCurrentProgram__stg;
static alignas(16) unsigned char beginOfProgramMemory__stg[8192]; void *beginOfProgramMemory = beginOfProgramMemory__stg;
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
__attribute__((constructor)) static void z47_init_relocated_pointer_globals(void) {
    tmpString = tmpString__stg;
    errorMessage = errorMessage__stg;
    ram = ram__stg;
    statisticalSumsPointer = statisticalSumsPointer__stg;
    allNamedVariables = allNamedVariables__stg;
    currentSubroutineLevelData = currentSubroutineLevelData__stg;
    firstFreeProgramByte = firstFreeProgramByte__stg;
}

// --- storage globals (exact size + alignment) ---
alignas(1) unsigned char DM_Cycling[1];
alignas(1) unsigned char DRG_Cycling[1];
alignas(1) unsigned char Input_Default[1];
alignas(1) unsigned char LongPressF[1];
alignas(1) unsigned char LongPressM[1];
alignas(2) unsigned char Norm_Key_00[20];
alignas(1) unsigned char PLOT_AXIS[1];
alignas(1) unsigned char PLOT_DIFF[1];
alignas(1) unsigned char PLOT_INTG[1];
alignas(1) unsigned char PLOT_RMS[1];
alignas(1) unsigned char PLOT_SHADE[1];
alignas(1) unsigned char PLOT_ZMY[1];
alignas(2) unsigned char amortP1[2];
alignas(2) unsigned char amortP2[2];
alignas(1) unsigned char bcdDisplaySign[1];
alignas(1) unsigned char calcModel[1];
alignas(1) unsigned char cancelFilename[1];
alignas(2) unsigned char currentProgramNumber[2];
alignas(1) unsigned char dispBase[1];
alignas(1) unsigned char displayFormat[1];
alignas(1) unsigned char displayFormatDigits[1];
alignas(1) unsigned char displayStack[1];
alignas(1) unsigned char displayStackSHOIDISP[1];
alignas(2) unsigned char exponentHideLimit[2];
alignas(2) unsigned char exponentLimit[2];
alignas(1) unsigned char firstDayOfWeek[1];
alignas(1) unsigned char firstWeekOfYearDay[1];
alignas(1) unsigned char fractionDigits[1];
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
alignas(2) unsigned char lrChosen[2];
alignas(2) unsigned char lrSelection[2];
alignas(2) unsigned char numberOfUserMenus[2];
alignas(8) unsigned char pcg32_global[16];
alignas(4) unsigned char printerState[16];
alignas(1) unsigned char roundedTicks[1];
alignas(1) unsigned char shortIntegerMode[1];
alignas(1) unsigned char shortIntegerWordSize[1];
alignas(1) unsigned char timeDisplayFormatDigits[1];
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
void convertLongIntegerRegisterToLongInteger(int16_t a0, int64_t a1) {}
void convertLongIntegerToLongIntegerRegister(int64_t a0, int16_t a1) {}
void convertShortIntegerRegisterToUInt64(int16_t a0, void *a1, void *a2) {}
void convertUInt64ToShortIntegerRegister(int16_t a0, int64_t a1, int32_t a2, int16_t a3) {}
void createMenu(void *a0) {}
void * decNumberFromString(void *a0, void *a1, void *a2) { return 0; }
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
void * getRegisterDataPointer(int16_t a0) { return 0; }
int32_t getRegisterDataType(int16_t a0) { return 0; }
int32_t getRegisterTag(int16_t a0) { return 0; }
int8_t getSystemFlag(int32_t a0) { return 0; }
void initStatisticalSums(void) {}
void ioFileWrite(void *a0, int32_t a1) {}
void longIntegerToAllocatedString(int64_t a0, void *a1, int32_t a2) {}
void parseEquation(int16_t a0, int16_t a1, void *a2, void *a3) {}
void reLoadStatisticalSums(void) {}
void reallocateRegister(int16_t a0, int32_t a1, int16_t a2, int32_t a3) {}
void resetOtherConfigurationStuff(int8_t a0) {}
void resizeProgramMemory(int16_t a0) {}
void scanLabelsAndPrograms(void) {}
void setEquation(int16_t a0, void *a1) {}
void setLineDelay(int16_t a0) {}
void setLongPressFg(int32_t a0, int16_t a1) {}
void setSystemFlag(int32_t a0) {}
void setUserKeyArgument(int16_t a0, void *a1) {}
void stringToUtf8(void *a0, void *a1) {}
void utf8ToString(void *a0, void *a1) {}

// gmp stubs — the register codec references these but the header-only fixture
// never invokes it, so no-ops satisfy the link without a system gmp (which the
// Windows/macOS CI runners cannot resolve via linkSystemLibrary).
void __gmpz_init(void *x) { (void)x; }
int __gmpz_set_str(void *r, const char *s, int b) { (void)r; (void)s; (void)b; return 0; }
void __gmpz_clear(void *x) { (void)x; }

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
