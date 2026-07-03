// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/softmenus.c: the master softmenu table (softmenu[],
// 181 entries), the mutable dynamicSoftmenu[] (22 entries), the ~150 per-menu
// int16 softkey arrays (menu_X[]), and the softmenu rendering / stack / dynamic
// menu machinery (showSoftmenuCurrentPart, showKey, changeSoftKey, pushSoftmenu,
// popSoftmenu, showSoftmenu, fnOpenMenu, findMenu, initVariableSoftmenu, ...).
//
// THE softmenu[] TABLE holds pointers (softkeyItem -> menu_X[]); it is therefore
// emitted into code_data_section (__DATA_CONST on macOS) so dyld can rebase it
// without faulting in read-only __TEXT. The pure-integer menu_X[] arrays go in
// code_section. dynamicSoftmenu[] is mutable (the renderer fills .menuContent /
// .numItems at runtime) so it is a `pub export var`.
//
// PER-TARGET TABLE GATES: softmenus.c gates several menu_X[] entries on compile
// macros. They map to frontier build options (verified by a host+DMCP probe of
// every table variant):
//   CALCMODEL == USER_R47   <=> dmcp_build   (menu_HOME/EE/ASN_N/KEYS/XXFCNS/VECT)
//   OPTION_VECTOR           <=> option_vector (menu_MATX/VECT, menu_HOME tail)
//   OPTION_ELEC             <=> option_elec   (menu_HOME tail)
//   OPTION_XFN_1000         <=> !(dmcp_build and old_hw)  (menu_XFN)
//   OPTION_TVM_AMORT        <=> !(dmcp_build and old_hw)  (menu_AMORT)
//   PC_BUILD                <=> !dmcp_build   (menu_PRINT, PAT)
//   SAVE_SPACE_DM42_15      <=> strip_15      (menu_PROB, DDMENU; DMCP pkg 4)
//   SAVE_SPACE_DM42_21_HP35 <=> strip_21_hp35 (menu_Dev; DMCP pkg 1)
// INLINE_TEST is #undef'd unconditionally upstream, so its table/render branches
// take the !INLINE_TEST path.
//
// RENAMED-AWAY: fnDynamicMenu is owned elsewhere (the retired shim renamed it to
// z47_frontier_legacy_fnDynamicMenu); here it is an extern. The two helpers the
// shim provided (z47_frontier_dynamic_menu_softmenu_id / _item) are reproduced
// as pub export fn reading softmenuStack[0].softmenuId and dynamicMenuItem.
//
// DMCP ROM trampolines (lcd_fill_rect, bitblt24 behind setBlackPixel/setWhitePixel)
// are fixed-address jump-table calls on firmware (LIBRARY_FN_BASE + offset from
// lft_ifc.h) and real host symbols otherwise. Mirrors the status-bar owner.
//
// Dead code skipped: VERBOSE_LEVEL == -1 diag blocks, PC_BUILD printf/jm_show_*
// telltale (host-only, kept under !dmcp_build where they have observable effect
// like fnDumpMenus/fnMenuDump), /* */-commented bodies. EXTRA_INFO_ON_CALC_ERROR
// hints use the extra_info build option.

const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const ir_printing: bool = frontier_build_options.ir_printing;
const option_vector: bool = frontier_build_options.option_vector;
const option_elec: bool = frontier_build_options.option_elec;
const strip_15: bool = frontier_build_options.strip_15;
const strip_21_hp35: bool = frontier_build_options.strip_21_hp35;
const strip_16: bool = frontier_build_options.strip_16;
const strip_17: bool = frontier_build_options.strip_17;
const strip_17b: bool = frontier_build_options.strip_17b;
const strip_17c: bool = frontier_build_options.strip_17c;
const strip_ortho_bessel_ellip: bool = frontier_build_options.strip_ortho_bessel_ellip;
// OPTION_XFN_1000 / OPTION_TVM_AMORT are #undef'd for the flash-limited DMCP
// TWO_FILE packages (dmcp_build and old_hw); host and DMCP5 keep them.
const option_xfn_1000: bool = !(dmcp_build and old_hw);
const option_tvm_amort: bool = !(dmcp_build and old_hw);

const code_section = if (dmcp_build and old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

const code_data_section = if (dmcp_build and old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__DATA_CONST,__const"
else
    ".rodata";

const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;

// ---------------------------------------------------------------------------
// Types (matching the C build's extern struct layouts).
// ---------------------------------------------------------------------------
const bool_t = u8;
const calcRegister_t = i16;
const dataType_t = u32;
const videoMode_t = c_int;
const font_t = opaque {};

const softmenu_t = abi.Softmenu;
const dynamicSoftmenu_t = extern struct {
    menuItem: i16,
    numItems: i16,
    menuContent: [*c]u8,
};
const softmenuStack_t = extern struct {
    softmenuId: i16,
    firstItem: i16,
    userMenuId: i16,
    calcMode: u8,
};

const item_t = abi.Item;

const userMenuItem_t = extern struct {
    item: i16,
    unused: i16, // padding (present in the C struct)
    argumentName: [16]u8,
};
const userMenu_t = extern struct {
    menuName: [16]u8,
    menuItem: [18]userMenuItem_t,
};

// labelList entries: only fields softmenus.c reads (step, instructionPointer,
// labelPointer). Layout mirrors src/c47 label.h labelList_t.
const labelList_t = extern struct {
    program: i16,
    step: i32,
    labelPointer: [*c]u8,
    instructionPointer: [*c]u8,
};

// registerHeader_t: 32-bit union; notUsed is bits 26..31 (after
// pointerToRegisterData:16, dataType:4, tag:5, readOnly:1).
const registerHeader_t = extern struct {
    bits: u32,
    inline fn notUsed(self: *align(1) const registerHeader_t) bool {
        return ((self.bits >> 26) & 0x3F) != 0;
    }
};

// real_t for placeSubscript / changeSoftKey local math.
const DECNUMUNITS = 25;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const real34_t = abi.Real34;

// ---------------------------------------------------------------------------
// Numeric constants (probe-resolved from c47.h; identical sim/dmcp).
// ---------------------------------------------------------------------------
const NUMBER_OF_DYNAMIC_SOFTMENUS: i16 = 22;
const SOFTMENU_STACK_SIZE: usize = 8;
const SOFTMENU_HEIGHT: i16 = 23;
const SCREEN_WIDTH: i16 = 400;
const SCREEN_HEIGHT: i16 = 240;
const TMP_STR_LENGTH: usize = 2560;
const AIM_BUFFER_LENGTH: usize = 1024;
const ON_PIXEL: i32 = 0x303030;
const LCD_SET_VALUE: c_int = 0;
const LCD_EMPTY_VALUE: c_int = 255;


// Probe-resolved enum/macro constants from c47.h (identical across sim/dmcp).
const AC_LOWER = 1;
const AC_UPPER = 0;
const AIM_REGISTER_LINE = 100;
const CATALOG_AINT = 5;
const CATALOG_NONE = 0;
const CAT_CNST = 48;
const CAT_MENU = 32;
const CAT_MNUH = 176;
const CAT_STATUS = 240;
const CB_FALSE = 2;
const CB_TRUE = 3;
const CMP_BINARY = 0;
const CMP_CLEANED_STRING_ONLY = 1;
const CMP_EXTENSIVE = 2;
const CMP_NAME = 3;
const CM_AIM = 1;
const CM_ASN_BROWSER = 17;
const CM_ASSIGN = 4;
const CM_BUG_ON_SCREEN = 10;
const CM_EIM = 13;
const CM_FLAG_BROWSER = 6;
const CM_FONT_BROWSER = 7;
const CM_NIM = 2;
const CM_NORMAL = 0;
const CM_PEM = 3;
const CM_PLOT_STAT = 8;
const CM_GRAPH = 15;
const CM_REGISTER_BROWSER = 5;
const DF_UN = 5;
const EQUATION_AIM_BUFFER = 65535;
const EQUATION_NO_CURSOR = 65535;
const EQUATION_PARSER_MVAR = 0;
const ERROR_EQUATION_TOO_COMPLEX = 46;
const ERROR_NONE = 0;
const ERROR_OUT_OF_RANGE = 8;
const ERROR_RAM_FULL = 11;
const ERROR_UNDEF_MENU = 59;
const ERROR_VARIABLE_NOT_SELECTED = 57;
const ERR_REGISTER_LINE = 102;
const FIRST_LABEL = 2200;
const FIRST_NAMED_RESERVED_VARIABLE = 2026;
const FIRST_NAMED_VARIABLE = 256;
const FIRST_RESERVED_VARIABLE = 2000;
const FLAG_2TO10 = 32829;
const FLAG_ALPHA = 32782;
const FLAG_ASLIFT = 49187;
const FLAG_BASE_HOME = 32862;
const FLAG_BASE_MYM = 32860;
const FLAG_G_DOUBLETAP = 32861;
const FLAG_HPCONV = 32834;
const FLAG_IGN1ER = 32804;
const FLAG_US = 32853;
const FLAG_VMDISP = 49191;
const INVALID_MENU = 2791;
const INVALID_VARIABLE = 2199;
const ITM_10X_XFN = 2570;
const ITM_1ONX_XFN = 2562;
const ITM_AMORT_P1 = 2716;
const ITM_AMORT_P2 = 2717;
const ITM_ASSIGN = 1411;
const ITM_BINOM = 1209;
const ITM_BINOMM1 = 1211;
const ITM_BINOMP = 1208;
const ITM_BINOMU = 1210;
const ITM_CAUCH = 1214;
const ITM_CAUCHM1 = 1216;
const ITM_CAUCHP = 1213;
const ITM_CAUCHU = 1215;
const ITM_CFG = 1941;
const ITM_CHS_XFN = 2580;
const ITM_CROSS = 855;
const ITM_DELITM = 1455;
const ITM_DENMAX2 = 2551;
const ITM_DISUNIFORMI = 2609;
const ITM_DISUNIFORML = 2607;
const ITM_DISUNIFORMP = 2606;
const ITM_DISUNIFORMU = 2608;
const ITM_DOT = 849;
const ITM_DRAW = 2372;
const ITM_DRAW_LU = 2373;
const ITM_DREAL = 1899;
const ITM_DSP = 1573;
const ITM_DSPCYCLE = 1864;
const ITM_EE_A2S = 1814;
const ITM_EE_D2Y = 1812;
const ITM_EE_EXP_TH = 1816;
const ITM_EE_RCL_I = 1822;
const ITM_EE_RCL_V = 1820;
const ITM_EE_RCL_Z = 1818;
const ITM_EE_S2A = 1815;
const ITM_EE_STO_I = 1821;
const ITM_EE_STO_IR = 1824;
const ITM_EE_STO_V = 1819;
const ITM_EE_STO_V_I = 1823;
const ITM_EE_STO_V_Z = 1825;
const ITM_EE_STO_Z = 1817;
const ITM_EE_X2BAL = 1826;
const ITM_EE_Y2D = 1813;
const ITM_ELLIPSE = 2395;
const ITM_ENTER = 35;
const ITM_EQ_NEW = 1465;
const ITM_EULPHI = 2386;
const ITM_EXPON = 1219;
const ITM_EXPONM1 = 1221;
const ITM_EXPONP = 1218;
const ITM_EXPONU = 1220;
const ITM_EXP_XFN = 2569;
const ITM_FACTORS = 1477;
const ITM_FM1P = 1226;
const ITM_FPX = 1223;
const ITM_FUX = 1225;
const ITM_FX = 1224;
const ITM_GAP_L = 2159;
const ITM_GAP_R = 2161;
const ITM_GAP_RX = 2160;
const ITM_GEOM = 1229;
const ITM_GEOMM1 = 1231;
const ITM_GEOMP = 1228;
const ITM_GEOMU = 1230;
const ITM_GEV = 1283;
const ITM_GEVM1 = 1285;
const ITM_GEVP = 1282;
const ITM_GEVU = 1284;
const ITM_GRP1_L = 2157;
const ITM_GRP1_L_OF = 2156;
const ITM_GRP_L = 2155;
const ITM_GRP_R = 2158;
const ITM_HN = 1483;
const ITM_HNP = 1484;
const ITM_HPLOT = 1792;
const ITM_HYPER = 1234;
const ITM_HYPERM1 = 1236;
const ITM_HYPERP = 1233;
const ITM_HYPERU = 1235;
const ITM_IMINUS = 1491;
const ITM_IPLUS = 1490;
const ITM_JMINUS = 1494;
const ITM_JPLUS = 1493;
const ITM_JYX = 1492;
const ITM_LGNRM = 1239;
const ITM_LGNRMM1 = 1241;
const ITM_LGNRMP = 1238;
const ITM_LGNRMU = 1240;
const ITM_LN_XFN = 2567;
const ITM_LOGIS = 1244;
const ITM_LOGISM1 = 1246;
const ITM_LOGISP = 1243;
const ITM_LOGISU = 1245;
const ITM_LOG_XFN = 2568;
const ITM_MENU = 1520;
const ITM_MODANG_XFN = 2578;
const ITM_MOD_XFN = 2577;
const ITM_MVAR = 1524;
const ITM_REM = 1554;
const ITM_MZOOMY = 2034;
const ITM_M_EDI = 1529;
const ITM_M_EDIN = 1530;
const ITM_NBIN = 1249;
const ITM_NBINM1 = 1251;
const ITM_NBINP = 1248;
const ITM_NBINU = 1250;
const ITM_NEXTP = 107;
const ITM_NOP = 1542;
const ITM_NORML = 1254;
const ITM_NORMLM1 = 1256;
const ITM_NORMLP = 1253;
const ITM_NORMLU = 1255;
const ITM_NULL = 0;
const ITM_PARETO2L = 1292;
const ITM_PARETO2M1 = 1294;
const ITM_PARETO2P = 1291;
const ITM_PARETO2U = 1293;
const ITM_PARETOL = 1288;
const ITM_PARETOM1 = 1290;
const ITM_PARETOP = 1287;
const ITM_PARETOU = 1289;
const ITM_PFACTORSMULT = 2385;
const ITM_PLOT_ASSESS = 1759;
const ITM_PLOT_CENTRL = 1756;
const ITM_PLOT_SCATR = 1549;
const ITM_PLOT_STAT = 2040;
const ITM_POISS = 1259;
const ITM_POISSM1 = 1261;
const ITM_POISSP = 1258;
const ITM_POISSU = 1260;
const ITM_POWER_XFN = 2571;
const ITM_PRIME = 33;
const ITM_PRINTERHP = 2683;
const ITM_PRINTERMARTEL = 2684;
const ITM_PRINTEROTHER = 2685;
const ITM_PZOOMY = 2035;
const ITM_RCLCFG = 1561;
const ITM_RDP_XFN = 2556;
const ITM_RSD_XFN = 2557;
const ITM_SCR = 2191;
const ITM_SETSIG2 = 2197;
const ITM_SIGMA0 = 2409;
const ITM_SIGMA1 = 2410;
const ITM_SIM_EQ = 1602;
const ITM_SQRT_XFN = 2572;
const ITM_SQR_XFN = 2583;
const ITM_STDNORML = 1279;
const ITM_STDNORMLM1 = 1281;
const ITM_STDNORMLP = 1278;
const ITM_STDNORMLU = 1280;
const ITM_STO = 44;
const ITM_STOCFG = 1611;
const ITM_STOP = 70;
const ITM_STORCL_FV = 2643;
const ITM_STORCL_NPPER = 2640;
const ITM_STORCL_PMT = 2644;
const ITM_STORCL_PV = 2642;
const ITM_TIMER = 1622;
const ITM_TIMER_RESET = 1778;
const ITM_TIMER_R_L = 1785;
const ITM_TIMER_R_S = 1786;
const ITM_TIMER_R_T = 1784;
const ITM_TIMER_SIGMA_L = 1783;
const ITM_TIMER_SIGMA_T = 1782;
const ITM_TM1P = 1266;
const ITM_TO_XFN = 2579;
const ITM_TPX = 1263;
const ITM_TUX = 1265;
const ITM_TX = 1264;
const ITM_UNIFORMI = 2604;
const ITM_UNIFORML = 2602;
const ITM_UNIFORMP = 2601;
const ITM_UNIFORMU = 2603;
const ITM_UNIT = 1867;
const ITM_V001 = 2481;
const ITM_V01 = 2491;
const ITM_V010 = 2480;
const ITM_V10 = 2490;
const ITM_V100 = 2479;
const ITM_WEIBL = 1269;
const ITM_WEIBLM1 = 1271;
const ITM_WEIBLP = 1268;
const ITM_WEIBLU = 1270;
const ITM_XTHROOT_XFN = 2584;
const ITM_YYX = 1665;
const ITM_YY_DFLT = 2550;
const LAST_ITEM = 2860;
const MB_FALSE = 4;
const MB_TRUE = 5;
const MNU_1STDERIV = 1335;
const MNU_2NDDERIV = 1336;
const MNU_ADV = 1313;
const MNU_ALLVARS = 2232;
const MNU_ALPHA = 1922;
const MNU_ALPHAINTL = 1374;
const MNU_ALPHAMATH = 1375;
const MNU_ALPHAMISC = 1378;
const MNU_ALPHA_OMEGA = 1377;
const MNU_AMORT = 2382;
const MNU_ANGLES = 1314;
const MNU_ASN_N = 1920;
const MNU_BINOM = 1207;
const MNU_CATALOG = 1318;
const MNU_CAUCH = 1212;
const MNU_CHARS = 1319;
const MNU_CHI2 = 1272;
const MNU_CONFIGS = 2231;
const MNU_CONST = 1322;
const MNU_CONVA = 1316;
const MNU_CONVANG = 2046;
const MNU_CONVCHEF = 1901;
const MNU_CONVE = 1329;
const MNU_CONVFP = 1337;
const MNU_CONVHUM = 1359;
const MNU_CONVM = 1351;
const MNU_CONVP = 1358;
const MNU_CONVS = 2045;
const MNU_CONVTEMP = 2047;
const MNU_CONVV = 1371;
const MNU_CONVX = 1373;
const MNU_CONVYMMV = 2222;
const MNU_CPXS = 1324;
const MNU_DATES = 1325;
const MNU_DISP = 1326;
const MNU_DISTR = 1237;
const MNU_DISUNIFORM = 2605;
const MNU_DYNAMIC = 1394;
const MNU_EIMCATALOG = 2227;
const MNU_ELLIPT = 1397;
const MNU_EQN = 1327;
const MNU_EQ_EDIT = 1399;
const MNU_EXPON = 1217;
const MNU_F = 1222;
const MNU_FCNS = 1330;
const MNU_FCNS_EIM = 2228;
const MNU_GEOM = 1227;
const MNU_GEV = 1247;
const MNU_GRAPHS = 2374;
const MNU_HOME = 1921;
const MNU_HYPER = 1232;
const MNU_INL_TST = 1883;
const MNU_IO = 1341;
const MNU_LINTS = 1338;
const MNU_LOGIS = 1242;
const MNU_MATRS = 1343;
const MNU_MENU = 2407;
const MNU_MENUS = 1345;
const MNU_MISC = 1860;
const MNU_MODE = 1346;
const MNU_MVAR = 1398;
const MNU_NORML = 1252;
const MNU_NUMBRS = 2230;
const MNU_ORTHOG = 1352;
const MNU_PARETO = 1286;
const MNU_PFN = 1403;
const MNU_PLOT_FUNC = 2028;
const MNU_POISS = 1257;
const MNU_PREF = 2037;
const MNU_PRINTER = 2681;
const MNU_PROG = 1392;
const MNU_PROGS = 1355;
const MNU_REALS = 1360;
const MNU_SHOW = 2315;
const MNU_SINTS = 1332;
const MNU_STDNORML = 1277;
const MNU_STRINGS = 1364;
const MNU_SYSFL = 1379;
const MNU_T = 1262;
const MNU_TAMFLAG = 1390;
const MNU_TIMERF = 1400;
const MNU_TIMES = 1366;
const MNU_UNIFORM = 2600;
const MNU_UNITCONV = 1369;
const MNU_VAR = 1389;
const MNU_WEIBL = 1267;
const MNU_XXFCNS = 2596;
const NC_NORMAL = 0;
const NC_SUBSCRIPT = 1;
const NC_SUPERSCRIPT = 2;
const NIM_REGISTER_LINE = 100;
const NOPARAM = 9876;
const NOVAL = -126;
const NUMBER_OF_RESERVED_VARIABLES = 48;
const PRINTER_HP = 0;
const PRINTER_MARTEL = 1;
const PRINTER_OTHER = 2;
const RB_FALSE = 0;
const RB_TRUE = 1;
const REGISTER_I = 109;
const REGISTER_J = 110;
const REGISTER_X = 100;
const SCRUPD_AUTO = 0;
const SCRUPD_MANUAL_MENU = 4;
const SCRUPD_SKIP_MENU_ONE_TIME = 64;
const SCRUPD_SKIP_STATUSBAR_ONE_TIME = 16;
const SFL_DREAL = 2261;
const SOLVER_STATUS_EQUATION_1ST_DERIVATIVE = 8;
const SOLVER_STATUS_EQUATION_2ND_DERIVATIVE = 12;
const SOLVER_STATUS_EQUATION_GRAPHER = 8192;
const SOLVER_STATUS_EQUATION_INTEGRATE = 4;
const SOLVER_STATUS_EQUATION_MODE = 8204;
const SOLVER_STATUS_EQUATION_SOLVER = 0;
const SOLVER_STATUS_INTERACTIVE = 2;
const SOLVER_STATUS_USES_FORMULA = 256;
const STRING_LABEL_VARIABLE = 253;
const TM_KEY = 10012;
const VAR_ACC = 1192;
const VAR_FV = 1195;
const VAR_LEST = 2546;
const VAR_LLIM = 1194;
const VAR_LX = 1206;
const VAR_LY = 2548;
const VAR_NPPER = 1197;
const VAR_PMT = 1199;
const VAR_PV = 1200;
const VAR_UEST = 2545;
const VAR_ULIM = 1193;
const VAR_UX = 1205;
const VAR_UY = 2547;
const YY_MASK_OFF = 32768;
const YY_MASK_TRACKING = 16384;
const amNone = 5;
const dtComplex34 = 2;
const dtComplex34Matrix = 7;
const dtConfig = 9;
const dtDate = 4;
const dtLongInteger = 0;
const dtNumbers = 15;
const dtReal34 = 1;
const dtReal34Matrix = 6;
const dtShortInteger = 8;
const dtString = 5;
const dtTime = 3;
const stdNoEnlarge = 0;
const vmNormal = 0;
const vmReverse = 1;

// String-literal macros (byte-faithful).
const NOTEXT: [*:0]const u8 = "";

// Supplemental constants (lowercase-bearing names + a few items/STD bytes).
const ITM_RESERVE2 = 1947;
const ITM_op_a = 1828;
const ITM_op_a2 = 1829;
const ITM_op_j = 1830;
const ITM_op_j_SIGN = 2165;
const ITM_op_j_pol = 1795;
const MNU_ALPHAintl = 1384;
const MNU_Grapher = 1388;
const MNU_MyAlpha = 1350;
const MNU_Sf = 1380;
const MNU_Sf_TOOL = 2375;
const MNU_Sfdx = 1381;
const MNU_Solver = 1361;
const MNU_Solver_TOOL = 2376;
const MNU_alpha_omega = 1383;

// STD_* glyph byte strings (fonts.h), byte-faithful (probe-resolved).
const STD_0: [*:0]const u8 = "\x30";
const STD_9: [*:0]const u8 = "\x39";
const STD_BOX: [*:0]const u8 = "\xa5\xa2";
const STD_CR: [*:0]const u8 = "\xa1\xb5";
const STD_GAUSS_WHITE_L: [*:0]const u8 = "\xa4\x32";
const STD_GAUSS_WHITE_R: [*:0]const u8 = "\xa4\x31";
const STD_LEFT_ARROW: [*:0]const u8 = "\xa1\x90";
const STD_RIGHT_ARROW: [*:0]const u8 = "\xa1\x92";
const STD_SIGMA: [*:0]const u8 = "\x83\xa3";
const STD_SPACE_3_PER_EM: [*:0]const u8 = "\xa0\x04";
const STD_SPACE_4_PER_EM: [*:0]const u8 = "\xa0\x05";
const STD_SPACE_6_PER_EM: [*:0]const u8 = "\xa0\x06";
const STD_SUB_0: [*:0]const u8 = "\xa0\x80";
const STD_SUB_B: [*:0]const u8 = "\xa4\xd1";
const STD_SUB_S: [*:0]const u8 = "\xa4\xe2";
const STD_SUB_U: [*:0]const u8 = "\xa4\xe4";
const STD_SUB_X: [*:0]const u8 = "\xa4\xe7";
const STD_SUB_a: [*:0]const u8 = "\xa4\x9c";
const STD_SUB_b: [*:0]const u8 = "\xa4\x9d";
const STD_SUB_f: [*:0]const u8 = "\xa4\xa1";
const STD_SUB_i: [*:0]const u8 = "\xa4\xa4";
const STD_SUB_m: [*:0]const u8 = "\xa4\xa8";
const STD_SUB_o: [*:0]const u8 = "\xa4\xaa";
const STD_SUB_s: [*:0]const u8 = "\xa4\xae";
const STD_SUB_t: [*:0]const u8 = "\xa4\xaf";
const STD_SUB_u: [*:0]const u8 = "\xa4\xb0";
const STD_SUB_v: [*:0]const u8 = "\xa4\xb1";
const STD_SUB_x: [*:0]const u8 = "\xa4\xb3";
const STD_SUP_P: [*:0]const u8 = "\xa4\xc5";
const STD_SUP_S: [*:0]const u8 = "\xa4\xc8";
const STD_SUP_U: [*:0]const u8 = "\xa4\xca";
const STD_SUP_i: [*:0]const u8 = "\xa4\x8a";
const STD_SUP_p: [*:0]const u8 = "\xa4\x91";
const STD_SUP_s: [*:0]const u8 = "\xa4\x94";
const STD_SUP_u: [*:0]const u8 = "\xa4\x96";
const STD_alpha: [*:0]const u8 = "\x83\xb1";
const STD_op_i: [*:0]const u8 = "\xa1\x48";
const RADIX34_MARK_CHAR_DOT: u8 = '.';

// ---------------------------------------------------------------------------
// DMCP-ROM trampolines (fixed-address on firmware; verified in lft_ifc.h).
// lcd_fill_rect: LIBRARY_FN_BASE+60 (lft_ifc.h:61)
// bitblt24:      LIBRARY_FN_BASE+36 (lft_ifc.h:55)
// On host these are real symbols (GTK / screen layer). Mirrors the status-bar
// owner verbatim.
// ---------------------------------------------------------------------------
const LcdFillRectFn = *const fn (x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void;
const c_lcd_fill_rect = @extern(LcdFillRectFn, .{ .name = "lcd_fill_rect" });
inline fn lcd_fill_rect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) void {
    if (comptime dmcp_build) {
        const f: LcdFillRectFn = @ptrFromInt(LIBRARY_FN_BASE + 60);
        f(x, y, dx, dy, val);
    } else {
        c_lcd_fill_rect(x, y, dx, dy, val);
    }
}

const Bitblt24Fn = *const fn (x: u32, dx: u32, y: u32, val: u32, blt_op: c_int, fill: c_int) callconv(.c) void;
const c_bitblt24 = @extern(Bitblt24Fn, .{ .name = "bitblt24" });
inline fn bitblt24(x: u32, dx: u32, y: u32, val: u32, blt_op: c_int, fill: c_int) void {
    if (comptime dmcp_build) {
        const f: Bitblt24Fn = @ptrFromInt(LIBRARY_FN_BASE + 36);
        f(x, dx, y, val, blt_op, fill);
    } else {
        c_bitblt24(x, dx, y, val, blt_op, fill);
    }
}
const BLT_OR: c_int = 0;
const BLT_ANDN: c_int = 1;
const BLT_NONE: c_int = 0;
inline fn setBlackPixel(x: u32, y: u32) void {
    bitblt24(x, 1, y, 1, BLT_OR, BLT_NONE);
}
inline fn setWhitePixel(x: u32, y: u32) void {
    bitblt24(x, 1, y, 1, BLT_ANDN, BLT_NONE);
}

// ---------------------------------------------------------------------------
// Cross-owner / runtime extern globals.
// ---------------------------------------------------------------------------
extern const standardFont: font_t;
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });
const softmenuStack = @extern([*c]softmenuStack_t, .{ .name = "softmenuStack" });
// allNamedVariables is a POINTER (namedVariableHeader_t *); allReservedVariables
// is an ARRAY (const reservedVariableHeader_t[]).
extern var allNamedVariables: [*c]const namedVariableHeader_t;
const allReservedVariables = @extern([*c]const reservedVariableHeader_t, .{ .name = "allReservedVariables" });
// userMenus and labelList are POINTERS in C (userMenu_t* / labelList_t*); bind
// them as extern var pointer values, not address-of-array.
extern var userMenus: [*c]userMenu_t;
const userMenuItems = @extern([*c]userMenuItem_t, .{ .name = "userMenuItems" });
const userAlphaItems = @extern([*c]userMenuItem_t, .{ .name = "userAlphaItems" });
extern var labelList: [*c]labelList_t;
const lastCatalogPosition = @extern([*c]i16, .{ .name = "lastCatalogPosition" });
// KEY_X is const int[7] (C int = c_int), not int16_t.
const KEY_X = @extern([*c]const c_int, .{ .name = "KEY_X" });

// namedVariableHeader_t / reservedVariableHeader_t: a 32-bit registerHeader_t
// union followed by a length-prefixed name array (Pascal-style: [0] = length).
const namedVariableHeader_t = extern struct {
    header: registerHeader_t,
    variableName: [16]u8,
};
const reservedVariableHeader_t = extern struct {
    header: registerHeader_t,
    reservedVariableName: [8]u8,
};

const programmableMenu_t = extern struct {
    itemName: [18][16]u8,
    itemParam: [21]u16,
    unused: u16,
};
extern var programmableMenu: programmableMenu_t;

extern var calcMode: u8;
extern var menuPageNumber: u16;
extern var catalog: i16;
extern var dynamicMenuItem: i16;
extern var cachedDynamicMenu: i16;
extern var numberOfUserMenus: u16;
extern var numberOfNamedVariables: u16;
extern var numberOfLabels: u16;
extern var currentUserMenu: u16;
extern var currentSolverVariable: u16;
extern var currentSolverProgram: u16;
extern var currentMvarLabel: u16;
extern var currentSolverStatus: u16;
extern var lastErrorCode: u8;
extern var screenUpdatingMode: u8;
extern var doRefreshSoftMenu: bool_t;
extern var numberOfTamMenusToPop: i16;
extern var numberOfFormulae: u16;
extern var currentFormula: u16;
extern var solverEstimatesUsed: bool_t;
extern var compressString: u8;
extern var itemToBeAssigned: i16;
extern fn itemToBeCoded(unusedButMandatoryParameter: u16) void;
extern var last_CM: u8;
extern var alphaCase: u8;
extern var calcModel: u8;
extern var amortP1: u16;
extern var amortP2: u16;
extern var denMax: u32;
extern var lastCenturyHighUsed: u16;
extern var gapItemLeft: u16;
extern var gapItemRight: u16;
extern var gapItemRadix: u16;
extern var grpGroupingLeft: u8;
extern var grpGroupingGr1Left: u8;
extern var grpGroupingGr1LeftOverflow: u8;
extern var grpGroupingRight: u8;
// PLOT_ZMY: extern int8_t (graphs.h). zoomOverride is a #define (18). isR47FAM is
// a macro over calcModel; reproduced inline.
extern var PLOT_ZMY: i8;
const zoomOverride: i8 = 18;
const USER_C47: u8 = 46;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
inline fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}
extern var yCursor: u32;
extern var xCursor: u32;
extern var displayFormat: u8;
// tmpString, aimBuffer, errorMessage are char* POINTERS in C (not arrays).
extern var tmpString: [*c]u8;
extern var aimBuffer: [*c]u8;
extern var errorMessage: [*c]u8;
// printerState_t: {print_on:u8, trace_done:u8, print_blank_line:u8, print_mode:c_int,
// printer_model:c_int, delay:u16}. Enums are int-sized; print_mode is naturally
// aligned to offset 4. Only printer_model is read here.
const printerState_t = extern struct {
    print_on: bool_t,
    trace_done: bool_t,
    print_blank_line: u8,
    print_mode: c_int,
    printer_model: c_int,
    delay: u16,
};
extern var printerState: printerState_t;

// tamState_t: only mode / alpha / keyInputFinished are read here.
const tamState_t = extern struct {
    mode: u16,
    function: i16,
    alpha: bool_t,
    currentOperation: i16,
    dot: bool_t,
    indirect: bool_t,
    digitsSoFar: i16,
    value0: i16,
    value: i16,
    min: i16,
    max: i16,
    key: i16,
    keyAlpha: bool_t,
    keyDot: bool_t,
    keyIndirect: bool_t,
    keyInputFinished: bool_t,
};
extern var tam: tamState_t;

// fnGetSystemFlag: compared by address against indexOfItems[].func.
extern fn fnGetSystemFlag(systemFlag: u16) void;

// File-local bug-screen message (TO_QSPI const char[] in C).
const bugScreenIdMustNotBe0: [*:0]const u8 = "In function showSoftmenu: id must not be 0!";



// ---------------------------------------------------------------------------
// Runtime extern functions.
// ---------------------------------------------------------------------------
extern fn getSystemFlag(sf: c_int) bool_t;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
// isSystemFlagWriteProtected(sf) = (sf & 0x4000) != 0 (macro).
inline fn isSystemFlagWriteProtected(sf: c_int) bool_t {
    return @intFromBool((sf & 0x4000) != 0);
}
extern fn compareString(s1: [*c]const u8, s2: [*c]const u8, mode: c_int) i32;
// stringByteLength(str) = (int32_t)strlen(str) (macro).
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
extern fn getRegisterTag(regist: calcRegister_t) u32;
// getRegisterAngularMode(reg) = getRegisterTag(reg) & amAngleMask (macro).
const amAngleMask: u32 = 15;
// stringCopy is a macro for stpcpy (returns pointer to terminating NUL of dst).
fn stpcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8 {
    var d = dst;
    var s = src;
    while (s[0] != 0) {
        d[0] = s[0];
        d += 1;
        s += 1;
    }
    d[0] = 0;
    return d;
}
inline fn stringCopy(dst: [*c]u8, src: [*c]const u8) [*c]u8 {
    return stpcpy(dst, src);
}
extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque;
extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, errRegisterLine: calcRegister_t) void;
extern fn displayBugScreen(msg: [*c]const u8) void;
extern fn moreInfoOnError(m1: [*c]const u8, m2: [*c]const u8, m3: [*c]const u8, m4: [*c]const u8) void;
extern fn enterAsmModeIfMenuIsACatalog(menuId: i16) void;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*c]u8;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
inline fn getRegisterAngularMode(reg: calcRegister_t) c_int {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
extern fn getRegisterAsRealQuiet(regist: calcRegister_t, r: *real_t) bool_t;
extern fn fnUndo(p: u16) void;
extern fn liftStack() void;
extern fn createMenu(menuName: [*c]const u8) void;
extern fn assignToUserMenu(item: u16) void;
extern fn refreshScreen(source: u16) void;
extern fn checkOpCodeOfStep(step: [*c]const u8, op: i16) bool_t;
extern fn findNextStep(step: [*c]u8) [*c]u8;
extern fn findOrAllocateNamedVariable(name: [*c]const u8) i16;
extern fn boundProgramNameLength(nameStart: [*c]const u8, claimedLength: u8) u8;
extern fn parseEquation(equation: u16, parseMode: u16, buffer: [*c]u8, dest: [*c]u8) [*c]u8;
extern fn reallyRunFunction(func: i16, param: i16) void;
extern fn saveForUndo() void;
extern fn fn1stDerivEq(p: u16) void;
extern fn fn2ndDerivEq(p: u16) void;
extern fn showEquation(equationId: u16, startAt: u16, cursorAt: u16, dryRun: bool_t, cursorShown: ?*bool_t, rightEllipsis: ?*bool_t) void;
extern fn itemNotAvail(itemNr: i16) bool_t;
extern fn isMatrixIndexed() bool_t;
extern fn realToUint32C47(r: *const real_t, err: ?*bool_t) u32;
// real34ToReal(s,d) = decQuadToNumber = decimal128ToNumber (macro).
extern fn decimal128ToNumber(d: *const real34_t, dn: *real_t) *real_t;
inline fn real34ToReal(x: *const real34_t, r: *real_t) void {
    _ = decimal128ToNumber(x, r);
}
extern fn realToFloat(r: *const real_t, f: *f32) void;
// realIsZero(x) = decNumberIsZero(x): lsu[0]==0 && digits==1 && !(bits&DECSPECIAL).
const DECSPECIAL: u8 = 0x70;
inline fn realIsZero(r: *const real_t) bool_t {
    return @intFromBool(r.lsu[0] == 0 and r.digits == 1 and (r.bits & DECSPECIAL) == 0);
}
extern fn fnCbIsSet(item: i16) i8;
extern fn fnItemShowValue(item: i16) i16;
extern fn figlabel(label: [*c]const u8, showText: [*c]const u8, showValue: i16) [*c]u8;
extern fn stringToSub(showText: [*c]const u8) [*c]u8;
extern fn formatDoubleWidth(value: *const real34_t, decimals: i32, displayName: [*c]u8, convertedRealPerfectly: *bool_t, maxWidth: i32, tmpBuf: [*c]u8, tmpBufLen: i32) [*c]u8;
extern fn radixProcess(dest: [*c]u8, src: [*c]const u8) void;
extern fn eatSpacesMid(str: [*c]u8) [*c]u8;
extern fn compressConversionName(name: [*c]u8) void;
extern fn showString(str: [*c]const u8, font: *const font_t, x: u32, y: u32, videoMode: c_int, showLeadingCols: bool_t, showEndingCols: bool_t) u32;
extern fn showStringEnhanced(str: [*c]const u8, font: *const font_t, x: i32, y: i32, videoMode: c_int, showLeadingCols: bool_t, showEndingCols: bool_t, compress: c_int, raise: c_int, doShow: c_int, bold: c_int, lf: c_int) i16;
extern fn stringWidthC47(str: [*c]const u8, mode: c_int, comp: c_int, withLeadingEmptyRows: bool_t, withEndingEmptyRows: bool_t) i32;
extern fn clearScreenOld(a: bool_t, b: bool_t, c: bool_t) void;
extern fn showShiftState() void;
extern fn plotline1(x1: i16, y1: i16, x2: i16, y2: i16) void;
extern fn RB_CHECKED(xx: u32, yy: u32) void;
extern fn RB_UNCHECKED(xx: u32, yy: u32) void;
extern fn CB_CHECKED(xx: u32, yy: u32) void;
extern fn CB_UNCHECKED(xx: u32, yy: u32) void;
extern fn MB_MACRO(tt: u32, yy: u32) void;
extern fn MB_MACRO_CHECKED(xx: u32, yy: u32) void;

// fnDynamicMenu is owned elsewhere (renamed away by the retired shim).
extern fn fnDynamicMenu(unusedButMandatoryParameter: u16) void;

// libc.
extern fn malloc(n: usize) [*c]u8;
extern fn free(p: ?*anyopaque) void;
extern fn memset(s: ?*anyopaque, c: c_int, n: usize) ?*anyopaque;
extern fn qsort(base: ?*anyopaque, n: usize, size: usize, cmp: *const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) void;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strchr(s: [*c]const u8, c: c_int) [*c]u8;

// ===========================================================================
// Menu tables (probe-generated, byte-faithful; per-target gates applied).
// ===========================================================================
// menu_HOME and menu_MyPFN are referenced by name from functions (createHOME/createPFN)
pub export const menu_HOME linksection(code_section) = [_]i16{ (if (dmcp_build) @as(i16,1830) else 1873), (if (dmcp_build) @as(i16,1795) else 60), (if (dmcp_build) @as(i16,108) else 58), (if (dmcp_build) @as(i16,63) else 67), (if (dmcp_build) @as(i16,67) else 65), (if (dmcp_build) @as(i16,65) else 1795), 1868, 122, (if (dmcp_build) @as(i16,1405) else 108), 1703, (if (dmcp_build) @as(i16,2083) else 1816), (if (dmcp_build) @as(i16,1816) else 2083), 94, 93, (if (dmcp_build) @as(i16,1622) else -2229), (if (option_vector) @as(i16,-1925) else 0), 1949, 1946 };
const menu_MyPFN linksection(code_section) = [_]i16{ 1, 2, 3, 4, 1458, -1356, 0, 0, 0, 0, -1342, -1365, 2404, 0, 0, 0, -2403, -1357 };

const menu_1stDeriv linksection(code_section) = [_]i16{ 0, 0, 0, 0, -2374, 2377 };
const menu_2ndDeriv linksection(code_section) = [_]i16{ 0, 0, 0, 0, -2374, 2378 };
const menu_42 linksection(code_section) = [_]i16{ 1527, 0, 0, 0, 0, 0 };
const menu_ADV linksection(code_section) = [_]i16{ 1671, 1672, 1476, 1475, -1381, 1608, 1754, 1755, 1555, 1604, 1546, 1547, 0, 0, 0, 0, 0, 0 };
const menu_AIMCATALOG linksection(code_section) = [_]i16{ -1350, -1377, -1375, -1378, -1374, 1958 };
const menu_ALPHA linksection(code_section) = [_]i16{ -1377, -1375, -1378, -1374, 1952, 1953, -1350, 2420, 2419, 1411, 1954, 1955, 1858, 2029, 2191, 1729, 1926, 1928 };
const menu_ALPHA_OMEGA linksection(code_section) = [_]i16{ 602, 603, 604, 605, 606, 1810, 607, 608, 609, 610, 612, 613, 614, 615, 616, 617, 618, 1809, 619, 620, 620, 621, 622, 624, 625, 626, 627, 1811, 0, 0, 0, 0, 0, 0, 0, 0, 611, 0, 0, 623, 0, 0 };
const menu_AMORT linksection(code_section) = if ((!(dmcp_build and old_hw))) [_]i16{2716, 2717, 2718, 2719, 2720, 2721, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2052} else [_]i16{};
const menu_ASN_N linksection(code_section) = [_]i16{ 1906, 1904, 1898, (if (dmcp_build) @as(i16,1978) else 1918), (if (dmcp_build) @as(i16,1979) else 1900), 1894, (if (dmcp_build) @as(i16,1915) else 1975), (if (dmcp_build) @as(i16,0) else 1977), (if (dmcp_build) @as(i16,0) else 1976), (if (dmcp_build) @as(i16,0) else 1974), 0, 1914 };
const menu_AUDIO linksection(code_section) = [_]i16{ 1414, 1624, 2202, 2203, 2200, 2201, 0, 0, 0, 0, 0, 2198 };
const menu_AngleConv_43S linksection(code_section) = [_]i16{ 115, 119, 117, 116, 118, -1367, 0, 0, 0, 0, 1741, 1910, 1445, 1557, 1480, 0, 0, 0 };
const menu_BASE linksection(code_section) = [_]i16{ 1834, 1833, 1832, 1831, 1872, 120, 124, 125, 126, 123, 0, 2553, 1838, 1837, 1836, 1835, 112, -1881, 550, 551, 552, 553, 554, 555, 1993, 1992, 1991, 1990, 2004, 2003, 1998, 1997, 1996, 1995, 112, -1881 };
const menu_BITS linksection(code_section) = [_]i16{ 124, 125, 126, 123, 419, 420, 402, 403, 404, 422, 425, 426, 408, 405, 406, 407, 112, 409, 1999, 2000, 2001, 2002, 1956, 1957, 414, 415, 410, 412, 411, 413, 421, 416, 417, 418, 112, -1881 };
const menu_BITSET linksection(code_section) = [_]i16{ 550, 551, 552, 553, 554, 555, 1404, 1406, 1629, 1601, 0, 1638, 1986, 1987, 1988, 1985, 112, 1895 };
const menu_BLUE_C47 linksection(code_section) = [_]i16{ 105, -1323, -1363, -2102, -1328, 1723, 1706, 1666, 63, 1830, 1850, 1849, 1422, 1872, 1909, 1741, 1, 4, 1871, 101, 1729, 0, 0, 0, 1405, 1622, -1339, -1365, -1322, 0, 0, 0, 0, 0, 0, 0, 0, -1927, -1376, -1342, -1341, 0, 1935, -1317, -1320, -1353, -1340, 0, 1560, -1921, -1331, -1372, -2107, 0 };
const menu_Base2 linksection(code_section) = [_]i16{ 550, 551, 552, 553, 554, 555, 124, 125, 126, 123, 100, 102, -1923, 414, 415, 1831, 1833, 1834, 550, 551, 552, 553, 554, 555, 1857, 1852, 1851, 0, 0, 2553, -1923, 422, 408, 407, 405, -1881 };
const menu_Binom linksection(code_section) = [_]i16{ 1208, 0, 1209, 1210, 0, 1211, 1248, 0, 1249, 1250, 0, 1251, 2316, 2317, 0, 0, 0, 0 };
const menu_CASHFL linksection(code_section) = [_]i16{  };
const menu_CATALOG linksection(code_section) = [_]i16{ -1330, -1322, -1319, -1355, -1370, -1345, 0, 0, 0, 0, 0, 1958 };
const menu_CHARS linksection(code_section) = [_]i16{ -1350, -1377, -1375, -1378, -1374, 0 };
const menu_CLK linksection(code_section) = [_]i16{ 1438, 1454, 1621, 1862, 1863, 1622, 1439, 1911, 1843, 1910, 1741, 1504, 1681, 1644, 1842, 1688, 1686, 2550, 1942, 1943, 1619, 1453, 1528, 1649, 1592, 1597, 1633, 1440, 1521, 1647, 1438, 1621, 2505, 1841, 1840, 1839, 1471, 1495, 2147, 2148, 2149, 2150, 2504, 0, 0, 2501, 2502, 2503 };
const menu_CLR linksection(code_section) = [_]i16{ 110, 1424, 1420, 1427, 41, 1428, 1421, 2239, 2240, 1429, 2033, 1423, 1568, 0, 1452, 0, 2005, -2243 };
pub export const menu_CONST linksection(code_section) = [_]i16{ 128, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 184, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 129, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 185, 186, 209, 187, 188, 189, 190, 191, 192, 193, 194, 195, 210, 196, 197, 198, 199, 208, 212, 200, 211, 201, 202, 203, 204, 205 };
const menu_CPX linksection(code_section) = [_]i16{ 1566, 1485, 1431, 1570, 1830, 1795, 1848, 1628, 105, 1706, 1449, 1436, 1850, 1849, 1437, 1569, 1949, 1946 };
const menu_Cauch linksection(code_section) = [_]i16{ 1213, 0, 1214, 1215, 0, 1216, 0, 0, 0, 0, 0, 0, 2318, 2319, 0, 0, 0, 0 };
const menu_ConvA linksection(code_section) = [_]i16{ 234, 236, 370, 371, 388, 389, 238, 240, 372, 373, 390, 391, 223, 224, 226, 227, 229, 230 };
const menu_ConvAng linksection(code_section) = [_]i16{ 2096, 2097, 2098, 2099, 2100, 2101, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
const menu_ConvChef linksection(code_section) = [_]i16{ 347, 395, 338, 385, 315, 299, 305, 394, 303, 383, 301, 297, 266, 268, 354, 319, 359, 325, 345, 393, 335, 369, 312, 287, 309, 392, 308, 365, 306, 285, 270, 272, 351, 317, 362, 327 };
const menu_ConvE linksection(code_section) = [_]i16{ 290, 291, 250, 251, 248, 249, 2464, 2465, 2658, 2659, 2660, 2661, 0, 0, 0, 0, 0, 0 };
const menu_ConvFP linksection(code_section) = [_]i16{ 324, 326, 284, 286, 320, 321, 243, 242, 342, 343, 0, 0, 246, 247, 346, 344, 0, 0 };
const menu_ConvHum linksection(code_section) = [_]i16{ 2169, 2170, 2171, 2172, 2173, 2174, 2468, 2469, 2177, 2178, 2179, 2180, 2466, 2467, 2183, 2184, 2185, 2186, 2175, 2176, 2181, 2182, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
const menu_ConvM linksection(code_section) = [_]i16{ 293, 292, 256, 257, 295, 294, 302, 300, 298, 296, 318, 316, 0, 0, 0, 0, 0, 0, 313, 310, 307, 304, 350, 353, 352, 355, 314, 311, 0, 0, 0, 0, 0, 0, 0, 0 };
const menu_ConvP linksection(code_section) = [_]i16{ 278, 279, 282, 283, 280, 281, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
const menu_ConvS linksection(code_section) = [_]i16{ 2084, 2085, 2086, 2087, 2088, 2089, 2090, 2091, 2092, 2093, 2094, 2095, 2187, 2188, 2189, 2190, 0, 0 };
const menu_ConvTemp linksection(code_section) = [_]i16{ 220, 221, 2665, 2666, 2673, 2674, 2669, 2670, 2667, 2668, 2671, 2672, 0, 0, 0, 0, 0, 0 };
const menu_ConvV linksection(code_section) = [_]i16{ 237, 235, 265, 264, 255, 253, 266, 268, 241, 239, 274, 275, 233, 232, 364, 366, 356, 357, 237, 235, 269, 267, 255, 253, 270, 272, 273, 271, 276, 277, 1903, 1902, 364, 366, 262, 261 };
const menu_ConvX linksection(code_section) = [_]i16{ 328, 329, 341, 340, 333, 332, 331, 330, 258, 259, 322, 323, 2167, 2168, 288, 289, 244, 245, 374, 375, 378, 379, 0, 0, 0, 0, 382, 384, 380, 381, 0, 0, 376, 377, 386, 387, 336, 339, 260, 263, 337, 334, 360, 363, 358, 361, 0, 0, 0, 0, 2163, 2164, 0, 0 };
const menu_ConvYmmv linksection(code_section) = [_]i16{ 2204, 2205, 2206, 2207, 2208, 2209, 2210, 2211, 2212, 2213, 2215, 2214, 2216, 2217, 2218, 2219, 2220, 2221 };
const menu_DELETE linksection(code_section) = [_]i16{ 1419, 2241, 2242, 1426, 1425, 1780, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1455 };
const menu_DELITM linksection(code_section) = [_]i16{ 0, 0, 0, -1355, -1370, -1345 };
const menu_DISP linksection(code_section) = [_]i16{ 1473, 1587, 1460, 1867, 1866, 1410, 1744, 2056, 1888, 2551, 1876, 1877, 2159, 2160, 2161, 2154, 1896, 1619, 1865, 1899, 1450, 2006, 1689, 2500, 1936, 1937, 0, 1798, 1944, 1945, 1950, 1951, 0, 0, 2549, 2195, 1591, 1593, 1594, 1595, 1598, 1599, 0, 0, 0, 0, 0, 1596, 0, 0, 0, 0, 0, 0 };
const menu_DISTR linksection(code_section) = [_]i16{ -1252, -1272, -1262, -1222, -1217, -1267, -1277, -2600, -1212, -1286, -1242, -1247, 0, -2605, -1227, -1232, -1257, -1207 };
const menu_Dev linksection(code_section) = [_]i16{ (if (strip_21_hp35) @as(i16,0) else 2626), 2627, 2628, 2629, 0, 0 };
const menu_DisUniform linksection(code_section) = [_]i16{ 2606, 0, 2607, 2608, 0, 2609, 0, 0, 0, 0, 0, 0, 2333, 2334, 0, 0, 0, 0 };
const menu_EE linksection(code_section) = [_]i16{ 1830, 1795, (if (dmcp_build) @as(i16,1848) else 58), 1705, 1703, 1428, 115, 119, 1828, 1829, 1827, 2623, 1445, 1557, 1931, 2041, 1949, 1946, 1824, 1825, 1823, 1826, 2586, 2587, 1820, 1822, 1818, 1813, 1812, -2597, 1819, 1821, 1817, 1814, 1815, 2624 };
const menu_EIMCATALOG linksection(code_section) = [_]i16{ -2228, -1322, -1319, 0, 0, 1958 };
const menu_EQN linksection(code_section) = [_]i16{ 1465, 1464, -1336, -1335, -1380, -1361, 1463, 0, 0, 0, 0, -1388 };
const menu_EXP linksection(code_section) = [_]i16{ 59, 60, 1794, 68, 1614, 72, 62, 63, 61, 64, 1575, 65, 78, 75, 80, 84, 82, 86 };
const menu_Eim linksection(code_section) = [_]i16{ 999, 2383, 832, 1000, 995, 996, 1858, 2029, 2191, 822, 814, 815, 0, 0, 0, 0, 0, 0, 76, 74, 79, 644, 995, 996, 83, 81, 85, 2165, 998, 1706, 0, 0, 0, 0, 0, 0, 807, 2166, 2420, 2419, 995, 996, 0, 0, 0, 0, 0, 0 };
const menu_Ellipt linksection(code_section) = [_]i16{ 1682, 1683, 1684, 1726, 1727, 1728, 2104, 2105, 1584, 1763, 1764, 1765, 2599, 2598, 2395, 115, 116, 119 };
const menu_Expon linksection(code_section) = [_]i16{ 1218, 0, 1219, 1220, 0, 1221, 0, 0, 0, 0, 0, 0, 2321, 0, 0, 0, 0, 0 };
const menu_F linksection(code_section) = [_]i16{ 1223, 0, 1224, 1225, 0, 1226, 0, 0, 0, 0, 0, 0, 2322, 2323, 0, 0, 0, 0 };
pub export const menu_FCNS linksection(code_section) = [_]i16{ 2053, 1987, 67, 1836, 1404, 73, 1406, 2594, 2593, 64, 1837, 2587, 2585, 2589, 1822, 1820, 1818, 2624, 2588, 1821, 1819, 1817, 2586, 62, 1527, 2595, 1838, 2683, 1835, 1986, 2044, 2764, 2763, 1408, 1409, 1410, 1308, 1584, 124, 2396, 81, 82, 83, 85, 84, 86, 416, 1411, 1775, 1814, 2018, 2395, 1412, 2720, 1895, 1413, 1985, 1988, 406, 1414, 1415, 1310, 1435, 1831, 1208, 1209, 1210, 1211, 1416, 1734, 405, 2202, 1417, 2004, 1851, 1418, 1304, 1213, 1214, 1215, 1216, 407, 1730, 87, 1756, 110, 97, 1420, 1421, 2033, 1942, 1943, 1423, 2239, 1424, 1427, 2005, 1428, 1452, 2240, 41, 1429, 2525, 2706, 207, 1683, 49, 1848, 2526, 1431, 56, 1433, 74, 75, 1434, 1936, 1937, 1798, 1856, 2371, 2370, 1436, 2710, 26, 2493, 1437, 2492, 1438, 1440, 1689, 1441, 1442, 1443, 1833, 1444, 91, 1445, 1419, 1780, 1455, 2241, 1425, 1426, 2242, 1876, 1877, 2767, 2766, 1474, 2606, 2607, 2608, 2609, 1865, 2043, 2551, 2770, 2110, 1558, 1453, 1684, 1449, 2373, 2372, 1873, 37, 1544, 8, 2006, 9, 1573, 1450, 10, 1862, 1899, 1451, 2397, 1454, 1911, 1439, 2404, 1776, 1456, 1457, 1816, 1458, 1459, 1460, 1951, 1461, 35, 57, 1463, 1464, 1465, 1466, 1467, 1853, 1468, 22, 65, 1469, 1298, 1218, 1219, 1220, 1221, 1470, 1575, 1727, 1764, 1731, 1477, 409, 1722, 2128, 20, 396, 398, 397, 2154, 1481, 2124, 112, 2059, 1897, 2058, 1472, 42, 1473, 1935, 88, 2136, 2133, 94, 2126, 2158, 1223, 24, 1744, 1896, 1864, 2132, 21, 399, 401, 400, 2131, 2135, 2129, 2125, 2127, 2134, 2130, 1763, 1224, 1225, 1226, 1893, 1475, 1476, 1732, 1303, 89, 1478, 1479, 1228, 1229, 1230, 1231, 1282, 1283, 1284, 1285, 1480, 2, 1797, 1834, 2195, 1766, 1790, 1791, 1483, 1793, 1484, 1859, 1854, 1839, 2052, 1792, 1233, 1234, 1235, 1236, 1306, 1688, 1686, 1889, 1891, 1890, 1887, 2115, 100, 1632, 2111, 1485, 2528, 2530, 92, 1486, 2123, 43, 2120, 25, 93, 2113, 2155, 2157, 2156, 2056, 5, 6, 2765, 1606, 2119, 7, 2118, 2122, 2116, 2112, 2114, 2121, 2117, 1487, 1488, 1489, 1754, 1755, 1490, 1491, 1781, 1825, 2147, 2148, 2149, 2150, 1492, 1493, 1494, 1495, 1471, 1863, 2008, 1498, 1958, 1499, 2039, 77, 1501, 1726, 2104, 1677, 1502, 68, 1, 1503, 90, 1857, 1504, 1238, 1239, 1240, 1241, 1299, 2083, 120, 2398, 417, 1505, 1506, 69, 1507, 1508, 1614, 1509, 1510, 1511, 1512, 2388, 1552, 1513, 1514, 1515, 71, 1300, 1243, 1244, 1245, 1246, 72, 2662, 2663, 2664, 1905, 1516, 2689, 1517, 2684, 419, 420, 27, 1518, 103, 1528, 1519, 1520, 2408, 104, 1840, 421, 1924, 102, 1521, 1496, 1944, 1945, 1523, 1524, 1796, 1861, 2509, 2510, 2713, 2714, 2478, 2739, 2367, 2506, 2712, 2365, 1525, 1526, 1739, 2737, 1529, 1530, 2513, 2385, 2507, 2715, 2514, 1531, 1532, 1533, 2726, 2364, 1534, 1535, 1536, 1537, 1538, 1646, 2511, 2512, 2366, 1539, 2508, 2515, 2727, 113, 1541, 2105, 2041, 2598, 402, 28, 1248, 1249, 1250, 1251, 2769, 2768, 2622, 2620, 106, 107, 2705, 1542, 403, 2690, 1253, 1254, 1255, 1256, 123, 2621, 2399, 2721, 435, 1832, 23, 1543, 2405, 1827, 1828, 1829, 2623, 1830, 1795, 125, 1301, 1852, 2716, 2717, 1305, 38, 50, 1546, 2732, 1547, 1548, 2203, 2040, 2734, 1550, 1551, 1258, 1259, 1260, 1261, 1946, 1553, 1302, 33, 1948, 2020, 1888, 1291, 1292, 1293, 1294, 1287, 1288, 1289, 1290, 1556, 1557, 1675, 1559, 51, 1561, 1562, 1563, 1564, 2249, 2728, 2482, 2483, 2484, 52, 53, 54, 2224, 55, 1432, 1462, 2141, 2137, 1565, 1566, 1567, 2369, 2368, 1949, 1560, 1554, 1568, 1309, 1570, 2527, 2529, 418, 2001, 1956, 411, 410, 2524, 122, 121, 2019, 2549, 1678, 2497, 1574, 1307, 1868, 1869, 2139, 1917, 2002, 1957, 413, 412, 1577, 1578, 4, 1579, 2142, 2138, 2140, 1580, 1581, 1582, 1583, 29, 1569, 39, 40, 1585, 1586, 2389, 2387, 408, 1549, 1587, 1950, 2197, 1588, 423, 424, 1841, 1589, 1592, 1597, 111, 1742, 1855, 1866, 1600, 1601, 1602, 76, 1500, 1540, 78, 66, 2400, 1603, 1999, 414, 1555, 1604, 1605, 1758, 1607, 1405, 1682, 1608, 1940, 30, 2000, 2038, 415, 1938, 1939, 1609, 1736, 1446, 1610, 44, 1611, 1612, 1613, 70, 1622, 1615, 2250, 2729, 2485, 2486, 2487, 45, 46, 47, 48, 1430, 1545, 2692, 31, 1617, 1618, 1815, 1447, 1591, 1596, 1593, 1594, 1595, 1598, 1599, 79, 80, 1619, 1620, 1621, 1623, 1624, 34, 1263, 2691, 2402, 1264, 1265, 1266, 2401, 1843, 1625, 1626, 1627, 1723, 2601, 2602, 2603, 2604, 1867, 1628, 1629, 426, 2491, 2490, 2494, 2477, 2481, 2480, 2479, 2703, 2476, 2489, 1630, 2531, 2532, 1631, 101, 2198, 2200, 2201, 2199, 2498, 1824, 1633, 1268, 1269, 1270, 1271, 1634, 1635, 2505, 2501, 2503, 2502, 2504, 1636, 1590, 1933, 1638, 1639, 1637, 2003, 1643, 1640, 1826, 1743, 2570, 2562, 58, 59, 2565, 2573, 2564, 2566, 2563, 2580, 2559, 2576, 2582, 3, 2223, 2569, 1641, 1746, 2078, 2567, 2568, 2077, 1653, 2074, 1654, 2577, 2578, 2575, 404, 126, 1576, 2571, 2075, 2076, 2079, 2556, 1747, 2557, 2558, 2583, 2572, 2574, 1616, 2560, 1642, 2584, 63, 2561, 2420, 2419, 108, 1644, 2554, 2555, 2579, 1645, 127, 36, 16, 17, 11, 15, 12, 18, 19, 13, 14, 2082, 1648, 1812, 1647, 1649, 60, 2475, 2495, 2550, 1919, 2237, 1665, 1650, 425, 1762, 1681, 1931, 1842, 2702, 2474, 2488, 2496, 1651, 1823, 1652, 1932, 1655, 1656, 1657, 1658, 1659, 1660, 1661, 1663, 1662, 1664, 1813, 1666, 1693, 1667, 1668, 1669, 1670, 1765, 2599, 1671, 1728, 1673, 2409, 2410, 2412, 2718, 2411, 2413, 444, 447, 443, 442, 446, 1672, 2719, 1674, 436, 438, 439, 451, 449, 457, 458, 441, 454, 452, 450, 453, 448, 437, 440, 455, 456, 445, 433, 434, 2386, 1278, 1279, 1280, 1281, 1273, 1274, 1275, 1276, 1679, 1704, 1705, 95, 32, 96, 98, 1680, 1701, 1909, 1910, 99, 2470, 115, 116, 117, 1871, 1872, 118, 1849, 1983, 1981, 119, 1691, 1850, 1984, 1982, 2471, 1789, 1788, 1694, 1703, 1702, 105, 2704, 2472, 2473, 2247, 2248, 1695, 1696, 1697, 1698, 1692, 1699, 61, 1794, 1700, 1690, 1706, 1745, 1708, 1799, 2695, 1710, 1711, 2693, 1712, 2688, 2687, 1713, 1714, 1715, 1716, 2696, 1718, 1719, 1676, 2694, 1707, 2682, 1720, 2697, 422 };
const menu_FCNS_EIM linksection(code_section) = [_]i16{ 62, 81, 82, 83, 85, 84, 86, 1775, 1416, 1417, 87, 49, 1431, 74, 75, 1466, 1467, 65, 1472, 88, 1478, 1479, 1483, 1484, 100, 1485, 68, 1505, 1506, 69, 1508, 71, 72, 103, 104, 102, 50, 1550, 1566, 122, 76, 1500, 1540, 78, 79, 80, 1623, 1627, 1635, 1636, 1637, 63, 108, 1664, 1670, 105, 61, 1706 };
const menu_FIN linksection(code_section) = [_]i16{ 433, 1697, 1695, 1666, 1699, 1696, 434, 436, 435, 1743, 0, 0, 1429, 1698, 1692, 1693, -2381, -1368 };
const menu_FLAGS linksection(code_section) = [_]i16{ 111, 21, 112, 1610, 20, 110, 400, 399, 401, 398, 397, 396, 0, 0, 0, 0, 0, 1421 };
const menu_Flg linksection(code_section) = [_]i16{ 2336, 2337, 2338, 2339, 2340, 2341, 538, 535, 531, 532, 533, 534, 536, 537, 527, 528, 529, 530, 2342, 2343, 2344, 2345, 2346, 2347, 2348, 2349, 0, 0, 0, 0 };
const menu_GAP_L linksection(code_section) = [_]i16{ 2113, 2115, 2111, 2118, 2119, 2123, 2114, 2116, 2112, 2117, 2121, 2122, 2155, 2157, 2156, 0, 2120, 0 };
const menu_GAP_R linksection(code_section) = [_]i16{ 2126, 2128, 2124, 2131, 2132, 2136, 2127, 2129, 2125, 2130, 2134, 2135, 2158, 0, 0, 0, 2133, 0 };
const menu_GAP_RX linksection(code_section) = [_]i16{ 2139, 2141, 2137, 2140, 2142, 2138 };
const menu_GEV linksection(code_section) = [_]i16{ 1282, 0, 1283, 1284, 0, 1285, 0, 0, 0, 0, 0, 0, 2326, 2327, 2330, 0, 0, 0 };
const menu_GRAPHS linksection(code_section) = [_]i16{ 1206, 1205, 2548, 2547, 2373, 2372 };
const menu_Geom linksection(code_section) = [_]i16{ 1228, 0, 1229, 1230, 0, 1231, 0, 0, 0, 0, 0, 0, 2316, 0, 0, 0, 0, 0 };
const menu_Grapher linksection(code_section) = [_]i16{ 0, 0, 0, 0, 0, 0 };
const menu_HIST linksection(code_section) = [_]i16{ 1790, 1791, 1788, 1787, 1789, 1792, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
const menu_HPLOT linksection(code_section) = [_]i16{ 1793, 2034, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
const menu_Hyper linksection(code_section) = [_]i16{ 1233, 0, 1234, 1235, 0, 1236, 0, 0, 0, 0, 0, 0, 2324, 2317, 2325, 0, 0, 0 };
const menu_INFO linksection(code_section) = [_]i16{ 1631, 1905, 1677, 1501, 1515, 1519, 1634, 1413, 1474, 2199, 2686, 1446, 0, 0, 0, 0, 0, 2408, 2402, 2737, 106, 1626, 1609, 2019, 1678, 1766, 1588, 1481, 1435, 1639, 1471, 2504, 0, 0, 0, 0, 2763, 1606, 2766, 2768, 1558, 0, 2764, 2765, 2767, 2769, 2770, 0 };
const menu_INTS linksection(code_section) = [_]i16{ 550, 551, 552, 553, 554, 555, 100, 122, 102, 1680, 120, 90, 1443, 1441, 1442, 1701, 66, 89 };
const menu_IO linksection(code_section) = [_]i16{ 1590, 2387, 1586, 1510, 1511, 1552, 1567, 2388, 1509, 1513, 1512, -1315, 1576, 1933, 2389, 0, 1405, -2390 };
const menu_Inl_Tst linksection(code_section) = [_]i16{ 1884, 0, 0, 1882, 1885, 1886 };
const menu_KEYS linksection(code_section) = [_]i16{ -1920, -2235, -2234, 1411, 1729, 1958, (if (dmcp_build) @as(i16,2391) else 1959), (if (dmcp_build) @as(i16,2393) else 1916), (if (dmcp_build) @as(i16,2394) else 0), (if (dmcp_build) @as(i16,2392) else 0), 0, 0 };
const menu_LOOP linksection(code_section) = [_]i16{ 8, 10, 9, 5, 7, 6, 91, 0, 0, 0, 0, 92 };
const menu_Logis linksection(code_section) = [_]i16{ 1243, 0, 1244, 1245, 0, 1246, 0, 0, 0, 0, 0, 0, 2326, 2328, 0, 0, 0, 0 };
const menu_MATX linksection(code_section) = [_]i16{ 1536, 1704, 1529, 1530, 1602, (if (option_vector) @as(i16,-2106) else 0), 2726, 1526, 1739, 2737, 2478, 2739, 2497, 2498, 2729, 2728, 0, 0, 1705, 2727, 1578, 2710, 1702, (if (option_vector) @as(i16,-2106) else 1428), 2704, 1628, 1704, 1745, 1449, 1436, 0, 0, 1457, 1456, 1535, 1646, 1490, 1491, 1613, 1563, 1494, 1493, 2714, 2713, 1539, 2712, 2715, 1486, 1538, 1531, 1612, 1562, 2250, 2249 };
const menu_MODE linksection(code_section) = [_]i16{ 1445, 1557, 1480, 2197, 1949, 1946, 2043, 2044, 0, 1853, 1917, 1941, 0, 0, 0, 0, 0, 0, 1938, 1939, 1856, 1940, 1949, 1946, 1890, 1887, 1889, 1891, 121, 1941, 0, 0, 0, 0, 0, 0, 2038, 1797, 1855, 1897, 2058, 2059, 2064, 2060, 2062, 1924, 1796, 1859, 2063, 2065, 2061, 2039, 1861, 1854 };
const menu_MODEL linksection(code_section) = [_]i16{ 1299, 1298, 1300, 1302, 1516, 1759, 1307, 1306, 1305, 1304, 1303, 0, 1309, 1308, 1310, 1435, 0, 1301 };
const menu_MULTSTK linksection(code_section) = [_]i16{ 2588, 2589, 2587, 2585, 2586, 2595, 2593, 2594, 2622, 2620, 2621, 0 };
const menu_M_EDIT linksection(code_section) = [_]i16{ 2366, 2367, 1830, 1532, 892, 894, 1534, 2364, 1795, 1537, 893, 895, 1525, 2365, 0, 0, 1541, 1533 };
const menu_M_SIM_Q linksection(code_section) = [_]i16{ 1202, 1203, 0, 0, 0, 1518 };
const menu_Misc linksection(code_section) = [_]i16{ 367, 368, 254, 252, 231, 225, 349, 348, 0, 0, 228, 222, 0, 0, 0, 0, 0, 0 };
const menu_NUMTHEORY linksection(code_section) = [_]i16{ 1477, 2409, 2410, 2411, 2412, 2413, 2385, 2386, 0, 0, 0, 0 };
const menu_Norml linksection(code_section) = [_]i16{ 1253, 0, 1254, 1255, 0, 1256, 1238, 0, 1239, 1240, 0, 1241, 2326, 2327, 0, 0, 0, 0 };
const menu_Orthog linksection(code_section) = [_]i16{ 1483, 1505, 1506, 1550, 1623, 1627, 1484, 0, 0, 0, 0, 0 };
const menu_PARTS linksection(code_section) = [_]i16{ 93, 94, 1517, 1470, 1600, 1444, 423, 424, 1868, 1869, 1565, 1577, 88, 87, 105, 1706, 1566, 1485 };
const menu_PFN_1 linksection(code_section) = [_]i16{ 43, 2018, 2020, 38, 1620, -1357, 1496, 1468, 1554, 77, 1501, 1556, 1548, 1551, 1409, 1762, 2042, 2852 };
const menu_PFN_2 linksection(code_section) = [_]i16{ 1498, 1499, 1520, 1524, 1630, -2403, 1514, 1553, 1424, 2405, 1469, -2738, 1581, 1582, 1583, 1580, 0, 0 };
const menu_PFN_3 linksection(code_section) = [_]i16{ 1, 2, 3, 4, 1458, -1403, 1603, 1412, 2223, 1579, -1342, -1365, 2404, 1418, 2224, 0, 0, 2055 };
const menu_PLOTFUNC linksection(code_section) = [_]i16{ 1206, 1205, 0, 0, 0, 0, 2007, 2042, 0, 0, 0, 0, 2034, 2035, 0, 0, 0, 0, 2015, 2014, 0, 0, 0, 0, 2384, 1880, 0, 0, 0, 0, -2374, 1405, 0, 0, 0, 0, 2010, 2162, 0, 0, 0, 0, 2009, 2011, 0, 0, 0, 0, 1980, 0, 0, 0, 0, 0, 2025, 2024, 0, 0, 0, 0, 2026, 2027, 0, 0, 0, 0, 2013, 2012, 0, 0, 0, 0 };
const menu_PLOTTING linksection(code_section) = [_]i16{ 433, 436, 438, 437, 440, 441, 434, 452, 453, 455, 456, 454, 435, 457, 458, 2040, -1401, -2080, 433, 443, 444, 446, 447, 439, 434, 445, 442, 448, 449, 451, 435, 0, 0, 450, 0, 1429 };
const menu_PLOT_LR linksection(code_section) = [_]i16{ 1760, 2034, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
const menu_PLOT_SCATR linksection(code_section) = [_]i16{ 1756, 1758, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
const menu_PLOT_STAT linksection(code_section) = [_]i16{ 2014, 2015, 0, 0, 0, 0, 2007, 2042, 0, 0, 0, 0, 2034, 2035, 0, 0, 0, 0, 2010, 2162, 0, 0, 0, 0, 2009, 2011, 0, 0, 0, 0, 1980, 1405, 0, 0, 0, 0, 2025, 2024, 0, 0, 0, 0, 2026, 2027, 0, 0, 0, 0, 2013, 2012, 0, 0, 0, 0 };
const menu_PREF linksection(code_section) = [_]i16{ 2043, 2044, 2197, 1853, 1917, 1941, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1938, 1939, 1856, 1940, 121, 1941, 1890, 1887, 1889, 1891, 0, 0, 0, 0, 0, 0, 0, 0, 2038, 1797, 1855, 1897, 2058, 2059, 2064, 2060, 2062, 1924, 1796, 1859, 2063, 2065, 2061, 2039, 1861, 1854 };
const menu_PREFIX linksection(code_section) = [_]i16{ 1805, 1806, 1807, 1808, 1892, 1864, 1804, 1803, 1802, 1801, 1800, 1573, 2533, 2534, 2535, 2536, 2537, 2053 };
const menu_PRINT linksection(code_section) = [_]i16{ 1708, 1716, 1676, 1714, 2682, 1713, 2687, 2688, 2697, 0, 2695, 2693, -2681, 0, 2689, 2690, 2691, 2692, 1708, 1720, 1707, 1715, 2696, 1718, 2687, 2688, 2694, 1799, 1719, 1711, -2681, (if (dmcp_build) @as(i16,0) else 2699), 2689, 2690, 2691, 2692 };
const menu_PROB linksection(code_section) = [_]i16{ 1559, 1675, 49, 50, 108, (if (strip_15) @as(i16,0) else -1237), 1589, 0, 0, 0, 0, 0 };
const menu_Pareto linksection(code_section) = [_]i16{ 1287, 0, 1288, 1289, 0, 1290, 1291, 0, 1292, 1293, 0, 1294, 2326, 2327, 2329, 0, 0, 0 };
const menu_Poiss linksection(code_section) = [_]i16{ 1258, 0, 1259, 1260, 0, 1261, 0, 0, 0, 0, 0, 0, 2321, 0, 0, 0, 0, 0 };
const menu_Printer linksection(code_section) = [_]i16{ 2683, 2684, 0, 0, 1712, 1710 };
const menu_REGR linksection(code_section) = [_]i16{ 1516, 1433, 1618, 1434, 1643, 1648, 1447, 0, 0, 0, 0, 0, 2662, 2663, 2664, -2081, 1759, 1549 };
const menu_RESETS linksection(code_section) = [_]i16{ 2021, 2022, 2054, 2055, 0, 2023, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
const menu_RIBBONS linksection(code_section) = [_]i16{ 2506, 2513, 2507, 2508, 2509, 2511, 0, 0, 2514, 2515, 2510, 2512, 0, 0, 0, 0, 0, 0 };
const menu_Reg linksection(code_section) = [_]i16{ 2336, 2337, 2338, 2339, 2340, 2341, 538, 535, 531, 532, 533, 534, 536, 537, 527, 528, 529, 530, 2342, 2343, 2344, 2345, 2346, 2347, 2348, 2349, 0, 0, 0, 0 };
const menu_SHOW linksection(code_section) = [_]i16{  };
const menu_STAT linksection(code_section) = [_]i16{ 433, 1640, 1585, 1673, 1605, 1747, 434, 1642, 1617, 1674, 1607, 1746, 435, 1641, 1667, 1669, 1668, -2080, 1654, 2075, 2074, 2076, 1653, 1616, 0, 2082, 2077, 2078, 0, 2079, 0, 0, 0, 0, 0, 1429 };
const menu_STK linksection(code_section) = [_]i16{ 37, 40, 39, 1502, 42, 1428, 1544, 127, 1650, 1651, 1625, 1694, 2595, 0, 0, 0, 0, -2597 };
pub export const menu_SYSFL linksection(code_section) = [_]i16{ 524, 2288, 2289, 477, 497, 498, 493, 494, 523, 2276, 2292, 474, 2253, 2272, 468, 2255, 467, 472, 473, 2257, 465, 2261, 504, 491, 2256, 2286, 2287, 2285, 470, 505, 2252, 492, 2280, 2281, 2283, 480, 499, 500, 2259, 2258, 2275, 525, 476, 484, 466, 2273, 2251, 490, 2279, 2282, 2254, 496, 475, 2260, 2265, 2266, 2277, 2262, 2268, 2271, 2267, 2270, 2269, 2263, 2264, 469, 471, 488, 506, 479, 511, 521, 510, 509, 507, 512, 513, 514, 516, 520, 519, 522, 517, 518, 508, 515, 2274, 2284, 2293, 485, 501, 481, 486, 487, 463, 503, 483, 502, 526, 489, 464, 478, 2278, 495, 2290, 2291, 482 };
const menu_Sf linksection(code_section) = [_]i16{ 0, 0, 0, 0, 0, 0 };
const menu_Sf_TOOL linksection(code_section) = [_]i16{ 1192, 1690, 1700, 1194, 1193, -2374, 0, 204, 205, 0, 0, 0 };
const menu_Sfdx linksection(code_section) = [_]i16{ 1192, 1690, 1700, 1194, 1193, 0, 0, 204, 205, 0, 0, 0 };
const menu_Solver linksection(code_section) = [_]i16{ 0, 0, 0, 0, 0, 0 };
const menu_Solver_TOOL linksection(code_section) = [_]i16{ 2197, 2370, 2371, 2546, 2545, -2374, 0, 2368, 2369, 0, 0, 0 };
const menu_StdNorml linksection(code_section) = [_]i16{ 1278, 0, 1279, 1280, 0, 1281, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
const menu_TEST linksection(code_section) = [_]i16{ 16, 17, 11, 12, 18, 19, 14, 13, 15, 33, 2850, 2851, 57, 77, 1503, 34, 1504, 56, 2400, 2398, 29, 26, 2397, 2401, 0, 0, 0, 0, 0, 0, 31, 0, 2524, 2525, 0, 2526, 24, 25, 2527, 2528, 27, 113, 22, 23, 2529, 2530, 2531, 2532, 2399, 2396, 28, 32, 30 };
const menu_TRG linksection(code_section) = [_]i16{ 1445, 1557, 1480, 1451, 1523, 1775, 115, 119, 117, 116, 118, 0, 1850, 1849, 1909, 1910, 1500, 1540 };
const menu_TRG_C47 linksection(code_section) = [_]i16{ 115, 119, 117, 116, 118, 1873, 1500, 1540, 1909, 1910, 1850, 1849, 1445, 1557, 1480, 1451, 1523, 1775 };
const menu_TRG_C47_MORE linksection(code_section) = [_]i16{ 115, 119, 117, 76, 74, 79, 1500, 1540, 1775, 83, 81, 85, 78, 75, 80, 84, 82, 86 };
const menu_TRI linksection(code_section) = [_]i16{ 115, 119, 117, 76, 74, 79, 1500, 1540, 1775, 83, 81, 85, 78, 75, 80, 84, 82, 86 };
const menu_TVM linksection(code_section) = [_]i16{ 1197, 1196, 1200, 1199, 1195, 1198, 1452, 1776, 1781, 0, 0, 2379, 1415, 1459, 2197, 0, 0, -2382 };
const menu_Tam linksection(code_section) = [_]i16{ 539, -1389, 527, 528, 529, 530, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2066 };
const menu_TamAlpha linksection(code_section) = [_]i16{ -1377, -1375, -1378, -1374, 1952, 1953, -1350, 0, 0, 0, 0, 0, 1858, 2029, 2191, 1729, 0, 0 };
const menu_TamCmp linksection(code_section) = [_]i16{ 539, -1389, 527, 528, 529, 530, 988, 989, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2066 };
const menu_TamFlag linksection(code_section) = [_]i16{ 539, -1379, 527, 528, 529, 530, 0, 0, 0, 0, 0, 0, 2276, 2275, 476, 475, 474, -2067 };
const menu_TamIndirect linksection(code_section) = [_]i16{ 0, -1389, 527, 528, 529, 530, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2066 };
const menu_TamLabel linksection(code_section) = [_]i16{ 539, -1392, 533, 534, 2342, 2343, 576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586, 587 };
const menu_TamLabelOnly linksection(code_section) = [_]i16{ 539, -1392, 0, 0, 0, 0 };
const menu_TamMenu linksection(code_section) = [_]i16{ 539, -2407, 2415, 2416, 2417, 2418 };
const menu_TamNonReg linksection(code_section) = [_]i16{ 539, 0, 2415, 2416, 2417, 2418 };
const menu_TamNonRegMax linksection(code_section) = [_]i16{ 539, 2110, 2415, 2416, 2417, 2418 };
const menu_TamNonRegTrk linksection(code_section) = [_]i16{ 539, 2237, 2415, 2416, 2417, 2418, 0, 1919, 0, 0, 0, 0 };
const menu_TamNorm linksection(code_section) = [_]i16{ 539, 924, 2415, 2416, 2417, 2418, 0, 2705, 1574, 2706, 1461, 0 };
const menu_TamRcl linksection(code_section) = [_]i16{ 539, -1389, 527, 528, 529, 530, 2656, 2657, 2650, 0, 2655, 2654, 2652, 2653, 2647, 2648, 2649, -2066 };
const menu_TamRclTVM linksection(code_section) = [_]i16{ 2640, 2641, 2642, 2644, 2643, 1198, 0, 0, 0, 0, 0, 2379, 539, -1389, 2655, 2654, 0, -2066 };
const menu_TamShuffle linksection(code_section) = [_]i16{ 0, 0, 527, 528, 529, 530 };
const menu_TamSto linksection(code_section) = [_]i16{ 539, -1389, 527, 528, 529, 530, 2656, 2657, 2650, 2651, 2655, 2654, 2652, 2653, 2647, 2648, 2649, -2066 };
const menu_TamStoTVM linksection(code_section) = [_]i16{ 2640, 2641, 2642, 2644, 2643, 1198, 0, 0, 0, 0, 0, 2379, 539, -1389, 2655, 2654, 0, -2066 };
const menu_TamVarOnly linksection(code_section) = [_]i16{ 539, -1389, 0, 0, 0, 0 };
const menu_Timer linksection(code_section) = [_]i16{ 1782, 1783, 1784, 1785, 1786, 1778, 2040, 1560, 1779, 1844, 1777, 1429 };
const menu_Uniform linksection(code_section) = [_]i16{ 2601, 0, 2602, 2603, 0, 2604, 0, 0, 0, 0, 0, 0, 2333, 2334, 0, 0, 0, 0 };
const menu_UnitConv linksection(code_section) = [_]i16{ -1329, -1351, -2047, -1373, -1316, -1371, -1358, -2222, -2046, -2045, -1337, -1901, -1860, 0, 0, 0, 0, -1359 };
const menu_VARS linksection(code_section) = [_]i16{ -2230, -1324, -1360, -1314, -1338, -2232, -2231, -1343, -1325, -1366, -1332, -1364 };
const menu_VECCONV linksection(code_section) = [_]i16{ 2475, 2477, 2498, 2497, 2702, 2703, 0, 0, 0, 0, 0, 0, 2493, 2494, 0, 0, 2700, 2701 };
const menu_VECT linksection(code_section) = [_]i16{ 1850, 2471, 2470, 2496, (if (option_vector) @as(i16,-2499) else 0), (if (dmcp_build) @as(i16,1428) else 1873), 2704, 1628, 2472, 1745, 1449, 1436, 115, 119, 118, 2479, 2480, 2481, 1850, 1849, 2492, 2495, (if (option_vector) @as(i16,-2499) else 0), (if (dmcp_build) @as(i16,1428) else 1873), 2704, 1628, 2472, 1745, 1449, 1436, 115, 119, 118, 0, 2490, 2491 };
const menu_Weibl linksection(code_section) = [_]i16{ 1268, 0, 1269, 1270, 0, 1271, 0, 0, 0, 0, 0, 0, 2331, 2332, 0, 0, 0, 0 };
const menu_XFN linksection(code_section) = [_]i16{ 107, 33, 1477, 1472, 1408, 2083, 1670, 1703, 2385, 1816, 1679, 108, 1478, 1479, -2414, (if ((!(dmcp_build and old_hw))) @as(i16,-2596) else 0), 1416, 1417, 1662, 1663, 1488, 1489, 1664, 1508, 1635, 1636, 1637, 1487, 1661, 1507, -1397, -1352, 1492, 1665, 1466, 1467, 104, 103, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
const menu_XXFCNS linksection(code_section) = [_]i16{ 2554, 2555, 2573, 2574, 2575, 2576, 1445, 1557, 2561, 2558, 2559, 2560, 2579, 2582, 2563, 2564, 2565, 2566, (if (dmcp_build) @as(i16,2583) else 2577), (if (dmcp_build) @as(i16,2572) else 2562), (if (dmcp_build) @as(i16,2562) else 2572), (if (dmcp_build) @as(i16,2571) else 2568), (if (dmcp_build) @as(i16,2568) else 2567), (if (dmcp_build) @as(i16,2567) else 2556), (if (dmcp_build) @as(i16,2580) else 2578), (if (dmcp_build) @as(i16,2577) else 2571), (if (dmcp_build) @as(i16,2578) else 2583), (if (dmcp_build) @as(i16,2584) else 2570), (if (dmcp_build) @as(i16,2570) else 2569), (if (dmcp_build) @as(i16,2569) else 2557), 2579, (if (dmcp_build) @as(i16,0) else 2584), 0, 0, (if (dmcp_build) @as(i16,2556) else 0), (if (dmcp_build) @as(i16,2557) else 2580), 2588, 2589, 2587, 2586, 2585, 0, 0, 0, 0, 0, 0, 0, 1865, 1899, 0, 0, 0, 0 };
const menu_YESNO linksection(code_section) = [_]i16{ 0, 2245, 0, 0, 2246, 0 };
const menu_alphaFN linksection(code_section) = [_]i16{ 1722, 1645, 1660, 1652, 1655, 1932, 1658, 1659, 1656, 1657, 2543, 2544, 2538, 2539, 0, 2540, 2541, 2542 };
const menu_alphaMATH linksection(code_section) = [_]i16{ 824, 949, 825, 947, 950, 826, 834, 829, 814, 815, 831, 836, 830, 821, 857, 855, 819, 817, 832, 920, 921, 922, 867, 866, 845, 932, 933, 956, 957, 958, 837, 943, 942, 948, 944, 847, 1161, 925, 1149, 927, 2429, 812, 835, 846, 876, 880, 1165, 955, 930, 919, 918, 1155, 644, 1159, 1160, 888, 2032, 1168, 916, 848, 936, 938, 937, 939, 2430, 2431, 627, 905, 909, 910, 2447, 2444, 906, 907, 911, 912, 913, 914, 908, 935, 934, 1167, 1158, 904, 886, 926, 889, 890, 891, 1156, 964, 967, 852, 851, 923, 924, 963, 966, 2421, 1076, 1075, 1077, 962, 965, 903, 1004, 1003, 1006, 2437, 2438, 2439, 797, 799, 2440, 2443, 2441, 796, 798, 800, 2442, 0, 0, 0, 761, 2445, 2446 };
const menu_alphaMisc linksection(code_section) = [_]i16{ 1172, 809, 828, 812, 811, 813, 808, 810, 839, 885, 840, 841, 838, 853, 820, 818, 823, 822, 807, 827, 893, 895, 892, 894, 897, 1164, 2433, 2435, 2432, 2434, 898, 1171, 1169, 1154, 1157, 1163, 981, 896, 2427, 2428, 844, 850, 1174, 1173, 842, 941, 919, 816, 1007, 837, 960, 959, 1001, 980, 977, 975, 961, 901, 899, 900, 1152, 1170, 1073, 1074, 979, 978, 991, 879, 880, 1153, 1148, 2436, 1144, 1145, 1146, 1147, 1151, 1162, 982, 983, 0, 0, 0, 0 };
pub export const menu_alpha_INTL linksection(code_section) = [_]i16{ 667, 665, 670, 669, 668, 671, 672, 664, 666, 673, 676, 674, 675, 678, 677, 682, 680, 684, 683, 679, 681, 858, 685, 860, 686, 690, 688, 692, 691, 687, 689, 693, 694, 697, 698, 696, 701, 699, 700, 705, 703, 708, 707, 706, 709, 702, 704, 710, 862, 863, 712, 714, 713, 711, 716, 715, 720, 718, 723, 721, 722, 717, 719, 724, 864, 725, 727, 726, 728, 729, 731, 730 };
pub export const menu_alpha_intl linksection(code_section) = [_]i16{ 735, 733, 738, 737, 736, 739, 740, 732, 734, 741, 744, 742, 743, 746, 745, 750, 748, 752, 751, 747, 749, 859, 753, 861, 754, 759, 757, 761, 760, 756, 758, 762, 764, 766, 767, 765, 770, 768, 769, 774, 772, 777, 776, 775, 778, 771, 773, 779, 781, 780, 783, 785, 784, 782, 787, 786, 791, 789, 794, 792, 793, 788, 790, 795, 865, 796, 801, 800, 802, 803, 805, 804 };
const menu_alpha_omega linksection(code_section) = [_]i16{ 628, 629, 630, 631, 632, 1846, 633, 634, 635, 636, 638, 639, 640, 641, 642, 643, 644, 1845, 645, 646, 660, 647, 648, 650, 651, 652, 653, 1847, 0, 0, 654, 655, 656, 657, 658, 0, 637, 659, 661, 649, 662, 663 };
const menu_chi2 linksection(code_section) = [_]i16{ 1273, 0, 1274, 1275, 0, 1276, 0, 0, 0, 0, 0, 0, 2320, 0, 0, 0, 0, 0 };
const menu_t linksection(code_section) = [_]i16{ 1263, 0, 1264, 1265, 0, 1266, 0, 0, 0, 0, 0, 0, 2320, 0, 0, 0, 0, 0 };
pub export const softmenu linksection(code_data_section) = [_]softmenu_t{
    .{ .menuItem = -1349, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1350, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1355, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1389, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1392, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1343, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1364, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1325, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1366, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1314, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1332, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1338, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1360, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1324, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -2230, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -2231, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -2232, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1398, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1345, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1394, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1520, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -2407, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1390, .numItems = @as(i16, @intCast(menu_TamFlag.len)), .softkeyItem = &menu_TamFlag },
    .{ .menuItem = -1379, .numItems = @as(i16, @intCast(menu_SYSFL.len)), .softkeyItem = &menu_SYSFL },
    .{ .menuItem = -1374, .numItems = @as(i16, @intCast(menu_alpha_INTL.len)), .softkeyItem = &menu_alpha_INTL },
    .{ .menuItem = -1384, .numItems = @as(i16, @intCast(menu_alpha_intl.len)), .softkeyItem = &menu_alpha_intl },
    .{ .menuItem = -1313, .numItems = @as(i16, @intCast(menu_ADV.len)), .softkeyItem = &menu_ADV },
    .{ .menuItem = -1381, .numItems = @as(i16, @intCast(menu_Sfdx.len)), .softkeyItem = &menu_Sfdx },
    .{ .menuItem = -1317, .numItems = @as(i16, @intCast(menu_BITS.len)), .softkeyItem = &menu_BITS },
    .{ .menuItem = -1320, .numItems = @as(i16, @intCast(menu_CLK.len)), .softkeyItem = &menu_CLK },
    .{ .menuItem = -1321, .numItems = @as(i16, @intCast(menu_CLR.len)), .softkeyItem = &menu_CLR },
    .{ .menuItem = -1323, .numItems = @as(i16, @intCast(menu_CPX.len)), .softkeyItem = &menu_CPX },
    .{ .menuItem = -1326, .numItems = @as(i16, @intCast(menu_DISP.len)), .softkeyItem = &menu_DISP },
    .{ .menuItem = -1327, .numItems = @as(i16, @intCast(menu_EQN.len)), .softkeyItem = &menu_EQN },
    .{ .menuItem = -1335, .numItems = @as(i16, @intCast(menu_1stDeriv.len)), .softkeyItem = &menu_1stDeriv },
    .{ .menuItem = -1336, .numItems = @as(i16, @intCast(menu_2ndDeriv.len)), .softkeyItem = &menu_2ndDeriv },
    .{ .menuItem = -1380, .numItems = @as(i16, @intCast(menu_Sf.len)), .softkeyItem = &menu_Sf },
    .{ .menuItem = -1361, .numItems = @as(i16, @intCast(menu_Solver.len)), .softkeyItem = &menu_Solver },
    .{ .menuItem = -1328, .numItems = @as(i16, @intCast(menu_EXP.len)), .softkeyItem = &menu_EXP },
    .{ .menuItem = -1367, .numItems = @as(i16, @intCast(menu_TRI.len)), .softkeyItem = &menu_TRI },
    .{ .menuItem = -1331, .numItems = @as(i16, @intCast(menu_FIN.len)), .softkeyItem = &menu_FIN },
    .{ .menuItem = -1368, .numItems = @as(i16, @intCast(menu_TVM.len)), .softkeyItem = &menu_TVM },
    .{ .menuItem = -1333, .numItems = @as(i16, @intCast(menu_FLAGS.len)), .softkeyItem = &menu_FLAGS },
    .{ .menuItem = -1339, .numItems = @as(i16, @intCast(menu_INFO.len)), .softkeyItem = &menu_INFO },
    .{ .menuItem = -1340, .numItems = @as(i16, @intCast(menu_INTS.len)), .softkeyItem = &menu_INTS },
    .{ .menuItem = -1342, .numItems = @as(i16, @intCast(menu_LOOP.len)), .softkeyItem = &menu_LOOP },
    .{ .menuItem = -1344, .numItems = @as(i16, @intCast(menu_MATX.len)), .softkeyItem = &menu_MATX },
    .{ .menuItem = -1347, .numItems = @as(i16, @intCast(menu_M_SIM_Q.len)), .softkeyItem = &menu_M_SIM_Q },
    .{ .menuItem = -1348, .numItems = @as(i16, @intCast(menu_M_EDIT.len)), .softkeyItem = &menu_M_EDIT },
    .{ .menuItem = -1346, .numItems = @as(i16, @intCast(menu_MODE.len)), .softkeyItem = &menu_MODE },
    .{ .menuItem = -1353, .numItems = @as(i16, @intCast(menu_PARTS.len)), .softkeyItem = &menu_PARTS },
    .{ .menuItem = -1354, .numItems = @as(i16, @intCast(menu_PROB.len)), .softkeyItem = &menu_PROB },
    .{ .menuItem = -1262, .numItems = @as(i16, @intCast(menu_t.len)), .softkeyItem = &menu_t },
    .{ .menuItem = -1222, .numItems = @as(i16, @intCast(menu_F.len)), .softkeyItem = &menu_F },
    .{ .menuItem = -1272, .numItems = @as(i16, @intCast(menu_chi2.len)), .softkeyItem = &menu_chi2 },
    .{ .menuItem = -1252, .numItems = @as(i16, @intCast(menu_Norml.len)), .softkeyItem = &menu_Norml },
    .{ .menuItem = -1520, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -1212, .numItems = @as(i16, @intCast(menu_Cauch.len)), .softkeyItem = &menu_Cauch },
    .{ .menuItem = -1217, .numItems = @as(i16, @intCast(menu_Expon.len)), .softkeyItem = &menu_Expon },
    .{ .menuItem = -1242, .numItems = @as(i16, @intCast(menu_Logis.len)), .softkeyItem = &menu_Logis },
    .{ .menuItem = -1267, .numItems = @as(i16, @intCast(menu_Weibl.len)), .softkeyItem = &menu_Weibl },
    .{ .menuItem = -1207, .numItems = @as(i16, @intCast(menu_Binom.len)), .softkeyItem = &menu_Binom },
    .{ .menuItem = -1227, .numItems = @as(i16, @intCast(menu_Geom.len)), .softkeyItem = &menu_Geom },
    .{ .menuItem = -1232, .numItems = @as(i16, @intCast(menu_Hyper.len)), .softkeyItem = &menu_Hyper },
    .{ .menuItem = -1247, .numItems = @as(i16, @intCast(menu_GEV.len)), .softkeyItem = &menu_GEV },
    .{ .menuItem = -1257, .numItems = @as(i16, @intCast(menu_Poiss.len)), .softkeyItem = &menu_Poiss },
    .{ .menuItem = -1356, .numItems = @as(i16, @intCast(menu_PFN_1.len)), .softkeyItem = &menu_PFN_1 },
    .{ .menuItem = -1357, .numItems = @as(i16, @intCast(menu_PFN_2.len)), .softkeyItem = &menu_PFN_2 },
    .{ .menuItem = -1362, .numItems = @as(i16, @intCast(menu_STAT.len)), .softkeyItem = &menu_STAT },
    .{ .menuItem = -2107, .numItems = @as(i16, @intCast(menu_PLOTTING.len)), .softkeyItem = &menu_PLOTTING },
    .{ .menuItem = -2374, .numItems = @as(i16, @intCast(menu_GRAPHS.len)), .softkeyItem = &menu_GRAPHS },
    .{ .menuItem = -1395, .numItems = @as(i16, @intCast(menu_PLOT_SCATR.len)), .softkeyItem = &menu_PLOT_SCATR },
    .{ .menuItem = -1396, .numItems = @as(i16, @intCast(menu_PLOT_LR.len)), .softkeyItem = &menu_PLOT_LR },
    .{ .menuItem = -1402, .numItems = @as(i16, @intCast(menu_HPLOT.len)), .softkeyItem = &menu_HPLOT },
    .{ .menuItem = -1401, .numItems = @as(i16, @intCast(menu_HIST.len)), .softkeyItem = &menu_HIST },
    .{ .menuItem = -1363, .numItems = @as(i16, @intCast(menu_STK.len)), .softkeyItem = &menu_STK },
    .{ .menuItem = -1365, .numItems = @as(i16, @intCast(menu_TEST.len)), .softkeyItem = &menu_TEST },
    .{ .menuItem = -1372, .numItems = @as(i16, @intCast(menu_XFN.len)), .softkeyItem = &menu_XFN },
    .{ .menuItem = -1352, .numItems = @as(i16, @intCast(menu_Orthog.len)), .softkeyItem = &menu_Orthog },
    .{ .menuItem = -1397, .numItems = @as(i16, @intCast(menu_Ellipt.len)), .softkeyItem = &menu_Ellipt },
    .{ .menuItem = -1318, .numItems = @as(i16, @intCast(menu_CATALOG.len)), .softkeyItem = &menu_CATALOG },
    .{ .menuItem = -1319, .numItems = @as(i16, @intCast(menu_CHARS.len)), .softkeyItem = &menu_CHARS },
    .{ .menuItem = -1370, .numItems = @as(i16, @intCast(menu_VARS.len)), .softkeyItem = &menu_VARS },
    .{ .menuItem = -1377, .numItems = @as(i16, @intCast(menu_ALPHA_OMEGA.len)), .softkeyItem = &menu_ALPHA_OMEGA },
    .{ .menuItem = -1383, .numItems = @as(i16, @intCast(menu_alpha_omega.len)), .softkeyItem = &menu_alpha_omega },
    .{ .menuItem = -1330, .numItems = @as(i16, @intCast(menu_FCNS.len)), .softkeyItem = &menu_FCNS },
    .{ .menuItem = -1375, .numItems = @as(i16, @intCast(menu_alphaMATH.len)), .softkeyItem = &menu_alphaMATH },
    .{ .menuItem = -1378, .numItems = @as(i16, @intCast(menu_alphaMisc.len)), .softkeyItem = &menu_alphaMisc },
    .{ .menuItem = -1376, .numItems = @as(i16, @intCast(menu_alphaFN.len)), .softkeyItem = &menu_alphaFN },
    .{ .menuItem = -1382, .numItems = @as(i16, @intCast(menu_AngleConv_43S.len)), .softkeyItem = &menu_AngleConv_43S },
    .{ .menuItem = -1369, .numItems = @as(i16, @intCast(menu_UnitConv.len)), .softkeyItem = &menu_UnitConv },
    .{ .menuItem = -1329, .numItems = @as(i16, @intCast(menu_ConvE.len)), .softkeyItem = &menu_ConvE },
    .{ .menuItem = -1358, .numItems = @as(i16, @intCast(menu_ConvP.len)), .softkeyItem = &menu_ConvP },
    .{ .menuItem = -1337, .numItems = @as(i16, @intCast(menu_ConvFP.len)), .softkeyItem = &menu_ConvFP },
    .{ .menuItem = -1351, .numItems = @as(i16, @intCast(menu_ConvM.len)), .softkeyItem = &menu_ConvM },
    .{ .menuItem = -1373, .numItems = @as(i16, @intCast(menu_ConvX.len)), .softkeyItem = &menu_ConvX },
    .{ .menuItem = -1371, .numItems = @as(i16, @intCast(menu_ConvV.len)), .softkeyItem = &menu_ConvV },
    .{ .menuItem = -1316, .numItems = @as(i16, @intCast(menu_ConvA.len)), .softkeyItem = &menu_ConvA },
    .{ .menuItem = -2045, .numItems = @as(i16, @intCast(menu_ConvS.len)), .softkeyItem = &menu_ConvS },
    .{ .menuItem = -2046, .numItems = @as(i16, @intCast(menu_ConvAng.len)), .softkeyItem = &menu_ConvAng },
    .{ .menuItem = -1359, .numItems = @as(i16, @intCast(menu_ConvHum.len)), .softkeyItem = &menu_ConvHum },
    .{ .menuItem = -2222, .numItems = @as(i16, @intCast(menu_ConvYmmv.len)), .softkeyItem = &menu_ConvYmmv },
    .{ .menuItem = -1322, .numItems = @as(i16, @intCast(menu_CONST.len)), .softkeyItem = &menu_CONST },
    .{ .menuItem = -1341, .numItems = @as(i16, @intCast(menu_IO.len)), .softkeyItem = &menu_IO },
    .{ .menuItem = -1315, .numItems = @as(i16, @intCast(menu_PRINT.len)), .softkeyItem = &menu_PRINT },
    .{ .menuItem = -1385, .numItems = @as(i16, @intCast(menu_Tam.len)), .softkeyItem = &menu_Tam },
    .{ .menuItem = -1386, .numItems = @as(i16, @intCast(menu_TamCmp.len)), .softkeyItem = &menu_TamCmp },
    .{ .menuItem = -1387, .numItems = @as(i16, @intCast(menu_TamSto.len)), .softkeyItem = &menu_TamSto },
    .{ .menuItem = -2066, .numItems = @as(i16, @intCast(menu_Reg.len)), .softkeyItem = &menu_Reg },
    .{ .menuItem = -1391, .numItems = @as(i16, @intCast(menu_TamShuffle.len)), .softkeyItem = &menu_TamShuffle },
    .{ .menuItem = -1393, .numItems = @as(i16, @intCast(menu_TamLabel.len)), .softkeyItem = &menu_TamLabel },
    .{ .menuItem = -1399, .numItems = @as(i16, @intCast(menu_Eim.len)), .softkeyItem = &menu_Eim },
    .{ .menuItem = -1400, .numItems = @as(i16, @intCast(menu_Timer.len)), .softkeyItem = &menu_Timer },
    .{ .menuItem = -1455, .numItems = @as(i16, @intCast(menu_DELITM.len)), .softkeyItem = &menu_DELITM },
    .{ .menuItem = -1920, .numItems = @as(i16, @intCast(menu_ASN_N.len)), .softkeyItem = &menu_ASN_N },
    .{ .menuItem = -1927, .numItems = @as(i16, @intCast(menu_KEYS.len)), .softkeyItem = &menu_KEYS },
    .{ .menuItem = -1901, .numItems = @as(i16, @intCast(menu_ConvChef.len)), .softkeyItem = &menu_ConvChef },
    .{ .menuItem = -2028, .numItems = @as(i16, @intCast(menu_PLOTFUNC.len)), .softkeyItem = &menu_PLOTFUNC },
    .{ .menuItem = -1922, .numItems = @as(i16, @intCast(menu_ALPHA.len)), .softkeyItem = &menu_ALPHA },
    .{ .menuItem = -1923, .numItems = @as(i16, @intCast(menu_BASE.len)), .softkeyItem = &menu_BASE },
    .{ .menuItem = -1925, .numItems = @as(i16, @intCast(menu_EE.len)), .softkeyItem = &menu_EE },
    .{ .menuItem = -1912, .numItems = @as(i16, @intCast(menu_TamRcl.len)), .softkeyItem = &menu_TamRcl },
    .{ .menuItem = -2036, .numItems = @as(i16, @intCast(menu_TRG.len)), .softkeyItem = &menu_TRG },
    .{ .menuItem = -2037, .numItems = @as(i16, @intCast(menu_PREF.len)), .softkeyItem = &menu_PREF },
    .{ .menuItem = -2080, .numItems = @as(i16, @intCast(menu_REGR.len)), .softkeyItem = &menu_REGR },
    .{ .menuItem = -2081, .numItems = @as(i16, @intCast(menu_MODEL.len)), .softkeyItem = &menu_MODEL },
    .{ .menuItem = -1860, .numItems = @as(i16, @intCast(menu_Misc.len)), .softkeyItem = &menu_Misc },
    .{ .menuItem = -1277, .numItems = @as(i16, @intCast(menu_StdNorml.len)), .softkeyItem = &menu_StdNorml },
    .{ .menuItem = -1913, .numItems = @as(i16, @intCast(menu_TamAlpha.len)), .softkeyItem = &menu_TamAlpha },
    .{ .menuItem = -2102, .numItems = @as(i16, @intCast(menu_TRG_C47.len)), .softkeyItem = &menu_TRG_C47 },
    .{ .menuItem = -2103, .numItems = @as(i16, @intCast(menu_TRG_C47_MORE.len)), .softkeyItem = &menu_TRG_C47_MORE },
    .{ .menuItem = -2068, .numItems = @as(i16, @intCast(menu_TamNonReg.len)), .softkeyItem = &menu_TamNonReg },
    .{ .menuItem = -2108, .numItems = @as(i16, @intCast(menu_TamIndirect.len)), .softkeyItem = &menu_TamIndirect },
    .{ .menuItem = -1448, .numItems = @as(i16, @intCast(menu_BLUE_C47.len)), .softkeyItem = &menu_BLUE_C47 },
    .{ .menuItem = -2151, .numItems = @as(i16, @intCast(menu_GAP_L.len)), .softkeyItem = &menu_GAP_L },
    .{ .menuItem = -2152, .numItems = @as(i16, @intCast(menu_GAP_RX.len)), .softkeyItem = &menu_GAP_RX },
    .{ .menuItem = -2153, .numItems = @as(i16, @intCast(menu_GAP_R.len)), .softkeyItem = &menu_GAP_R },
    .{ .menuItem = -2229, .numItems = @as(i16, @intCast(menu_PREFIX.len)), .softkeyItem = &menu_PREFIX },
    .{ .menuItem = -2233, .numItems = 0, .softkeyItem = null },
    .{ .menuItem = -2234, .numItems = @as(i16, @intCast(menu_RESETS.len)), .softkeyItem = &menu_RESETS },
    .{ .menuItem = -2235, .numItems = @as(i16, @intCast(menu_RIBBONS.len)), .softkeyItem = &menu_RIBBONS },
    .{ .menuItem = -1883, .numItems = @as(i16, @intCast(menu_Inl_Tst.len)), .softkeyItem = &menu_Inl_Tst },
    .{ .menuItem = -2243, .numItems = @as(i16, @intCast(menu_DELETE.len)), .softkeyItem = &menu_DELETE },
    .{ .menuItem = -2244, .numItems = @as(i16, @intCast(menu_YESNO.len)), .softkeyItem = &menu_YESNO },
    .{ .menuItem = -1237, .numItems = @as(i16, @intCast(menu_DISTR.len)), .softkeyItem = &menu_DISTR },
    .{ .menuItem = -2067, .numItems = @as(i16, @intCast(menu_Flg.len)), .softkeyItem = &menu_Flg },
    .{ .menuItem = -2315, .numItems = @as(i16, @intCast(menu_SHOW.len)), .softkeyItem = &menu_SHOW },
    .{ .menuItem = -2376, .numItems = @as(i16, @intCast(menu_Solver_TOOL.len)), .softkeyItem = &menu_Solver_TOOL },
    .{ .menuItem = -2375, .numItems = @as(i16, @intCast(menu_Sf_TOOL.len)), .softkeyItem = &menu_Sf_TOOL },
    .{ .menuItem = -2381, .numItems = @as(i16, @intCast(menu_CASHFL.len)), .softkeyItem = &menu_CASHFL },
    .{ .menuItem = -2382, .numItems = @as(i16, @intCast(menu_AMORT.len)), .softkeyItem = &menu_AMORT },
    .{ .menuItem = -1388, .numItems = @as(i16, @intCast(menu_Grapher.len)), .softkeyItem = &menu_Grapher },
    .{ .menuItem = -2390, .numItems = @as(i16, @intCast(menu_AUDIO.len)), .softkeyItem = &menu_AUDIO },
    .{ .menuItem = -2109, .numItems = @as(i16, @intCast(menu_TamNonRegMax.len)), .softkeyItem = &menu_TamNonRegMax },
    .{ .menuItem = -2403, .numItems = @as(i16, @intCast(menu_PFN_3.len)), .softkeyItem = &menu_PFN_3 },
    .{ .menuItem = -2406, .numItems = @as(i16, @intCast(menu_TamMenu.len)), .softkeyItem = &menu_TamMenu },
    .{ .menuItem = -2414, .numItems = @as(i16, @intCast(menu_NUMTHEORY.len)), .softkeyItem = &menu_NUMTHEORY },
    .{ .menuItem = -1907, .numItems = @as(i16, @intCast(menu_PLOT_STAT.len)), .softkeyItem = &menu_PLOT_STAT },
    .{ .menuItem = -2238, .numItems = @as(i16, @intCast(menu_TamNonRegTrk.len)), .softkeyItem = &menu_TamNonRegTrk },
    .{ .menuItem = -1286, .numItems = @as(i16, @intCast(menu_Pareto.len)), .softkeyItem = &menu_Pareto },
    .{ .menuItem = -2499, .numItems = @as(i16, @intCast(menu_VECCONV.len)), .softkeyItem = &menu_VECCONV },
    .{ .menuItem = -1881, .numItems = @as(i16, @intCast(menu_BITSET.len)), .softkeyItem = &menu_BITSET },
    .{ .menuItem = -2552, .numItems = @as(i16, @intCast(menu_AIMCATALOG.len)), .softkeyItem = &menu_AIMCATALOG },
    .{ .menuItem = -2227, .numItems = @as(i16, @intCast(menu_EIMCATALOG.len)), .softkeyItem = &menu_EIMCATALOG },
    .{ .menuItem = -2228, .numItems = @as(i16, @intCast(menu_FCNS_EIM.len)), .softkeyItem = &menu_FCNS_EIM },
    .{ .menuItem = -2596, .numItems = @as(i16, @intCast(menu_XXFCNS.len)), .softkeyItem = &menu_XXFCNS },
    .{ .menuItem = -2597, .numItems = @as(i16, @intCast(menu_MULTSTK.len)), .softkeyItem = &menu_MULTSTK },
    .{ .menuItem = -2226, .numItems = @as(i16, @intCast(menu_TamLabelOnly.len)), .softkeyItem = &menu_TamLabelOnly },
    .{ .menuItem = -2225, .numItems = @as(i16, @intCast(menu_TamVarOnly.len)), .softkeyItem = &menu_TamVarOnly },
    .{ .menuItem = -2600, .numItems = @as(i16, @intCast(menu_Uniform.len)), .softkeyItem = &menu_Uniform },
    .{ .menuItem = -2605, .numItems = @as(i16, @intCast(menu_DisUniform.len)), .softkeyItem = &menu_DisUniform },
    .{ .menuItem = -2625, .numItems = @as(i16, @intCast(menu_Dev.len)), .softkeyItem = &menu_Dev },
    .{ .menuItem = -2638, .numItems = @as(i16, @intCast(menu_TamStoTVM.len)), .softkeyItem = &menu_TamStoTVM },
    .{ .menuItem = -2639, .numItems = @as(i16, @intCast(menu_TamRclTVM.len)), .softkeyItem = &menu_TamRclTVM },
    .{ .menuItem = -2047, .numItems = @as(i16, @intCast(menu_ConvTemp.len)), .softkeyItem = &menu_ConvTemp },
    .{ .menuItem = -2681, .numItems = @as(i16, @intCast(menu_Printer.len)), .softkeyItem = &menu_Printer },
    .{ .menuItem = -2106, .numItems = @as(i16, @intCast(menu_VECT.len)), .softkeyItem = &menu_VECT },
    .{ .menuItem = -2711, .numItems = @as(i16, @intCast(menu_TamNorm.len)), .softkeyItem = &menu_TamNorm },
    .{ .menuItem = -2736, .numItems = @as(i16, @intCast(menu_Base2.len)), .softkeyItem = &menu_Base2 },
    .{ .menuItem = -2738, .numItems = @as(i16, @intCast(menu_42.len)), .softkeyItem = &menu_42 },
    .{ .menuItem = 0, .numItems = 0, .softkeyItem = null },
};
// dynamicSoftmenu is a MUTABLE RAM global in C (softmenus.c:1164, written at
// runtime by _dynmenuConstructUser etc.), NOT a TO_QSPI const. It must stay in
// the normal writable data section -- code_data_section is read-only
// (__DATA_CONST on macOS / .text on Windows+Linux), so writing to it there
// faults (EXC_BAD_ACCESS code=2 on macOS, access violation on Windows).
pub export var dynamicSoftmenu = [_]dynamicSoftmenu_t{
    .{ .menuItem = -1349, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1350, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1355, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1389, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1392, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1343, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1364, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1325, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1366, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1314, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1332, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1338, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1360, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1324, .numItems = 0, .menuContent = null },
    .{ .menuItem = -2230, .numItems = 0, .menuContent = null },
    .{ .menuItem = -2231, .numItems = 0, .menuContent = null },
    .{ .menuItem = -2232, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1398, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1345, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1394, .numItems = 0, .menuContent = null },
    .{ .menuItem = -1520, .numItems = 0, .menuContent = null },
    .{ .menuItem = -2407, .numItems = 0, .menuContent = null },
};

// Additional probe-resolved constants for function bodies.
const MNU_M_EDIT = 1348;
const MNU_TAMALPHA = 1913;
const STD_WCOMMA: [*:0]const u8 = "\xa7\x88";

const DO_compress = 1;
const NO_raise = 0;
const NO_Show = 1;
const DO_Show = 0;
const NO_Bold = 0;
const NO_LF = 0;
const CATALOG_aint = 6;
const FLAG_CPXj = 32773;
const FLAG_MNUp1 = 32854;
const FLAG_MULTx = 32795;
const ITM_3x1TOSTK = 2041;
const ITM_BITSp2 = 2553;
const ITM_CLKp2 = 2500;
const ITM_PLTFCNS = 2852;
const ITM_CPXexV = 2492;
const ITM_Ek = 1727;
const ITM_Ephik = 1764;
const ITM_Fphik = 1763;
const ITM_Kk = 1726;
const ITM_KtoM = 2104;
const ITM_Lm = 1505;
const ITM_LmALPHA = 1506;
const ITM_MtoK = 2105;
const ITM_MtoTH = 2598;
const ITM_PInk = 1728;
const ITM_Pn = 1550;
const ITM_SIGMAk = 2411;
const ITM_SIGMAp1 = 2412;
const ITM_SIGMApk = 2413;
const ITM_STKTO3x1 = 1931;
const ITM_STORCL_CPERonA = 2646;
const ITM_STORCL_IPonA = 2641;
const ITM_STORCL_PPERonA = 2645;
const ITM_THtoM = 2599;
const ITM_Tn = 1623;
const ITM_Un = 1627;
const ITM_V3toCYL = 2470;
const ITM_V3toSPH = 2471;
const ITM_ZETAphik = 1765;
const ITM_am = 1584;
const ITM_chi2M1 = 1276;
const ITM_chi2Px = 1273;
const ITM_chi2ux = 1275;
const ITM_chi2x = 1274;
const ITM_cn = 1683;
const ITM_dn = 1684;
const ITM_sn = 1682;
const ITM_stkexV2 = 2495;
const ITM_stkexV3 = 2496;
const MNU_MyMenu = 1349;
const RESERVED_VARIABLE_ACC = 2031;
const VAR_CPERonA = 2379;
const VAR_IPonA = 1196;
const VAR_PPERonA = 1198;

// ---------------------------------------------------------------------------
// Small C-macro helpers reproduced inline.
// ---------------------------------------------------------------------------
inline fn TO_BLOCKS(n: i32) u16 {
    return @intCast((n + 3) >> 2); // BYTES_PER_BLOCK = 4, BPB = 2
}
inline fn cmod(n: i32, d: i32) i32 {
    // mod(n,d) = ((n%d + d) % d)
    return @mod(@rem(n, d) + d, d);
}
inline fn modulo(n: i32, d: i32) i32 {
    // modulo(n,d): only valid for d>0 = (n%d<0 ? n%d+d : n%d)
    const r = @rem(n, d);
    return if (r < 0) r + d else r;
}
inline fn maxI(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}
inline fn minI(a: i32, b: i32) i32 {
    return if (a < b) a else b;
}
inline fn REGISTER_REAL34_DATA(a: calcRegister_t) *real34_t {
    return @ptrCast(@alignCast(getRegisterDataPointer(a)));
}
inline fn REGISTER_STRING_DATA(a: calcRegister_t) [*c]u8 {
    // dataLen is sizeof(strLgIntHeader_t) = 4 bytes.
    return getRegisterDataPointer(a) + 4;
}
inline fn IS_BASEBLANK_(menuId: i16) bool {
    return menuId == 0 and getSystemFlag(FLAG_BASE_MYM) == 0 and getSystemFlag(FLAG_BASE_HOME) == 0;
}
inline fn GRAPHMODE() bool {
    return calcMode == CM_PLOT_STAT or calcMode == CM_GRAPH;
}
inline fn BLOCK_DOUBLEPRESS_MENU(m: i16, x: i32, y: i32) bool {
    return (m == -MNU_ALPHA and y == 0 and (x == 4 or x == 5)) or
        (m == -MNU_M_EDIT and y == 0 and (x == 4 or x == 5)) or
        (m == -MNU_EQ_EDIT and y == 0 and (x == 4 or x == 5)) or
        (m == -MNU_TAMALPHA and y == 0 and (x == 4 or x == 5));
}
// RADIX34_MARK_CHAR: maps comma / wide-comma to ',' else '.'.
inline fn RADIX34_MARK_CHAR() u8 {
    const rx: [*c]const u8 = &indexOfItems[@intCast(gapItemRadix)].itemSoftmenuName;
    if (rx[0] == ',' or (rx[0] == STD_WCOMMA[0] and rx[1] == STD_WCOMMA[1])) {
        return ',';
    }
    return '.';
}

// ---------------------------------------------------------------------------
// getNthString: advance past n NUL-terminated strings.
// ---------------------------------------------------------------------------
pub export fn getNthString(ptr_in: [*c]u8, n_in: i16) callconv(.c) [*c]u8 {
    var ptr = ptr_in;
    var n = n_in;
    while (n != 0) {
        ptr += @as(usize, @intCast(stringByteLength(ptr) + 1));
        n -= 1;
    }
    return ptr;
}

// fnDynamicMenu is owned elsewhere; the two bridge helpers read its inputs.
pub export fn z47_frontier_dynamic_menu_softmenu_id() callconv(.c) i16 {
    return softmenuStack[0].softmenuId;
}
pub export fn z47_frontier_dynamic_menu_item() callconv(.c) i16 {
    return dynamicMenuItem;
}

// Forward declarations (static in C).
// (Zig resolves these automatically since all live in this file.)

pub export fn fnOpenMenu(menuArg: u16) callconv(.c) void {
    var i: i16 = 0;
    var numItems: i16 = 0;
    i = 0;
    while (softmenu[@intCast(i)].menuItem != 0) {
        if (softmenu[@intCast(i)].menuItem == -%@as(i16, @bitCast(menuArg))) {
            if (i < NUMBER_OF_DYNAMIC_SOFTMENUS) {
                initVariableSoftmenu(i);
                numItems = dynamicSoftmenu[@intCast(i)].numItems;
            } else {
                numItems = softmenu[@intCast(i)].numItems;
            }
            break;
        }
        i += 1;
    }

    if (softmenu[@intCast(i)].menuItem == 0) {
        displayCalcErrorMessage(ERROR_UNDEF_MENU, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "menuArg '%d' is not a valid menuArg item", @as(c_int, @intCast(menuArg)));
            moreInfoOnError("In function fnOpenMenu:", errorMessage, null, null);
        }
        menuPageNumber = 1;
        return;
    }

    const numItems32: i32 = numItems;
    const mpn: i32 = menuPageNumber;
    if ((mpn > 0) and (mpn <= 9) and ((numItems32 > 18 * (mpn - 1)) or ((numItems32 == 0) and (mpn == 1)))) {
        if (menuArg == MNU_DYNAMIC) {
            i = 0;
            while (i < @as(i16, @intCast(numberOfUserMenus))) : (i += 1) {
                if (compareString(tmpString, &userMenus[@intCast(i)].menuName, CMP_NAME) == 0) {
                    currentUserMenu = @intCast(i);
                    break;
                }
            }
        }
        enterAsmModeIfMenuIsACatalog(-%@as(i16, @bitCast(menuArg)));
        if (menuArg == MNU_CONVCHEF or menuArg == MNU_CONVV) {
            lastCatalogPosition[@intCast(catalog)] = if (getSystemFlag(FLAG_US) != 0) 18 else 0;
        } else {
            lastCatalogPosition[@intCast(catalog)] = @intCast(18 * (mpn - 1));
        }
        showSoftmenu(-%@as(i16, @bitCast(menuArg)));
        lastCatalogPosition[CATALOG_NONE] = 0;
    } else {
        if (getSystemFlag(FLAG_IGN1ER) != 0) {
            clearSystemFlag(FLAG_IGN1ER);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "Page Number %u is not a valid page for the menuArg %u", @as(c_uint, menuPageNumberU()), @as(c_uint, menuArg));
                moreInfoOnError("In function fnOpenMenu:", errorMessage, "ignored since IGN1ER system flag was set", null);
            }
        } else {
            displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "Page Number %u is not a valid page for the menuArg %u", @as(c_uint, menuPageNumberU()), @as(c_uint, menuArg));
                moreInfoOnError("In function fnOpenMenu:", errorMessage, null, null);
            }
        }
    }
    menuPageNumber = 1;
}
inline fn menuPageNumberU() u16 {
    return @bitCast(menuPageNumber);
}

pub export fn _stripMenuName(buffer: [*c]u8, name: [*c]u8) callconv(.c) void {
    var i: usize = 0;
    menuPageNumber = 1;
    while (buffer[i] != 0) {
        if ((buffer[i] == STD_CR[0]) and (buffer[i + 1] == STD_CR[1])) {
            if ((buffer[i + 3] == 0) and (buffer[i + 2] > STD_0[0]) and (buffer[i + 2] <= STD_9[0])) {
                name[i] = 0;
                menuPageNumber = @intCast(@as(i32, buffer[i + 2]) - @as(i32, STD_0[0]));
            } else {
                menuPageNumber = 0;
            }
            break;
        } else {
            name[i] = buffer[i];
            i += 1;
        }
    }
    name[i] = 0;
}

pub export fn findMenu(buffer: [*c]u8) callconv(.c) i16 {
    var menu_id: i16 = INVALID_MENU;
    var name: [16]u8 = undefined;
    var i: i16 = undefined;
    var menuItem: i16 = undefined;
    var found: bool = false;

    _stripMenuName(buffer, &name);

    i = 0;
    menuItem = MNU_MyMenu;

    while (menuItem != 0) {
        if ((indexOfItems[@intCast(menuItem)].status & CAT_STATUS) == CAT_MENU) {
            if (compareString(&name, &indexOfItems[@intCast(menuItem)].itemCatalogName, CMP_CLEANED_STRING_ONLY) == 0) {
                found = true;
                menu_id = menuItem;
                break;
            }
        }
        i += 1;
        menuItem = -%softmenu[@intCast(i)].menuItem;
    }

    if (!found) {
        i = 0;
        while (i < @as(i16, @intCast(numberOfUserMenus))) : (i += 1) {
            if (compareString(&name, &userMenus[@intCast(i)].menuName, CMP_NAME) == 0) {
                const len: i16 = @intCast(stringByteLength(&name) + 1);
                found = true;
                menu_id = MNU_DYNAMIC;
                _ = xcopy(tmpString, &name, @intCast(len));
                break;
            }
        }
    }

    if (!found) {
        i = 0;
        menuItem = MNU_MyMenu;
        while (menuItem != 0) {
            if ((indexOfItems[@intCast(menuItem)].status & CAT_STATUS) == CAT_MNUH) {
                if (compareString(&name, &indexOfItems[@intCast(menuItem)].itemCatalogName, CMP_CLEANED_STRING_ONLY) == 0) {
                    found = true;
                    menu_id = menuItem;
                    break;
                }
            }
            i += 1;
            menuItem = -%softmenu[@intCast(i)].menuItem;
        }
    }

    if (menu_id == INVALID_MENU) {
        menuPageNumber = 1;
    }
    return menu_id;
}

pub export fn _add_digitglyph(tmp: [*c]u8, xx: i16) callconv(.c) void {
    tmp[0] = 0;
    _ = stringCopy(tmp, STD_0);
    if (xx >= 1 and xx <= 9) {
        tmp[0] +%= @intCast(xx);
    }
}

pub export fn fnGetMenu(_: u16) callconv(.c) void {
    var lenInBytes: i16 = undefined;
    const menuItem: i16 = -%softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem;
    const userMenuId: i16 = softmenuStack[0].userMenuId;
    var menuName: [12]u8 = undefined;
    var firstItem: i16 = undefined;

    liftStack();
    setSystemFlag(FLAG_ASLIFT);

    if (menuItem != MNU_DYNAMIC) {
        lenInBytes = @intCast(stringByteLength(&indexOfItems[@intCast(menuItem)].itemCatalogName) + 1);
        _ = xcopy(&menuName, &indexOfItems[@intCast(menuItem)].itemCatalogName, @intCast(lenInBytes));
        firstItem = softmenuStack[0].firstItem;
        if (firstItem >= 18) {
            var tmp: [16]u8 = undefined;
            lenInBytes -= 1;
            menuName[@intCast(lenInBytes)] = STD_CR[0];
            lenInBytes += 1;
            menuName[@intCast(lenInBytes)] = STD_CR[1];
            lenInBytes += 1;
            menuName[@intCast(lenInBytes)] = 0;
            _add_digitglyph(&tmp, @intCast(@divTrunc(@as(i32, firstItem), 18) + 1));
            _ = stringCopy(@ptrCast(&menuName[@intCast(stringByteLength(&menuName))]), &tmp);
            lenInBytes = @intCast(stringByteLength(&menuName) + 1);
        }
        reallocateRegister(REGISTER_X, dtString, TO_BLOCKS(lenInBytes), amNone);
        if (lastErrorCode == ERROR_RAM_FULL) {
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            fnUndo(NOPARAM);
            return;
        }
        _ = xcopy(REGISTER_STRING_DATA(REGISTER_X), &menuName, @intCast(lenInBytes));
    } else {
        lenInBytes = @intCast(stringByteLength(&userMenus[@intCast(userMenuId)].menuName) + 1);
        reallocateRegister(REGISTER_X, dtString, TO_BLOCKS(lenInBytes), amNone);
        if (lastErrorCode == ERROR_RAM_FULL) {
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            fnUndo(NOPARAM);
            return;
        }
        _ = xcopy(REGISTER_STRING_DATA(REGISTER_X), &userMenus[@intCast(userMenuId)].menuName, @intCast(lenInBytes));
    }
}

fn sortMenu(a: ?*const anyopaque, b: ?*const anyopaque) callconv(.c) c_int {
    return compareString(@ptrCast(a), @ptrCast(b), CMP_EXTENSIVE);
}

fn _filterDataType(regist: calcRegister_t, typeFilter: dataType_t, isAngular: bool_t) bool_t {
    const dt: dataType_t = getRegisterDataType(regist);
    if (dt != dtReal34 and dt == typeFilter) {
        return 1;
    }
    if (typeFilter == dtReal34Matrix and dt == dtComplex34Matrix) {
        return 1;
    }
    if (typeFilter == dtReal34 and dt == dtReal34) {
        if (isAngular != 0) {
            return @intFromBool(getRegisterAngularMode(regist) != amNone);
        }
        if (isAngular == 0) {
            return @intFromBool(getRegisterAngularMode(regist) == amNone);
        }
    }
    if (typeFilter == dtNumbers and (dt == dtLongInteger or dt == dtReal34 or dt == dtComplex34)) {
        return 1;
    }
    return 0;
}

fn _dynmenuConstructVars(mIdx: i16, applyFilter: bool_t, typeFilter: dataType_t, isAngular: bool_t) void {
    var numberOfBytes: u16 = 1;
    var numberOfVars: u16 = 0;
    _ = memset(tmpString, 0, TMP_STR_LENGTH);
    {
        var i: i32 = 0;
        while (i < @as(i32, numberOfNamedVariables)) : (i += 1) {
            const regist: calcRegister_t = @intCast(i + FIRST_NAMED_VARIABLE);
            if (applyFilter == 0 or _filterDataType(regist, typeFilter, isAngular) != 0) {
                const nv = &allNamedVariables[@intCast(i)];
                _ = xcopy(&tmpString[15 * @as(usize, numberOfVars)], &nv.variableName[1], nv.variableName[0]);
                const cur: [*c]u8 = &tmpString[15 * @as(usize, numberOfVars)];
                if ((softmenu[@intCast(softmenuStack[2].softmenuId)].menuItem == -%@as(i16, ITM_DELITM)) and
                    ((compareString(cur, "STATS", CMP_NAME) == 0) or (compareString(cur, "HISTO", CMP_NAME) == 0) or
                        (compareString(cur, "Mat_A", CMP_NAME) == 0) or (compareString(cur, "Mat_B", CMP_NAME) == 0) or
                        (compareString(cur, "Mat_X", CMP_NAME) == 0)))
                {
                    _ = memset(cur, 0, 15);
                } else {
                    numberOfVars += 1;
                    numberOfBytes += 1 + @as(u16, nv.variableName[0]);
                }
            }
        }
    }
    if (softmenu[@intCast(softmenuStack[2].softmenuId)].menuItem != -%@as(i16, ITM_DELITM)) {
        var i: i32 = FIRST_NAMED_RESERVED_VARIABLE - FIRST_RESERVED_VARIABLE;
        while (i < NUMBER_OF_RESERVED_VARIABLES) : (i += 1) {
            const regist: calcRegister_t = @intCast(i + FIRST_RESERVED_VARIABLE);
            const rv = &allReservedVariables[@intCast(i)];
            if (((rv.header.bits >> 26) & 0x3F) != 0) {
                continue;
            }
            if (applyFilter == 0 or _filterDataType(regist, typeFilter, isAngular) != 0) {
                _ = xcopy(&tmpString[15 * @as(usize, numberOfVars)], &rv.reservedVariableName[1], rv.reservedVariableName[0]);
                numberOfVars += 1;
                numberOfBytes += 1 + @as(u16, rv.reservedVariableName[0]);
            }
        }
    }

    if (numberOfVars != 0) {
        qsort(tmpString, numberOfVars, 15, &sortMenu);
    }

    var ptr: [*c]u8 = malloc(numberOfBytes);
    dynamicSoftmenu[@intCast(mIdx)].menuContent = ptr;
    {
        var i: i32 = 0;
        while (i < @as(i32, numberOfVars)) : (i += 1) {
            const len: i16 = @intCast(stringByteLength(&tmpString[15 * @as(usize, @intCast(i))]) + 1);
            _ = xcopy(ptr, &tmpString[15 * @as(usize, @intCast(i))], @intCast(len));
            ptr += @intCast(len);
        }
    }
    dynamicSoftmenu[@intCast(mIdx)].numItems = @intCast(numberOfVars);
}

fn _dynmenuConstructMVarsFromPgm(label: u16, numberOfBytes: *u16, numberOfVars: *u16) void {
    var step: [*c]u8 = labelList[label].instructionPointer;
    while (numberOfVars.* < 18) {
        // Skip any user REM so a REM before an MVAR is transparent to the MVAR
        // count (matches C); a non-REM non-MVAR step (or .END) ends the count.
        while (checkOpCodeOfStep(step, ITM_REM) != 0) {
            step = findNextStep(step);
        }
        if (!(checkOpCodeOfStep(step, ITM_MVAR) != 0 and step[2] == STRING_LABEL_VARIABLE)) {
            break;
        }
        const varNameLen = boundProgramNameLength(step + 4, step[3]);
        _ = xcopy(&tmpString[numberOfBytes.*], step + 4, varNameLen);
        _ = findOrAllocateNamedVariable(&tmpString[numberOfBytes.*]);
        numberOfBytes.* += @as(u16, varNameLen) + 1;
        numberOfVars.* += 1;
        step = findNextStep(step);
    }
}

fn _dynmenuConstructMVars(mIdx: i16) void {
    var numberOfBytes: u16 = 0;
    var numberOfVars: u16 = 0;
    _ = memset(tmpString, 0, TMP_STR_LENGTH);

    if (currentMvarLabel != INVALID_VARIABLE) {
        _dynmenuConstructMVarsFromPgm(@intCast(currentMvarLabel - FIRST_LABEL), &numberOfBytes, &numberOfVars);
    } else if ((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) != 0) {
        var bufPtr: [*c]u8 = tmpString;
        const errorCode: u8 = lastErrorCode;
        lastErrorCode = ERROR_NONE;
        _ = parseEquation(currentFormula, EQUATION_PARSER_MVAR, &tmpString[TMP_STR_LENGTH - AIM_BUFFER_LENGTH], tmpString);
        while (bufPtr[0] != 0 or numberOfVars < 6) {
            numberOfVars += 1;
            numberOfBytes +%= @intCast(stringByteLength(bufPtr) + 1);
            bufPtr += @intCast(stringByteLength(bufPtr) + 1);
        }
        lastErrorCode = errorCode;
    } else {
        _dynmenuConstructMVarsFromPgm(currentSolverProgram, &numberOfBytes, &numberOfVars);
    }

    dynamicSoftmenu[@intCast(mIdx)].menuContent = malloc(numberOfBytes);
    _ = xcopy(dynamicSoftmenu[@intCast(mIdx)].menuContent, tmpString, numberOfBytes);
    dynamicSoftmenu[@intCast(mIdx)].numItems = @intCast(numberOfVars);
}

fn _dynmenuConstructUser(mIdx: i16) void {
    const menuData: [*c]userMenuItem_t = if (dynamicSoftmenu[@intCast(mIdx)].menuItem == -%@as(i16, MNU_DYNAMIC))
        &userMenus[@intCast(currentUserMenu)].menuItem
    else if (dynamicSoftmenu[@intCast(mIdx)].menuItem == -%@as(i16, MNU_MyAlpha))
        userAlphaItems
    else
        userMenuItems;
    var numberOfBytes: i16 = 1;
    var ptr: [*c]u8 = undefined;

    {
        var i: i16 = 0;
        while (i < 18) : (i += 1) {
            const md = menuData[@intCast(i)];
            if (md.argumentName[0] != 0) {
                numberOfBytes += @intCast(stringByteLength(&md.argumentName) + 1);
            } else if (md.item == ITM_NOP or md.item == ITM_NULL) {
                numberOfBytes += 1;
            } else if (indexOfItems[@intCast(cabs(md.item))].itemCatalogName[0] == 0 or (md.item == ITM_op_j or md.item == ITM_op_j_pol or md.item == ITM_op_a or md.item == ITM_op_a2)) {
                numberOfBytes += @intCast(stringByteLength(&indexOfItems[@intCast(cabs(md.item))].itemSoftmenuName) + 1);
            } else {
                numberOfBytes += @intCast(stringByteLength(&indexOfItems[@intCast(cabs(md.item))].itemCatalogName) + 1);
            }
        }
    }
    ptr = malloc(@intCast(numberOfBytes));
    dynamicSoftmenu[@intCast(mIdx)].menuContent = ptr;
    {
        var i: i16 = 0;
        while (i < 18) : (i += 1) {
            const md = menuData[@intCast(i)];
            var lbl: [*c]const u8 = undefined;
            if (md.argumentName[0] != 0) {
                lbl = &md.argumentName;
            } else if (md.item == ITM_NULL) {
                lbl = "";
            } else if (indexOfItems[@intCast(cabs(md.item))].itemCatalogName[0] == 0 or (md.item == ITM_op_j or md.item == ITM_op_j_pol or md.item == ITM_op_a or md.item == ITM_op_a2)) {
                lbl = &indexOfItems[@intCast(cabs(md.item))].itemSoftmenuName;
            } else {
                lbl = &indexOfItems[@intCast(cabs(md.item))].itemCatalogName;
            }
            const len: i16 = @intCast(stringByteLength(lbl) + 1);
            _ = xcopy(ptr, lbl, @intCast(len));
            ptr += @intCast(len);
        }
    }
    dynamicSoftmenu[@intCast(mIdx)].numItems = if (numberOfBytes <= 19) 0 else 18;
}
inline fn cabs(x: i16) i16 {
    return if (x < 0) -x else x;
}

fn initVariableSoftmenu(mIdx: i16) void {
    var i: i16 = undefined;
    var numberOfBytes: i16 = undefined;
    var numberOfGlobalLabels: i16 = undefined;
    var ptr: [*c]u8 = undefined;

    free(dynamicSoftmenu[@intCast(mIdx)].menuContent);

    switch (-%dynamicSoftmenu[@intCast(mIdx)].menuItem) {
        MNU_MyAlpha => _dynmenuConstructUser(mIdx),
        MNU_MyMenu => _dynmenuConstructUser(mIdx),
        MNU_VAR => _dynmenuConstructVars(mIdx, 0, 0, 0),
        MNU_PROG, MNU_PROGS => {
            numberOfBytes = 1;
            numberOfGlobalLabels = 0;
            _ = memset(tmpString, 0, TMP_STR_LENGTH);
            i = 0;
            while (i < @as(i16, @bitCast(numberOfLabels))) : (i += 1) {
                if (labelList[@intCast(i)].step > 0) {
                    var lblNameLen: u8 = labelList[@intCast(i)].labelPointer[0];
                    if (lblNameLen > 14) { // this menu lays each name out in a fixed 15-byte slot
                        lblNameLen = 14;
                    }
                    _ = xcopy(&tmpString[15 * @as(usize, @intCast(numberOfGlobalLabels))], labelList[@intCast(i)].labelPointer + 1, lblNameLen);
                    numberOfGlobalLabels += 1;
                    numberOfBytes += 1 + @as(i16, lblNameLen);
                }
            }
            if (numberOfGlobalLabels != 0) {
                qsort(tmpString, @intCast(numberOfGlobalLabels), 15, &sortMenu);
            }
            ptr = malloc(@intCast(numberOfBytes));
            dynamicSoftmenu[@intCast(mIdx)].menuContent = ptr;
            i = 0;
            while (i < numberOfGlobalLabels) : (i += 1) {
                const len: i16 = @intCast(stringByteLength(&tmpString[15 * @as(usize, @intCast(i))]) + 1);
                _ = xcopy(ptr, &tmpString[15 * @as(usize, @intCast(i))], @intCast(len));
                ptr += @intCast(len);
            }
            dynamicSoftmenu[@intCast(mIdx)].numItems = numberOfGlobalLabels;
        },
        MNU_MATRS => _dynmenuConstructVars(mIdx, 1, dtReal34Matrix, 0),
        MNU_STRINGS => _dynmenuConstructVars(mIdx, 1, dtString, 0),
        MNU_DATES => _dynmenuConstructVars(mIdx, 1, dtDate, 0),
        MNU_TIMES => _dynmenuConstructVars(mIdx, 1, dtTime, 0),
        MNU_ANGLES => _dynmenuConstructVars(mIdx, 1, dtReal34, 1),
        MNU_SINTS => _dynmenuConstructVars(mIdx, 1, dtShortInteger, 0),
        MNU_LINTS => _dynmenuConstructVars(mIdx, 1, dtLongInteger, 0),
        MNU_REALS => _dynmenuConstructVars(mIdx, 1, dtReal34, 0),
        MNU_CPXS => _dynmenuConstructVars(mIdx, 1, dtComplex34, 0),
        MNU_NUMBRS => _dynmenuConstructVars(mIdx, 1, dtNumbers, 0),
        MNU_CONFIGS => _dynmenuConstructVars(mIdx, 1, dtConfig, 0),
        MNU_ALLVARS => _dynmenuConstructVars(mIdx, 0, 0, 0),
        MNU_MVAR => _dynmenuConstructMVars(mIdx),
        MNU_MENU, MNU_MENUS => {
            numberOfBytes = 1;
            numberOfGlobalLabels = 0;
            _ = memset(tmpString, 0, TMP_STR_LENGTH);
            if (softmenu[@intCast(softmenuStack[1].softmenuId)].menuItem != -%@as(i16, ITM_DELITM)) {
                i = 0;
                while (i < LAST_ITEM) : (i += 1) {
                    if ((indexOfItems[@intCast(i)].status & CAT_STATUS) == CAT_MENU and indexOfItems[@intCast(i)].itemCatalogName[0] != 0) {
                        const len: i16 = @intCast(stringByteLength(&indexOfItems[@intCast(i)].itemCatalogName));
                        _ = xcopy(&tmpString[15 * @as(usize, @intCast(numberOfGlobalLabels))], &indexOfItems[@intCast(i)].itemCatalogName, @intCast(len));
                        numberOfGlobalLabels += 1;
                        numberOfBytes += 1 + len;
                    }
                }
            }
            i = 0;
            while (i < @as(i16, @intCast(numberOfUserMenus))) : (i += 1) {
                const len: i16 = @intCast(stringByteLength(&userMenus[@intCast(i)].menuName));
                if ((softmenu[@intCast(softmenuStack[1].softmenuId)].menuItem != -%@as(i16, ITM_DELITM)) or
                    ((compareString("HOME", &userMenus[@intCast(i)].menuName, CMP_NAME) != 0) and (compareString("P.FN", &userMenus[@intCast(i)].menuName, CMP_NAME) != 0)))
                {
                    _ = xcopy(&tmpString[15 * @as(usize, @intCast(numberOfGlobalLabels))], &userMenus[@intCast(i)].menuName, @intCast(len));
                    numberOfGlobalLabels += 1;
                    numberOfBytes += 1 + len;
                }
            }
            if (numberOfGlobalLabels != 0) {
                qsort(tmpString, @intCast(numberOfGlobalLabels), 15, &sortMenu);
            }
            ptr = malloc(@intCast(numberOfBytes));
            dynamicSoftmenu[@intCast(mIdx)].menuContent = ptr;
            i = 0;
            while (i < numberOfGlobalLabels) : (i += 1) {
                const len: i16 = @intCast(stringByteLength(&tmpString[15 * @as(usize, @intCast(i))]) + 1);
                _ = xcopy(ptr, &tmpString[15 * @as(usize, @intCast(i))], @intCast(len));
                ptr += @intCast(len);
            }
            dynamicSoftmenu[@intCast(mIdx)].numItems = numberOfGlobalLabels;
        },
        MNU_DYNAMIC => _dynmenuConstructUser(mIdx),
        ITM_MENU => {
            numberOfBytes = 0;
            numberOfGlobalLabels = 0;
            _ = memset(tmpString, 0, TMP_STR_LENGTH);
            i = 0;
            while (i < 18) : (i += 1) {
                _ = xcopy(&tmpString[@intCast(numberOfBytes)], &programmableMenu.itemName[@intCast(i)], @intCast(stringByteLength(&programmableMenu.itemName[@intCast(i)]) + 1));
                numberOfBytes += @intCast(stringByteLength(&programmableMenu.itemName[@intCast(i)]) + 1);
            }
            ptr = malloc(@intCast(numberOfBytes));
            dynamicSoftmenu[@intCast(mIdx)].menuContent = ptr;
            _ = xcopy(ptr, tmpString, @intCast(numberOfBytes));
            dynamicSoftmenu[@intCast(mIdx)].numItems = 18;
        },
        else => {
            _ = sprintf(errorMessage, "In function initVariableSoftmenu: unexpected variable softmenu %d!", @as(c_int, -%dynamicSoftmenu[@intCast(mIdx)].menuItem));
            displayBugScreen(errorMessage);
        },
    }
}

// ---------------------------------------------------------------------------
// showKey family + softkey helpers.
// ---------------------------------------------------------------------------
var label0: [30]u8 = undefined;
var xx1: i16 = 0;
var maxfLines: i8 = 0;
var maxgLines: i8 = 0;

pub export fn maxfgLines(y: i16) callconv(.c) bool_t {
    if (((maxfLines & 1) == 1) and ((maxgLines & 1) == 1)) {
        return @intFromBool((2 == y) or (1 == y));
    } else if (((maxfLines & 1) == 1) and ((maxgLines & 1) == 0)) {
        return @intFromBool(1 == y);
    } else {
        return 0;
    }
}

fn initSoftkeyCoordinates(label: [*c]const u8, xSoftkey: i16, ySoftKey: i16, x1: *i16, x2: *i16, y1: *i16, y2: *i16) bool_t {
    if (label[0] != 0) {
        if (ySoftKey == 1) {
            maxfLines |= 1;
        }
        if (ySoftKey == 2) {
            maxgLines |= 1;
            maxfLines |= 1;
        }
    }
    if (GRAPHMODE() and xSoftkey >= 2) {
        return 0;
    }
    if (0 <= xSoftkey and xSoftkey <= 5) {
        x1.* = @intCast(KEY_X[@intCast(xSoftkey)]);
        x2.* = @intCast(KEY_X[@intCast(xSoftkey + 1)]);
    } else {
        _ = sprintf(errorMessage, "In function initSoftkeyCoordinates: xSoftkey=%d must be from 0 to 5", @as(c_int, xSoftkey));
        displayBugScreen(errorMessage);
        return 0;
    }
    if (0 <= ySoftKey and ySoftKey <= 2) {
        y1.* = 217 - SOFTMENU_HEIGHT * ySoftKey;
        y2.* = y1.* + SOFTMENU_HEIGHT;
    } else {
        _ = sprintf(errorMessage, "In function initSoftkeyCoordinates: ySoftKey=%d but must be from 0 to 2!", @as(c_int, ySoftKey));
        displayBugScreen(errorMessage);
        return 0;
    }
    return 1;
}

fn truncateAtString(label: [*c]u8, search: [*c]const u8) void {
    var i: usize = 0;
    while (label[i + 1] != 0) {
        if (search[0] == label[i] and search[1] == label[i + 1]) {
            label[i] = 0;
            break;
        }
        i += 1;
    }
}

fn truncateAtArrow(label: [*c]u8) void {
    var sample: [4]u8 = undefined;
    _ = stringCopy(&sample, STD_RIGHT_ARROW);
    truncateAtString(label, &sample);
    _ = stringCopy(&sample, STD_LEFT_ARROW);
    truncateAtString(label, &sample);
}

pub export fn greyRect(x: i16, y: i16, dx: i16, dy: i16) callconv(.c) void {
    var col: i16 = undefined;
    var row: i16 = undefined;
    row = y;
    while (row < dy + y) : (row += 1) {
        col = x + @as(i16, @intCast(cmod(@as(i32, x) + @as(i32, row), 2)));
        while (col < dx + x) : (col += 2) {
            setBlackPixel(@intCast(col), @intCast(row));
        }
    }
}

fn showSoftkey(label: [*c]const u8, xSoftkey: i16, ySoftKey: i16, videoMode: videoMode_t, topLine: bool_t, bottomLine: bool_t, showCb: i8, showValue: i16, showText: [*c]const u8) void {
    var x1: i16 = undefined;
    var y1: i16 = undefined;
    var x2: i16 = undefined;
    var y2: i16 = undefined;
    if (initSoftkeyCoordinates(label, xSoftkey, ySoftKey, &x1, &x2, &y1, &y2) == 0) {
        return;
    }
    showKey(label, x1, x2, y1, y2, videoMode, topLine, bottomLine, showCb, showValue, showText);
}

fn showSoftkey2(labelSM1: [*c]const u8, xSoftkey: i16, ySoftKey: i16, videoMode: videoMode_t, topLine: bool_t, bottomLine: bool_t, showCb: i8, showValue: i16, showText: [*c]const u8) void {
    var x1: i16 = undefined;
    var y1: i16 = undefined;
    var x2: i16 = undefined;
    var y2: i16 = undefined;
    if (initSoftkeyCoordinates(labelSM1, xSoftkey, ySoftKey, &x1, &x2, &y1, &y2) == 0) {
        return;
    }
    var label1: [30]u8 = undefined;
    if (xSoftkey == 0 or xSoftkey == 2 or xSoftkey == 4) {
        xx1 = x1;
        label0[0] = 0;
        _ = stringCopy(@ptrCast(&label0[@intCast(stringByteLength(&label0))]), labelSM1);
        compressConversionName(&label0);
    }
    truncateAtArrow(&label0);

    if (xSoftkey == 1 or xSoftkey == 3 or xSoftkey == 5) {
        label1[0] = 0;
        _ = stringCopy(@ptrCast(&label1[@intCast(stringByteLength(&label1))]), labelSM1);
        compressConversionName(&label1);
        truncateAtArrow(&label1);
        showKey2(&label0, &label1, xx1, x2, y1, y2, videoMode, topLine, bottomLine, showCb, showValue, showText);
    }
}

fn drawKeyFrame(x1: i16, x2: i16, y1: i16, y2: i16, videoMode: videoMode_t, topLine: bool_t, bottomLine: bool_t) void {
    const grx1: i16 = @intCast(maxI(0, x1));
    const gry1: i16 = y1 + @as(i16, @intFromBool(bottomLine == 0));
    greyRect(grx1, gry1, @intCast(minI(@as(i32, x2) + 1, SCREEN_WIDTH) - grx1), @intCast(minI(@as(i32, y2) + @intFromBool(topLine != 0), SCREEN_HEIGHT) - gry1));
    lcd_fill_rect(@intCast(x1 + 1), @intCast(y1 + 1), @bitCast(@as(i32, @intCast(minI(x2, SCREEN_WIDTH))) - x1 - 1), @bitCast(@as(i32, @intCast(minI(y2, SCREEN_HEIGHT))) - y1 - 1), if (videoMode == vmNormal) LCD_SET_VALUE else LCD_EMPTY_VALUE);
}

const YY: i16 = -100;

fn showKey2(label0p: [*c]const u8, label1: [*c]const u8, x1: i16, x2: i16, y1: i16, y2: i16, videoMode: videoMode_t, topLine: bool_t, bottomLine: bool_t, showCb: i8, showValue: i16, showText: [*c]const u8) void {
    _ = showValue;
    _ = showCb;
    _ = showText;
    var Text0: i16 = undefined;
    var Arr0: i16 = undefined;
    var midpoint: i16 = undefined;
    var Arr1: i16 = undefined;
    var Text1: i16 = undefined;
    var space: f32 = undefined;
    var space0: f32 = 0;
    var space1: f32 = 0;

    var t: [4][*c]const u8 = undefined;
    var widths: [4]i16 = undefined;
    var arrowSpace: i16 = undefined;
    var w: [4][*c]const u8 = undefined;

    if (getSystemFlag(FLAG_HPCONV) != 0) {
        t[0] = label1;
        t[1] = STD_LEFT_ARROW;
        t[2] = label0p;
        t[3] = STD_RIGHT_ARROW;
        w[0] = label1;
        w[1] = STD_LEFT_ARROW;
        w[2] = STD_RIGHT_ARROW;
        w[3] = label0p;
        arrowSpace = 2;
    } else {
        t[0] = label0p;
        t[1] = STD_RIGHT_ARROW;
        t[2] = label1;
        t[3] = STD_LEFT_ARROW;
        w[0] = label0p;
        w[1] = STD_RIGHT_ARROW;
        w[2] = STD_LEFT_ARROW;
        w[3] = label1;
        arrowSpace = 10;
    }
    {
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            widths[i] = showStringEnhanced(w[i], &standardFont, 0, y1 + YY, videoMode, 0, 0, DO_compress, NO_raise, NO_Show, NO_Bold, NO_LF);
        }
    }

    midpoint = @divTrunc(x2 - x1, 2);
    space0 = (@as(f32, @floatFromInt(x2 - x1)) / 2.0 - @as(f32, @floatFromInt(widths[0])) - @as(f32, @floatFromInt(widths[1])) - @as(f32, @floatFromInt(arrowSpace))) / 2.0;
    Text0 = @intFromFloat(@as(f32, @floatFromInt(x1 + midpoint - arrowSpace - widths[1])) - space0 - @as(f32, @floatFromInt(widths[0])));
    Arr0 = x1 + midpoint - arrowSpace - widths[1];
    space1 = (@as(f32, @floatFromInt(x2 - x1)) / 2.0 - @as(f32, @floatFromInt(widths[2])) - @as(f32, @floatFromInt(widths[3])) - @as(f32, @floatFromInt(arrowSpace))) / 2.0;
    Arr1 = x1 + midpoint + arrowSpace;
    Text1 = @intFromFloat(@as(f32, @floatFromInt(x1 + midpoint + arrowSpace + widths[2])) + space1);

    if (space0 < @as(f32, @floatFromInt(arrowSpace)) or space1 < @as(f32, @floatFromInt(arrowSpace))) {
        space = @as(f32, @floatFromInt((x2 - x1) - widths[0] - widths[1] - widths[2] - widths[3])) / 7.0;
        Text0 = @intFromFloat(@as(f32, @floatFromInt(x1)) + space);
        midpoint = @intFromFloat(3.5 * space + @as(f32, @floatFromInt(widths[0] + widths[1])));
        if (getSystemFlag(FLAG_HPCONV) != 0) {
            Arr0 = x1 + midpoint - arrowSpace - widths[1];
            Arr1 = x1 + midpoint + arrowSpace;
        } else {
            Arr0 = @intFromFloat(@as(f32, @floatFromInt(x1)) + space + @as(f32, @floatFromInt(widths[0])) + space);
            Arr1 = @intFromFloat(@as(f32, @floatFromInt(x2)) - space - @as(f32, @floatFromInt(widths[2] + widths[3])) - space);
        }
        Text1 = @intFromFloat(@as(f32, @floatFromInt(x2)) - space - @as(f32, @floatFromInt(widths[3])));
    }

    drawKeyFrame(x1, x2, y1, y2, videoMode, topLine, bottomLine);

    const xpos = [4]i16{ Text0, Arr0, Text1, Arr1 };
    {
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            _ = showStringEnhanced(t[i], &standardFont, xpos[i], y1 + 1, videoMode, 0, 0, DO_compress, NO_raise, DO_Show, NO_Bold, NO_LF);
        }
    }
    lcd_fill_rect(@intCast(x1 + midpoint), @intCast(y1 + 5), 1, @bitCast(@as(i32, @intCast(minI(y2, SCREEN_HEIGHT - 1))) + 1 - y1 - 2 * 5), if (videoMode == vmNormal) LCD_EMPTY_VALUE else LCD_SET_VALUE);
}

pub export fn showKey(label: [*c]const u8, x1: i16, x2: i16, y1: i16, y2: i16, videoMode: videoMode_t, topLine: bool_t, bottomLine: bool_t, showCb: i8, showValue: i16, showText: [*c]const u8) callconv(.c) void {
    var w: i16 = undefined;
    var l: [16]u8 = undefined;

    drawKeyFrame(x1, x2, y1, y2, videoMode, topLine, bottomLine);

    _ = xcopy(&l, label, @intCast(stringByteLength(label) + 1));
    w = @intCast(stringWidthC47(figlabel(&l, showText, showValue), stdNoEnlarge, 0, 0, 0));
    if ((showCb >= 0) or (@as(i32, w) >= @divTrunc((@as(i32, @intCast(minI(x2, SCREEN_WIDTH))) - maxI(0, x1)) * 3, 4))) {
        w = @intCast(stringWidthC47(figlabel(&l, showText, showValue), stdNoEnlarge, 1, 0, 0));
        if (showCb >= 0) {
            w = w + 8;
        }
        compressString = 1;
        _ = showString(figlabel(&l, showText, showValue), &standardFont, @bitCast(@as(i32, @divTrunc(x1 + x2 - w, 2))), @intCast(y1 + 2), videoMode, 0, 0);
        compressString = 0;
    } else {
        _ = showString(figlabel(&l, showText, showValue), &standardFont, @bitCast(@as(i32, @divTrunc(x1 + x2 - w, 2))), @intCast(y1 + 2), videoMode, 0, 0);
    }

    // JM_LINE2_DRAW is not defined -> skipped.

    if (showCb >= 0) {
        if (videoMode == vmNormal) {
            if (showCb == RB_FALSE) {
                RB_UNCHECKED(@bitCast(@as(i32, x2 - 11)), @bitCast(@as(i32, y2 - 16)));
            } else if (showCb == RB_TRUE) {
                RB_CHECKED(@bitCast(@as(i32, x2 - 11)), @bitCast(@as(i32, y2 - 16)));
            } else if (showCb == CB_TRUE) {
                CB_CHECKED(@bitCast(@as(i32, x2 - 11)), @bitCast(@as(i32, y2 - 16)));
            } else if (showCb == CB_FALSE) {
                CB_UNCHECKED(@bitCast(@as(i32, x2 - 11)), @bitCast(@as(i32, y2 - 16)));
            } else if (showCb == MB_FALSE) {
                MB_MACRO(@bitCast(@as(i32, x2 - 11)), @bitCast(@as(i32, y2 - 16)));
            } else if (showCb == MB_TRUE) {
                MB_MACRO_CHECKED(@bitCast(@as(i32, x2 - 11)), @bitCast(@as(i32, y2 - 16)));
            }
        }
    }

    const _off: i16 = 1;
    if (calcMode == CM_ASSIGN and itemToBeAssigned != 0 and
        (currentMenu() == -%@as(i16, MNU_HOME) or
            currentMenu() == -%@as(i16, MNU_MyMenu) or
            currentMenu() == -%@as(i16, MNU_MyAlpha) or
            currentMenu() == -%@as(i16, MNU_PFN) or
            currentMenu() == -%@as(i16, MNU_DYNAMIC)))
    {
        var xs: [4]i16 = undefined;
        var ys: [4]i16 = undefined;
        var ws: [4]i16 = undefined;
        var hs: [4]i16 = undefined;
        // _off == 2 branch is dead (constant 1); take the else.
        xs[0] = @intCast(maxI(0, x1) + 2 + _off);
        ys[0] = y1 + 1 + _off;
        ws[0] = 3;
        hs[0] = 2;
        xs[1] = @intCast(maxI(0, x1) + 2 + _off);
        ys[1] = y1 + SOFTMENU_HEIGHT - 2 - _off;
        ws[1] = 3;
        hs[1] = 2;
        xs[2] = x2 - 1 - 3 - _off;
        ys[2] = y1 + 1 + _off;
        ws[2] = 3;
        hs[2] = 2;
        xs[3] = x2 - 1 - 3 - _off;
        ys[3] = y1 + SOFTMENU_HEIGHT - 2 - _off;
        ws[3] = 3;
        hs[3] = 2;
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            lcd_fill_rect(@intCast(xs[i]), @intCast(ys[i]), @intCast(ws[i]), @intCast(hs[i]), if (videoMode == vmNormal) LCD_EMPTY_VALUE else LCD_SET_VALUE);
        }
    }
}

pub export fn isFunctionItemAMenu(item: i16) callconv(.c) bool_t {
    return @intFromBool(item == ITM_PLOT_SCATR or
        item == ITM_PLOT_ASSESS or
        item == ITM_HPLOT or
        item == ITM_DRAW or
        item == ITM_DRAW_LU or
        item == ITM_CFG or
        item == ITM_GAP_L or
        item == ITM_GAP_RX or
        item == ITM_GAP_R or
        item == ITM_PLOT_STAT or
        item == ITM_EQ_NEW or
        item == ITM_SIM_EQ or
        item == ITM_DELITM or
        item == ITM_M_EDI or
        item == ITM_M_EDIN or
        item == ITM_CLKp2 or
        item == ITM_PLTFCNS or
        item == ITM_BITSp2);
}

var FF: [16]u8 = undefined;
fn changeDotAndIJ(item: i16, itemN: [*c]const u8) [*c]u8 {
    if ((item == ITM_DREAL or item == SFL_DREAL) and itemN[3] == '.') {
        _ = stringCopy(&FF, itemN);
        FF[3] = RADIX34_MARK_CHAR();
        return &FF;
    } else if (getSystemFlag(FLAG_CPXj) != 0) {
        _ = stringCopy(&FF, itemN);
        if ((item == ITM_op_j or item == ITM_op_j_pol or item == ITM_op_j_SIGN) and FF[1] == STD_op_i[1]) {
            FF[1] +%= 1;
        }
        if (item == ITM_EE_EXP_TH and FF[3] == STD_SUP_i[1]) {
            FF[3] +%= 1;
        }
        return &FF;
    }
    return @constCast(itemN);
}

const mstr = extern struct { modeName: [5]u8 };
const modeNames = [_]mstr{
    .{ .modeName = [5]u8{ 'A', 'L', 'L', 0, 0 } },
    .{ .modeName = [5]u8{ 'F', 'I', 'X', 0, 0 } },
    .{ .modeName = [5]u8{ 'S', 'C', 'I', 0, 0 } },
    .{ .modeName = [5]u8{ 'E', 'N', 'G', 0, 0 } },
    .{ .modeName = [5]u8{ 'S', 'I', 'G', 0, 0 } },
    .{ .modeName = [5]u8{ 'U', 'N', 'I', 'T', 0 } },
};

fn placeSubscript(itemNr: i16, flt: bool_t, tmpF: f32, itemName: [*c]u8, tmpS: [*c]u8, tmpSS: [*c]u8, showText: [*c]u8) void {
    const itemMod: i32 = cmodNonNeg(@as(i32, itemNr), 10000);
    if (flt != 0 and tmpF == @as(f32, @floatFromInt(@as(i32, @intFromFloat(tmpF)))) and
        ((tmpF >= 0 and tmpF < (if (itemMod == VAR_NPPER or itemMod == VAR_PMT) @as(f32, 100000.0) else @as(f32, 1000000.0))) or
            (tmpF < 0 and -tmpF < (if (itemMod == VAR_NPPER or itemMod == VAR_PMT) @as(f32, 10000.0) else @as(f32, 100000.0)))))
    {
        _ = sprintf(tmpS, "%i", @as(c_int, @intFromFloat(tmpF)));
    } else {
        if (tmpF > 0 and tmpF < 1.0e-34) {
            _ = strcpy(tmpS, concat2(STD_GAUSS_WHITE_R, STD_SUB_0));
        } else if (tmpF < 0 and tmpF > -1.0e-34) {
            _ = strcpy(tmpS, concat2(STD_GAUSS_WHITE_L, STD_SUB_0));
        } else if (tmpF > 1.0e34) {
            _ = strcpy(tmpS, concat2(STD_GAUSS_WHITE_R, STD_GAUSS_WHITE_R));
        } else if (tmpF < -1.0e34) {
            _ = strcpy(tmpS, concat2(STD_GAUSS_WHITE_L, STD_GAUSS_WHITE_L));
        } else {
            var convertedRealPerfectly: bool_t = undefined;
            var tmpBuf: [100]u8 = undefined;
            _ = strcpy(tmpS, formatDoubleWidth(REGISTER_REAL34_DATA(@intCast(indexOfItems[@intCast(itemMod)].param)), 4, itemName, &convertedRealPerfectly, 400 / 6 - 2 - 4, &tmpBuf, 60));
            if (tmpS[0] == '?' or strchr(tmpS, 'E') != null) {
                switch (itemMod) {
                    VAR_ULIM, VAR_LLIM, VAR_UEST, VAR_LEST => {
                        _ = stringCopy(@ptrCast(itemName + 3), STD_SPACE_4_PER_EM);
                    },
                    VAR_IPonA, VAR_PPERonA, VAR_CPERonA => {
                        _ = stringCopy(@ptrCast(itemName + 1), concat2(STD_SUB_a, STD_SPACE_4_PER_EM));
                    },
                    VAR_PV => {
                        _ = stringCopy(@ptrCast(itemName + 1), STD_SUB_v);
                    },
                    VAR_FV => {
                        itemName[1] = 0;
                    },
                    VAR_PMT => {
                        _ = stringCopy(@ptrCast(itemName + 1), STD_SUB_m);
                    },
                    else => {},
                }
                _ = strcpy(tmpS, formatDoubleWidth(REGISTER_REAL34_DATA(@intCast(indexOfItems[@intCast(itemMod)].param)), 4, itemName, &convertedRealPerfectly, 400 / 6 - 2 - 4, &tmpBuf, 60));
            }
        }
    }

    radixProcess(tmpSS, tmpS);
    if (stringByteLength(tmpSS) < 4) {
        _ = sprintf(tmpS, concat2(STD_SPACE_3_PER_EM, "%s"), tmpSS);
    } else {
        _ = sprintf(tmpS, "%s", tmpSS);
    }
    _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), tmpSS_via(tmpS));
}
inline fn tmpSS_via(tmpS: [*c]u8) [*c]const u8 {
    return tmpS;
}
inline fn cmodNonNeg(n: i32, d: i32) i32 {
    return @rem(n, d);
}
// concat2: build a small comptime-known concatenation of two byte strings on a
// scratch buffer. Used to reproduce C string-literal concatenation (e.g.
// STD_GAUSS_WHITE_R STD_SUB_0). The two operands here are always short STD_*.
var concatBuf: [64]u8 = undefined;
fn concat2(a: [*c]const u8, b: [*c]const u8) [*c]const u8 {
    const la: usize = @intCast(strlenc(a));
    const lb: usize = @intCast(strlenc(b));
    var i: usize = 0;
    while (i < la) : (i += 1) concatBuf[i] = a[i];
    var j: usize = 0;
    while (j < lb) : (j += 1) concatBuf[la + j] = b[j];
    concatBuf[la + lb] = 0;
    return &concatBuf;
}
extern fn strlen(s: [*c]const u8) usize;
inline fn strlenc(s: [*c]const u8) usize {
    return strlen(s);
}

pub export fn changeSoftKey(menuNr: i16, itemNr: i16, itemName: [*c]u8, vm: *videoMode_t, showCb: *i8, showValue: *i16, showText: [*c]u8) callconv(.c) void {
    _ = menuNr;
    var tmpF: f32 = 0;
    var tmpS: [30]u8 = undefined;
    var tmpSS: [20]u8 = undefined;
    var tmpR: real_t = undefined;
    const itemMod: i32 = @rem(@as(i32, itemNr), 10000);
    vm.* = if ((itemNr < 0) or (isFunctionItemAMenu(@intCast(itemMod)) != 0)) vmReverse else vmNormal;
    showCb.* = NOVAL;
    showValue.* = NOVAL;
    showText[0] = 0;
    _ = stringCopy(itemName, NOTEXT);
    showText[0] = 0;

    if (itemNr > 0) {
        showCb.* = fnCbIsSet(@intCast(itemMod));
        showValue.* = fnItemShowValue(@intCast(itemMod));

        switch (itemMod) {
            VAR_ACC => {
                real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_ACC), &tmpR);
                if (realIsZero(&tmpR) != 0) {
                    _ = strcpy(&tmpS, "0");
                } else {
                    realToFloat(&tmpR, &tmpF);
                    if (tmpF < 0) {
                        _ = strcpy(&tmpS, "NEG");
                    } else if (tmpF < 1.0e-34) {
                        _ = strcpy(&tmpS, concat2(STD_GAUSS_WHITE_L, "1E-34"));
                    } else if (tmpF > 1) {
                        _ = strcpy(&tmpS, concat2(STD_GAUSS_WHITE_R, "1"));
                    } else {
                        _ = sprintf(&tmpS, "%5.G", @as(f64, tmpF));
                        _ = strcpy(&tmpS, eatSpacesMid(&tmpS));
                    }
                }
                _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), &tmpS);
            },
            ITM_PZOOMY, ITM_MZOOMY => {
                if (PLOT_ZMY == zoomOverride) {
                    _ = strcpy(&tmpS, concat2(STD_SPACE_6_PER_EM, STD_SUB_X));
                    showValue.* = NOVAL;
                    _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), &tmpS);
                }
            },
            ITM_IPLUS, ITM_IMINUS => {
                if (isMatrixIndexed() != 0 and getRegisterAsRealQuiet(REGISTER_I, &tmpR) != 0) {
                    _ = sprintf(&tmpS, concat2(concat2(STD_SPACE_3_PER_EM, STD_SPACE_3_PER_EM), "%u"), @as(c_uint, @as(u16, @truncate(realToUint32C47(&tmpR, null)))));
                    _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), &tmpS);
                    showValue.* = NOVAL;
                }
            },
            ITM_JPLUS, ITM_JMINUS => {
                if (isMatrixIndexed() != 0 and getRegisterAsRealQuiet(REGISTER_J, &tmpR) != 0) {
                    _ = sprintf(&tmpS, concat2(concat2(STD_SPACE_3_PER_EM, STD_SPACE_3_PER_EM), "%u"), @as(c_uint, @as(u16, @truncate(realToUint32C47(&tmpR, null)))));
                    _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), &tmpS);
                    showValue.* = NOVAL;
                }
            },
            VAR_ULIM, VAR_LLIM, VAR_UX, VAR_LX, VAR_UEST, VAR_LEST, VAR_UY, VAR_LY, ITM_STORCL_FV, ITM_STORCL_IPonA, ITM_STORCL_NPPER, ITM_STORCL_PPERonA, ITM_STORCL_CPERonA, ITM_STORCL_PMT, ITM_STORCL_PV, VAR_IPonA, VAR_NPPER, VAR_PPERonA, VAR_CPERonA, VAR_PV, VAR_FV, VAR_PMT => {
                _ = stringCopy(itemName, &indexOfItems[@intCast(itemMod)].itemSoftmenuName);
                placeSubscript(itemNr, 0, tmpF, itemName, &tmpS, &tmpSS, showText);
                return;
            },
            ITM_AMORT_P1 => {
                _ = stringCopy(itemName, &indexOfItems[@intCast(itemMod)].itemSoftmenuName);
                tmpF = @floatFromInt(amortP1);
                placeSubscript(itemNr, 1, tmpF, itemName, &tmpS, &tmpSS, showText);
                return;
            },
            ITM_AMORT_P2 => {
                _ = stringCopy(itemName, &indexOfItems[@intCast(itemMod)].itemSoftmenuName);
                tmpF = @floatFromInt(amortP2);
                placeSubscript(itemNr, 1, tmpF, itemName, &tmpS, &tmpSS, showText);
                return;
            },
            ITM_DSP, ITM_UNIT => {
                if (getSystemFlag(FLAG_2TO10) != 0 and displayFormat == DF_UN) {
                    _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), STD_SUB_i);
                }
            },
            ITM_DSPCYCLE => {
                switch (showValue.*) {
                    32700, 32701, 32702, 32703, 32704, 32705 => {
                        _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), &modeNames[@intCast(showValue.* - 32700)].modeName);
                        showValue.* = NOVAL;
                    },
                    else => {},
                }
            },
            ITM_SCR => {
                switch (showValue.*) {
                    NC_NORMAL => {
                        showValue.* = NOVAL;
                    },
                    NC_SUBSCRIPT => {
                        _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), if (alphaCase == AC_LOWER) concat3(STD_SUB_s, STD_SUB_u, STD_SUB_b) else if (alphaCase == AC_UPPER) concat3(STD_SUB_S, STD_SUB_U, STD_SUB_B) else "");
                        showValue.* = NOVAL;
                        _ = stringCopy(itemName, &indexOfItems[@intCast(itemMod)].itemSoftmenuName);
                        itemName[0] = STD_alpha[0];
                        itemName[1] = STD_alpha[1];
                        itemName[2] = 0;
                        return;
                    },
                    NC_SUPERSCRIPT => {
                        _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), if (alphaCase == AC_LOWER) concat3(STD_SUP_s, STD_SUP_u, STD_SUP_p) else if (alphaCase == AC_UPPER) concat3(STD_SUP_S, STD_SUP_U, STD_SUP_P) else "");
                        showValue.* = NOVAL;
                        _ = stringCopy(itemName, &indexOfItems[@intCast(itemMod)].itemSoftmenuName);
                        itemName[0] = STD_alpha[0];
                        itemName[1] = STD_alpha[1];
                        itemName[2] = 0;
                        return;
                    },
                    else => {},
                }
            },
            ITM_DENMAX2 => {
                showValue.* = @intCast(@as(i32, @bitCast(denMax)) & 0xFFFF);
                if (denMax == 0) {
                    _ = strcpy(showText, concat3(STD_SUB_m, STD_SUB_a, STD_SUB_x));
                    showText[6] = 0;
                    showValue.* = NOVAL;
                }
            },
            ITM_YY_DFLT => {
                showValue.* = @intCast(lastCenturyHighUsed & (YY_MASK_TRACKING - 1));
                showText[0] = 0;
                if ((lastCenturyHighUsed & YY_MASK_OFF) != 0) {
                    showValue.* = NOVAL;
                    _ = strcpy(showText, concat3(STD_SUB_o, STD_SUB_f, STD_SUB_f));
                }
                if ((lastCenturyHighUsed & YY_MASK_TRACKING) != 0) {
                    _ = strcat(showText, concat2(STD_SPACE_3_PER_EM, STD_SUB_t));
                }
            },
            ITM_GAP_L => {
                if (gapItemLeft == ITM_NULL) {
                    _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), "\x01\x01");
                } else {
                    _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), &indexOfItems[@intCast(gapItemLeft)].itemSoftmenuName);
                }
                showValue.* = NOVAL;
            },
            ITM_GAP_RX => {
                _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), &indexOfItems[@intCast(gapItemRadix)].itemSoftmenuName);
                showValue.* = NOVAL;
            },
            ITM_GAP_R => {
                if (gapItemRight == ITM_NULL) {
                    _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), "\x01\x01");
                } else {
                    _ = stringCopy(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), &indexOfItems[@intCast(gapItemRight)].itemSoftmenuName);
                }
                showValue.* = NOVAL;
            },
            ITM_GRP_L => {
                showValue.* = @intCast(grpGroupingLeft);
            },
            ITM_GRP1_L => {
                showValue.* = @intCast(grpGroupingGr1Left);
            },
            ITM_GRP1_L_OF => {
                showValue.* = @intCast(grpGroupingGr1LeftOverflow);
            },
            ITM_GRP_R => {
                showValue.* = @intCast(grpGroupingRight);
            },
            else => {},
        }

        if (itemMod == 9999) {
            _ = stringCopy(itemName, &indexOfItems[@intCast(if (getSystemFlag(FLAG_MULTx) == 0) @as(i16, ITM_DOT) else @as(i16, ITM_CROSS))].itemSoftmenuName);
            return;
        } else if ((indexOfItems[@intCast(itemMod)].status & CAT_STATUS) == CAT_CNST) {
            _ = stringCopy(itemName, &indexOfItems[@intCast(itemMod)].itemCatalogName);
        } else {
            _ = stringCopy(itemName, changeDotAndIJ(itemNr, &indexOfItems[@intCast(itemMod)].itemSoftmenuName));
            return;
        }
    } else if (itemNr < 0) {
        if (itemNr == -%@as(i16, MNU_PRINTER)) {
            switch (printerState.printer_model) {
                PRINTER_HP => {
                    _ = sprintf(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), concat2(STD_SPACE_3_PER_EM, "%s"), stringToSub(&indexOfItems[@intCast(ITM_PRINTERHP)].itemSoftmenuName));
                },
                PRINTER_MARTEL => {
                    _ = sprintf(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), "%s", stringToSub(&indexOfItems[@intCast(ITM_PRINTERMARTEL)].itemSoftmenuName));
                },
                PRINTER_OTHER => {
                    _ = sprintf(@ptrCast(showText + @as(usize, @intCast(stringByteLength(showText)))), concat2(STD_SPACE_3_PER_EM, "%s"), stringToSub(&indexOfItems[@intCast(ITM_PRINTEROTHER)].itemSoftmenuName));
                },
                else => {},
            }
        }
        _ = stringCopy(itemName, &indexOfItems[@intCast(@rem(-%itemNr, 10000))].itemSoftmenuName);
        return;
    }
}
// concat3: three-operand string concat onto a separate scratch buffer (does not
// alias concatBuf, since changeSoftKey passes concat3 alongside other strings).
var concat3Buf: [64]u8 = undefined;
fn concat3(a: [*c]const u8, b: [*c]const u8, c: [*c]const u8) [*c]const u8 {
    const la: usize = strlen(a);
    const lb: usize = strlen(b);
    const lc: usize = strlen(c);
    var k: usize = 0;
    var i: usize = 0;
    while (i < la) : (i += 1) {
        concat3Buf[k] = a[i];
        k += 1;
    }
    i = 0;
    while (i < lb) : (i += 1) {
        concat3Buf[k] = b[i];
        k += 1;
    }
    i = 0;
    while (i < lc) : (i += 1) {
        concat3Buf[k] = c[i];
        k += 1;
    }
    concat3Buf[k] = 0;
    return &concat3Buf;
}

pub export fn savedspace(itemNr: i16) callconv(.c) bool_t {
    // Each cluster of case labels is gated by its build option; an itemNr
    // matching an enabled cluster (or 9999) returns true. Mirrors the upstream
    // savedspace() #if-gated switch.
    if (comptime (dmcp_build and old_hw)) { switch (itemNr) { -2382 => return 1, else => {} } }
    if (comptime strip_ortho_bessel_ellip) { switch (itemNr) { -1352, 1483, 1505, 1506, 1550, 1623, 1627, 1484 => return 1, else => {} } }
    // gate defined_SAVE_SPACE_DM42_20_TIMER_ never defined for any frontier build -> omitted
    if (comptime strip_ortho_bessel_ellip) { switch (itemNr) { 1492, 1665 => return 1, else => {} } }
    // gate defined_SAVE_SPACE_DM42_12PRIME_ never defined for any frontier build -> omitted
    if (comptime strip_ortho_bessel_ellip) { switch (itemNr) { -1397, 1682, 1683, 1684, 1726, 1727, 1728, 1584, 1763, 1764, 1765, 2104, 2105, 2599, 2598, 2395 => return 1, else => {} } }
    if (comptime (!option_vector)) { switch (itemNr) { 2492, 2495, 2490, 2491, 2471, 2470, 2496, 2479, 2480, 2481 => return 1, else => {} } }
    if (comptime (!option_elec)) { switch (itemNr) { 1931, 2041, 1824, 1825, 1823, 1826, 1820, 1822, 1818, 1813, 1812, 1819, 1821, 1817, 1814, 1815 => return 1, else => {} } }
    if (comptime (dmcp_build and old_hw)) { switch (itemNr) { 2583, 2572, 2562, 2571, 2568, 2567, 2580, 2577, 2578, 2584, 2570, 2569, 2579, 2556, 2557 => return 1, else => {} } }
    if (comptime strip_17b) { switch (itemNr) { -1212, 1213, 1214, 1215, 1216, -1272, 1273, 1274, 1275, 1276, -1217, 1218, 1219, 1220, 1221, -1267, 1268, 1269, 1270, 1271, -1242, 1243, 1244, 1245, 1246, -1262, 1263, 1264, 1265, 1266 => return 1, else => {} } }
    if (comptime strip_17c) { switch (itemNr) { -1247, 1282, 1283, 1284, 1285, -1286, 1287, 1288, 1289, 1290, 1291, 1292, 1293, 1294, -2600, 2601, 2602, 2603, 2604, -2605, 2606, 2607, 2608, 2609 => return 1, else => {} } }
    if (comptime strip_16) { switch (itemNr) { -1252, 1253, 1254, 1255, 1256, 1238, 1239, 1240, 1241, -1277, 1278, 1279, 1280, 1281 => return 1, else => {} } }
    if (comptime strip_17) { switch (itemNr) { -1222, -1207, -1232, -1257, -1227, 1223, 1224, 1225, 1226, 1208, 1209, 1210, 1211, 1248, 1249, 1250, 1251, 1233, 1234, 1235, 1236, 1258, 1259, 1260, 1261, 1228, 1229, 1230, 1231 => return 1, else => {} } }
    switch (itemNr) { 9999 => return 1, else => {} }
    return 0;
}

const typeStrikeOut: u8 = 1;
const typeStrikeThrough: u8 = 2;
fn strokeStrike(type_: u8, condition: bool_t, xStroke: *i16, yStroke: *i16, x: i16, y: i16) void {
    _ = y; // strokeStrike does not use y (matches upstream).
    xStroke.* = x * 67 + 1 + 9;
    while (xStroke.* < x * 67 + 66 - 10) : (xStroke.* += 1) {
        if (type_ == typeStrikeOut) {
            if (@rem(@as(i32, xStroke.*), 3) == 0) {
                yStroke.* -= 1;
            }
        }
        if (condition != 0) {
            setBlackPixel(@intCast(xStroke.*), @bitCast(@as(i32, yStroke.* - 3)));
        } else {
            setWhitePixel(@intCast(xStroke.*), @bitCast(@as(i32, yStroke.* - 3)));
        }
    }
}

pub export fn fnStrikeOutIfNotCoded(itemNr: i16, x: i16, y: i16) callconv(.c) void {
    if (itemNr == -%@as(i16, MNU_HOME) or itemNr == -%@as(i16, MNU_PFN)) {
        return;
    }
    var strike: i16 = 0;
    if (itemNr > 0) {
        // C compares indexOfItems[i].func to the itemToBeCoded FUNCTION address.
        if (indexOfItems[@intCast(@rem(@as(i32, itemNr), 10000))].func == @as(?*const fn (u16) callconv(.c) void, &itemToBeCoded) or savedspace(itemNr) != 0) {
            strike = 1;
        }
    } else if (itemNr < 0) {
        var m: i16 = 0;
        while (softmenu[@intCast(m)].menuItem != 0) {
            if (softmenu[@intCast(m)].menuItem == @as(i16, @intCast(@rem(@as(i32, itemNr), 10000)))) {
                break;
            }
            m += 1;
        }
        if ((softmenu[@intCast(m)].numItems == 0 or savedspace(itemNr) != 0) and m >= NUMBER_OF_DYNAMIC_SOFTMENUS) {
            strike = -1;
        }
    }

    if (strike != 0) {
        var yStroke: i16 = SCREEN_HEIGHT - y * 23 - 1;
        var xStroke: i16 = undefined;
        strokeStrike(typeStrikeOut, @intFromBool(strike == 1), &xStroke, &yStroke, x, y);
    }
}

pub export fn fnStrikeThroughIfNA(itemNr: i16, x: i16, y: i16) callconv(.c) void {
    var yStroke: i16 = SCREEN_HEIGHT - y * 23 - 9;
    var xStroke: i16 = undefined;
    if (itemNotAvail(itemNr) != 0) {
        strokeStrike(typeStrikeThrough, @intFromBool(itemNr > 0), &xStroke, &yStroke, x, y);
    }
}

const menuOps_t = u8;
const openMenu: menuOps_t = 0;
const closeMenu: menuOps_t = 1;

fn setScreenUpdateFromMenu(id: i16, op: menuOps_t) void {
    switch (id) {
        -%@as(i16, MNU_XXFCNS), -%@as(i16, MNU_EQN), -%@as(i16, MNU_DISTR), -%@as(i16, MNU_EQ_EDIT), -%@as(i16, MNU_Solver_TOOL) => {
            if (op == closeMenu) {
                solverEstimatesUsed = 0;
            }
            screenUpdatingMode = SCRUPD_AUTO;
            screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
        },
        -%@as(i16, MNU_MVAR) => {
            screenUpdatingMode = SCRUPD_AUTO;
            screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
        },
        else => {},
    }
}

pub export var BASE_OVERRIDEONCE: bool_t = 0;

pub export fn showSoftmenuCurrentPart() callconv(.c) void {
    if (currentMenu() == -%@as(i16, MNU_HOME)) {
        changeToHOME();
    } else if (currentMenu() == -%@as(i16, MNU_PFN)) {
        changeToPFN();
    }

    maxfLines = 0;
    maxgLines = 0;
    var tmp1: [16]u8 = undefined;
    var x: i16 = undefined;
    var y: i16 = undefined;
    var yDotted: i16 = 0;
    var currentFirstItem: i16 = undefined;
    var item: i16 = undefined;
    var numberOfItems: i16 = undefined;
    const m: i16 = softmenuStack[0].softmenuId;
    var dottedTopLine: bool_t = undefined;

    screenUpdatingMode &= ~@as(u8, SCRUPD_MANUAL_MENU | SCRUPD_SKIP_MENU_ONE_TIME);
    setScreenUpdateFromMenu(softmenu[@intCast(m)].menuItem, openMenu);

    if ((!IS_BASEBLANK_(m) or BASE_OVERRIDEONCE != 0) and calcMode != CM_FLAG_BROWSER and calcMode != CM_ASN_BROWSER and calcMode != CM_FONT_BROWSER and calcMode != CM_REGISTER_BROWSER and calcMode != CM_BUG_ON_SCREEN) {
        clearScreenOld(0, 0, 1);
        BASE_OVERRIDEONCE = 0;
        if (tam.mode == TM_KEY and tam.keyInputFinished == 0) {
            y = 0;
            while (y <= 2) : (y += 1) {
                x = 0;
                while (x < 6) : (x += 1) {
                    _ = stringCopy(&tmp1, " ");
                    if (1 + x + y * 6 > 9) {
                        tmp1[0] = '1';
                        _ = stringCopy(@ptrCast(&tmp1[1]), " ");
                        tmp1[1] = @intCast(48 + @rem(@as(i32, 1 + x + y * 6), 10));
                    } else {
                        tmp1[0] = @intCast(48 + 1 + x + y * 6);
                    }
                    showSoftkey(&tmp1, x, y, vmReverse, 1, 1, NOVAL, NOVAL, NOTEXT);
                }
            }
            return;
        }

        if (m < NUMBER_OF_DYNAMIC_SOFTMENUS) {
            if (softmenu[@intCast(m)].menuItem != cachedDynamicMenu or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_DYNAMIC)) {
                initVariableSoftmenu(m);
                cachedDynamicMenu = softmenu[@intCast(m)].menuItem;
            }
            numberOfItems = dynamicSoftmenu[@intCast(m)].numItems;
        } else if (softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_EQN) and numberOfFormulae == 0) {
            numberOfItems = 1;
        } else {
            numberOfItems = softmenu[@intCast(m)].numItems;
        }
        currentFirstItem = softmenuStack[0].firstItem;

        if (numberOfItems <= 18) {
            dottedTopLine = 0;
            if (catalog != CATALOG_NONE) {
                currentFirstItem = 0;
                softmenuStack[0].firstItem = 0;
                setCatalogLastPos();
            }
        } else {
            dottedTopLine = 1;
            yDotted = @intCast(minI(3, @divTrunc(@as(i32, numberOfItems) + modulo(@as(i32, currentFirstItem) - numberOfItems, 6), 6) - @divTrunc(@as(i32, currentFirstItem), 6)) - 1);

            if (m >= NUMBER_OF_DYNAMIC_SOFTMENUS) {
                item = 6 * (@divTrunc(currentFirstItem, 6) + yDotted);
                if (sixZero(m, item)) {
                    yDotted -= 1;
                }
                item = 6 * (@divTrunc(currentFirstItem, 6) + yDotted);
                if (yDotted >= 0 and sixZero(m, item)) {
                    yDotted -= 1;
                }
                item = 6 * (@divTrunc(currentFirstItem, 6) + yDotted);
                if (yDotted >= 0 and sixZero(m, item)) {
                    yDotted -= 1;
                }
            }
        }

        var itemName: [16]u8 = undefined;
        itemName[0] = 0;
        var showText: [16]u8 = undefined;
        showText[0] = 0;
        var vm: videoMode_t = vmNormal;
        var showCb: i8 = NOVAL;
        var showValue: i16 = NOVAL;
        showText[0] = 0;

        if (m < NUMBER_OF_DYNAMIC_SOFTMENUS) {
            if (numberOfItems == 0) {
                x = 0;
                while (x < 6) : (x += 1) {
                    showSoftkey("", x, 0, vmNormal, 1, 1, NOVAL, NOVAL, NOTEXT);
                }
            } else {
                var ptr: [*c]u8 = getNthString(dynamicSoftmenu[@intCast(m)].menuContent, currentFirstItem);
                y = 0;
                while (y < 3) : (y += 1) {
                    x = 0;
                    while (x < 6) : (x += 1) {
                        if (x + 6 * y + currentFirstItem < numberOfItems) {
                            if (ptr[0] != 0) {
                                vm = vmNormal;
                                showText[0] = 0;
                                showCb = NOVAL;
                                showValue = NOVAL;
                                var itemNr: i16 = userMenuItems[@intCast(x + 6 * y)].item;
                                _ = stringCopy(&itemName, ptr);
                                switch (-%softmenu[@intCast(m)].menuItem) {
                                    MNU_MENU, MNU_MENUS => {
                                        vm = vmReverse;
                                    },
                                    MNU_MyMenu => {
                                        if (itemNr < 0) {
                                            vm = vmReverse;
                                        } else {
                                            if (userMenuItems[@intCast(x + 6 * y)].argumentName[0] == 0) {
                                                changeSoftKey(softmenu[@intCast(m)].menuItem, itemNr, &itemName, &vm, &showCb, &showValue, &showText);
                                            }
                                        }
                                    },
                                    MNU_MyAlpha => {
                                        vm = if (userAlphaItems[@intCast(x + 6 * y)].item < 0) vmReverse else vmNormal;
                                        itemNr = 0;
                                    },
                                    MNU_DYNAMIC => {
                                        itemNr = userMenus[@intCast(currentUserMenu)].menuItem[@intCast(x + 6 * y)].item;
                                        if (itemNr < 0) {
                                            vm = vmReverse;
                                        } else {
                                            if (userMenus[@intCast(currentUserMenu)].menuItem[@intCast(x + 6 * y)].argumentName[0] == 0) {
                                                changeSoftKey(softmenu[@intCast(m)].menuItem, itemNr, &itemName, &vm, &showCb, &showValue, &showText);
                                            }
                                        }
                                    },
                                    MNU_1STDERIV, MNU_2NDDERIV, MNU_MVAR => {
                                        if (compareString(getNthString(dynamicSoftmenu[@intCast(m)].menuContent, x + 6 * y), &indexOfItems[@intCast(ITM_DRAW)].itemSoftmenuName, CMP_NAME) == 0) {
                                            vm = vmReverse;
                                        } else if (compareString(getNthString(dynamicSoftmenu[@intCast(m)].menuContent, x + 6 * y), &indexOfItems[@intCast(ITM_DRAW_LU)].itemSoftmenuName, CMP_NAME) == 0) {
                                            vm = vmReverse;
                                        } else if (compareString(getNthString(dynamicSoftmenu[@intCast(m)].menuContent, x + 6 * y), &indexOfItems[@intCast(MNU_GRAPHS)].itemSoftmenuName, CMP_NAME) == 0) {
                                            vm = vmReverse;
                                        } else if (compareString(getNthString(dynamicSoftmenu[@intCast(m)].menuContent, x + 6 * y), &indexOfItems[@intCast(MNU_Solver_TOOL)].itemSoftmenuName, CMP_NAME) == 0) {
                                            vm = vmReverse;
                                        } else if (compareString(getNthString(dynamicSoftmenu[@intCast(m)].menuContent, x + 6 * y), &indexOfItems[@intCast(MNU_Sf_TOOL)].itemSoftmenuName, CMP_NAME) == 0) {
                                            vm = vmReverse;
                                        }

                                        if (compareString(getNthString(dynamicSoftmenu[@intCast(m)].menuContent, x + 6 * y), &indexOfItems[@intCast(ITM_SETSIG2)].itemSoftmenuName, CMP_NAME) == 0) {
                                            _ = strcpy(&itemName, figlabel(getNthString(dynamicSoftmenu[@intCast(m)].menuContent, x + 6 * y), "", fnItemShowValue(ITM_SETSIG2)));
                                        }

                                        var tmpC: [16]u8 = undefined;
                                        tmpC[0] = 0;
                                        const svIdx: i32 = @as(i32, currentSolverVariable) - FIRST_NAMED_VARIABLE;
                                        _ = xcopy(&tmpC, &allNamedVariables[@intCast(svIdx)].variableName[1], allNamedVariables[@intCast(svIdx)].variableName[0]);
                                        tmpC[allNamedVariables[@intCast(svIdx)].variableName[0]] = 0;
                                        if (compareString(getNthString(dynamicSoftmenu[@intCast(m)].menuContent, x + 6 * y), &tmpC, CMP_NAME) == 0) {
                                            _ = strcpy(&itemName, &tmpC);
                                            _ = strcat(&itemName, "*");
                                        }
                                        itemNr = 0;
                                    },
                                    MNU_PROG, MNU_PROGS => {
                                        itemNr = 0;
                                        vm = vmNormal;
                                    },
                                    else => {
                                        vm = vmNormal;
                                    },
                                }
                                showSoftkey(&itemName, x, y, vm, 1, 1, showCb, showValue, &showText);
                                fnStrikeOutIfNotCoded(itemNr, x, y);
                                fnStrikeThroughIfNA(itemNr, x, y);
                            }
                            ptr += @intCast(stringByteLength(ptr) + 1);
                        }
                    }
                }
            }
            if (softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_MVAR) and (currentSolverStatus & SOLVER_STATUS_USES_FORMULA) != 0 and (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) != 0) {
                showEquation(currentFormula, 0, EQUATION_NO_CURSOR, 0, null, null);
            }
        } else {
            var softkeyItem: [*c]const i16 = softmenu[@intCast(m)].softkeyItem + @as(usize, @intCast(currentFirstItem));
            var itemName2: [16]u8 = undefined;
            y = @intCast(@divTrunc(currentFirstItem, 6));
            while (y <= minI(@divTrunc(currentFirstItem, 6) + 2, @divTrunc(numberOfItems, 6))) : ({
                y += 1;
                softkeyItem += 6;
            }) {
                x = 0;
                while (x < 6) : (x += 1) {
                    if (@intFromPtr(softkeyItem + @as(usize, @intCast(x))) >= @intFromPtr(softmenu[@intCast(m)].softkeyItem + @as(usize, @intCast(numberOfItems)))) {
                        item = ITM_NULL;
                    } else {
                        item = softkeyItem[@intCast(x)];
                    }
                    changeSoftKey(softmenu[@intCast(m)].menuItem, item, &itemName2, &vm, &showCb, &showValue, &showText);

                    if (item < 0) {
                        var menuLocal: i16 = 0;
                        while (softmenu[@intCast(menuLocal)].menuItem != 0) {
                            if (softmenu[@intCast(menuLocal)].menuItem == item) {
                                break;
                            }
                            menuLocal += 1;
                        }

                        if (item == -%@as(i16, MNU_ASN_N) and calcModel == USER_C47) {
                            showSoftkey(concat2(STD_SIGMA, "+ KEY"), x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vmReverse, 1, 1, NOVAL, NOVAL, NOTEXT);
                        } else if (item == -%@as(i16, MNU_ASN_N) and isR47FAM()) {
                            showSoftkey(concat2(STD_BOX, " KEY"), x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vmReverse, 1, 1, NOVAL, NOVAL, NOTEXT);
                        } else if (item == -%@as(i16, MNU_HOME) or item == -%@as(i16, MNU_PFN)) {
                            showSoftkey(&indexOfItems[@intCast(-%item)].itemSoftmenuName, x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vmReverse, 1, 1, NOVAL, NOVAL, NOTEXT);
                        } else if (softmenu[@intCast(menuLocal)].menuItem == 0) {
                            _ = sprintf(errorMessage, "In function showSoftmenuCurrentPart: softmenu ID %d not found!", @as(c_int, item));
                            displayBugScreen(errorMessage);
                        } else if (softmenu[@intCast(menuLocal)].menuItem == -%@as(i16, MNU_ALPHA_OMEGA) and alphaCase == AC_UPPER) {
                            showSoftkey(&indexOfItems[@intCast(MNU_ALPHA_OMEGA)].itemSoftmenuName, x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vmReverse, 1, 1, NOVAL, NOVAL, NOTEXT);
                        } else if (softmenu[@intCast(menuLocal)].menuItem == -%@as(i16, MNU_ALPHA_OMEGA) and alphaCase == AC_LOWER) {
                            showSoftkey(&indexOfItems[@intCast(MNU_alpha_omega)].itemSoftmenuName, x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vmReverse, 1, 1, NOVAL, NOVAL, NOTEXT);
                        } else if (softmenu[@intCast(menuLocal)].menuItem == -%@as(i16, MNU_ALPHAINTL) and alphaCase == AC_UPPER) {
                            showSoftkey(&indexOfItems[@intCast(MNU_ALPHAINTL)].itemSoftmenuName, x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vmReverse, 1, 1, NOVAL, NOVAL, NOTEXT);
                        } else if (softmenu[@intCast(menuLocal)].menuItem == -%@as(i16, MNU_ALPHAINTL) and alphaCase == AC_LOWER) {
                            showSoftkey(&indexOfItems[@intCast(MNU_ALPHAintl)].itemSoftmenuName, x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vmReverse, 1, 1, NOVAL, NOVAL, NOTEXT);
                        } else if (softmenu[@intCast(menuLocal)].menuItem == -%@as(i16, MNU_PRINTER)) {
                            showSoftkey(&indexOfItems[@intCast(MNU_PRINTER)].itemSoftmenuName, x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vmReverse, 1, 1, NOVAL, NOVAL, &showText);
                        } else {
                            // INLINE_TEST is off -> only the main softmenu display arm.
                            showSoftkey(&indexOfItems[@intCast(-%softmenu[@intCast(menuLocal)].menuItem)].itemSoftmenuName, x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vmReverse, 1, 1, NOVAL, NOVAL, NOTEXT);
                        }
                    } else if (softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_SYSFL)) {
                        if (indexOfItems[@intCast(@rem(@as(i32, item), 10000))].itemCatalogName[0] != 0) {
                            if (isSystemFlagWriteProtected(@intCast(indexOfItems[@intCast(@rem(@as(i32, item), 10000))].param)) != 0) {
                                showSoftkey(changeDotAndIJ(item, &indexOfItems[@intCast(@rem(@as(i32, item), 10000))].itemCatalogName), x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vmNormal, @intFromBool(@divTrunc(@as(i32, item), 10000) == 0 or @divTrunc(@as(i32, item), 10000) == 2), @intFromBool(@divTrunc(@as(i32, item), 10000) == 0 or @divTrunc(@as(i32, item), 10000) == 1), showCb, if (getSystemFlag(@intCast(indexOfItems[@intCast(@rem(@as(i32, item), 10000))].param)) != 0) 1 else 0, NOTEXT);
                            } else {
                                showSoftkey(changeDotAndIJ(item, &indexOfItems[@intCast(@rem(@as(i32, item), 10000))].itemCatalogName), x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vmNormal, @intFromBool(@divTrunc(@as(i32, item), 10000) == 0 or @divTrunc(@as(i32, item), 10000) == 2), @intFromBool(@divTrunc(@as(i32, item), 10000) == 0 or @divTrunc(@as(i32, item), 10000) == 1), if (getSystemFlag(@intCast(indexOfItems[@intCast(@rem(@as(i32, item), 10000))].param)) != 0) CB_TRUE else CB_FALSE, NOVAL, NOTEXT);
                            }
                        }
                    } else if (softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_TAMFLAG) and indexOfItems[@intCast(@rem(@as(i32, item), 10000))].itemCatalogName[0] != 0 and funcIsGetSystemFlag(indexOfItems[@intCast(@rem(@as(i32, item), 10000))].func)) {
                        showSoftkey(&indexOfItems[@intCast(@rem(@as(i32, item), 10000))].itemCatalogName, x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vmNormal, @intFromBool(@divTrunc(@as(i32, item), 10000) == 0 or @divTrunc(@as(i32, item), 10000) == 2), @intFromBool(@divTrunc(@as(i32, item), 10000) == 0 or @divTrunc(@as(i32, item), 10000) == 1), if (getSystemFlag(@intCast(indexOfItems[@intCast(@rem(@as(i32, item), 10000))].param)) != 0) CB_TRUE else CB_FALSE, NOVAL, NOTEXT);
                    } else if (softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_ALPHA) and calcMode == CM_PEM and @rem(@as(i32, item), 10000) == ITM_ASSIGN) {
                        // do nothing
                    } else if (item > 0 and indexOfItems[@intCast(@rem(@as(i32, item), 10000))].itemSoftmenuName[0] != 0) {
                        if (softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONVS) or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONVANG) or
                            softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONVE) or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONVP) or
                            softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONVFP) or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONVM) or
                            softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONVX) or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONVV) or
                            softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONVA) or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_UNITCONV) or
                            softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_MISC) or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONVHUM) or
                            softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONVYMMV) or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONVCHEF) or
                            softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONVTEMP))
                        {
                            showSoftkey2(&indexOfItems[@intCast(@rem(@as(i32, item), 10000))].itemSoftmenuName, x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vmNormal, @intFromBool(@divTrunc(@as(i32, item), 10000) == 0 or @divTrunc(@as(i32, item), 10000) == 2), @intFromBool(@divTrunc(@as(i32, item), 10000) == 0 or @divTrunc(@as(i32, item), 10000) == 1), showCb, showValue, &showText);
                        } else {
                            if ((softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_FCNS) or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_FCNS_EIM) or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_CONST)) or
                                ((softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_IO) or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_PFN)) and (item == ITM_STOCFG or item == ITM_RCLCFG)))
                            {
                                _ = stringCopy(&itemName2, changeDotAndIJ(item, &indexOfItems[@intCast(@rem(@as(i32, item), 10000))].itemCatalogName));
                            }
                            showSoftkey(&itemName2, x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))), vm, @intFromBool(@divTrunc(@as(i32, item), 10000) == 0 or @divTrunc(@as(i32, item), 10000) == 2), @intFromBool(@divTrunc(@as(i32, item), 10000) == 0 or @divTrunc(@as(i32, item), 10000) == 1), showCb, showValue, &showText);
                        }

                        if ((getSystemFlag(FLAG_G_DOUBLETAP) != 0 and (BLOCK_DOUBLEPRESS_MENU(softmenu[@intCast(m)].menuItem, x, y))) or
                            (softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_TIMERF) and y == 0))
                        {
                            const yStrokeA: i16 = SCREEN_HEIGHT - (y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6)))) * 23 - 1;
                            const xStrokeA: i16 = x * 67 + 66 - 12;
                            plotline1(xStrokeA + 2 + 4, yStrokeA - 16 - 3 - 1, xStrokeA + 2 + 4 + 5 - 1, yStrokeA - 16 - 3 + 5);
                        }
                    }

                    if (softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_TIMERF) and y == 0) {
                        var tmpp: [16]u8 = undefined;
                        tmpp[0] = 0;
                        var tmpq: [16]u8 = undefined;
                        tmpq[0] = 0;
                        switch (item) {
                            ITM_TIMER_SIGMA_T => _ = sprintf(&tmpq, "%s", concat3("[", STD_SIGMA, "+]")),
                            ITM_TIMER_SIGMA_L => _ = sprintf(&tmpq, "%s", "[+]"),
                            ITM_TIMER_R_T => _ = sprintf(&tmpq, "%s", "[ENTER]"),
                            ITM_TIMER_R_L => _ = sprintf(&tmpq, "%s", "[.]"),
                            ITM_TIMER_R_S, ITM_STOP => _ = sprintf(&tmpq, "%s", "[R/S]"),
                            ITM_TIMER_RESET => _ = sprintf(&tmpq, "%s", concat3("[", STD_LEFT_ARROW, "]")),
                            else => {},
                        }
                        var x1: i16 = undefined;
                        var y1: i16 = undefined;
                        var x2: i16 = undefined;
                        var y2: i16 = undefined;
                        _ = initSoftkeyCoordinates(&tmpq, x, 2, &x1, &x2, &y1, &y2);
                        showKey(&tmpq, x1, x2, y1, y2, vmNormal, 0, 1, NOVAL, NOVAL, &tmpp);
                        var line: i16 = y1 + 3;
                        while (line < y2 - 2) : (line += 1) {
                            var col: i16 = x1 + 3 + @as(i16, @intCast(@rem(@as(i32, line), 6)));
                            while (col < x2 - 2) : (col += 6) {
                                setBlackPixel(@intCast(col), @intCast(line));
                            }
                        }
                    }

                    fnStrikeOutIfNotCoded(@intCast(@rem(@as(i32, item), 10000)), x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))));
                    fnStrikeThroughIfNA(@intCast(@rem(@as(i32, item), 10000)), x, y - @as(i16, @intCast(@divTrunc(currentFirstItem, 6))));
                }
            }

            if (softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_EQN)) {
                showEquation(currentFormula, 0, EQUATION_NO_CURSOR, 0, null, null);
                dottedTopLine = @intFromBool(numberOfFormulae >= 2);
                yDotted = 2;
            }
            const currentMenuV: i16 = softmenu[@intCast(m)].menuItem;
            if ((currentMenuV == -%@as(i16, MNU_EQ_EDIT)) or ((calcMode == CM_EIM) and ((currentMenuV == -%@as(i16, MNU_EIMCATALOG)) or (currentMenuV == -%@as(i16, MNU_CHARS))))) {
                var cursorShown: bool_t = undefined;
                var rightEllipsis: bool_t = undefined;
                while (true) {
                    showEquation(EQUATION_AIM_BUFFER, @intCast(yCursor), @intCast(xCursor), 1, &cursorShown, &rightEllipsis);
                    if (cursorShown != 0) {
                        break;
                    }
                    if (yCursor > xCursor) {
                        yCursor -= 1;
                    } else {
                        yCursor += 1;
                    }
                }
                if (rightEllipsis == 0 and yCursor > 0) {
                    while (true) {
                        yCursor -= 1;
                        showEquation(EQUATION_AIM_BUFFER, @intCast(yCursor), @intCast(xCursor), 1, &cursorShown, &rightEllipsis);
                        if ((cursorShown == 0) or rightEllipsis != 0) {
                            yCursor += 1;
                            break;
                        }
                        if (yCursor <= 0) break;
                    }
                }
                showEquation(EQUATION_AIM_BUFFER, @intCast(yCursor), @intCast(xCursor), 0, null, null);
            }
            if ((softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_Sfdx) or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_Solver_TOOL) or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_Sf_TOOL) or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_GRAPHS)) and (currentSolverStatus & SOLVER_STATUS_USES_FORMULA) != 0 and (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) != 0) {
                showEquation(currentFormula, 0, EQUATION_NO_CURSOR, 0, null, null);
            }
        }

        if (0 <= yDotted and yDotted <= 2) {
            yDotted = 217 - SOFTMENU_HEIGHT * yDotted;

            if (dottedTopLine != 0 and (!GRAPHMODE() or softmenu[@intCast(m)].menuItem == -%@as(i16, MNU_PLOT_FUNC))) {
                x = 0;
                while (x < (if (GRAPHMODE()) @divTrunc(SCREEN_WIDTH, 3) else SCREEN_WIDTH)) : (x += 1) {
                    if (@rem(@as(i32, x), 8) < 4) {
                        setBlackPixel(@intCast(x), @intCast(yDotted));
                    } else {
                        setWhitePixel(@intCast(x), @intCast(yDotted));
                    }
                }

                const t: f32 = 5;
                const t_o: f32 = 1.6 * t;
                const tt_o: f32 = 2;
                lcd_fill_rect(0, @intCast(@as(i32, yDotted) - @as(i32, @intFromFloat(t))), 20, @intFromFloat(t + 1), 0);
                var xx: i16 = 0;
                while (xx <= @as(i16, @intFromFloat(t))) : (xx += 1) {
                    if (catalog == 0) {
                        lcd_fill_rect(@intCast(xx), @intCast(@as(i32, @intFromFloat(tt_o - t)) + yDotted - xx + @as(i32, @intFromFloat(t))), @intCast(2 * (@as(i32, @intFromFloat(t)) - xx)), 1, 1);
                        lcd_fill_rect(@intCast(xx + @as(i16, @intFromFloat(t_o))), @intCast(@as(i32, @intFromFloat(tt_o - t)) + yDotted - @as(i32, @intFromFloat(t)) + xx + @as(i32, @intFromFloat(t))), @intCast(2 * (@as(i32, @intFromFloat(t)) - xx)), 1, 1);
                    } else {
                        if (xx != @as(i16, @intFromFloat(t))) {
                            lcd_fill_rect(@intCast(xx), @intCast(@as(i32, @intFromFloat(tt_o - t)) + yDotted - xx + @as(i32, @intFromFloat(t))), 2, 1, 1);
                            lcd_fill_rect(@intCast(xx + 2 * (@as(i16, @intFromFloat(t)) - xx) - 1), @intCast(@as(i32, @intFromFloat(tt_o - t)) + yDotted - xx + @as(i32, @intFromFloat(t))), 2, 1, 1);
                            lcd_fill_rect(@intCast(xx + @as(i16, @intFromFloat(t_o))), @intCast(@as(i32, @intFromFloat(tt_o - t)) + yDotted - @as(i32, @intFromFloat(t)) + xx + @as(i32, @intFromFloat(t))), 2, 1, 1);
                            lcd_fill_rect(@intCast(xx + @as(i16, @intFromFloat(t_o)) + 2 * (@as(i16, @intFromFloat(t)) - xx) - 1), @intCast(@as(i32, @intFromFloat(tt_o - t)) + yDotted - @as(i32, @intFromFloat(t)) + xx + @as(i32, @intFromFloat(t))), 2, 1, 1);
                        }
                    }
                }
            }
        }
        showShiftState();
    }
}
inline fn sixZero(m: i16, item: i16) bool {
    const si = softmenu[@intCast(m)].softkeyItem;
    const i: usize = @intCast(item);
    return si[i] == 0 and si[i + 1] == 0 and si[i + 2] == 0 and si[i + 3] == 0 and si[i + 4] == 0 and si[i + 5] == 0;
}
inline fn funcIsGetSystemFlag(func: ?*const fn (u16) callconv(.c) void) bool {
    return func == @as(?*const fn (u16) callconv(.c) void, &fnGetSystemFlag);
}

fn pushSoftmenu(softmenuId: i16) void {
    var i: usize = undefined;
    var userMenuId: i16 = undefined;

    if (softmenu[@intCast(softmenuId)].menuItem == -%@as(i16, MNU_DYNAMIC)) {
        userMenuId = @intCast(currentUserMenu);
    } else {
        userMenuId = 0;
    }
    if ((softmenuStack[0].softmenuId == softmenuId) and (softmenuStack[0].userMenuId == userMenuId)) {
        return;
    }

    i = 0;
    while (i < SOFTMENU_STACK_SIZE) : (i += 1) {
        if ((softmenuStack[i].softmenuId == softmenuId) and (softmenuStack[i].userMenuId == userMenuId)) {
            if (catalog == 0) {
                if (getSystemFlag(FLAG_MNUp1) == 0 and (calcMode == CM_NORMAL or calcMode == CM_NIM)) {
                    lastCatalogPosition[CATALOG_NONE] = softmenuStack[i].firstItem;
                    calcMode = softmenuStack[i].calcMode;
                } else {
                    lastCatalogPosition[CATALOG_NONE] = 0;
                }
            }
            _ = xcopy(softmenuStack + 1, softmenuStack, @intCast(i * @sizeOf(softmenuStack_t)));
            break;
        }
    }

    if (i == SOFTMENU_STACK_SIZE) {
        _ = xcopy(softmenuStack + 1, softmenuStack, (SOFTMENU_STACK_SIZE - 1) * @sizeOf(softmenuStack_t));
    }

    softmenuStack[0].softmenuId = softmenuId;
    softmenuStack[0].firstItem = lastCatalogPosition[@intCast(catalog)];
    softmenuStack[0].userMenuId = userMenuId;
    softmenuStack[0].calcMode = calcMode;

    if ((softmenu[@intCast(softmenuId)].menuItem == -%@as(i16, MNU_CONVCHEF) or softmenu[@intCast(softmenuId)].menuItem == -%@as(i16, MNU_CONVV)) and
        ((menu(1) == -%@as(i16, MNU_UNITCONV)) or
            (menu(1) == -%@as(i16, MNU_MENUS) and menu(2) == -%@as(i16, MNU_CATALOG))))
    {
        softmenuStack[0].firstItem = if (getSystemFlag(FLAG_US) != 0) 18 else 0;
    }

    doRefreshSoftMenu = 1;
}

pub export fn popSoftmenu() callconv(.c) void {
    screenUpdatingMode &= ~@as(u8, SCRUPD_MANUAL_MENU | SCRUPD_SKIP_MENU_ONE_TIME);
    setScreenUpdateFromMenu(currentMenu(), closeMenu);

    _ = xcopy(softmenuStack, softmenuStack + 1, (SOFTMENU_STACK_SIZE - 1) * @sizeOf(softmenuStack_t));
    _ = memset(softmenuStack + (SOFTMENU_STACK_SIZE - 1), 0, @sizeOf(softmenuStack_t));

    doRefreshSoftMenu = 1;

    if (softmenuStack[0].softmenuId == 0 and calcMode == CM_AIM) {
        softmenuStack[0].softmenuId = 1;
    } else if (softmenuStack[0].softmenuId == 1 and calcMode != CM_AIM) {
        softmenuStack[0].softmenuId = 0;
    }
    if (softmenuStack[0].softmenuId == 0 and getSystemFlag(FLAG_BASE_HOME) != 0 and calcMode != CM_AIM) {
        showSoftmenu(-%@as(i16, MNU_HOME)); // must PUSH HOME to base here; not changeToHOME() which only re-points
    } else if (softmenuStack[0].softmenuId == 0 and getSystemFlag(FLAG_BASE_MYM) != 0 and calcMode != CM_AIM) {
        // already 0
    } else if (softmenuStack[0].softmenuId == 1 and calcMode == CM_AIM) {
        changeToALPHA();
    }

    softmenuStack[0].calcMode = calcMode;

    enterAsmModeIfMenuIsACatalog(softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem);

    if (softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem == -%@as(i16, MNU_MVAR)) {
        setSystemFlag(FLAG_VMDISP);
    } else {
        clearSystemFlag(FLAG_VMDISP);
    }

    if (softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem == -%@as(i16, MNU_DYNAMIC)) {
        currentUserMenu = @intCast(softmenuStack[0].userMenuId);
    }
}

pub export fn setCurrentUserMenu(item: i16, funcParam: [*c]u8) callconv(.c) bool_t {
    if (item == -%@as(i16, MNU_DYNAMIC)) {
        var i: u32 = 0;
        while (i < numberOfUserMenus) : (i += 1) {
            if (compareString(funcParam, &userMenus[@intCast(i)].menuName, CMP_NAME) == 0) {
                currentUserMenu = @intCast(i);
                return 1;
            }
        }
    }
    return 0;
}

pub export fn createHOME() callconv(.c) bool_t {
    const itemToBeAssignedMeM: i16 = itemToBeAssigned;
    if (setCurrentUserMenu(-%@as(i16, MNU_DYNAMIC), @constCast("HOME")) == 0) {
        createMenu("HOME");
        if (setCurrentUserMenu(-%@as(i16, MNU_DYNAMIC), @constCast("HOME")) == 0) {
            itemToBeAssigned = itemToBeAssignedMeM;
            return 0;
        }
    }
    var ii: u16 = 0;
    while (ii < 18) : (ii += 1) {
        itemToBeAssigned = ITM_ENTER;
        screenUpdatingMode = ~@as(u8, SCRUPD_AUTO);
        doRefreshSoftMenu = 0;
        last_CM = 240;
        assignToUserMenu(ii);
        itemToBeAssigned = menu_HOME[ii];
        screenUpdatingMode = ~@as(u8, SCRUPD_AUTO);
        doRefreshSoftMenu = 0;
        last_CM = 240;
        assignToUserMenu(ii);
    }
    screenUpdatingMode = SCRUPD_AUTO;
    refreshScreen(170);
    itemToBeAssigned = itemToBeAssignedMeM;
    return 1;
}

pub export fn createPFN() callconv(.c) bool_t {
    const itemToBeAssignedMeM: i16 = itemToBeAssigned;
    if (setCurrentUserMenu(-%@as(i16, MNU_DYNAMIC), @constCast("P.FN")) == 0) {
        createMenu("P.FN");
        if (setCurrentUserMenu(-%@as(i16, MNU_DYNAMIC), @constCast("P.FN")) == 0) {
            itemToBeAssigned = itemToBeAssignedMeM;
            return 0;
        }
    }
    var ii: u16 = 0;
    while (ii < 18) : (ii += 1) {
        itemToBeAssigned = ITM_ENTER;
        screenUpdatingMode = ~@as(u8, SCRUPD_AUTO);
        doRefreshSoftMenu = 0;
        last_CM = 240;
        assignToUserMenu(ii);
        itemToBeAssigned = menu_MyPFN[ii];
        screenUpdatingMode = ~@as(u8, SCRUPD_AUTO);
        doRefreshSoftMenu = 0;
        last_CM = 240;
        assignToUserMenu(ii);
    }
    screenUpdatingMode = SCRUPD_AUTO;
    refreshScreen(171);
    itemToBeAssigned = itemToBeAssignedMeM;
    return 1;
}

fn changeToHOME() void {
    if (setCurrentUserMenu(-%@as(i16, MNU_DYNAMIC), @constCast("HOME")) == 0) {
        showSoftmenu(-%@as(i16, MNU_HOME));
    }
}
fn changeToPFN() void {
    if (setCurrentUserMenu(-%@as(i16, MNU_DYNAMIC), @constCast("P.FN")) == 0) {
        showSoftmenu(-%@as(i16, MNU_PFN));
    }
}
pub export fn changeToALPHA() callconv(.c) void {
    showSoftmenu(-%@as(i16, MNU_ALPHA));
}

pub export fn menu(n: u8) callconv(.c) i16 {
    if (softmenu[@intCast(softmenuStack[n].softmenuId)].menuItem == -%@as(i16, MNU_DYNAMIC) and compareString("HOME", &userMenus[@intCast(currentUserMenu)].menuName, CMP_NAME) == 0) {
        return -%@as(i16, MNU_HOME);
    } else if (softmenu[@intCast(softmenuStack[n].softmenuId)].menuItem == -%@as(i16, MNU_DYNAMIC) and compareString("P.FN", &userMenus[@intCast(currentUserMenu)].menuName, CMP_NAME) == 0) {
        return -%@as(i16, MNU_PFN);
    } else {
        return softmenu[@intCast(softmenuStack[n].softmenuId)].menuItem;
    }
}

pub export fn currentMenu() callconv(.c) i16 {
    return menu(0);
}

pub export fn isAlphaSubmenu(n: u8) callconv(.c) bool_t {
    return @intFromBool(menu(n) == -%@as(i16, MNU_MyAlpha) or
        menu(n) == -%@as(i16, MNU_ALPHA_OMEGA) or
        menu(n) == -%@as(i16, MNU_alpha_omega) or
        menu(n) == -%@as(i16, MNU_ALPHAMATH) or
        menu(n) == -%@as(i16, MNU_ALPHAMISC) or
        menu(n) == -%@as(i16, MNU_ALPHAINTL) or
        menu(n) == -%@as(i16, MNU_ALPHAintl));
}

pub export fn removeUserMenuFromStack(userMenuId: i16) callconv(.c) void {
    var i: i32 = undefined;
    const all: bool_t = if (userMenuId == @as(i16, @intCast(numberOfUserMenus))) 1 else 0;

    i = 0;
    while (i < SOFTMENU_STACK_SIZE) : (i += 1) {
        if (softmenu[@intCast(softmenuStack[@intCast(i)].softmenuId)].menuItem == -%@as(i16, MNU_DYNAMIC)) {
            if ((softmenuStack[@intCast(i)].userMenuId == userMenuId) or all == 1) {
                _ = xcopy(softmenuStack + @as(usize, @intCast(i)), softmenuStack + @as(usize, @intCast(i + 1)), @intCast((SOFTMENU_STACK_SIZE - @as(usize, @intCast(i))) * @sizeOf(softmenuStack_t)));
                softmenuStack[SOFTMENU_STACK_SIZE - 1].softmenuId = 0;
                softmenuStack[SOFTMENU_STACK_SIZE - 1].firstItem = 0;
                softmenuStack[SOFTMENU_STACK_SIZE - 1].userMenuId = 0;
                softmenuStack[SOFTMENU_STACK_SIZE - 1].calcMode = 0;
                i -= 1;
            } else if (softmenuStack[@intCast(i)].userMenuId > userMenuId) {
                softmenuStack[@intCast(i)].userMenuId -= 1;
            }
        }
    }
    if (softmenuStack[0].softmenuId == 0 and getSystemFlag(FLAG_BASE_HOME) != 0 and calcMode != CM_AIM) {
        showSoftmenu(-%@as(i16, MNU_HOME)); // must PUSH HOME to base here; not changeToHOME() which only re-points
    }
}

pub export fn removeMenuFromStack(userMenuId: i16) callconv(.c) void {
    var i: i32 = SOFTMENU_STACK_SIZE - 1;
    while (i >= 0) : (i -= 1) {
        if (menu(@intCast(i)) == userMenuId) {
            _ = xcopy(softmenuStack + @as(usize, @intCast(i)), softmenuStack + @as(usize, @intCast(i + 1)), @intCast((SOFTMENU_STACK_SIZE - @as(usize, @intCast(i)) - 1) * @sizeOf(softmenuStack_t)));
            _ = memset(softmenuStack + (SOFTMENU_STACK_SIZE - 1), 0, @sizeOf(softmenuStack_t));
        }
    }
}

pub export fn extractPFNMenus() callconv(.c) void {
    var ii: i32 = SOFTMENU_STACK_SIZE - 1;
    while (ii >= 0) : (ii -= 1) {
        if (softmenuStack[@intCast(ii)].calcMode == CM_PEM or menu(@intCast(ii)) == -%@as(i16, MNU_PFN)) {
            removeMenuFromStack(menu(@intCast(ii)));
        }
    }
}

// printTrace is IR-printing only.
const c_printTrace = if (ir_printing) @extern(*const fn (func: i16, param: u16) callconv(.c) void, .{ .name = "printTrace" }) else {};

pub export fn showSoftmenu(id_in: i16) callconv(.c) void {
    var id: i16 = id_in;
    var m: i16 = undefined;

    if (comptime ir_printing) {
        if (tam.mode == 0) {
            c_printTrace(id, NOPARAM);
        }
    }

    // INLINE_TEST is off -> the !INLINE_TEST guard returns for MNU_INL_TST.
    if (id == -%@as(i16, MNU_INL_TST)) {
        return;
    }

    screenUpdatingMode &= ~@as(u8, SCRUPD_MANUAL_MENU | SCRUPD_SKIP_MENU_ONE_TIME);
    setScreenUpdateFromMenu(id, openMenu);

    if (id == -%@as(i16, MNU_HOME)) {
        if (setCurrentUserMenu(-%@as(i16, MNU_DYNAMIC), @constCast("HOME")) == 0) {
            if (createHOME() == 0) {
                return;
            }
        }
        id = -%@as(i16, MNU_DYNAMIC);
    } else if (id == -%@as(i16, MNU_PFN)) {
        if (setCurrentUserMenu(-%@as(i16, MNU_DYNAMIC), @constCast("P.FN")) == 0) {
            if (createPFN() == 0) {
                return;
            }
        }
        id = -%@as(i16, MNU_DYNAMIC);
    }

    enterAsmModeIfMenuIsACatalog(id);

    if (id == 0) {
        displayBugScreen(bugScreenIdMustNotBe0);
        return;
    }
    if ((softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem == id) and (softmenuStack[0].softmenuId >= NUMBER_OF_DYNAMIC_SOFTMENUS) and catalog == 0) {
        softmenuStack[0].firstItem = 0;
        return;
    }

    screenUpdatingMode &= ~@as(u8, SCRUPD_MANUAL_MENU);

    if (id == -%@as(i16, MNU_ALPHAINTL) and alphaCase == AC_LOWER) {
        id = -%@as(i16, MNU_ALPHAintl);
    } else if (id == -%@as(i16, MNU_ALPHA_OMEGA) and alphaCase == AC_LOWER) {
        id = -%@as(i16, MNU_alpha_omega);
    } else if (((id == -%@as(i16, MNU_Solver) or
        id == -%@as(i16, MNU_Grapher) or
        id == -%@as(i16, MNU_Sf) or
        id == -%@as(i16, MNU_Sf_TOOL) or
        id == -%@as(i16, MNU_Solver_TOOL) or
        id == -%@as(i16, MNU_1STDERIV) or
        id == -%@as(i16, MNU_2NDDERIV)) and numberOfFormulae >= 1) or
        (id == -%@as(i16, MNU_MVAR) and (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) != 0 and (currentSolverStatus & SOLVER_STATUS_USES_FORMULA) == 0 and (currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_INTEGRATE))
    {
        var numberOfVars: i32 = -1;
        var varList: [*c]u8 = null;
        if (id != -%@as(i16, MNU_MVAR)) {
            currentSolverStatus = SOLVER_STATUS_USES_FORMULA | SOLVER_STATUS_INTERACTIVE;
            currentMvarLabel = INVALID_VARIABLE;
        }
        switch (-%id) {
            MNU_Grapher => {
                currentSolverStatus &= ~@as(u16, SOLVER_STATUS_EQUATION_MODE);
                currentSolverStatus |= SOLVER_STATUS_EQUATION_GRAPHER;
            },
            MNU_Solver_TOOL, MNU_Solver => {
                currentSolverStatus &= ~@as(u16, SOLVER_STATUS_EQUATION_MODE);
                currentSolverStatus |= SOLVER_STATUS_EQUATION_SOLVER;
            },
            MNU_Sf_TOOL, MNU_Sf => {
                currentSolverStatus &= ~@as(u16, SOLVER_STATUS_EQUATION_MODE);
                currentSolverStatus |= SOLVER_STATUS_EQUATION_INTEGRATE;
            },
            MNU_1STDERIV => {
                currentSolverStatus &= ~@as(u16, SOLVER_STATUS_EQUATION_MODE);
                currentSolverStatus |= SOLVER_STATUS_EQUATION_1ST_DERIVATIVE;
            },
            MNU_2NDDERIV => {
                currentSolverStatus &= ~@as(u16, SOLVER_STATUS_EQUATION_MODE);
                currentSolverStatus |= SOLVER_STATUS_EQUATION_2ND_DERIVATIVE;
            },
            else => {},
        }
        cachedDynamicMenu = 0;
        if (id == -%@as(i16, MNU_MVAR)) {
            var mm: i16 = 0;
            while (mm < NUMBER_OF_DYNAMIC_SOFTMENUS) : (mm += 1) {
                if (softmenu[@intCast(mm)].menuItem == -%@as(i16, MNU_MVAR)) {
                    initVariableSoftmenu(mm);
                    varList = dynamicSoftmenu[@intCast(mm)].menuContent;
                    getNthString(varList, dynamicSoftmenu[@intCast(mm)].numItems)[0] = 0;
                    break;
                }
            }
            if (varList == null) {
                displayBugScreen("In function showSoftmenu: MVAR not found!");
                varList = @constCast("\x00");
            }
        } else {
            _ = parseEquation(currentFormula, EQUATION_PARSER_MVAR, aimBuffer, tmpString);
            varList = tmpString;
        }

        if (id != -%@as(i16, MNU_Solver_TOOL) and id != -%@as(i16, MNU_Sf_TOOL)) {
            id = -%@as(i16, MNU_MVAR);
        }
        while (true) {
            numberOfVars += 1;
            if (getNthString(varList, @intCast(numberOfVars))[0] == 0) break;
        }

        if (numberOfVars > 12) {
            displayCalcErrorMessage(ERROR_EQUATION_TOO_COMPLEX, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            if (comptime extra_info) {
                moreInfoOnError("In function showSoftmenu:", "there are more than 12 variables in this equation!", null, null);
            }
        } else if ((((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_INTEGRATE) or
            ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_SOLVER) or
            ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_GRAPHER)) and numberOfVars == 1)
        {
            currentSolverVariable = @intCast(findOrAllocateNamedVariable(getNthString(varList, 0)));
        } else if ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE or (currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_2ND_DERIVATIVE) {
            if (getNthString(varList, 1)[0] == 0) {
                currentSolverVariable = @intCast(findOrAllocateNamedVariable(getNthString(varList, 0)));
                reallyRunFunction(ITM_STO, @intCast(currentSolverVariable));
                saveForUndo();
                if ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE) {
                    fn1stDerivEq(NOPARAM);
                } else {
                    fn2ndDerivEq(NOPARAM);
                }
            }
        }
    } else if (id == -%@as(i16, MNU_ADV) or id == -%@as(i16, MNU_EQN)) {
        currentSolverStatus &= ~@as(u16, SOLVER_STATUS_INTERACTIVE);
        removeMenuFromStack(-%@as(i16, MNU_MVAR));
    } else if (id == -%@as(i16, MNU_GRAPHS)) {
        currentSolverStatus &= ~@as(u16, SOLVER_STATUS_EQUATION_MODE);
        currentSolverStatus |= SOLVER_STATUS_EQUATION_GRAPHER;
    } else if (currentSolverVariable == INVALID_VARIABLE) {
        if (id == -%@as(i16, MNU_Sf_TOOL) or
            id == -%@as(i16, MNU_Sf) or
            id == -%@as(i16, MNU_Solver) or
            id == -%@as(i16, MNU_Grapher) or
            id == -%@as(i16, MNU_Solver_TOOL) or
            id == -%@as(i16, MNU_1STDERIV) or
            id == -%@as(i16, MNU_2NDDERIV))
        {
            id = -%@as(i16, MNU_EQN);
            displayCalcErrorMessage(ERROR_VARIABLE_NOT_SELECTED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            if (comptime extra_info) {
                moreInfoOnError("In function showSoftmenu:", "The solver/integrator variable is not selected. Refusing access to Tools/Solver menu prior to variable selected!", null, null);
            }
        }
    }

    m = 0;
    while (softmenu[@intCast(m)].menuItem != 0) {
        if (softmenu[@intCast(m)].menuItem == id) {
            break;
        }
        m += 1;
    }

    if (softmenu[@intCast(m)].menuItem == 0) {
        _ = sprintf(errorMessage, "In function showSoftmenu: softmenu %d not found!", @as(c_int, id));
        displayBugScreen(errorMessage);
    } else {
        if (tam.mode != 0 or (calcMode == CM_ASSIGN and tam.alpha != 0)) {
            numberOfTamMenusToPop += 1;
        }
        pushSoftmenu(m);
        if (id == -%@as(i16, MNU_MVAR)) {
            setSystemFlag(FLAG_VMDISP);
        } else {
            clearSystemFlag(FLAG_VMDISP);
        }
    }
}

pub export fn setCatalogLastPos() callconv(.c) void {
    lastCatalogPosition[@intCast(catalog)] = if (catalog != 0) softmenuStack[0].firstItem else 0;
    if (catalog == CATALOG_AINT) {
        lastCatalogPosition[CATALOG_aint] = softmenuStack[0].firstItem;
    } else if (catalog == CATALOG_aint) {
        lastCatalogPosition[CATALOG_AINT] = softmenuStack[0].firstItem;
    }
}

pub export fn currentSoftmenuScrolls() callconv(.c) bool_t {
    const menuId: i16 = softmenuStack[0].softmenuId;
    return @intFromBool(menuId > 1 and
        ((menuId < NUMBER_OF_DYNAMIC_SOFTMENUS and dynamicSoftmenu[@intCast(menuId)].numItems > 18) or
            (menuId >= NUMBER_OF_DYNAMIC_SOFTMENUS and softmenu[@intCast(menuId)].numItems > 18)));
}

pub export fn isAlphabeticSoftmenu() callconv(.c) bool_t {
    return isAlphaSubmenu(0);
}

pub export fn isJMAlphaSoftmenu(menuId: i16) callconv(.c) bool_t {
    const menuItem: i16 = softmenu[@intCast(menuId)].menuItem;
    switch (menuItem) {
        -%@as(i16, MNU_MyAlpha), -%@as(i16, MNU_ALPHA) => return 1,
        else => return 0,
    }
}

pub export fn isJMAlphaOnlySoftmenu() callconv(.c) bool_t {
    return @intFromBool(softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem == -%@as(i16, MNU_ALPHA));
}

pub export fn fnPseudoMenu(target: u16) callconv(.c) void {
    menuPageNumber = @intCast(target >> 14);
    fnOpenMenu(@as(u16, @bitCast(@as(i16, @intCast(target & 0x3fff)))));
}

pub export fn dynmenuGetLabel(menuitem: i16) callconv(.c) [*c]u8 {
    return dynmenuGetLabelWithDup(menuitem, null);
}

pub export fn dynmenuGetLabelWithDup(menuitem_in: i16, dupNum: ?*i16) callconv(.c) [*c]u8 {
    var menuitem = menuitem_in;
    if (dupNum) |dn| {
        dn.* = 0;
    }
    if (menuitem < 0 or menuitem >= dynamicSoftmenu[@intCast(softmenuStack[0].softmenuId)].numItems) {
        return @constCast("");
    }
    var labelName: [*c]u8 = dynamicSoftmenu[@intCast(softmenuStack[0].softmenuId)].menuContent;
    var prevLabelName: [*c]u8 = labelName;
    while (menuitem > 0) {
        labelName += @intCast(stringByteLength(labelName) + 1);
        menuitem -= 1;
        if (dupNum) |dn| {
            if (compareString(labelName, prevLabelName, CMP_BINARY) == 0) {
                dn.* += 1;
            } else {
                prevLabelName = labelName;
                dn.* = 0;
            }
        }
    }
    return labelName;
}

pub export fn fnBaseMenu(_: u16) callconv(.c) void {
    BASE_OVERRIDEONCE = 1;
    showSoftmenu(-%@as(i16, MNU_MyMenu));
}

pub export fn fnExitAllMenus(_: u16) callconv(.c) void {
    var cnt: u16 = SOFTMENU_STACK_SIZE - 1;
    while ((softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem != -%@as(i16, MNU_MyMenu) and softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem != -%@as(i16, MNU_MyAlpha)) or (softmenu[@intCast(softmenuStack[1].softmenuId)].menuItem != -%@as(i16, MNU_MyMenu))) {
        popSoftmenu();
        const prev = cnt;
        cnt -%= 1;
        if (prev == 0) {
            break;
        }
    }
    softmenuStack[1].softmenuId = 0;
    popSoftmenu();
}

// fnMenuDump / fnDumpMenus are entirely PC_BUILD (#if defined(PC_BUILD)); on
// firmware the bodies compile to empty. They dump menu screenshots to BMP via
// the GTK layer; debug-only, never exercised by the test suite.
const FILE = opaque {};
extern fn fopen(path: [*c]const u8, mode: [*c]const u8) ?*FILE;
extern fn fclose(f: ?*FILE) c_int;
extern fn fwrite(ptr: ?*const anyopaque, size: usize, n: usize, f: ?*FILE) usize;
extern fn printf(fmt: [*:0]const u8, ...) c_int;
extern fn stringToASCII(str: [*c]const u8, ascii: [*c]u8) void;
extern fn stringToFileNameChars(str: [*c]const u8, ascii: [*c]u8) void;
const c_gtk_widget_queue_draw = if (!dmcp_build) @extern(*const fn (?*anyopaque) callconv(.c) void, .{ .name = "gtk_widget_queue_draw" }) else {};
const c_gtk_events_pending = if (!dmcp_build) @extern(*const fn () callconv(.c) c_int, .{ .name = "gtk_events_pending" }) else {};
const c_gtk_main_iteration = if (!dmcp_build) @extern(*const fn () callconv(.c) c_int, .{ .name = "gtk_main_iteration" }) else {};
const screen_ptr = if (!dmcp_build) @extern(*?*anyopaque, .{ .name = "screen" }) else {};
const screenData_ptr = if (!dmcp_build) @extern(*[*c]u32, .{ .name = "screenData" }) else {};
const screenStride_ptr = if (!dmcp_build) @extern(*i16, .{ .name = "screenStride" }) else {};

pub export fn fnMenuDump(menu_arg: u16, item: u16, newFilenameformat: u16) callconv(.c) void {
    if (comptime dmcp_build) {
        _ = &menu_arg;
        _ = &item;
        _ = &newFilenameformat;
        return;
    }
    if (comptime !dmcp_build) {
        doRefreshSoftMenu = 1;
        showSoftmenu(softmenu[menu_arg].menuItem);
        softmenuStack[0].firstItem +%= @bitCast(item);
        showSoftmenuCurrentPart();

        var bmpFileName: [600]u8 = undefined;
        var x: i32 = undefined;
        var y: i32 = undefined;
        var uint32: u32 = undefined;
        var uint16: u16 = undefined;
        var uint8: u8 = 0;

        c_gtk_widget_queue_draw(screen_ptr.*);
        while (c_gtk_events_pending() != 0) {
            _ = c_gtk_main_iteration();
        }

        var asciiString: [448]u8 = undefined;
        var asciiMenuName: [448]u8 = undefined;

        if (newFilenameformat == 2) {
            stringToASCII(&indexOfItems[@intCast(-%softmenu[menu_arg].menuItem)].itemSoftmenuName, &asciiMenuName);
            stringToFileNameChars(&asciiMenuName, &asciiString);
            _ = sprintf(&bmpFileName, "%s.%d.bmp", &asciiString, @as(c_int, @intCast(@divTrunc(item, 18) + 1)));
            _ = printf(">>> filename:%s|\n", &bmpFileName);
        } else if (newFilenameformat == 1) {
            stringToASCII(&indexOfItems[@intCast(-%softmenu[menu_arg].menuItem)].itemSoftmenuName, &asciiMenuName);
            stringToFileNameChars(&asciiMenuName, &asciiString);
            _ = sprintf(&bmpFileName, "Menu_%03d_p%d_%s.bmp", @as(c_int, menu_arg), @as(c_int, @intCast(@divTrunc(item, 18) + 1)), &asciiString);
            _ = printf(">>> filename:%s|\n", &bmpFileName);
        }

        const bmp = fopen(&bmpFileName, "wb");

        _ = fwrite("BM", 1, 2, bmp);

        uint32 = (SCREEN_WIDTH / 8 * (SCREEN_HEIGHT - 171)) + 610;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x00000082;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x0000006c;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = SCREEN_WIDTH;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = SCREEN_HEIGHT - 171;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint16 = 0x0001;
        _ = fwrite(&uint16, 1, 2, bmp);
        uint16 = 0x0001;
        _ = fwrite(&uint16, 1, 2, bmp);
        uint32 = 0;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x000030c0;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x00001a7c;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x00001a7c;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x00000002;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x00000002;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x73524742;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0;
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x00000002;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0;
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x00dff5cc;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0;
        _ = fwrite(&uint32, 1, 4, bmp);

        uint16 = 0;
        uint32 = 0;
        y = SCREEN_HEIGHT - 1;
        while (y >= 171) : (y -= 1) {
            x = 0;
            while (x < SCREEN_WIDTH) : (x += 1) {
                uint8 <<= 1;
                if (screenData_ptr.*[@intCast(y * screenStride_ptr.* + @as(i16, @intCast(x)))] == ON_PIXEL) {
                    uint8 |= 1;
                }
                if (@rem(x, 8) == 7) {
                    _ = fwrite(&uint8, 1, 1, bmp);
                    uint8 = 0;
                }
            }
            _ = fwrite(&uint16, 1, 2, bmp);
        }

        _ = fclose(bmp);
        popSoftmenu();
    }
}

pub export fn fnDumpMenus(newFilenameformat: u16) callconv(.c) void {
    if (comptime dmcp_build) {
        _ = &newFilenameformat;
        return;
    }
    if (comptime !dmcp_build) {
        const cc: i32 = currentSolverStatus;
        currentSolverStatus = currentSolverStatus & (SOLVER_STATUS_USES_FORMULA | SOLVER_STATUS_INTERACTIVE);
        _ = printf("Dumping menus\n");
        var m: i16 = 0;
        var n: i16 = undefined;
        m = 0;
        while (softmenu[@intCast(m)].menuItem != 0) {
            n = 0;
            while (n < softmenu[@intCast(m)].numItems and softmenu[@intCast(m)].numItems != 0) {
                _ = printf("m=%d n=%d softmenu[%u].numItems=%u name:%s.%u\n", @as(c_int, m), @as(c_int, n), @as(c_uint, @intCast(m)), @as(c_uint, @intCast(softmenu[@intCast(m)].numItems)), &indexOfItems[@intCast(m)].itemCatalogName, @as(c_uint, @intCast(@rem(@as(i32, n), 18))));
                switch (-%softmenu[@intCast(m)].menuItem) {
                    MNU_1STDERIV, MNU_2NDDERIV, MNU_Sf, MNU_Solver, MNU_Grapher, MNU_SHOW => {},
                    else => {
                        fnMenuDump(@intCast(m), @intCast(n), newFilenameformat);
                    },
                }
                n += 18;
            }
            m += 1;
        }
        currentSolverStatus = @intCast(cc);
    }
}
