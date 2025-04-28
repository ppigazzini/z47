project('gmp', 'c',
  version       : '6.2.1',
  meson_version : '>=0.57.0',
  license       : ['LGPL-3.0-only', 'GPL-2.0-only'],
)

env = environment()
env.append('CFLAGS',
  '-Os',
  separator : ' ')

mod = import('unstable-external_project')

p = mod.add_project(
  'configure',
  configure_options : [
    '--prefix=@PREFIX@',
    '--libdir=@PREFIX@/@LIBDIR@',
    '--includedir=@PREFIX@/@INCLUDEDIR@',
    '--disable-cxx'],
  cross_configure_options : [
    '--host=arm-none-eabi',
    '--disable-assembly',
    '--disable-shared',
    '--disable-fft'],
  env : env
)

arm_gmp_dep = p.dependency('gmp')
meson.override_dependency('arm-gmp-6.2.1', arm_gmp_dep)

