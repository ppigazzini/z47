// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

#include "c47.h"
#include "c47-gtk.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

#define FILENAME_BUFFER_LENGTH 400  //allow for longer paths on pc systems

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
  static char untitled[7*11+1];    //data gets copied into here, and data can be up to 7 two-byte characters, whci can be translated to max 11 ASCII chars per two-byte character (max=STD_GAUSS_BLACK_L).
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

  gtk_file_chooser_set_current_folder(chooser, base_dir);
  if(disp_save) {
    gtk_file_chooser_set_current_name (chooser, untitled);
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
      if(strcmp(fe, ee) != 0) {
        strcat(data, ee);     //filename doesn't have the expected extension
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
  static char base_dir[FILENAME_BUFFER_LENGTH]; // at least exceed the 256 limit
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
      strcpy(filename, BASEPATH "res/testPgms/testPgms.bin");
      return FILE_OK;

    case ioPathBackup:
      strcpy(filename, CALCMODEL == USER_C47 ? "backup.cfg" : "backupR47.cfg");
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
      strcpy(base_dir, current_dir);
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

    case ioPathExportRTFProgram:
    case ioPathSaveProgram:
    case ioPathLoadProgram:
      current_dir = g_get_current_dir();
      strcpy(base_dir, current_dir);
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
      else if(path == ioPathExportRTFProgram) {
        // set current label name as default file name
        stringToASCII(tmpStringLabelOrVariableName, filename);
        //strcpy(filename, tmpStringLabelOrVariableName);
        ret = file_selection_screen("Export Program File RTF", base_dir, "*"RTF_EXT, 1, 1, filename);
      }
      else if(path == ioPathLoadProgram) {
        ret = file_selection_screen("Load Program File", base_dir, "*"PRGM_EXT, 0, 0, filename);
      }
      g_free(current_dir);
      return ret;


    case ioPathSaveAllPrograms:
    case ioPathExportRTFAllPrograms:
      if(create_dir("./" PROGRAMS_DIR) != 0) {
        return FILE_ERROR;
      }
      if(create_dir("./" PROGRAMS_DIR "/" ALLPROGRAMS_SUBDIR) != 0) {
        return FILE_ERROR;
      }
      // set current label name as default file name
      stringToASCII(tmpStringLabelOrVariableName, filename);
      //strcpy(filename, tmpStringLabelOrVariableName);

      char filename1[FILENAME_BUFFER_LENGTH];
      filename1[0] = 0;
      stringCopy(filename1, PROGRAMS_DIR "/" ALLPROGRAMS_SUBDIR "/");
      stringCopy(filename1 + stringByteLength(filename1), filename);
      filename[0] = 0;
      stringCopy(filename, filename1);
      stringCopy(filename + stringByteLength(filename), (path == ioPathSaveAllPrograms) ? PRGM_EXT : (path == ioPathExportRTFAllPrograms) ? RTF_EXT : "ERR");
      //printf("#### Filename:%s\n",filename);
      return FILE_OK;

    default:
      return FILE_ERROR;
  }
}


int ioFileOpen(ioFilePath_t path, ioFileMode_t mode) {
  assert(_ioFileHandle == NULL);
  const char *filemode;
  static char filename[FILENAME_BUFFER_LENGTH];
  strcpy(filename, "untitled");
  fileNameSelected[0]=0;
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
  if(_ioFileHandle != NULL) {
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
  static char filename[FILENAME_BUFFER_LENGTH];
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