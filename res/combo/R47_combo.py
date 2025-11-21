import binascii
import os
import sys

if(len(sys.argv) >= 1):
  Version = sys.argv[1]
else:
  Version = "TEST"

path1  = "DMCP5_flash_3.55.bin"
path2  = "R47.pg5"
output = "DMCP5_flash_3.55_R47-" + Version + ".bin"
FwName = Version

addrData2 = 0xA0000
tailSize = 24


with open(path1, 'rb') as f1:
  with open(path2, 'rb') as f2:
    data1 = f1.read()
    data2 = f2.read()
    with open(output, 'wb') as f3:
      f3.write(data1)
      pad1 = bytearray(addrData2 - len(data1))
      f3.write(pad1)
      f3.write(data2)
      pad2 = bytearray(2048 -24 -((addrData2 + len(data2)) % 2048))
      f3.write(pad2)
      f3.close
    with open(output, 'rb') as f3:
      combo = f3.read()
      crc   = binascii.crc32(combo)
      f3.close
    with open(output, 'ab') as f3:
      Info_ID = bytearray("SMFW", "ascii")
      Fw_ID   = bytearray([0xd3, 0x42, 0xe1, 0xee])
      splitFwName = FwName.split('.', 2)
      if(len(splitFwName) < 2):
        name = FwName
      else:
        name = splitFwName[2]
      name = name[:12] if len(name) > 12 else name  # max 12 characters
      print(name)
      Fw_Name = bytearray(name, "ascii") + bytearray(12 - len(name))
      CRC_Combo = crc.to_bytes(4, 'little')  # length: 4 bytes, byte order: Little-endian
      Fw_Info = Info_ID + Fw_ID + Fw_Name + CRC_Combo
      f3.write(Fw_Info)
      f3.close
    f2.close
  f1.close