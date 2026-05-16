# UYAP Doküman Editörü - Otomatik Kaydetme

UYAP Doküman Editörü için arka planda çalışan, **gizliliğe saygılı** bir otomatik
kaydedici. Bilgisayarınız her açıldığında otomatik devreye girer ve **20 saniyede
bir** UYAP'ta açık olan dosyayı kaydeder.

## Özet

- Bir kez kurulur, ömür boyu çalışır.
- Bilgisayar her açıldığında **gizli** olarak başlar (kullanıcı arayüzü yoktur).
- 20 saniyede bir UYAP penceresine sadece `Ctrl+S` tuşunu gönderir.
- **Yönetici yetkisine ihtiyaç duymaz.** Sadece sizin kullanıcı hesabınızda çalışır.

## Gizlilik Garantileri

Bu çok önemli olduğu için ayrıca yazıyorum:

| Konu | Durum |
|------|-------|
| Dosya içeriği okunur mu? | **Hayır.** Hiçbir UDF dosyası, hiçbir metin okunmaz. |
| İnternete bağlanır mı? | **Hayır.** Hiçbir veri gönderilmez/alınmaz. |
| Pencere başlığı okunur mu? | **Evet.** Sadece dosya adı (örn. "dilekce.udf"). Bu Windows'un her uygulamaya verdiği genel bir bilgidir, dosyanın içeriği değildir. |
| Klavye dinler mi? | **Hayır.** Sadece UYAP penceresine `Ctrl+S` **gönderir**, hiçbir tuşu dinlemez/kaydetmez. |
| Ekran görüntüsü alır mı? | **Hayır.** |
| Veri saklar mı? | Sadece istek üzerine basit bir log dosyası: "x tarihinde dilekce.udf kaydedildi" gibi. Asla dosya içeriği saklanmaz. |

Tüm kod açık kaynaktır. `UyapOtomatikKayit.ps1` dosyasını Not Defteri ile açıp
kendi gözünüzle inceleyebilirsiniz.

## Kurulum (1 Dakika)

### GitHub'dan İndirdiyseniz: ÖNEMLİ ilk adım

İnternetten indirilen ZIP dosyalarını Windows otomatik olarak "engelli" işaretler.
Bu işareti kaldırmadan kurulum başarısız olabilir:

1. İndirdiğiniz **ZIP dosyasına sağ tıklayın** → **"Özellikler"**.
2. Pencerenin en altında **"Engellemeyi kaldır"** kutusunu işaretleyin.
3. **"Tamam"** deyip pencereyi kapatın.
4. Şimdi ZIP'i bir klasöre çıkarabilirsiniz.

> Not: Kurulum scripti otomatik olarak da bunu temizlemeye çalışır, ama yukarıdaki
> adım en garantili yöntemdir.

### Asıl Kurulum

1. Çıkardığınız klasörün içindeki **`Kurulum.bat`** dosyasına çift tıklayın.
2. Açılan siyah pencereden işlemler tamamlanana kadar bekleyin.
3. "Kurulum BAŞARIYLA tamamlandı!" yazısını gördüğünüzde herhangi bir tuşa basın.

İşte bu kadar! Program artık:
- `%LOCALAPPDATA%\UyapOtomatikKayit` klasörüne kuruldu
- Windows başlangıcına eklendi
- Hemen arka planda çalışmaya başladı

> **Yönetici yetkisi GEREKMİYOR.** Sistem dosyalarına dokunmaz, sadece sizin
> kullanıcı hesabınızda çalışır.

### Windows Uyarıları İle Ne Yapmalı?

Microsoft, **dijital olarak imzalanmamış** scriptlere her zaman uyarı gösterir.
Bu, kodun zararlı olduğu anlamına **gelmez** — sadece "henüz tanımıyoruz" demektir.

| Uyarı | Ne Yapmalı |
|------|-----------|
| **SmartScreen "Windows PC'nizi korudu"** | "Daha fazla bilgi" → "Yine de çalıştır" |
| **Windows Defender** | İstisna olarak ekleyin veya kodu inceleyip kabul edin |
| **Antivirüs (Avast, Kaspersky, Norton vb.)** | İstisna ekleyin |

Endişeleniyorsanız `UyapOtomatikKayit.ps1` dosyasını **Not Defteri** ile açıp kodu
kendi gözünüzle inceleyebilirsiniz — zararlı bir şey içermediğini göreceksiniz.

## Nasıl Çalışır?

UYAP Doküman Editörü'nün penceresinin başlığı şu formattadır:

```
Doküman Editörü v5.4.16 (*) - dilekce.udf (C:\Klasor\dilekce.udf)
```

Buradaki **`(*)`** işareti **dosyada kaydedilmemiş değişiklik olduğunu** gösterir
(UYAP'ın kendi gösterimi). Programımız bu davranıştan faydalanır:

1. Her 20 saniyede bir tüm açık pencereler taranır.
2. Başlığında "Doküman Editörü" geçen pencere(ler) bulunur.
3. Pencere başlığında **`.udf`** uzantılı dosya adı yoksa (henüz kaydedilmemiş yeni belge), işlem **atlanır**. Böylece istemediğiniz "Farklı Kaydet" penceresi açılmaz. Bunu en az **bir kez** kendiniz Ctrl+S ile kaydetmeniz yeterlidir; sonrasında otomatik kaydetme devreye girer.
4. Pencere başlığında **`(*)`** işareti yoksa (yani dosyada kaydedilmemiş değişiklik yok), işlem **atlanır**. Boşa Ctrl+S gönderilmez, sistem rahatsız edilmez.
5. Hem `.udf` adı hem de `(*)` işareti varsa: Ctrl+S gönderilir.
   - UYAP **ön plandaysa** (siz aktif çalışıyorsanız), tuş anında gönderilir.
   - UYAP **arka plandaysa** ve siz **3 saniyeden uzun süredir başka bir uygulamada hareket etmediyseniz**, focus geçici olarak UYAP'a alınır, kaydedilir, eski focus geri verilir. Bu sayede başka bir uygulamada yazı yazarken focus çalınmaz.

> **Önemli:** Bu yaklaşımda dosya içeriği asla okunmaz; sadece pencere başlığındaki
> standart değişiklik göstergesi (`(*)`) kullanılır. Bu, gizliliği koruyan akıllı
> bir tetikleyicidir.

## Ayarları Değiştirmek

`%LOCALAPPDATA%\UyapOtomatikKayit\UyapOtomatikKayit.ps1` dosyasını Not Defteri ile
açın. En üstteki "AYARLAR" bölümünden:

- `$KayitAraligiSaniye = 20` &rarr; kayıt sıklığı (saniye)
- `$BostaKalmaEsigiMs = 3000` &rarr; arka plan kayıt için boşta kalma eşiği (ms)
- `$LogDosyasi` &rarr; log dosyasının yeri (boş bırakırsanız log tutulmaz)

Değişikliklerin etkili olması için programı durdurup yeniden başlatın
(en kolayı: bilgisayarı yeniden başlatmak).

## Test Etmek

Programın çalıştığını doğrulamak için:

1. UYAP Doküman Editörü'nü açın ve bir dosyayı **bir kez kendiniz** kaydedin.
2. Dosyada bir değişiklik yapın (bir harf yazın).
3. Hiçbir şey yapmadan 20-25 saniye bekleyin.
4. UYAP penceresinin başlığında "değiştirildi" işareti varsa kaybolur, yoksa kaydedilmiştir.
5. Log dosyasını kontrol edebilirsiniz:

   ```
   %LOCALAPPDATA%\UyapOtomatikKayit\kayit.log
   ```

   İçinde "Kaydedildi: dilekce.udf - UYAP..." gibi satırlar göreceksiniz.

## Programı Geçici Olarak Durdurma

Görev Yöneticisi (Ctrl+Shift+Esc) > Ayrıntılar sekmesinde:
- `wscript.exe` veya
- `powershell.exe` (komut satırında `UyapOtomatikKayit.ps1` geçen)

işlemini sonlandırın. Bilgisayarı tekrar başlatınca otomatik kaydetme yine devreye girer.

## Tamamen Kaldırma

`%LOCALAPPDATA%\UyapOtomatikKayit\Kaldir.bat` dosyasına çift tıklayın.
Bu işlem:

- Çalışan örnekleri durdurur
- Windows başlangıç kaydını siler
- Tüm program dosyalarını siler

## Sık Sorulan Sorular

**S: Yönetici yetkisi gerekiyor mu?**
C: Hayır. Tamamen kullanıcı hesabınızda çalışır. Sistem dosyalarına dokunmaz.

**S: Bilgisayara virüs gibi yerleşir mi?**
C: Hayır. Sadece sizin kullanıcı klasörünüzde (`%LOCALAPPDATA%`) bir klasör oluşturur ve sizin "başlangıç programlarına" kaydolur. Görev Yöneticisi → Başlangıç sekmesinde görebilirsiniz. Tek tıkla devre dışı bırakılabilir.

**S: UYAP'ın kendisini etkiler mi?**
C: Hayır. UYAP'a sadece dışarıdan bir kullanıcı gibi `Ctrl+S` tuşu gönderir. UYAP'ın kendi davranışını hiç değiştirmez.

**S: Birden fazla UYAP penceresi açıkken çalışır mı?**
C: Evet, hepsini sırayla kaydeder.

**S: Antivirüs uyarı verirse?**
C: PowerShell scriptleri bazen "potansiyel risk" olarak işaretlenebilir. Kodun tamamı açıktır, isterseniz inceleyip antivirüs istisnasına ekleyebilirsiniz.

## Dosyaların Görevi

| Dosya | Görevi |
|------|--------|
| `Kurulum.bat` | Kurulumu başlatır (çift tıklayın) |
| `Kurulum.ps1` | Asıl kurulum mantığı (PowerShell) |
| `UyapOtomatikKayit.ps1` | Ana program; arka planda 20 sn'de bir kaydeder |
| `Baslat.vbs` | PowerShell scriptini gizli pencerede başlatır |
| `Kaldir.bat` / `Kaldir.ps1` | Programı sistemden kaldırır |
| `OKUBENI.md` | Bu doküman |

## Lisans

Bu kod tamamen sizindir. İsterseniz inceleyin, isterseniz değiştirin, isterseniz başkalarıyla paylaşın. Hiçbir kısıtlama yoktur.
