c47_gtk_src = files(
  'c47-gtk.c',
  'gtkGui.c',
  'hal/audio.c',
  'hal/gui.c',
  'hal/lcd.c',
  'hal/io.c',
  'hal/print_ir.c')

override_opts = ['b_coverage=false']
cflags        = []
linkargs      = []
c47_gtk_rc    = []

if get_option('buildtype').startswith('release')
  override_opts += ['b_lto=true']
else
  cflags        += ['-fstack-protector-strong']
  linkargs      += ['-fstack-protector-strong']
  # Sanitizers not supported on MinGW
  if (host_machine.system() == 'linux' or host_machine.system() == 'darwin')
    override_opts += ['b_sanitize=address,undefined']
  endif
endif

if (target_machine.system() == 'windows')
  windows = import('windows')
  c47_gtk_rc += windows.compile_resources('c47-gtk.rc', depend_files: [version_h], depends: [vcs_h], include_directories: [c47_inc])
endif

sim = executable('c47',
  sources             : decNumber_src + c47_src + c47_gtk_src + c47_gtk_rc + [rasterFontsData_c, softmenuCatalogs_h, constantPointers_ch, vcs_h, version_h],
  c_pch               : 'pch/c47-gtk_pch.h',
  include_directories : [decNumber_inc, c47_inc],
  dependencies        : [gtk_dep, gmp_dep, m_dep, pulse_dep],
  native              : true,
  override_options    : ['b_lto=true'],
  win_subsystem       : 'windows'
)

alias_target('sim', sim)
