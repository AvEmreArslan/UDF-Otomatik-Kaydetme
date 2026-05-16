@echo off
chcp 65001 >nul
title UYAP Otomatik Kaydetme - Kaldirma

echo.
echo ============================================================
echo   UYAP Dokuman Editoru - Otomatik Kaydetme Kaldirma
echo ============================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Kaldir.ps1"
set EXITCODE=%ERRORLEVEL%

echo.
if "%EXITCODE%"=="0" goto :success
goto :failure

:success
echo Kaldirma BASARILI!
echo.
pause
exit /b 0

:failure
echo Kaldirma sirasinda bir HATA olustu.
echo Yukaridaki mesajlari kontrol edin.
echo.
pause
exit /b %EXITCODE%
