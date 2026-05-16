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
if errorlevel 1 (
  echo HATA: PowerShell bulunamadi. Bu program Windows 7 ve sonrasi icin yapilmistir.
  echo.
  pause
  exit /b 1
)

REM Kurulum.ps1 var mi diye kontrol et
if not exist "%~dp0Kurulum.ps1" (
  echo HATA: Kurulum.ps1 dosyasi bulunamadi.
  echo Bu BAT dosyasiyla ayni klasorde olmasi gerekir.
  echo Bulundugu klasor: %~dp0
  echo.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Kurulum.ps1"
set EXITCODE=%ERRORLEVEL%

echo.
if "%EXITCODE%"=="0" (
  echo ============================================================
  echo   Kurulum BASARIYLA tamamlandi!
  echo ============================================================
  echo.
  echo Program su an arka planda calisiyor ve bilgisayar her acildiginda
  echo otomatik olarak baslayacak. Hicbir sey yapmaniza gerek yok.
) else (
  echo ============================================================
  echo   Kurulum sirasinda bir HATA olustu.
  echo ============================================================
  echo.
  echo Olasi sebepler:
  echo   - PowerShell scriptleri kuruluş politikasiyla engellenmis olabilir
  echo   - Dosyalar Internet'ten indirildi ve "engelli" isaretli olabilir
  echo     (ZIP dosyasina sag tik - Ozellikler - "Engellemeyi kaldir")
  echo   - Klasor adinda Turkce karakter veya OneDrive olabilir, basit bir
  echo     yere kopyalayip tekrar deneyin (orn. C:\UyapKurulum)
)
echo.
pause
exit /b %EXITCODE%
