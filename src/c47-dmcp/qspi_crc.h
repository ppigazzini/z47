// This file is used in the first pass of the DMCP build so that the real QSPI
// size can be determined

#if defined(USE_GEN_QSPI_CRC)
  #include "generated_qspi_crc.h"
#elif defined(USE_GEN_R47_QSPI_CRC)
  #include "generated_r47_qspi_crc.h"
#else
  #define QSPI_DATA_SIZE 82620
  #define QSPI_DATA_CRC 0x000CFED6
#endif
