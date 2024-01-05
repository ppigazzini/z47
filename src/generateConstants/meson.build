generateConstants = executable(
  'generateConstants',
  build_by_default    : false,
  sources             : files('generateConstants.c') + decNumber_src,
  include_directories : [decNumber_inc, c47_inc],
  native              : true)
constantPointers_ch = custom_target(
  'constantPointers.ch',
  build_by_default : false,
  output           : ['constantPointers.c', 'constantPointers.h'],
  command          : [generateConstants, '@OUTPUT@'])
