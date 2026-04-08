// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

#include "c47.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

#define FILENAME_BUFFER_LENGTH 50

static bool_t _ioWriteEnabled = false;
static bool_t _ioReadEnabled  = false;

int _ioFileNameFromFilePath(ioFilePath_t path, char * filename) {
  int ret = 0;
  switch(path) {
    case ioPathManualSave:
      check_create_dir(SAVE_DIR);
      strcpy(filename, SAVE_DIR "\\" SAVE_FILE);
      return FILE_OK;
    case ioPathAutoSave:
      check_create_dir(SAVE_DIR);
      strcpy(filename, SAVE_DIR "\\" AUTO_SAVE_FILE);
      return FILE_OK;
    case ioPathPgmFile:
      check_create_dir(LIB_DIR);
      strcpy(filename, LIB_DIR "\\" LIB_FILE);
      return FILE_OK;
    case ioPathTestPgms:
      strcpy(filename, "testPgms.bin");
      return FILE_OK;
    case ioPathRegDump:
      //check_create_dir(SAVE_DIR);
      //strcpy(filename, SAVE_DIR "\\regx-");
      //getTimeStampString(filename + strlen(filename));
      //strcat(filename, ".tsv");
      return FILE_OK;
    case ioPathSaveStateFile:
      check_create_dir(STATE_DIR);
      ret = file_selection_screen("Save Calculator State", STATE_DIR, STATE_EXT, save_statefile, 1, 1, filename);
      return (ret == MRET_EXIT? FILE_CANCEL : FILE_OK);
   case ioPathLoadStateFile:
      check_create_dir(STATE_DIR);
      ret = file_selection_screen("Load Calculator State", STATE_DIR, STATE_EXT, load_statefile, 0, 0, filename);
      return (ret == MRET_EXIT? FILE_CANCEL : FILE_OK);
   case ioPathSaveProgram:
      check_create_dir(PROGRAMS_DIR);
      ret = file_selection_screen("Save Program", PROGRAMS_DIR, PRGM_EXT, save_programfile, 1, 1, filename);
      return (ret == MRET_EXIT? FILE_CANCEL : FILE_OK);
   case ioPathExportRTFProgram:
      check_create_dir(PROGRAMS_DIR);
      ret = file_selection_screen("Export Program RTF", PROGRAMS_DIR, RTF_EXT, save_programfile, 1, 1, filename);
      return (ret == MRET_EXIT? FILE_CANCEL : FILE_OK);
   case ioPathLoadProgram:
      check_create_dir(PROGRAMS_DIR);
      ret = file_selection_screen("Load Program", PROGRAMS_DIR, PRGM_EXT, load_programfile, 0, 0, filename);
      return (ret == MRET_EXIT? FILE_CANCEL : FILE_OK);
  default:
      return FILE_ERROR;
  }
}



int ioFileOpen(ioFilePath_t path, ioFileMode_t mode) {
  assert(!_ioWriteEnabled && !_ioReadEnabled);
  static char filename[40];
  fileNameSelected[0]=0;
  uint8_t ret = _ioFileNameFromFilePath(path, filename);
  if(ret != FILE_OK) {
    return ret;
  }
  BYTE filemode;
  switch(mode) {
    case ioModeRead:
      filemode = FA_READ;
      _ioReadEnabled = true;
      break;
    case ioModeWrite:
      filemode = FA_CREATE_ALWAYS | FA_WRITE;
      _ioWriteEnabled = true;
      break;
    case ioModeUpdate:
      filemode = FA_READ | FA_WRITE | FA_OPEN_EXISTING;
      _ioWriteEnabled = true;
      _ioReadEnabled = true;
      break;
    default:
      return FILE_ERROR;
  }
  if(mode != ioModeRead) {
    sys_disk_write_enable(1);
  }

  FRESULT result = f_open(ppgm_fp, filename, filemode);
  if(result != FR_OK) {
    if(mode != ioModeRead) {
      sys_disk_write_enable(0);
    }
    _ioWriteEnabled = false;
    _ioReadEnabled  = false;
  }
  if(result == FR_OK) {
    if(mode == ioModeRead) {
      int16_t jj = stringByteLength(filename);
      int16_t kk = max(0, jj - stateFileNameVarLength + 1);
      while(jj>kk) {
        if(filename[jj-1]!='\\' && filename[jj-1]!='/' && filename[jj-1]!=0) {
          jj--;
        }
        else {
          break;
        }
      }
      stringCopy(fileNameSelected, filename + jj);
    }
    return FILE_OK;
  }
  else {
    return FILE_ERROR;
  }
}



void ioFileWrite(const void *buffer, uint32_t size) {
  assert(_ioWriteEnabled);
  UINT bytesWritten;
  f_write(ppgm_fp, buffer, size, &bytesWritten);
}



uint32_t ioFileRead(void *buffer, uint32_t size) {
  assert(_ioReadEnabled);
  UINT bytesRead;
  f_read(ppgm_fp, buffer, size, &bytesRead);
  return bytesRead;
}



void ioFileSeek(uint32_t position) {
  assert(_ioWriteEnabled || _ioReadEnabled);
  f_lseek(ppgm_fp, position);
}



void ioFileClose(void) {
  assert(_ioWriteEnabled || _ioReadEnabled);
  f_close(ppgm_fp);
  if(_ioWriteEnabled) {
    sys_disk_write_enable(0);
  }
  _ioWriteEnabled = false;
  _ioReadEnabled = false;
}


int ioEof(void) {
  assert(_ioReadEnabled);
  return f_eof(ppgm_fp);
}



int ioFileRemove(ioFilePath_t path, uint32_t *errorNumber) {
  static char filename[40];
  uint8_t ret;
  assert(!_ioWriteEnabled && !_ioReadEnabled);
  FRESULT result;
  sys_disk_write_enable(1);
  ret = _ioFileNameFromFilePath(path, filename);
  if(ret != FILE_OK) {
    return ret;
  }
  result = f_unlink(filename);
  if(result != FR_OK && errorNumber != NULL) {
    *errorNumber = result;
  }
  sys_disk_write_enable(0);
  return (result == FR_OK? FILE_OK : FILE_ERROR);
}

//
int save_statefile(const char * fpath, const char * fname, void * data) {

  lcd_puts(t24, "Saving state ...");
  lcd_puts(t24, fname);
  lcd_refresh();

  // Store the state file name
  strcpy(data, fpath);
  set_reset_state_file(fpath);

  // Exit with appropriate code to save state file save
  return MRET_SAVESTATE;
}

int load_statefile(const char * fpath, const char * fname, void * data) {

  // 'Sure' dialog
  lcd_puts(t24, "");
  lcd_puts(t24, "WARNING: Current calculator state");
  lcd_puts(t24, "will be lost.");
  lcd_puts(t24, "");
  lcd_puts(t24, "");
  //lcd_puts(t24, "Are you sure to load this file?");
  lcd_puts(t24, "Press [ENTER] to confirm.");
  lcd_refresh();

  wait_for_key_release(-1);

  for(;;) {
    int k1 = runner_get_key(NULL);
    if(IS_EXIT_KEY(k1)) {
      return 0; // Continue the selection screen
    }
    if(is_menu_auto_off()) {
      return MRET_EXIT; // Leave selection screen
    }
    if(k1 == KEY_ENTER) {
      break; // Proceed with load
    }
  }

  lcd_putsRAt(t24, 6, "  Loading ...");
  lcd_refresh_wait();

  // Store the state file name
  strcpy(data, fpath);
  set_reset_state_file(fpath);

  // Exit with appropriate code to load state file
  return MRET_LOADSTATE;
}

int save_programfile(const char * fpath, const char * fname, void * data) {
  lcd_puts(t24, "Saving program ...");
  lcd_puts(t24, fname);
  lcd_refresh();

  // Store the program file name
  strcpy(data, fpath);

  // Exit with appropriate code to save state file save
  return MRET_SAVESTATE;
}

int load_programfile(const char * fpath, const char * fname, void * data) {
  lcd_putsRAt(t24, 6, "  Loading ...");
  lcd_refresh_wait();

  // Store the program file name
  strcpy(data, fpath);

  // Exit with appropriate code to load state file
  return MRET_LOADSTATE;
}

void show_warning(char *str) {
  char delim[] = "\n";
  char *ptr = strtok(str, delim);

  lcd_clear_buf();
  lcd_putsRAt(t24, 0, "                   WARNING");
  lcd_setLine(t24, 1);

  while(ptr != NULL) {
    lcd_puts(t24, ptr);
    ptr = strtok(NULL, delim);
  }

  lcd_putsRAt(t24, 8, "Press [ENTER] to continue.");
  lcd_refresh();
  wait_for_key_release(-1);
  for(;;) {
    int k1 = runner_get_key(NULL);
    if(k1 == KEY_ENTER || IS_EXIT_KEY(k1) || is_menu_auto_off()) {
      break;
    }
  }
}

void fnDiskInfo(uint16_t unusedButMandatoryParameter) {
  disp_disk_info("Disk Info");
  wait_for_key_press();
}
