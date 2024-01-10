// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

#include "hal/io.h"

#include "charString.h"
#include "dateTime.h"
#include "defines.h"
#include "c47-gtk.h"
#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>

#include "c47.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

static FILE *_ioFileHandle = NULL;

static int create_dir(char * dir) {
  int ret;
  #if defined(WIN32)
    ret = mkdir( dir );
  #else // !WIN32
    ret = mkdir( dir, 0775);
  #endif // WIN32

  if(ret != 0 && errno != EEXIST) {
    return -1;
  }
  else {
    return 0;
  }
}


int file_selection_screen(const char * title, const char * base_dir, const char * ext, int disp_save, int overwrite_check, void * data) {
  GtkFileChooserNative *native;
  static char untitled[16];
  gint res;


  strcpy(untitled, data);
  strcat(untitled, ext+1);

  if(disp_save) {
    GtkFileChooserAction action = GTK_FILE_CHOOSER_ACTION_SAVE;
    native = gtk_file_chooser_native_new (title, GTK_WINDOW(frmCalc), action, "_Save", "_Cancel");
  }
  else {
    GtkFileChooserAction action = GTK_FILE_CHOOSER_ACTION_OPEN;
    native = gtk_file_chooser_native_new (title, GTK_WINDOW(frmCalc), action, "_Load", "_Cancel");
  }

  GtkFileChooser *chooser = GTK_FILE_CHOOSER (native);

  if(overwrite_check) {
      gtk_file_chooser_set_do_overwrite_confirmation (chooser, TRUE);
  }

  gtk_file_chooser_set_current_folder(chooser,base_dir);
  if(disp_save) {
    gtk_file_chooser_set_current_name (chooser,untitled);
  }
  GtkFileFilter *filter = gtk_file_filter_new ();
  gtk_file_filter_add_pattern (filter, ext);
  gtk_file_chooser_add_filter(chooser, filter);
  res = gtk_native_dialog_run (GTK_NATIVE_DIALOG (native));
  if(res == GTK_RESPONSE_ACCEPT) {
    char *filename;
    filename = gtk_file_chooser_get_filename (chooser);
    strcpy(data, filename);
    if(disp_save) {
      char * fe = data+strlen(filename)-4;
      const char * ee = ext+1;
      if(strcmp(fe,ee) != 0) {
        strcat(data,ee);     //filename doesn't have the expected extension
      }
    }
    g_free(filename);
    g_object_unref (native);
    return FILE_OK;
  }
  else {
    g_object_unref (native);
    return FILE_CANCEL;
  }
}


int _ioFileNameFromFilePath(ioFilePath_t path, char * filename) {
  static char base_dir[200];
  char * current_dir;
  int ret = 0;

  switch(path) {
    case ioPathManualSave:
      if(create_dir("./" SAVE_DIR) != 0) {
        return FILE_ERROR;
      }
      strcpy(filename, SAVE_DIR "/" SAVE_FILE);
      return FILE_OK;

    case ioPathPgmFile:
      if(create_dir("./" LIB_DIR) != 0) {
        return FILE_ERROR;
      }
      strcpy(filename, LIB_DIR "/" LIB_FILE);
      return FILE_OK;

    case ioPathTestPgms:
      strcpy(filename, BASEPATH "res/dmcp/testPgms.bin");
      return FILE_OK;

    case ioPathBackup:
      strcpy(filename, "backup.cfg");
      return FILE_OK;

    case ioPathRegDump:
      //if(create_dir("./" SAVE_DIR) != 0) {
      //  return FILE_ERROR;
      //}
      //strcpy(filename, SAVE_DIR "/regx-");
      //getTimeStampString(filename + strlen(filename));
      //strcat(filename, ".tsv");
      return FILE_OK;

    case ioPathSaveStateFile:
    case ioPathLoadStateFile:
      current_dir = g_get_current_dir();
      strcpy(base_dir,current_dir);
      if(create_dir("./" STATE_DIR) != 0) return FILE_ERROR;
      strcat(base_dir, "/" STATE_DIR);
      if(path == ioPathSaveStateFile) {
        ret = file_selection_screen("Save State File", base_dir, "*"STATE_EXT, 1, 1, filename);
      }
      else if(path == ioPathLoadStateFile) {
        ret = file_selection_screen("Load State File", base_dir, "*"STATE_EXT, 0, 0, filename);
      }
      g_free(current_dir);
      return ret;

    case ioPathExportProgram:
    case ioPathSaveProgram:
    case ioPathLoadProgram:
      current_dir = g_get_current_dir();
      strcpy(base_dir,current_dir);
      if(create_dir("./" PROGRAMS_DIR) != 0) {
        return 0;
      }
      strcat(base_dir, "/" PROGRAMS_DIR);
      if(path == ioPathSaveProgram) {
        // set current label name as default file name
        stringToASCII(tmpStringLabelOrVariableName, filename);
        //strcpy(filename, tmpStringLabelOrVariableName);
        ret = file_selection_screen("Save Program File", base_dir, "*"PRGM_EXT, 1, 1, filename);
      }
      else if(path == ioPathExportProgram) {
        // set current label name as default file name
        stringToASCII(tmpStringLabelOrVariableName, filename);
        //strcpy(filename, tmpStringLabelOrVariableName);
        ret = file_selection_screen("Export Program File", base_dir, "*"TXT_EXT, 1, 1, filename);
      }
      else if(path == ioPathLoadProgram) {
        ret = file_selection_screen("Load Program File", base_dir, "*"PRGM_EXT, 0, 0, filename);
      }
      g_free(current_dir);
      return ret;

    default:
      return FILE_ERROR;
  }
}


int ioFileOpen(ioFilePath_t path, ioFileMode_t mode) {
  assert(_ioFileHandle == NULL);
  const char *filemode;
  static char filename[40];
  strcpy(filename, "untitled");
  int ret = _ioFileNameFromFilePath(path, filename);
  if(ret != FILE_OK) {
    return ret;
  }
  switch(mode) {
    case ioModeRead:   filemode = "rb";  break;
    case ioModeWrite:  filemode = "wb";  break;
    case ioModeUpdate: filemode = "r+b"; break;
    default: return false;
  }
  _ioFileHandle = fopen(filename, filemode);
  return (_ioFileHandle != NULL ? FILE_OK : FILE_ERROR);
}


void ioFileWrite(const void *buffer, uint32_t size) {
  assert(_ioFileHandle != NULL);
  fwrite(buffer, 1, size, _ioFileHandle);
}


uint32_t ioFileRead(void *buffer, uint32_t size) {
  assert(_ioFileHandle != NULL);
  return fread(buffer, 1, size, _ioFileHandle);
}


void ioFileSeek(uint32_t position) {
  assert(_ioFileHandle != NULL);
  fseek(_ioFileHandle, position, SEEK_SET);
}


void ioFileClose(void) {
  assert(_ioFileHandle != NULL);
  fclose(_ioFileHandle);
  _ioFileHandle = NULL;
}


int ioEof(void) {
  assert(_ioFileHandle != NULL);
  return feof(_ioFileHandle);
}


int ioFileRemove(ioFilePath_t path, uint32_t *errorNumber) {
  assert(_ioFileHandle == NULL);
  static char filename[40];
  int ret = _ioFileNameFromFilePath(path, filename);
  if(ret != FILE_OK) {
    return ret;
  }
  int result = remove(filename);
  if(result == -1 && errorNumber != NULL) {
    *errorNumber = errno;
  }
  return (result != -1 ? FILE_OK : FILE_ERROR);
}


void show_warning(char *string) {
  #pragma GCC diagnostic push
  #pragma GCC diagnostic ignored "-Wformat-security"
  GtkWidget *dialog;
  dialog = gtk_message_dialog_new(GTK_WINDOW(frmCalc), GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_WARNING, GTK_BUTTONS_OK, string);
  gtk_window_set_title(GTK_WINDOW(dialog), "Warning");
  gtk_dialog_run(GTK_DIALOG(dialog));
  gtk_widget_destroy(dialog);
  #pragma GCC diagnostic pop
}


void fnDiskInfo(uint16_t unusedButMandatoryParameter) {
}