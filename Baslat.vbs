' UYAP Otomatik Kaydetme - Gizli Başlatıcı
' Bu VBS dosyası PowerShell scriptini hiçbir pencere göstermeden,
' tamamen arka planda çalıştırır. Kullanıcı hiçbir konsol görmez.

Option Explicit

Dim shell, fso, scriptYolu, klasor, komut

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Bu VBS dosyasının bulunduğu klasör
klasor = fso.GetParentFolderName(WScript.ScriptFullName)
scriptYolu = fso.BuildPath(klasor, "UyapOtomatikKayit.ps1")

If Not fso.FileExists(scriptYolu) Then
    WScript.Quit 1
End If

' PowerShell'i tamamen gizli olarak başlat
' -WindowStyle Hidden + 0 = pencere gösterilmez
' -ExecutionPolicy Bypass = sistem ayarlarına dokunmadan bu scripti çalıştır
komut = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptYolu & """"

' İkinci parametre 0 = pencere gizli, üçüncü parametre False = bekleme
shell.Run komut, 0, False
