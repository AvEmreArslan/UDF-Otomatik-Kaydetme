#Requires -Version 5.1
<#
.SYNOPSIS
    UYAP Otomatik Kaydetme programını sistemden tamamen kaldırır.
#>

$ErrorActionPreference = 'SilentlyContinue'
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

$hedefKlasor = Join-Path $env:LOCALAPPDATA 'UyapOtomatikKayit'
$runKey      = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runAdi      = 'UyapOtomatikKayit'

Write-Host ''
Write-Host 'Bu islem programi sisteminizden tamamen kaldiracak.'
Write-Host ('Hedef klasor: ' + $hedefKlasor)
Write-Host ''

# ============================================================
# 1) Çalışan örnekleri durdur
# ============================================================

try {
    Get-Process wscript -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            if ($cmd -and ($cmd -like "*UyapOtomatikKayit*Baslat.vbs*")) {
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }

    Get-Process powershell -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            if ($cmd -and ($cmd -like "*UyapOtomatikKayit.ps1*") -and ($_.Id -ne $PID)) {
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }

    Yaz 'Calisan ornekler durduruldu.' 'OK'
} catch {
    Yaz "Surec durdurma uyarisi: $($_.Exception.Message)" 'UYARI'
}

# ============================================================
# 2) Windows başlangıcından kaldır
# ============================================================

try {
    if (Test-Path $runKey) {
        $varMi = Get-ItemProperty -Path $runKey -Name $runAdi -ErrorAction SilentlyContinue
        if ($varMi) {
            Remove-ItemProperty -Path $runKey -Name $runAdi -Force
            Yaz 'Windows acilisindan kaldirildi.' 'OK'
        } else {
            Yaz 'Otomatik baslatma kaydi zaten yoktu.' 'BILGI'
        }
    }
} catch {
    Yaz "Baslangic kaydi silinemedi: $($_.Exception.Message)" 'UYARI'
}

# ============================================================
# 3) Klasörü sil
# ============================================================

# Bu script kendi içinden silinemez. Önce kendini farklı bir konuma kopyalayıp
# oradan silme komutunu vermek gerekir. En temizi: kullanıcıya el ile silmesini
# söylemek, ya da bir gecikmeli temizlik komutu başlatmak.

try {
    $bizScriptYolu = $MyInvocation.MyCommand.Path
    $bizScriptKlasoru = $null
    if ($bizScriptYolu) {
        $bizScriptKlasoru = Split-Path -Parent $bizScriptYolu
    }

    # Eğer bu script hedef klasörün içinden çalışıyorsa, gecikmeli silme yap
    if ($bizScriptKlasoru -and ((Resolve-Path $bizScriptKlasoru).Path -ieq (Resolve-Path $hedefKlasor).Path)) {
        Yaz 'Klasor 3 saniye sonra silinecek (script kendi icinden calisiyor).' 'BILGI'
        $silmeKomutu = "Start-Sleep -Seconds 3; Remove-Item -Path '$hedefKlasor' -Recurse -Force -ErrorAction SilentlyContinue"
        Start-Process -FilePath 'powershell.exe' `
            -ArgumentList @('-NoProfile', '-WindowStyle', 'Hidden', '-Command', $silmeKomutu) `
            -WindowStyle Hidden
        Yaz 'Program klasoru kaldirilmak uzere planlandi.' 'OK'
    } else {
        if (Test-Path $hedefKlasor) {
            Remove-Item -Path $hedefKlasor -Recurse -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $hedefKlasor)) {
                Yaz 'Program klasoru silindi.' 'OK'
            } else {
                Yaz 'Klasor silinemedi (acik dosyalar olabilir). Manuel silebilirsiniz.' 'UYARI'
                Yaz $hedefKlasor 'BILGI'
            }
        } else {
            Yaz 'Program klasoru zaten yok.' 'BILGI'
        }
    }
} catch {
    Yaz "Klasor silme uyarisi: $($_.Exception.Message)" 'UYARI'
}

Write-Host ''
Write-Host '============================================================'
Yaz 'KALDIRMA TAMAMLANDI.' 'OK'
Write-Host '============================================================'
Write-Host ''

exit 0
