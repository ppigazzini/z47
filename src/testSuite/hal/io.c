// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

#include "c47.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

static FILE *_ioFileHandle = NULL;

const char *_ioFileNameFromFilePath(ioFilePath_t path) {
  switch(path) {
    case ioPathManualSave: return "c47.sav";
    case ioPathPgmFile:    return "c47.dat";
    case ioPathTestPgms:   return "res/testPgms/testPgms.bin";
    case ioPathBackup:     return "backup.cfg";
    default:               return false;
  }
}



int ioFileOpen(ioFilePath_t path, ioFileMode_t mode) {
  assert(_ioFileHandle == NULL);
  const char *filemode;
  const char *filename = _ioFileNameFromFilePath(path);
  if(!filename) {
    return FILE_ERROR;
  }
  switch(mode) {
    case ioModeRead:   filemode = "rb";  break;
    case ioModeWrite:  filemode = "wb";  break;
    case ioModeUpdate: filemode = "r+b"; break;
    default: return FILE_ERROR;
  }
  _ioFileHandle = fopen(filename, filemode);
  return (_ioFileHandle != NULL? FILE_OK : FILE_ERROR);
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



int ioFileRemove(ioFilePath_t path, uint32_t *errorNumber) {
  assert(_ioFileHandle == NULL);
  const char *filename = _ioFileNameFromFilePath(path);
  if(!filename) {
    return FILE_ERROR;
  }
  int result = remove(filename);
  if(result == -1 && errorNumber != NULL) {
    *errorNumber = errno;
  }
  return (result != -1? FILE_OK : FILE_ERROR);
}
