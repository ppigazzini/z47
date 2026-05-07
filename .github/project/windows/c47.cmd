@echo off
setlocal

set "APP_ROOT=%~dp0"
cd /d "%APP_ROOT%"

"%APP_ROOT%c47.exe" "--portrait" %*