@echo off
chcp 65001 >nul
title UYAP Otomatik Kaydetme - Kurulum

echo.
echo ============================================================
echo   UYAP Dokuman Editoru - Otomatik Kaydetme Kurulumu
echo ============================================================
echo.

REM PowerShell var mi diye kontrol et
where powershell.exe >nul 2>&1
if errorlevel 1 goto :no_powershell

REM Kurulum.ps1 var mi diye kontrol et
if not exist "%~dp0Kurulum.ps1" goto :no_ps1

REM Asil kurulum
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Kurulum.ps1"
set EXITCODE=%ERRORLEVEL%

echo.
if "%EXITCODE%"=="0" goto :success
goto :failure

:no_powershell
echo HATA: PowerShell bulunamadi.
echo Bu program Windows 7 ve sonrasi icin yapilmistir.
echo.
pause
exit /b 1

:no_ps1
echo HATA: Kurulum.ps1 dosyasi bulunamadi.
echo Bu BAT dosyasiyla ayni klasorde olmasi gerekir.
echo Bulundugu klasor: %~dp0
echo.
pause
exit /b 1

:success
echo ============================================================
echo   Kurulum BASARIYLA tamamlandi!
echo ============================================================
echo.
echo Program su an arka planda calisiyor.
echo Bilgisayar her acildiginda otomatik baslayacak.
echo Hicbir sey yapmaniza gerek yok.
echo.
pause
exit /b 0

:failure
echo ============================================================
echo   Kurulum sirasinda bir HATA olustu.
echo ============================================================
echo.
echo Olasi sebepler:
echo   - PowerShell scriptleri grup politikasiyla engellenmis olabilir.
echo   - Dosyalar Internet'ten indirildi ve engelli isaretli olabilir.
echo     ZIP dosyasina sag tiklayip Ozellikler kismindan
echo     "Engellemeyi kaldir" kutusunu isaretleyin.
echo   - Klasor adinda Turkce karakter veya OneDrive olabilir.
echo     Basit bir yere kopyalayip tekrar deneyin.
echo     Ornegin: C:\UyapKurulum
echo.
pause
exit /b %EXITCODE%
