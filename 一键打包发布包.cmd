@echo off
setlocal
chcp 65001 >nul
title CK Free Toolbox Release Builder
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Build-ReleasePackage.ps1" -OpenOutput
set "EXIT_CODE=%ERRORLEVEL%"
echo.
if not "%EXIT_CODE%"=="0" (
    echo Build failed with exit code %EXIT_CODE%.
    pause
    exit /b %EXIT_CODE%
)
echo Release package completed.
pause