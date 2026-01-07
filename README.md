# 🕌 Dikey Mod Sultan Mescidi - Otomatik Başlatmalı Versiyon

**Orijinal APK'nın koyu mavi teması ve otomatik başlatma özelliği ile geliştirilmiş Flutter uygulaması**

## 🎨 Özellikler

### ✨ Görsel Özellikler
- ✅ **Orijinal Koyu Mavi Tema** (#4A8FBF) - APK'dan alınan renk tonu
- ✅ **Gradient Tasarım** - Koyu maviden açık maviye geçişler
- ✅ **Modern UI** - Material Design 3
- ✅ **Renkli Vakit Kartları** - Her vakit için özel renk
- ✅ **Animasyonlu Bildirimler** - Bir sonraki vakit animasyonu

### 🚀 Otomatik Başlatma
- ✅ **Cihaz Açıldığında Otomatik Başlar** - BOOT_COMPLETED izni
- ✅ **Hızlı Başlatma** - QUICKBOOT_POWERON desteği
- ✅ **Arka Plan İzni** - WAKE_LOCK ile güvenilir başlatma

### 📡 Canlı Vakitler
- ✅ **API Entegrasyonu** - vakit.vercel.app
- ✅ **Şehir Arama** - Sınırsız şehir
- ✅ **GPS Konum** - Otomatik yer belirleme
- ✅ **Önbellekleme** - Offline çalışma
- ✅ **Güncel Vakitler** - Her gün otomatik güncelleme

## 🎨 Renk Paleti

### Ana Renkler
- **Primary Blue**: #4A8FBF (Koyu Mavi - Orijinal APK'dan)
- **Dark Blue**: #2E5F85 (Daha Koyu Mavi)
- **Light Blue**: #6BA5D0 (Açık Mavi)
- **Accent Blue**: #3B7CA8 (Vurgu Mavisi)

### Vakit Renkleri
- **Fecr**: #2C3E50 (Çok koyu mavi-gri - Gece)
- **Güneş**: #F39C12 (Turuncu - Gün doğumu)
- **Öğle**: #3498DB (Parlak mavi - Öğlen)
- **İkindi**: #9B59B6 (Mor - Öğleden sonra)
- **Akşam**: #E74C3C (Kırmızı - Günbatımı)
- **Yatsı**: #34495E (Koyu gri-mavi - Gece)

## 📦 Kurulum

### 1. Bağımlılıkları Yükleyin
```bash
flutter pub get
```

### 2. Çalıştırın
```bash
flutter run
```

### 3. APK Oluşturun
```bash
flutter build apk --release
```

## 🔧 Otomatik Başlatma Nasıl Çalışır?

### Android Manifest İzinleri
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### Boot Receiver
Cihaz açıldığında `BootReceiver` tetiklenir ve uygulamayı başlatır:

```kotlin
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Uygulamayı başlat
            val launchIntent = Intent(context, MainActivity::class.java)
            context.startActivity(launchIntent)
        }
    }
}
```

### Desteklenen Başlatma Yöntemleri
- ✅ `ACTION_BOOT_COMPLETED` - Normal cihaz açılışı
- ✅ `QUICKBOOT_POWERON` - Hızlı başlatma (bazı cihazlar)

## 📱 Kullanım

### İlk Açılış
1. Uygulama otomatik olarak Denizli şehrini yükler
2. Vakitler API'den çekilir
3. Önbelleğe alınır

### Şehir Değiştirme
1. **Arama butonu (🔍)** - Sağ alt köşe
2. Şehir adını yazın ve Enter'a basın
3. Listeden şehrinizi seçin

### GPS Kullanma
1. **Konum butonu (📍)** - Sağ üst köşe
2. Konum iznini verin
3. Otomatik olarak en yakın şehir bulunur

### Vakitleri Yenileme
1. **Yenile butonu (🔄)** - Sağ üst köşe
2. Vakitler API'den yeniden çekilir

## 🎯 Önemli Notlar

### Otomatik Başlatma İçin
- Android 8.0+ cihazlarda bazı üreticiler (Xiaomi, Huawei, vb.) ek izin gerektirir
- Ayarlar → Uygulamalar → Sultan Mescidi → Otomatik Başlatma → İzin Ver

### Batarya Optimizasyonu
Bazı cihazlarda uygulamanın arka planda çalışması için:
- Ayarlar → Batarya → Uygulamalar → Sultan Mescidi → Optimizasyon Yapma

### MIUI (Xiaomi) İçin
- Güvenlik → İzinler → Otomatik Başlatma → Sultan Mescidi → İzin Ver
- Güvenlik → İzinler → Diğer İzinler → Sultan Mescidi → Arka Planda Çalış → İzin Ver

### ColorOS (Oppo/Realme) İçin
- Ayarlar → Uygulama Yönetimi → Sultan Mescidi → Otomatik Başlatma → Açık
- Ayarlar → Batarya → Uygulama Hızlı Dondurma → Sultan Mescidi → Kapat

## 📊 Karşılaştırma Tablosu

| Özellik | Eski Versiyon | Yeni Versiyon |
|---------|--------------|---------------|
| **Tema Rengi** | Yeşil | Koyu Mavi (Orijinal) |
| **Otomatik Başlatma** | ❌ | ✅ |
| **API Entegrasyonu** | ❌ | ✅ |
| **GPS Desteği** | ❌ | ✅ |
| **Şehir Arama** | ❌ | ✅ |
| **Önbellekleme** | ❌ | ✅ |
| **Gradient Tasarım** | Temel | Gelişmiş |
| **Vakit Renkleri** | Basit | Özelleştirilmiş |

## 🔐 İzinler

### Gerekli İzinler
- **INTERNET** - API'den veri çekme
- **ACCESS_FINE_LOCATION** - GPS konum (opsiyonel)
- **ACCESS_COARSE_LOCATION** - Yaklaşık konum (opsiyonel)
- **RECEIVE_BOOT_COMPLETED** - Otomatik başlatma
- **WAKE_LOCK** - Güvenilir başlatma

### İzin Kullanım Amacı
- Konum izni sadece kullanıcı GPS butonuna bastığında kullanılır
- İzinler isteğe bağlıdır, vermeden de uygulama çalışır
- Otomatik başlatma için RECEIVE_BOOT_COMPLETED şarttır

## 🛠️ Özelleştirme

### Renkleri Değiştirme
`lib/utils/colors.dart` dosyasında:

```dart
static const Color primaryBlue = Color(0xFF4A8FBF); // Değiştir
```

### Otomatik Başlatmayı Kapatma
`android/app/src/main/AndroidManifest.xml` dosyasında:

```xml
<!-- Bu receiver'ı sil veya enabled="false" yap -->
<receiver android:name=".BootReceiver" android:enabled="false">
```

### Varsayılan Şehri Değiştirme
`lib/main.dart` dosyasında:

```dart
await _searchAndSelectPlace('İstanbul'); // Şehir adını değiştir
```

## 📱 Test Etme

### Otomatik Başlatmayı Test Etme
1. Uygulamayı yükleyin
2. Cihazı kapatın
3. Cihazı açın
4. Uygulama otomatik olarak başlamalı

### Emülatörde Test
```bash
adb shell am broadcast -a android.intent.action.BOOT_COMPLETED
```

## 🐛 Sorun Giderme

### Otomatik Başlamıyor
1. Cihaz ayarlarından otomatik başlatma iznini kontrol edin
2. Batarya optimizasyonunu kapatın
3. Uygulamayı yeniden yükleyin

### Vakitler Yüklenmiyor
1. İnternet bağlantısını kontrol edin
2. Şehir adını doğru yazdığınızdan emin olun
3. Yenile butonuna basın

### GPS Çalışmıyor
1. Konum servislerinin açık olduğunu kontrol edin
2. Uygulama izinlerinden konum iznini verin
3. Dışarıda test edin (GPS sinyali için)

## 📚 Proje Yapısı

```
lib/
├── main.dart                      # Ana uygulama (Koyu mavi tema)
├── utils/
│   └── colors.dart               # Renk paleti
├── models/
│   ├── prayer_times_model.dart   # Vakit modeli
│   └── place_model.dart          # Yer modeli
└── services/
    ├── vakit_api_service.dart    # API servisi
    ├── storage_service.dart      # Yerel kayıt
    └── location_service.dart     # GPS servisi

android/app/src/main/kotlin/
└── com/example/imsakiye_app/
    ├── MainActivity.kt           # Ana aktivite
    └── BootReceiver.kt          # Otomatik başlatma
```

## 🎯 Öneriler

### Cami/Mescit Kullanımı İçin
1. ✅ Otomatik başlatma özelliği aktif
2. ✅ Ekranı açık tutma (istenirse MainActivity'de açın)
3. ✅ Batarya optimizasyonunu kapatın
4. ✅ Uçak modunu kapatın (API için internet gerekli)

### Kişisel Kullanım İçin
1. ✅ GPS özelliğini kullanın
2. ✅ Farklı şehirleri deneyin
3. ✅ Önbellekleme sayesinde offline çalışır

## 🔄 Güncellemeler

### Versiyon 1.0.0 (Mevcut)
- ✅ Koyu mavi tema (Orijinal APK'dan)
- ✅ Otomatik başlatma özelliği
- ✅ Canlı API entegrasyonu
- ✅ GPS konum desteği
- ✅ Şehir arama
- ✅ Önbellekleme

### Gelecek Güncellemeler
- [ ] Bildirim sistemi
- [ ] Widget desteği
- [ ] Kıble yönü
- [ ] Hadis-i şerif gösterimi
- [ ] Çoklu dil desteği

## 📄 Lisans

Bu proje eğitim ve ibadet amaçlı geliştirilmiştir.

## 🙏 Teşekkürler

- **vakit.vercel.app** - API için
- **Orijinal Dikey Mod APK** - Tasarım ilhamı için
- **Flutter Team** - Framework için

---

**📱 Cihaz açıldığında otomatik olarak başlar!**  
**🎨 Orijinal koyu mavi tema ile!**  
**📡 Canlı namaz vakitleri ile!**

**Son Güncelleme:** 6 Ocak 2026  
**Versiyon:** 1.0.0
