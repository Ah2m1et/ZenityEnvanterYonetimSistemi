# ZenityEnvanterYonetimSistemi
Shell Script ile yazılmış Envanter Yönetim Sistemi Zenity uygulaması

Bu proje, BLM0365 Linux Araçları ve Kabuk Programlama dersi için geliştirilmiş bir envanter yönetim sistemidir. Zenity araçları kullanılarak oluşturulan bu sistem, kullanıcı dostu bir grafiksel arayüz üzerinden ürün yönetimi, kullanıcı yönetimi ve raporlama işlemlerini gerçekleştirmeyi sağlar.

[![Kullanım Videosu](https://youtu.be/QhJdXJRRKgo)](https://youtu.be/QhJdXJRRKgo)

## Özellikler

### Ürün Yönetimi
- ✨ Ürün ekleme
- 📋 Ürün listeleme
- 📝 Ürün güncelleme
- 🗑️ Ürün silme

### Kullanıcı Yönetimi
- 👥 Yönetici ve kullanıcı rolleri
- 🔐 Güvenli parola saklama (MD5)
- 🔒 Hesap kilitleme sistemi
- 👤 Kullanıcı CRUD işlemleri

### Raporlama
- 📊 Stok durumu raporları
- ⚠️ Kritik stok seviyesi uyarıları
- 📜 Detaylı hata kayıtları

### Program Yönetimi
- 💾 Disk kullanım analizi
- 🔄 Otomatik yedekleme
- 📋 Log kayıtları görüntüleme

## Kurulum

1. Repoyu klonlayın:
```bash
git clone https://github.com/Ah2m1et/ZenityEnvanterYonetimSistemi.git
```

2. Proje dizinine gidin:
```bash
cd ZenityEnvanterYonetimSistemi
```

3. Çalıştırma izni verin:
```bash
chmod +x zenityEYS.sh
```

4. Programı çalıştırın:
```bash
./zenityEYS.sh
```

## Bağımlılıklar

- Zenity (`sudo apt-get install zenity`)
- Bash 4.0 veya üstü

## Kullanım

### Giriş Yapma
![Giriş Ekranı](https://github.com/user-attachments/assets/d597fab6-3b7b-47d8-88d7-5186b4b01280)

Varsayılan yönetici hesabı:
- Kullanıcı adı: `admin`
- Şifre: `admin123`

### Ana Menü
![Ana Menü](https://github.com/user-attachments/assets/29c9d80c-7e61-4cdc-aa9b-f5f63175e4b8)


Ana menüden tüm işlemlere erişebilirsiniz:
1. Ürün Ekle
2. Ürün Listele
3. Ürün Güncelle
4. Ürün Sil
5. Rapor Al
6. Kullanıcı Yönetimi
7. Program Yönetimi

### Ürün Ekleme
![Ürün Ekleme](https://github.com/user-attachments/assets/24905189-1278-4a0e-b013-4ae786553c21)

- Ürün adı (boşluk içermemeli)
- Stok miktarı (sayısal değer)
- Birim fiyatı (sayısal değer)
- Kategori (boşluk içermemeli)

### Raporlama
![Rapor Ekranı](https://github.com/user-attachments/assets/dd553245-581b-4f3a-833c-a86c14022a55)

İki tür rapor alabilirsiniz:
1. Stokta azalan ürünler
2. En yüksek stok miktarına sahip ürünler

## Güvenlik Özellikleri

- 🔒 3 başarısız giriş denemesinden sonra hesap kilitleme
- 🛡️ Rol tabanlı erişim kontrolü
- 📝 Detaylı log tutma
- ✅ Veri doğrulama kontrolleri

## Dosya Yapısı

```
envanter-yonetim/
├── envanter.sh
├── depo.csv
├── kullanici.csv
├── log.csv
└── README.md
```

## Hata Ayıklama

Sık karşılaşılan hatalar ve çözümleri:

1. "Command not found: zenity"
   ```bash
   sudo apt-get update
   sudo apt-get install zenity
   ```

2. "Permission denied"
   ```bash
   chmod +x envanter.sh
   ```

## Katkıda Bulunma

1. Bu repoyu fork edin
2. Yeni bir branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Branch'inizi push edin (`git push origin feature/AmazingFeature`)
5. Pull Request oluşturun

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakınız.

## Proje Bilgileri

- **Ders**: BLM0365 Linux Araçları ve Kabuk Programlama
- **Dönem**: Güz 2024
- **Ödev**: 3

## İletişim

[Ahmet Korkmaz] - [@Ah2m1et](https://github.com/Ah2m1et) - ah2m1et@gmail.com

Proje Linki: [https://github.com/Ah2m1et/ZenityEnvanterYonetimSistemi](https://github.com/Ah2m1et/ZenityEnvanterYonetimSistemi)
