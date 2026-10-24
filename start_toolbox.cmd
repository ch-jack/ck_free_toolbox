@echo off
setlocal
cd /d "%~dp0"
set "LAUNCHER=%~dp0CK免费工具箱.exe"
if not exist "%LAUNCHER%" goto powershell_fallback
"%LAUNCHER%" %*
exit /b %ERRORLEVEL%
:powershell_fallback
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0CKFreeToolbox.ps1" %*
exit /b %ERRORLEVEL%
