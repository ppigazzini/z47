#if !defined(_JIMAUTOCONF_H)
#define _JIMAUTOCONF_H
/*#define HAVE_ARPA_INET_H 1*/ //jm no sockets on win32 build
/* #undef HAVE_BACKTRACE */
#define HAVE_CFLAG_FNO_ASYNCHRONOUS_UNWIND_TABLES 1
#define HAVE_CFLAG_FNO_UNWIND_TABLES 1
/* #undef HAVE_CRT_EXTERNS_H */
#define HAVE_DECL_ISINF 1
#define HAVE_DECL_ISNAN 1
/*#define HAVE_DECL_S_IRWXG 1*/ //jm no group mode bits on win32
/*#define HAVE_DECL_S_IRWXO 1*/ //jm no other mode bits on win32
#define HAVE_DECL_S_IXUSR 1
#define HAVE_DIRENT_H 1
/*#define HAVE_DLFCN_H 1*/ //jm no dlfcn.h; win32compat provides dlopen
#define HAVE_DLOPEN_COMPAT 1
#define HAVE_DUP 1
/* #undef HAVE_EXECINFO_H */
/* #undef HAVE_EXECVPE */
#define HAVE_FCNTL_H 1
/* #undef HAVE_FORK */
#define HAVE_FSTAT 1
/*#define HAVE_FSYNC 1*/ //jm MinGW has _commit, not fsync
/*#define HAVE_GETADDRINFO 1*/ //jm no sockets on win32 build
/*#define HAVE_GETEUID 1*/ //jm no geteuid on win32
#define HAVE_GMTIME 1
/*#define HAVE_INET_NTOP 1*/ //jm no sockets on win32 build
#define HAVE_ISASCII 1
#define HAVE_ISATTY 1
#define HAVE_LFS 1
/*#define HAVE_LINK 1*/ //jm no link() on win32
#define HAVE_LOCALTIME 1
#define HAVE_LONG_LONG 1
/*#define HAVE_LSTAT 1*/ //jm no lstat() on win32
#define HAVE_MATH_H 1
#define HAVE_MKDIR_ONE_ARG 1 //jm MinGW mkdir takes one arg
#define HAVE_MKSTEMP 1
/*#define HAVE_NETDB_H 1*/ //jm no sockets on win32 build
/*#define HAVE_NETINET_IN_H 1*/ //jm no sockets on win32 build
#define HAVE_OPENDIR 1
/*#define HAVE_OPENPTY 1   */ //jm
#define HAVE_PIPE 1
/*#define HAVE_POSIX_OPENPT 1*/ //jm no pty on win32
/*#define HAVE_PTY_H 1   */ //jm
/*#define HAVE_READLINK 1*/ //jm no readlink() on win32
/*#define HAVE_REALPATH 1*/ //jm no realpath() on MinGW
#define HAVE_REGCOMP 1
#define HAVE_RESTRICT 1
/*#define HAVE_SELECT 1*/ //jm select is winsock-only, no sockets on win32 build
/*#define HAVE_SHUTDOWN 1*/ //jm no sockets on win32 build
/*#define HAVE_SIGACTION 1*/ //jm no sigaction on win32 (jim-nosignal.c)
#define HAVE_SLEEP 1
/*#define HAVE_SOCKET 1*/ //jm no sockets on win32 build
/*#define HAVE_SOCKETPAIR 1*/ //jm no sockets on win32 build
#define HAVE_STDLIB_H 1
#define HAVE_STRINGS_H 1
/* #undef HAVE_STRPTIME */
/*#define HAVE_STRUCT_FLOCK 1*/ //jm no struct flock / fcntl locking on win32
/*#define HAVE_STRUCT_STAT_ST_MTIM 1*/ //jm MinGW _stat64 has st_mtime, no st_mtim
/* #undef HAVE_STRUCT_STAT_ST_MTIMESPEC */
/*#define HAVE_STRUCT_SYSINFO_UPTIME 1*/ //jm no sysinfo on win32
#define HAVE_SYMLINK 1
/*#define HAVE_SYSINFO 1*/ //jm Linux sysinfo(2), not on win32
#define HAVE_SYSLOG 1
#define HAVE_SYSTEM 1
#define HAVE_SYS_SIGLIST 1
/* #undef HAVE_SYS_SIGNAME */
/*#define HAVE_SYS_SOCKET_H 1*/ //jm no sockets on win32 build
#define HAVE_SYS_STAT_H 1
/*#define HAVE_SYS_SYSINFO_H 1*/ //jm no sysinfo on win32
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TYPES_H 1
/*#define HAVE_SYS_UN_H 1*/ //jm no sockets on win32 build
/*#define HAVE_TERMIOS_H 1  */ //jm
#define HAVE_TIME_H 1
/*#define HAVE_UALARM 1*/ //jm no ualarm on win32
#define HAVE_UMASK 1
#define HAVE_UNISTD_H 1
#define HAVE_USLEEP 1
/* #undef HAVE_UTIL_H */
/*#define HAVE_UTIMES 1*/ //jm no utimes on win32
/* #undef HAVE_VFORK */
#define HAVE_WAITPID 1
#define HAVE_WINCONSOLE 1
#define HAVE_WINDOWS 1
/* #undef HAVE__NSGETENVIRON */
#define JIM_DOCS 1
#define JIM_GITVERSION "0.83-110-g5516ba9"
#define JIM_INSTALL 1
/* #undef JIM_RANDOMISE_HASH */
#define JIM_REFERENCES 1
#define JIM_REGEXP 1
#define JIM_STATICLIB 1
#define JIM_TAINT 1
#define JIM_UTF8 1
#define JIM_VERSION 84
#define SIZEOF_INT 4
#define SIZEOF_OFF_T 8
#define SIZEOF_TIME_T 8
#define TCL_LIBRARY "/usr/local/lib/jim"
#define TCL_PLATFORM_OS "mingw"
#define TCL_PLATFORM_PATH_SEPARATOR ";"
#define TCL_PLATFORM_PLATFORM "windows"
#define jim_ext_aio 1
#define jim_ext_array 1
#define jim_ext_clock 1
#define jim_ext_exec 1
#define jim_ext_file 1
#define jim_ext_glob 1
#define jim_ext_pack 1
#define jim_ext_package 1
#define jim_ext_readdir 1
#define jim_ext_regexp 1
#define jim_ext_signal 1
#define jim_ext_stdlib 1
#define jim_ext_tclcompat 1
#endif // _JIMAUTOCONF_H
