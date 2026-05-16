#Requires -Version 5.1
<#
.SYNOPSIS
    UYAP Otomatik Kaydetme programını kullanıcı hesabına kurar.
.DESCRIPTION
    - Dosyaları %LOCALAPPDATA%\UyapOtomatikKayit klasörüne kopyalar.
    - Windows açılışında otomatik başlaması için HKCU Run anahtarına ekler.
    - Programı arka planda hemen başlatır.
    Yönetici yetkisine GEREK YOKTUR.
#>

$ErrorActionPreference = 'Stop'

# Türkçe çıktı için kod sayfası ayarı
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

function Yaz {
    param([string]$Mesaj, [string]$Tip = 'BILGI')
    $renk = switch ($Tip) {
        'OK'    { 'Green' }
        'HATA'  { 'Red' }
        'UYARI' { 'Yellow' }
        default { 'White' }
    }
    Write-Host "[$Tip] $Mesaj" -ForegroundColor $renk
}

# ============================================================
# Yollar
# ============================================================

$kaynakKlasor = $PSScriptRoot
if (-not $kaynakKlasor) { $kaynakKlasor = (Get-Location).Path }

$hedefKlasor = Join-Path $env:LOCALAPPDATA 'UyapOtomatikKayit'
$vbsYolu     = Join-Path $hedefKlasor 'Baslat.vbs'
$runKey      = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runAdi      = 'UyapOtomatikKayit'

# ============================================================
# Mark-of-the-Web (MoTW) temizliği
# ============================================================
# İnternetten indirilen ZIP dosyalarındaki scriptler Windows tarafından
# "engelli" olarak işaretlenir. Bu işareti temizlemezsek PowerShell scripti
# güvenlik nedeniyle çalıştıramaz. Aşağıdaki blok kaynak klasördeki tüm
# UYAP dosyalarındaki bu işareti kaldırır.

try {
    $temizlenecek = @('*.ps1', '*.bat', '*.vbs', '*.md')
    foreach ($desen in $temizlenecek) {
        Get-ChildItem -Path $kaynakKlasor -Filter $desen -ErrorAction SilentlyContinue |
            Unblock-File -ErrorAction SilentlyContinue
    }
    Yaz 'Internet engelleme isareti temizlendi (Mark-of-the-Web).' 'OK'
} catch {
    Yaz "MoTW temizleme uyarisi: $($_.Exception.Message)" 'UYARI'
}

Write-Host ''
Write-Host 'Bu kurulum su islemleri yapacak:'
Write-Host '  1. Dosyalar  -> ' $hedefKlasor
Write-Host '  2. Otomatik baslangic kaydi (sadece sizin kullanici hesabiniz icin)'
Write-Host '  3. Program arka planda hemen baslatilir'
Write-Host ''
Write-Host 'Yonetici yetkisi GEREKMIYOR.'
Write-Host ''

# ============================================================
# 1) Klasör oluştur ve dosyaları kopyala
# ============================================================

try {
    if (-not (Test-Path $hedefKlasor)) {
        New-Item -ItemType Directory -Path $hedefKlasor -Force | Out-Null
    }

    $kopyalanacak = @(
        'UyapOtomatikKayit.ps1',
        'Baslat.vbs',
        'Kaldir.bat',
        'Kaldir.ps1',
        'OKUBENI.md'
    )

    $eksikZorunlular = @()
    foreach ($d in $kopyalanacak) {
        $kaynak = Join-Path $kaynakKlasor $d
        if (Test-Path $kaynak) {
            Copy-Item -Path $kaynak -Destination $hedefKlasor -Force
        } else {
            if ($d -in @('UyapOtomatikKayit.ps1', 'Baslat.vbs')) {
                $eksikZorunlular += $d
            }
        }
    }

    if ($eksikZorunlular.Count -gt 0) {
        throw "Zorunlu dosya(lar) bulunamadi: $($eksikZorunlular -join ', ')"
    }

    Yaz 'Dosyalar kopyalandi.' 'OK'
} catch {
    Yaz "Dosya kopyalama hatasi: $($_.Exception.Message)" 'HATA'
    exit 1
}

# ============================================================
# 2) Windows açılışına ekle (HKCU Run)
# ============================================================

try {
    if (-not (Test-Path $runKey)) {
        New-Item -Path $runKey -Force | Out-Null
    }
    $deger = "wscript.exe `"$vbsYolu`""
    Set-ItemProperty -Path $runKey -Name $runAdi -Value $deger -Force
    Yaz 'Windows acilisina eklendi.' 'OK'
} catch {
    Yaz "Otomatik baslatma kaydi yapilamadi: $($_.Exception.Message)" 'HATA'
    Yaz 'Bu, kullanici hesabinizdaki kayit defterine yazma izni eksikse olur.' 'BILGI'
    Yaz 'Genelde Group Policy kisitlamalarindan kaynaklanir.' 'BILGI'
    exit 1
}

# ============================================================
# 3) Eski örneği kapat ve yenisini başlat
# ============================================================

try {
    # Eskiden çalışan örnek varsa nazikçe sonlandır
    Get-Process wscript -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            if ($cmd -and ($cmd -like "*Baslat.vbs*")) {
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }

    Start-Sleep -Milliseconds 300

    Start-Process -FilePath 'wscript.exe' -ArgumentList "`"$vbsYolu`"" -WindowStyle Hidden
    Yaz 'Program arka planda baslatildi.' 'OK'
} catch {
    Yaz "Baslatma sirasinda uyari: $($_.Exception.Message)" 'UYARI'
    Yaz 'Bilgisayari yeniden baslattiginizda program otomatik calisacak.' 'BILGI'
}

# ============================================================
# Bitiş
# ============================================================

Write-Host ''
Write-Host '============================================================'
Yaz 'KURULUM TAMAMLANDI!' 'OK'
Write-Host '============================================================'
Write-Host ''
Write-Host 'Bilgisayariniz her acildiginda program kendiliginden calisacak.'
Write-Host ''
Write-Host 'Programi kaldirmak isterseniz:'
Write-Host '   ' $hedefKlasor '\Kaldir.bat'
Write-Host ''

exit 0
