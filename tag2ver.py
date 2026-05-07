# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

# This script reads Git tag name and prints the version number for the property of Windows executable
# This is only used for building the Windows executable.

import subprocess

try:
  result    = subprocess.run(['git', 'describe', '--tags', '--match=\'[0-9]*\'', '--long', '--dirty=-mod'], capture_output=True)
  output    = result.stdout.decode('utf-8').strip().split('-')
  majorver  = 0
  minorver  = 0
  patchver  = 0
  commitver = 0
  modded    = 0

  try:
    if output[-1] == 'mod':
      commitver = int(output[-3])
      modded = 1
    else:
      commitver = int(output[-2])
  except ValueError:
    pass

  if output[0].count('.') > 0:
    try:
      [majorver, minorver, patchver] = [int(x.rstrip('abcdefghijklmnopqrstuvwxyz')) for x in (output[0].split('.') + ['0','0','0'])[0:3]]
    except ValueError:
      pass
  elif output[0].count('_') > 0:
    try:
      [minorver, patchver] = [int(x.rstrip('abcdefghijklmnopqrstuvwxyz')) for x in (output[0].split('_') + ['0','0'])[0:2]]
      subver = 0
      try:
        subver = int(output[0].split('_')[1].lstrip('0123456789')[0], 36) - 9
      except IndexError:
        pass
      commitver += subver * 1000
    except ValueError:
      pass

  print('{0},{1},{2},{3};{4}'.format(majorver, minorver, patchver, commitver, modded))

except subprocess.CalledProcessError:
  print('0,0,0,0;0')
