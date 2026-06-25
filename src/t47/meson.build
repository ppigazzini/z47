# Jim Tcl DSL module — baked static library (no upstream configure/make/sh).

jim_srcdir = '../../dep/jimtcl'

if host_machine.system() == 'windows'
  _jimautoconf_in = 'jimautoconf-win32.h'
elif host_machine.system() == 'darwin'
  _jimautoconf_in = 'jimautoconf-macos.h'
else
  _jimautoconf_in = 'jimautoconf-linux.h'
endif
configure_file(
  input: _jimautoconf_in,
  output: 'jimautoconf.h',
  copy: true,
)

jim_core_src = files(
  jim_srcdir / 'jim.c',
  jim_srcdir / 'jimiocompat.c',
  jim_srcdir / 'jim-subcmd.c',
  jim_srcdir / 'jim-format.c',
  jim_srcdir / 'utf8.c',
  jim_srcdir / 'jimregexp.c',
)

jim_ext_src = files(
  jim_srcdir / 'jim-package.c',
  jim_srcdir / 'jim-aio.c',
  jim_srcdir / 'jim-array.c',
  jim_srcdir / 'jim-clock.c',
  jim_srcdir / 'jim-exec.c',
  jim_srcdir / 'jim-file.c',
  jim_srcdir / 'jim-pack.c',
  jim_srcdir / 'jim-readdir.c',
  jim_srcdir / 'jim-regexp.c',
)

jim_gen_src = files(
  'jimgen/_glob.c',
  'jimgen/_stdlib.c',
  'jimgen/_tclcompat.c',
)

jim_c_args = ['-Wno-error', '-w', '-DUSE_UTF8', '-D_GNU_SOURCE']
if host_machine.system() == 'windows'
  jim_load_static = files('jimgen/jim-load-static-exts-win32.c')
  jim_platform_src = files(
    jim_srcdir / 'jim-win32compat.c',
    jim_srcdir / 'jim-nosignal.c',
  )
  jim_c_args += ['-UWIN32']
else
  jim_load_static = files('jimgen/jim-load-static-exts.c')
  jim_platform_src = files(
    jim_srcdir / 'jim-tty.c',
    jim_srcdir / 'openpty.c',
    jim_srcdir / 'jim-signal.c',
  )
endif

jim_inc = [
  include_directories('.'),
  include_directories('jimgen'),
  include_directories(jim_srcdir),
]

jim_lib = static_library(
  'jim',
  jim_load_static + jim_core_src + jim_ext_src + jim_gen_src + jim_platform_src,
  include_directories: jim_inc,
  c_args: jim_c_args,
  install: false,
  native: true,
)

t47_inc = [
  include_directories('.'),
  include_directories(jim_srcdir),
]

t47_dsl_src = files('dsl.c', 'value.c')

if not meson.is_cross_build()
  t47_dep = declare_dependency(
    include_directories: t47_inc + [include_directories('../c47-gtk')],
    link_with: jim_lib,
    sources: t47_dsl_src,
  )
else
  t47_dep = declare_dependency(
    include_directories: t47_inc,
    link_with: jim_lib,
  )
endif
