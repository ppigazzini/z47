// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file c47-gtk.c
 ***********************************************/

#include "c47.h"
#include "version.h"

#if defined(PC_BUILD)
  #include "../t47/dsl.h"
  #include "gtkGui.h"

  #ifdef _WIN32
    #define WIN32_LEAN_AND_MEAN
    #include <windows.h>
    #include <io.h>
  #endif


  char                modelString[50];
  bool_t              mockup = false;
  uint16_t            dumpMenus = 0;
  bool_t              dumpMenusAll = false;
  bool_t              writeExportAll = false;
  uint8_t             config = 0;
  bool_t              factoryReset = false;
  bool_t              enableFunctionKeysDisplay;
  bool_t              calcLandscape;
  bool_t              calcAutoLandscapePortrait;
  GtkWidget          *screen;
  GtkWidget          *frmCalc;
  int16_t             screenStride;
  uint32_t           *screenData;
  bool_t              screenChange;
  calcKeyboard_t      calcKeyboard[43];
  int                 currentBezel; // 0=normal, 1=AIM, 2=TAM
  bool_t              resetKeys = false;
  uint8_t             calcModelNew = 255;
  char               *scriptFile = NULL;
  char               *menuDumpPath = NULL;
  char               *scriptCommand = NULL;
  bool_t              dumpDslCmds = false;

  #if defined(EXPORT_ITEMS)
    int sortItems(void const *a, void const *b) {
      return compareString(a, b, CMP_EXTENSIVE);
    }
  #endif // EXPORT_ITEMS

  #ifdef _WIN32
    static bool consoleAttached = false;
  #endif

  void readyToExit(void) {
    #ifdef _WIN32
      if(consoleAttached) {
        printf("\nYou may need to press ENTER to return to the command prompt\n");
      }
      fflush(stdout);
      fflush(stderr);
      FreeConsole();
    #endif //_WIN32
  }


  int main(int argc, char* argv[]) {
    //for debugging, force terminal output to be sequential
    //setvbuf(stdout, NULL, _IONBF, 0);
    //setvbuf(stderr, NULL, _IONBF, 0);

    #if defined(__APPLE__)
      // we take the directory where the application is as the root for this application.
      // in argv[0] is the application itself. We strip the name of the app by searching for the last '/':
      // Headless t47 keeps the shell cwd so script-relative paths resolve correctly.
      char *argv0Basename = NULL;
      if(argc >= 1 && argv[0] != NULL) {
        argv0Basename = g_path_get_basename(argv[0]);
      }
      if((argv0Basename == NULL || strcmp(argv0Basename, "t47") != 0) && argc >= 1) {
        char *curdir = malloc(1000);
        // find last /:
        char *s = strrchr(argv[0], '/');
        if(s != 0) {
          // take the directory before the appname:
          strncpy(curdir, argv[0], s-argv[0]);
          chdir(curdir);
          free(curdir);
        }
      }
      g_free(argv0Basename);
    #endif // __APPLE__

    c47MemInBlocks = 0;
    gmpMemInBytes = 0;
    mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);

    modelString[0] = 0;
    calcLandscape             = false;
    calcAutoLandscapePortrait = true;

    for(int arg=1; arg<argc; arg++) {

      if(strcmp(argv[arg], "--background") == 0) {    //must be first in the list of evaluations, as it can incremant the counter
        printf("Activated: %s\n", argv[arg]);
        if(arg+1<argc && (argv[arg+1])[0] != 0) {
          strcpy(modelString, argv[++arg]);
          if(arg+1<argc && (argv[arg+1])[0] != 0) {
            arg++;
          }
          else {
            break;
          }
        }
      }

      if(strcmp(argv[arg], "--functionkeys") == 0) {
        enableFunctionKeysDisplay = true;
        printf("Activated: %s\n", argv[arg]);
      }
      else {
        enableFunctionKeysDisplay = false;
      }

      if(strcmp(argv[arg], "--landscape") == 0) {
        calcLandscape             = true;
        calcAutoLandscapePortrait = false;
        printf("Activated: %s\n", argv[arg]);
      }

      if(strcmp(argv[arg], "--portrait") == 0) {
        calcLandscape             = false;
        calcAutoLandscapePortrait = false;
        printf("Activated: %s\n", argv[arg]);
      }

      if(strcmp(argv[arg], "--auto") == 0) {
        calcLandscape             = false;
        calcAutoLandscapePortrait = true;
        printf("Activated: %s\n", argv[arg]);
      }

      if(strcmp(argv[arg], "--c47") == 0) {
        calcModelNew = USER_C47;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--r47") == 0) {
        calcModelNew = USER_R47f_g;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--r47v0") == 0) {
        calcModelNew = USER_R47f_g;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--r47v1") == 0) {
        calcModelNew = USER_R47fg_bk;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--r47v2") == 0) {
        calcModelNew = USER_R47fg_g;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--r47v3") == 0) {
        calcModelNew = USER_R47bk_fg;
        printf("Activated: %s\n", argv[arg]);
      }


      if(strcmp(argv[arg], "--e47") == 0) {
        calcModelNew = USER_E47;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--n47") == 0) {
        calcModelNew = USER_N47;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--v47") == 0) {
        calcModelNew = USER_V47;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--d47") == 0) {
        calcModelNew = USER_D47;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--dm42") == 0) {
        calcModelNew = USER_DM42;
        printf("Activated: %s\n", argv[arg]);
      }

      if(strcmp(argv[arg], "--reset") == 0) {
        factoryReset = true;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--jm") == 0) {
        config = 1;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--rj") == 0) {
        config = 2;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--hp35") == 0) {
        config = 3;
        printf("Activated: %s\n", argv[arg]);
      }

      if(strcmp(argv[arg], "--deadkeys") == 0) {
        testDeadKeys = true;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--swapctrlcode") == 0) {
        swapCtrlCode = true;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--writeexportall") == 0) {
        printf("Activated: %s\n", argv[arg]);
        writeExportAll = true;
        loadTestPrograms = true;
        // headlessMode = true; //this needs to be made headless. Needs testing and tweaking. Later.
      }
      if(strcmp(argv[arg], "--script") == 0) {
        printf("Activated: %s\n", argv[arg]);
        if(arg+1<argc && (strcmp(argv[arg+1], "-") == 0 || argv[arg+1][0] != '-')) {
          scriptFile = argv[++arg];
          printf("File name: %s\n", scriptFile);
        } else {
            // If no script filename is provided, use stdin.
            scriptFile = "-";
        }
      }
      if(strcmp(argv[arg], "--dslcommands") == 0) {
        dumpDslCmds = true;
        headlessMode = true;
        printf("Activated: --dslcommands\n");
      }
      if(strcmp(argv[arg], "--exec") == 0 || strcmp(argv[arg], "--e") == 0 || strcmp(argv[arg], "-e") == 0) {
        printf("Activated: %s\n", argv[arg]);
        if(arg+1 < argc) {
          scriptCommand = argv[++arg];
        }
      }
      if(strcmp(argv[arg], "--headless") == 0) {
          headlessMode = true;
          printf("Activated: --headless\n");
      }
      if(strcmp(argv[arg], "--snapskiprefresh") == 0) {
          snapSkipRefresh = true;
          printf("Activated: --snapskiprefresh\n");
      }
      if(strcmp(argv[arg], "--mockup") == 0) {
        printf("Activated: %s\n", argv[arg]);
        mockup = true;
      }
      if(strcmp(argv[arg], "--dumpMenus1") == 0) {
        printf("Activated: %s\n", argv[arg]);
        dumpMenus = 1;
        headlessMode = true;
        if(arg+1<argc && (argv[arg+1])[0] != '-') {
          menuDumpPath = argv[++arg];
          if(menuDumpPath[0] == '\0' || strlen(menuDumpPath) >= 500) {
            printf("Error: implausible --dumpMenus1 path. No work done.\n");
            return 1;
          }
          printf("  menuDump path: %s\n", menuDumpPath);
        }
      }
      if(strcmp(argv[arg], "--dumpMenus2") == 0) {
        printf("Activated: %s\n", argv[arg]);
        dumpMenus = 2;
        headlessMode = true;
        if(arg+1<argc && (argv[arg+1])[0] != '-') {
          menuDumpPath = argv[++arg];
          if(menuDumpPath[0] == '\0' || strlen(menuDumpPath) >= 500) {
            printf("Error: implausible --dumpMenus2 path. No work done.\n");
            return 1;
          }
          printf("  menuDump path: %s\n", menuDumpPath);
        }
      }
      if(strcmp(argv[arg], "--dumpMenusAll") == 0) {
        printf("Activated: %s\n", argv[arg]);
        dumpMenus = 2;            // use new filename format
        dumpMenusAll = true;
        headlessMode = true;
        if(arg+1<argc && (argv[arg+1])[0] != '-') {
          menuDumpPath = argv[++arg];
          if(menuDumpPath[0] == '\0' || strlen(menuDumpPath) >= 500) {
            printf("Error: implausible --dumpMenusAll path. No work done.\n");
            return 1;
          }
          printf("  menuDump path: %s\n", menuDumpPath);
        }
      }
      if(strcmp(argv[arg], "--testPgms") == 0) {
        loadTestPrograms = true;
        printf("Activated: %s\n", argv[arg]);
      }
      if(strcmp(argv[arg], "--testData") == 0) {
        loadTestData = true;
        printf("Activated: %s\n", argv[arg]);
      }

      if(strcmp(argv[arg], "--help") == 0 || strcmp(argv[arg], "--h") == 0 || strcmp(argv[arg], "-h") == 0) {
        char cc[2];
        cc[1]=0;
        #if (CALCMODEL == USER_R47)
          #define MODELTEXT "R47"
          cc[0]='r';
        #else
          #define MODELTEXT "C47"
          cc[0]='c';
        #endif
        char ss[100];
        char sss[1000];
        stringToASCII(VERSION_STRING, ss);
        printf("\n-------------------------------------------------------------\n");
        sprintf(sss, MODELTEXT " Sim " VERSION1 ", SHA %s.\n", ss);
        printf("C47/R47 info to be found on 47calc.com\n");
        printf("C47/R47 license GPL3, details on 47calc.com\n");
        printf("\n%s", sss);
        printf("Activated: %s\n\n", argv[arg]);
        printf("%s47 --background          : specify background picture\n", cc);
        printf("%s47 --functionkeys        : display function key labels\n\n", cc);
        printf("%s47 --landscape           : landscape orientation\n", cc);
        printf("%s47 --portrait            : portrait orientation\n", cc);
        printf("%s47 --auto                : automatic orientation\n\n", cc);
        printf("%s47 --c47                 : C47\n", cc);
        printf("%s47 --r47                 : R47v0 layout (f g)\n", cc);
        printf("%s47 --r47v0               : R47v0 layout (f g)\n", cc);
        printf("%s47 --r47v1               : R47v1 layout (fg bk)\n", cc);
        printf("%s47 --r47v2               : R47v2 layout (fg g)\n", cc);
        printf("%s47 --r47v3               : R47v3 layout (bk fg) \n", cc);
        printf("%s47 --dm42                : DM42 layout\n", cc);
        printf("%s47 --e47                 : E47 layout (SIM only) (retired, historical info only)\n", cc);
        printf("%s47 --n47                 : N47 layout (SIM only) (retired, historical info only)\n", cc);
        printf("%s47 --v47                 : V47 layout (SIM only) (retired, historical info only)\n", cc);
        printf("%s47 --d47                 : D47 layout (SIM only) (retired, historical info only)\n\n", cc);
        printf("%s47 --reset               : factory defaults, do not load backup.cfg (scripted --exec/--script runs never write it back either)\n", cc);
        printf("%s47 --jm                  : Setting profile: Jaco preferences\n", cc);
        printf("%s47 --rj                  : Setting profile: RJvM preferences\n", cc);
        printf("%s47 --hp35                : Setting profile: HP-35 tribute\n\n", cc);
        printf("%s47 --deadkeys            : typewriter style dead keys\n", cc);
        printf("%s47 --swapctrlcode        : ctrl fix for Swiss keyboards\n", cc);
        printf("%s47 --testPgms            : load the test programs testPgms.bin if present; reset calculator with testPgms and create new backup.cfg when exit\n", cc);
        printf("%s47 --testData            : load the test data in Reg 10 to Reg 38\n", cc);
        printf("%s47 --help                : list all SIM switches\n", cc);
        printf("%s47 --h, %s47 -h           : see --help\n\n", cc, cc);
        printf("Dev and Automation\n%s47 --mockup              : output demo status bar layout\n", cc);
        printf("%s47 --dumpMenus1 [path]   : output all static menus to drive; old file name format 'Menu_140_p1_RIBBONS.bmp'; default folder 'menuDump' (auto headless mode)\n", cc);
        printf("%s47 --dumpMenus2 [path]   : output all static menus to drive; new file name format 'RIBBONS.1.bmp';           default folder 'menuDump' (auto headless mode)\n", cc);
        printf("%s47 --dumpMenusAll [path] : RefDB47 superset: every static menu incl. 1stDeriv/2ndDeriv/Sf/Solver/Grapher/SHOW; new file name format; default folder 'menuDump' (auto headless mode)\n", cc);
        printf("%s47 --writeexportall      : output all PROGs (internal use)\n", cc);
        printf("%s47 --script <file>       : execute DSL script from file or - for stdin\n", cc);
        printf("%s47 --exec <commands>     : execute DSL commands inline, ┬ e.g. ./t47 --exec 'nim 123; x!'\n", cc);
        printf("%s47 --e, %s47 -e <commands>: see --exec,                  ┴ e.g. ./t47 --exec 'nim 3; nim -4; xeq yˣ'\n", cc, cc);
        printf("%s47 --headless            : suppress GTK interface startup\n", cc);
        printf("%s47 --snapskiprefresh     : prevents refresh spoiling the graphic screens for DSL snap\n", cc);
        printf("%s47 --dslcommands         : produce T47 ops table in %s\n", cc, dslOpsFileName);
        #if defined(_WIN32)
          printf("\nExample for command line operation: \n  %s47.exe --headless --script res/SCRIPTS/example.t47\n", cc);
          printf(  "Cmd returns the prompt before output ends. Run via 'start /wait %s47.exe ...' or pipe '| more' to prevent that.\n\n", cc);
        #else
          printf("\nExample: ./%s47 --headless --script ./res/SCRIPTS/example.t47\n\n", cc);
        #endif
        return 0;
      }
    }


    if(!headlessMode) { //already we know it is headless, no need to check further
      char *argv0Basename = NULL;
      if(argc >= 1 && argv[0] != NULL) {
        argv0Basename = g_path_get_basename(argv[0]);
      }
      if(argv0Basename != NULL && (strcmp(argv0Basename, "t47") == 0 || strcmp(argv0Basename, "t47.exe") == 0)) { //if not explicit, then set headless if t47 is used
        headlessMode = true;
      }
      g_free(argv0Basename);
    }


    #ifdef _WIN32
      if(headlessMode && AttachConsole(ATTACH_PARENT_PROCESS)) {
        if(_fileno(stdout) < 0 || GetFileType((HANDLE)_get_osfhandle(_fileno(stdout))) == FILE_TYPE_UNKNOWN) {
          freopen("CONOUT$", "w", stdout);
          freopen("CONOUT$", "w", stderr);
          consoleAttached = true;
        }
      }
    #endif

    if(strcmp(indexOfItems[LAST_ITEM].itemSoftmenuName, "Last item") != 0) {
      printf("The last item (%u)of indexOfItems[] is not \"Last item\", but is %s\n", LAST_ITEM, indexOfItems[LAST_ITEM].itemSoftmenuName);
      readyToExit();
      exit(1);
    }

    #if defined(EXPORT_ITEMS)
      char name[LAST_ITEM][16], nameUtf8[25];
      int cat, nbrItems = 0;
      for(int i=1; i<LAST_ITEM; i++) {
        cat = indexOfItems[i].status & CAT_STATUS;
        if(cat == CAT_FNCT || cat == CAT_CNST || cat == CAT_SYFL || cat == CAT_RVAR) {
          strncpy(name[nbrItems++], indexOfItems[i].itemCatalogName, 16);
        }
      }
      qsort(name, nbrItems, 16, sortItems);
      printf("To be meaningful, the list below must\n");
      printf("be displayed with the C47__StandardFont!\n");
      for(int i=0; i<nbrItems; i++) {
        stringToUtf8(name[i], (uint8_t *)nameUtf8);
        printf("%s\n", nameUtf8);
      }
      readyToExit();
      exit(0);
    #endif // EXPORT_ITEMS

    //set the R47/C47 mode for initial startup, and bear in mind a command line override
    if(calcModel == USER_R47) {
      calcModel = USER_R47f_g;  //set the initial mode per sim starting exe file
    }
    if(calcModelNew != 255) {
      calcModel = calcModelNew; //set the initial mode if forced, override the default name from above
      printf("calcModel A re-set to %d\n", calcModelNew);
    }

    gtk_init(&argc, &argv);
    setupUI();

    if(!headlessMode) {
      // Without the following 8 lines of code
      // the f- and g-shifted labels are
      // miss aligned! I dont know why!
      calcModeAimGui();
      while(gtk_events_pending()) {
        gtk_main_iteration();
      }
      calcModeNormalGui();
      while(gtk_events_pending()) {
        gtk_main_iteration();
      }
    }

    if(factoryReset) {   //--reset: factory defaults, backup.cfg deliberately not loaded
      fnReset(CONFIRMED);
      printf("Factory reset: backup.cfg not loaded\n");
    }
    else {
      restoreCalc();
    }

    //set the calculator type again if it changes after loading the backup file
    if(calcModelNew != 255) {
      calcModel = calcModelNew;
      printf("calcModel B re-set to %d\n", calcModelNew);
      resetKeys = true;
    }
    if(CALCMODEL == USER_R47) {
      if(!isR47FAM) {
        fnRESET_MyM(ITM_RIBBON_R47);            // Reset Menu MyMenu
        printf("Restoring ribbon to R47 due to calculator model change.\n");
        resetKeys = true;
      }
    }
    if(CALCMODEL == USER_C47) {
      if(calcModel != USER_C47) {
        fnRESET_MyM(ITM_RIBBON_C47);            // Reset Menu MyMenu
        printf("Restoring ribbon to C47 due to calculator model change.\n");
        resetKeys = true;
      }
    }
    if(calcModelNew != 255) {
      printf("ClrMod due to calculator model change.\n");
      clearSystemFlag(FLAG_USER);
      fnClrMod(NOPARAM);
      calcModeNormal();
    }
    if(resetKeys) {
      printf("Resetting keys due to incompatible layout.\n");
      fnKeysManagement(calcModel);
      fnRefreshState();
      calcModeNormal();
    }


    //set the special user profile
    switch(config) {
      case 1: fnSetJM(0);   break;
      case 2: fnSetRJ(0);   break;
      case 3: fnSetHP35(0); break;
      default:;
    }

    if(writeExportAll) {
      fnReset(CONFIRMED);
      fnSaveAllPrograms(NOPARAM);
      readyToExit();
      return 0;
    }

    if(mockup) {
      fnReset(CONFIRMED);
      clearScreen(120);
      mockupSB();
      fnScreenDump(NOPARAM);
      char bmpFileName[22];
      time_t rawTime;
      struct tm *timeInfo;
      time(&rawTime);
      timeInfo = localtime(&rawTime);
      strftime(bmpFileName, 22, "%Y%m%d-%H%M****.bmp", timeInfo);
      printf("\n\nOutput file saved to: %s.\n\n", bmpFileName);
      readyToExit();
      return 0;
    }

    if(dumpMenus > 0) {
      fnReset(CONFIRMED);
      clearScreen(121);
      if(dumpMenusAll) {
        fnDumpMenusAll(dumpMenus, menuDumpPath);
      } else {
        fnDumpMenus(dumpMenus, menuDumpPath);
      }
      printf("\n\nOutput menus saved.\n");
      readyToExit();
      return 0;
    }

    // Run --exec command if given, before any script handling.
    if(scriptCommand != NULL) {
      initDSL();
      int ret = executeCommand(scriptCommand);
      cleanupDSL();
      readyToExit();
      return ret;
    }
    // Run scripts only after normal post-restore normalization.
    if(headlessMode || scriptFile != NULL) {
      // In headless mode with no script specified, use stdin.
      if(scriptFile == NULL) {
        scriptFile = "-";
      }
      initDSL();
      int ret = executeScript(scriptFile);
      cleanupDSL();
      readyToExit();
      return ret;
    }
    refreshScreen(190);

    gdk_threads_add_timeout(SCREEN_REFRESH_PERIOD, refreshLcd, NULL); // refreshLcd is called every SCREEN_REFRESH_PERIOD ms
    fnTimerReset();                                                    //dr timeouts for kb handling
    fnTimerConfig(TO_FG_LONG, refreshFn, TO_FG_LONG);
    fnTimerConfig(TO_CL_LONG, refreshFn, TO_CL_LONG);
    fnTimerConfig(TO_FG_TIMR, refreshFn, TO_FG_TIMR);
    fnTimerConfig(TO_FN_LONG, refreshFn, TO_FN_LONG);
    fnTimerConfig(TO_FN_EXEC, execFnTimeout, 0);
    fnTimerConfig(TO_3S_CTFF, shiftCutoff, TO_3S_CTFF);
    fnTimerConfig(TO_CL_DROP, fnTimerDummy1, TO_CL_DROP);
    //fnTimerConfig(TO_AUTO_REPEAT, execAutoRepeat, 0);                 //dr no autorepeat for emulator
    fnTimerConfig(TO_TIMER_APP, execTimerApp, 0);
    fnTimerConfig(TO_ASM_ACTIVE, refreshFn, TO_ASM_ACTIVE);
    //fnTimerConfig(TO_KB_ACTV, fnTimerEndOfActivity, TO_KB_ACTV);      //dr no keyboard scan boost for emulator
    gdk_threads_add_timeout(5, refreshTimer, NULL);                     //dr refreshTimer is called every 5 ms    //^^

    if(getSystemFlag(FLAG_AUTXEQ)) {
      clearSystemFlag(FLAG_AUTXEQ);
      if(programRunStop != PGM_RUNNING) {
        screenUpdatingMode = SCRUPD_AUTO;
        runFunction(ITM_RS);
      }
      refreshScreen(191);
    }

    gtk_main();

    readyToExit();
    return 0;
  }
#endif // PC_BUILD

