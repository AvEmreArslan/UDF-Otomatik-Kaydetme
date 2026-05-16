#Requires -Version 5.1
<#
.SYNOPSIS
    UYAP Doküman Editörü için arka planda çalışan otomatik kaydedici.

.DESCRIPTION
    Bu script her 20 saniyede bir UYAP Doküman Editörü penceresinin
    açık olup olmadığını kontrol eder. Eğer açıksa ve ön plandaysa,
    pencereye Ctrl+S tuş kombinasyonunu gönderir. UYAP'ın içindeki
    herhangi bir metni veya dosya içeriğini OKUMAZ. Sadece pencere
    başlığını (dosya adı) görür ve sadece klavye tuşu gönderir.

.NOTES
    - Hiçbir dosya içeriği okunmaz.
    - Hiçbir veri internete gönderilmez.
    - Tamamen yerel çalışır.
    - Kullanıcı 3 saniyeden uzun süredir başka uygulamada hareketsizse
      kısa süreliğine focus alıp kaydeder (yazma kesintisi önlenir).
#>

# ============================================================
# AYARLAR (isterseniz değiştirebilirsiniz)
# ============================================================

# Kayıt aralığı (saniye)
$KayitAraligiSaniye = 20

# UYAP Doküman Editörü penceresinin başlığında aranacak ifadeler.
# UYAP Editor'ün pencere başlığı versiyona göre değişebilir; tipik formatlar:
#   "Doküman Editörü v5.4.16 (*) - dosyaadi.udf (C:\...\dosyaadi.udf)"
#   "UYAP Doküman Editörü 5.4.x - dosya.udf"
#   "UYAP Editör 5.x.x"
# Burada "(*)" işareti dosyada kaydedilmemiş değişiklik olduğunu gösterir.
# Yanlış pencerelere müdahale etmemek için UYAP/.udf bağlamı zaten
# Test-KaydedilmisDosya kontrolünde tekrar doğrulanır.
$UyapBasligiAnahtarlar = @(
    'Doküman Editörü',     # Yeni sürümler (5.4.x ve sonrası)
    'Dokuman Editoru',     # Türkçe karakterler bozuksa
    'UYAP Doküman Editörü', # Eski sürümler / bazı dağıtımlar
    'UYAP Document Editor'  # İngilizce arayüz
)

# Kullanıcı kaç ms boşta kaldıktan sonra "aktif değil" sayılsın?
# (Ön planda olmayan UYAP pencerelerine güvenli kayıt için kullanılır)
$BostaKalmaEsigiMs = 3000

# SADECE değişiklik yapılmış dosyaları kaydet (önerilen).
# Pencere başlığındaki "(*)" işaretine bakar. İşaret yoksa Ctrl+S göndermez.
# $false yaparsanız UYAP açık olduğunda her 20 sn'de bir Ctrl+S gönderilir
# (UYAP zaten boşa kayıt yapmaz, ama başlığa bakmak daha az müdahalecidir).
$SadeceDegisiklikVarsaKaydet = $true

# Log dosyası (isteğe bağlı, yoksa loglama yapılmaz)
$LogDosyasi = Join-Path $env:LOCALAPPDATA 'UyapOtomatikKayit\kayit.log'

# Maksimum log boyutu (byte) - bu boyutu aşarsa sıfırlanır
$MaxLogBoyutu = 1MB

# ============================================================
# Win32 API Tanımları
# ============================================================

Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;

public class UyapWin32 {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowTextW(IntPtr hWnd, StringBuilder text, int count);

    [DllImport("user32.dll")]
    public static extern int GetWindowTextLengthW(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();

    [DllImport("user32.dll")]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();

    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }

    public static List<KeyValuePair<IntPtr, string>> FindWindowsByTitle(string[] keywords) {
        var result = new List<KeyValuePair<IntPtr, string>>();
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            if (!IsWindowVisible(hWnd)) return true;
            int len = GetWindowTextLengthW(hWnd);
            if (len == 0) return true;
            StringBuilder sb = new StringBuilder(len + 1);
            GetWindowTextW(hWnd, sb, sb.Capacity);
            string title = sb.ToString();
            foreach (string kw in keywords) {
                if (title.IndexOf(kw, StringComparison.OrdinalIgnoreCase) >= 0) {
                    result.Add(new KeyValuePair<IntPtr, string>(hWnd, title));
                    break;
                }
            }
            return true;
        }, IntPtr.Zero);
        return result;
    }

    public static uint GetIdleMilliseconds() {
        LASTINPUTINFO lii = new LASTINPUTINFO();
        lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
        if (!GetLastInputInfo(ref lii)) return 0;
        return GetTickCount() - lii.dwTime;
    }
}
"@

# ============================================================
# Yardımcı Fonksiyonlar
# ============================================================

function Yaz-Log {
    param([string]$Mesaj, [string]$Seviye = 'BILGI')
    if (-not $LogDosyasi) { return }
    try {
        $klasor = Split-Path -Parent $LogDosyasi
        if (-not (Test-Path $klasor)) {
            New-Item -ItemType Directory -Path $klasor -Force | Out-Null
        }
        # Log dosyası çok büyürse sıfırla
        if ((Test-Path $LogDosyasi) -and ((Get-Item $LogDosyasi).Length -gt $MaxLogBoyutu)) {
            Clear-Content -Path $LogDosyasi -ErrorAction SilentlyContinue
        }
        $zaman = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Add-Content -Path $LogDosyasi -Value "[$zaman] [$Seviye] $Mesaj" -ErrorAction SilentlyContinue
    } catch {
        # Log hatasında sessizce devam et
    }
}

function Test-KaydedilmisDosya {
    <#
    Pencere başlığından dosyanın daha önce diske kaydedilip kaydedilmediğini
    tespit eder. UYAP Editor'ün başlık formatı tipik olarak:
      "Doküman Editörü v5.4.16 (*) - dosyaadi.udf (C:\...\dosyaadi.udf)"
    Yeni/kaydedilmemiş bir dosya açıkken parantez içindeki dosya yolu
    bulunmaz. Bu durumda Ctrl+S "Farklı Kaydet" penceresi açacağı için
    kayıt yapılmamalıdır.
    #>
    param([string]$Baslik)
    if ([string]::IsNullOrWhiteSpace($Baslik)) { return $false }

    # Disk üzerinde gerçek bir dosya adı (.udf uzantılı) geçiyor mu?
    if ($Baslik -match '\.udf\b') { return $true }

    # Genel ofis dosya uzantıları da kabul edilebilir (UYAP başka dosya
    # türlerini de açabilir).
    if ($Baslik -match '\.(doc|docx|rtf|odt|txt|html|htm|xml)\b') { return $true }

    return $false
}

function Test-DegisiklikVar {
    <#
    UYAP Doküman Editörü, dosyada kaydedilmemiş değişiklik olduğunda
    pencere başlığına "(*)" işareti ekler. Bu fonksiyon o işaretin olup
    olmadığını kontrol eder. Bu işaret olmadığında zaten kaydedecek bir
    şey yoktur, dolayısıyla Ctrl+S göndermek de gereksizdir.
    #>
    param([string]$Baslik)
    if ([string]::IsNullOrWhiteSpace($Baslik)) { return $false }
    # "(*)" işareti tipik olarak versiyon numarasından hemen sonra gelir.
    return ($Baslik -match '\(\*\)')
}

function Gonder-CtrlS {
    <#
    Belirtilen pencereye Ctrl+S gönderir. Eğer pencere ön plandaysa
    direkt SendKeys kullanır (en güvenilir yöntem). Pencere ön planda
    değilse VE kullanıcı bir süredir boşta ise, kısa bir süre için focus
    alır, kaydeder, eski focus'u geri verir.
    #>
    param(
        [IntPtr]$PencereTutamaci,
        [string]$Baslik
    )

    if (-not [UyapWin32]::IsWindow($PencereTutamaci)) {
        return $false
    }

    $onPlan = [UyapWin32]::GetForegroundWindow()
    $uyapOnPlandaMi = ($onPlan -eq $PencereTutamaci)
    $bostaMs = [UyapWin32]::GetIdleMilliseconds()

    if ($uyapOnPlandaMi) {
        # En basit ve güvenli senaryo: UYAP zaten odakta
        try {
            [System.Windows.Forms.SendKeys]::SendWait('^s')
            Yaz-Log "Kaydedildi (ön planda): $Baslik"
            return $true
        } catch {
            Yaz-Log "SendKeys hatası: $($_.Exception.Message)" 'HATA'
            return $false
        }
    }

    # UYAP ön planda değil. Kullanıcı boşta mı kontrol et.
    if ($bostaMs -lt $BostaKalmaEsigiMs) {
        # Kullanıcı aktif olarak başka bir uygulamada çalışıyor.
        # Focus çalmamak için bu seferki kaydı atla.
        Yaz-Log "Atlandı (kullanıcı başka uygulamada aktif): $Baslik"
        return $false
    }

    # Kullanıcı boşta -> kısa bir süreliğine UYAP'a focus alıp kaydet
    try {
        # AttachThreadInput ile focus alma daha güvenilir olur
        $hedefThread = [UyapWin32]::GetWindowThreadProcessId($PencereTutamaci, [ref]([uint32]0))
        $bizimThread = [UyapWin32]::GetCurrentThreadId()

        $attached = $false
        if ($hedefThread -ne 0 -and $hedefThread -ne $bizimThread) {
            $attached = [UyapWin32]::AttachThreadInput($bizimThread, $hedefThread, $true)
        }

        [UyapWin32]::SetForegroundWindow($PencereTutamaci) | Out-Null
        Start-Sleep -Milliseconds 80

        # Sadece UYAP gerçekten ön plana geldiyse tuş gönder
        if ([UyapWin32]::GetForegroundWindow() -eq $PencereTutamaci) {
            [System.Windows.Forms.SendKeys]::SendWait('^s')
            Start-Sleep -Milliseconds 80
            Yaz-Log "Kaydedildi (focus geçişi ile): $Baslik"
            $sonuc = $true
        } else {
            Yaz-Log "Focus alınamadı, atlandı: $Baslik"
            $sonuc = $false
        }

        # Eski ön planı geri yükle
        if ([UyapWin32]::IsWindow($onPlan)) {
            [UyapWin32]::SetForegroundWindow($onPlan) | Out-Null
        }

        if ($attached) {
            [UyapWin32]::AttachThreadInput($bizimThread, $hedefThread, $false) | Out-Null
        }

        return $sonuc
    } catch {
        Yaz-Log "Focus geçişi hatası: $($_.Exception.Message)" 'HATA'
        return $false
    }
}

# ============================================================
# Tek Örnek (Single Instance) Kontrolü
# ============================================================

# Mutex'i kullanıcı oturumuna özel yapıyoruz (Local\). Aynı bilgisayarda
# birden fazla kullanıcı varsa her biri kendi örneğini çalıştırabilir.
# Kullanıcı SID'i ekleyerek farklı oturumlar arasında çakışma da olmaz.
$kullaniciKimligi = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
$mutexAdi = "Local\UyapOtomatikKayit_TekOrnek_$kullaniciKimligi"
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, $mutexAdi, [ref]$createdNew)
if (-not $createdNew) {
    Yaz-Log 'Zaten çalışan bir örnek var, çıkılıyor.' 'UYARI'
    exit 0
}

# ============================================================
# Ana Döngü
# ============================================================

Yaz-Log "UYAP Otomatik Kayıt başladı (aralık: $KayitAraligiSaniye sn)"

try {
    while ($true) {
        Start-Sleep -Seconds $KayitAraligiSaniye

        try {
            $pencereler = [UyapWin32]::FindWindowsByTitle($UyapBasligiAnahtarlar)
            if ($pencereler.Count -eq 0) { continue }

            foreach ($p in $pencereler) {
                $hWnd = $p.Key
                $baslik = $p.Value

                # 1) Yeni/kaydedilmemiş (henüz diske yazılmamış) dosya ise atla.
                #    Aksi halde Ctrl+S "Farklı Kaydet" penceresi açar, kullanıcıyı rahatsız eder.
                if (-not (Test-KaydedilmisDosya -Baslik $baslik)) {
                    Yaz-Log "Atlandı (henüz diske kaydedilmemiş yeni belge): $baslik"
                    continue
                }

                # 2) Dosyada gerçek bir değişiklik var mı? Yoksa Ctrl+S göndermek gereksiz.
                if ($SadeceDegisiklikVarsaKaydet -and -not (Test-DegisiklikVar -Baslik $baslik)) {
                    # Değişiklik yok, sessizce geç (her döngüde log basmamak için yorum satırına aldık)
                    # Yaz-Log "Atlandı (degisiklik yok): $baslik"
                    continue
                }

                Gonder-CtrlS -PencereTutamaci $hWnd -Baslik $baslik | Out-Null
            }
        } catch {
            Yaz-Log "Döngü hatası: $($_.Exception.Message)" 'HATA'
        }
    }
} finally {
    if ($mutex) {
        try { $mutex.ReleaseMutex() } catch {}
        $mutex.Dispose()
    }
    Yaz-Log 'UYAP Otomatik Kayıt durdu.'
}
