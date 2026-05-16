# UYAP Doküman Editörü Otomatik Kaydetme

UYAP Doküman Editörü için **gizliliğe saygılı**, hafif ve **kalıcı** bir otomatik kaydedici. Bilgisayar her açıldığında arka planda başlar; her **20 saniyede bir** açık olan UDF dosyasında değişiklik yapılmışsa otomatik olarak kaydeder.

> **Türkiye'deki tüm avukat, hâkim, savcı, kâtip ve UYAP kullanıcıları için.** Hiçbir zaman kaydetmeyi unutmayın, elektrik kesintisinde işiniz kaybolmasın.

## Özellikler

- **Bir kez kur**, ömür boyu çalışsın. Bilgisayar her açıldığında otomatik başlar.
- **Yönetici yetkisi GEREKMİYOR.** Sistem dosyalarına dokunmaz.
- **Tamamen yerel.** İnternete bağlanmaz, hiçbir veri dışarı çıkmaz.
- **Akıllı tetikleyici.** Sadece UYAP başlığında değişiklik göstergesi `(*)` varsa Ctrl+S gönderir, boşa çalışmaz.
- **Focus dostu.** Başka uygulamada yazı yazıyorsanız, aktif olduğunuz uygulamanın focus'unu çalmaz.
- **Açık kaynak.** Tüm kod okunabilir PowerShell, dilediğiniz an inceleyebilirsiniz.

## Gizlilik Garantileri

| Konu | Durum |
|------|-------|
| UDF dosyalarının içeriği okunur mu? | **Hayır.** Hiçbir dilekçenin içeriği okunmaz. |
| İnternete bağlanır mı? | **Hayır.** Hiçbir veri gönderilmez/alınmaz. |
| Klavye dinler mi? | **Hayır.** Sadece UYAP penceresine `Ctrl+S` **gönderir**. |
| Ekran görüntüsü alır mı? | **Hayır.** |
| Hangi pencere bilgilerini okur? | Sadece pencere **başlığını** (örn. `dilekce.udf`). Bu, Windows'un her uygulama için sağladığı bir metadata'dır. |

## Kurulum

### 1. Yöntem: ZIP olarak indir (Tavsiye edilen)

1. Bu sayfanın üstündeki yeşil **"Code"** düğmesine tıklayın → **"Download ZIP"**.
2. İndirilen ZIP dosyasına sağ tıklayın → **"Özellikler"** → en altta **"Engellemeyi kaldır"** kutusunu işaretleyin → **"Tamam"**.
   *(Bu adım çok önemli! Windows internetten gelen scriptleri varsayılan olarak engeller.)*
3. ZIP'i bir klasöre çıkartın.
4. Çıkan klasörün içindeki **`Kurulum.bat`** dosyasına çift tıklayın.
5. Açılan siyah pencereden **"KURULUM TAMAMLANDI!"** yazısını gördüğünüzde herhangi bir tuşa basıp pencereyi kapatın.

İşte bu kadar. Program artık:
- `%LOCALAPPDATA%\UyapOtomatikKayit` klasörüne kuruldu,
- Windows başlangıcına eklendi,
- Hemen arka planda çalışmaya başladı.

### 2. Yöntem: Git ile

```bash
git clone https://github.com/<kullanici_adi>/uyap-otomatik-kaydetme.git
cd uyap-otomatik-kaydetme
```
Sonra `Kurulum.bat` dosyasına çift tıklayın.

## SmartScreen / Antivirüs Uyarıları

Microsoft, **dijital imzalanmamış** scriptlere her zaman uyarı gösterir. Bu, kodun zararlı olduğu anlamına **gelmez** — sadece "Microsoft tarafından henüz tanınmıyor" demektir.

- **SmartScreen "Windows PC'nizi korudu"** → "Daha fazla bilgi" → "Yine de çalıştır"
- **Windows Defender uyarısı** → "Dışlama olarak ekle" veya kodu inceleyip kabul edin
- **Antivirüs (Avast, Kaspersky vb.)** → İstisna ekleyin

Tüm kod açık kaynaktır; istediğiniz zaman `UyapOtomatikKayit.ps1` dosyasını Not Defteri'yle açıp inceleyebilirsiniz.

## Nasıl Çalışır?

UYAP Doküman Editörü'nün penceresinin başlığı tipik olarak:

```
Doküman Editörü v5.4.16 (*) - dilekce.udf (C:\Klasor\dilekce.udf)
```

Buradaki **`(*)`** işareti UYAP'ın koyduğu **"kaydedilmemiş değişiklik var"** göstergesidir.

Program her 20 saniyede bir:

1. Tüm açık pencereleri tarar (sadece başlıklar — içerik **değil**).
2. Başlığında "Doküman Editörü" geçen pencereleri bulur.
3. Başlıkta `.udf` uzantısı varsa (yani dosya en az bir kez kaydedilmişse) ve `(*)` işareti varsa: pencereye `Ctrl+S` gönderir.
4. UYAP ön plandaysa anında, arka plandaysa ve siz başka bir uygulamada 3 saniyeden uzun süredir hareketsizseniz kısa süreliğine focus alıp kaydeder.

## Test Etmek

1. UYAP Doküman Editörü'nü açın ve bir dosyayı **bir kez kendiniz** kaydedin.
2. Bir karakter ekleyin → pencere başlığında `(*)` belirir.
3. 20-25 saniye bekleyin → `(*)` kaybolur → kaydedildi.
4. Log dosyası: `%LOCALAPPDATA%\UyapOtomatikKayit\kayit.log`

## Ayarlar

`%LOCALAPPDATA%\UyapOtomatikKayit\UyapOtomatikKayit.ps1` dosyasının başında:

| Ayar | Varsayılan | Açıklama |
|------|-----------|----------|
| `$KayitAraligiSaniye` | 20 | Kayıt sıklığı (saniye) |
| `$BostaKalmaEsigiMs` | 3000 | Arka plan kayıt için boşta kalma eşiği (ms) |
| `$SadeceDegisiklikVarsaKaydet` | `$true` | `(*)` işareti yoksa Ctrl+S göndermesin |

## Kaldırma

`%LOCALAPPDATA%\UyapOtomatikKayit\Kaldir.bat` dosyasına çift tıklayın. Tüm dosyalar ve başlangıç kaydı temizlenir.

## Sık Sorulan Sorular

**S: Yönetici yetkisi gerekiyor mu?**
C: Hayır. Sadece kullanıcı hesabınızda çalışır.

**S: UYAP'ı bozar mı?**
C: Hayır. UYAP'a sadece dışarıdan bir kullanıcı gibi `Ctrl+S` tuşu gönderir. UYAP'ın kendi davranışı hiç değişmez.

**S: Birden fazla UYAP penceresi açıkken çalışır mı?**
C: Evet, hepsini sırayla kaydeder.

**S: İmzalı dilekçelere zarar verir mi?**
C: Hayır. UYAP zaten imzalı dosyalarda otomatik koruma uygular; bu program sadece UYAP'ın kendi `Ctrl+S` davranışını tetikler.

**S: Antivirüs neden uyarı veriyor?**
C: Çünkü PowerShell scripti otomatik tuş gönderiyor. Bu, anahtar kayıtçısı (keylogger) olmadığı halde bazı antivirüsler için "şüpheli" sayılabilir. Kod açıktır, inceleyin ve istisnaya ekleyin.

**S: Mac veya Linux'ta çalışır mı?**
C: Hayır. Sadece Windows için yazıldı (UYAP Doküman Editörü zaten Windows uygulamasıdır).

## Sistem Gereksinimleri

- Windows 10 veya 11 (Windows 7/8 ile de uyumlu olmalı, ama test edilmedi)
- PowerShell 5.1+ (Windows 10 ile birlikte gelir)
- UYAP Doküman Editörü (herhangi bir versiyon)

## Sorun Giderme

Sorununuz çözülmüyorsa:

1. `%LOCALAPPDATA%\UyapOtomatikKayit\kayit.log` dosyasını açıp son satırlara bakın.
2. Bir GitHub Issue açın ve log içeriğini paylaşın (kişisel dosya adlarını maskeleyebilirsiniz).

## Katkı

Pull request'ler kabul edilir. Lütfen büyük değişikliklerden önce bir issue açıp tartışın.

## Lisans

[MIT](LICENSE) — istediğiniz gibi kullanın, değiştirin, paylaşın.

## Sorumluluk Reddi

Bu yazılım "olduğu gibi" sunulmuştur. Herhangi bir veri kaybı, dosya bozulması veya UYAP ile ilgili sorun durumunda yazar sorumluluk kabul etmez. Önemli dilekçelerinizi kullanmadan önce farklı bir konuda test edin.
