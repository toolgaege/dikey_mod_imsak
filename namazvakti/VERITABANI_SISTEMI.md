# 🗄️ SQLite Veritabanı Sistemi - Yıllık Namaz Vakitleri

## 🎯 Özellikler

✅ **Yıllık Veri Depolama**: 365 günlük namaz vakitleri SQLite'da saklanır
✅ **Offline Çalışma**: İnternet olmadan tam işlevsel
✅ **Otomatik Senkronizasyon**: Yıl değiştiğinde otomatik yeni yıl verileri
✅ **Akıllı Cache**: Veritabanında yoksa API'den çeker
✅ **Eski Veri Temizleme**: Geçmiş yılların verileri otomatik silinir
✅ **Detaylı Loglama**: Her işlem console'da görünür

## 📊 Veritabanı Yapısı

### Tablo: `prayer_times`

| Alan        | Tip     | Açıklama                    |
|-------------|---------|----------------------------|
| id          | INTEGER | Primary key (auto)         |
| date        | TEXT    | YYYY-MM-DD formatında      |
| year        | INTEGER | Yıl (indeksli)             |
| month       | INTEGER | Ay                         |
| day         | INTEGER | Gün                        |
| fajr        | TEXT    | Fecr vakti (HH:MM)         |
| sunrise     | TEXT    | Güneş vakti (HH:MM)        |
| dhuhr       | TEXT    | Öğle vakti (HH:MM)         |
| asr         | TEXT    | İkindi vakti (HH:MM)       |
| maghrib     | TEXT    | Akşam vakti (HH:MM)        |
| isha        | TEXT    | Yatsı vakti (HH:MM)        |
| place_id    | TEXT    | Yer ID (Denizli vs)        |
| place_name  | TEXT    | Yer adı                    |
| latitude    | REAL    | Enlem                      |
| longitude   | REAL    | Boylam                     |
| created_at  | TEXT    | Kayıt tarihi (ISO8601)     |

**UNIQUE constraint**: (date, place_id) - Her tarih/yer için tek kayıt

**İndeksler**:
- `idx_date`: date alanında hızlı arama
- `idx_year`: year alanında hızlı arama

## 🔄 Çalışma Mantığı

### 1. İlk Başlatma (Internet Var)

```
Uygulama Başlat
    ↓
Denizli lokasyonunu seç
    ↓
Veritabanında bugünün vakitleri var mı?
    ↓
HAYIR → Veritabanında 2026 yılı için yeterli veri var mı? (360+ kayıt)
    ↓
HAYIR → API'den 365 günlük veri çek
    ↓
Veritabanına kaydet (365 kayıt)
    ↓
Bugünün vakitlerini veritabanından yükle
    ↓
✅ Hazır! (İnternet artık gerekmez)
```

### 2. Normal Kullanım (Offline)

```
Uygulama Başlat
    ↓
Veritabanından bugünün vakitlerini oku
    ↓
✅ Göster (0.1 saniye)
```

### 3. Her 5 Dakikada Otomatik Kontrol

```
Timer Tetiklendi (5 dakika)
    ↓
Tarih değişti mi?
    ↓
EVET → Veritabanından yeni günün vakitlerini yükle
    ↓
Yıl değişti mi? (2026 → 2027)
    ↓
EVET → Yeni yılın 365 günlük verilerini API'den çek
    ↓
Eski yılın verilerini sil (2026)
    ↓
✅ Yeni yıl hazır!
```

## 📁 Oluşturulan Dosyalar

### 1. `lib/models/prayer_time_db_model.dart`
Veritabanı modeli - SQLite için veri yapısı

### 2. `lib/services/database_service.dart`
Veritabanı servisi - CRUD operasyonları:
- `insertPrayerTimes()`: Toplu veri ekleme
- `getPrayerTimeByDate()`: Tarihe göre veri getir
- `getPrayerTimesByYear()`: Yıllık verileri getir
- `hasDataForYear()`: Yıl için veri var mı kontrol
- `deleteOldYearData()`: Eski verileri temizle
- `printDatabaseStats()`: İstatistikleri göster

### 3. Güncellenmiş Dosyalar
- `pubspec.yaml`: sqflite ve path paketleri eklendi
- `lib/services/vakit_api_service.dart`: `getYearlyTimes()` eklendi
- `lib/services/storage_service.dart`: DB entegrasyonu eklendi
- `lib/main.dart`: DB okuma ve yıl değişim kontrolü eklendi

## 🚀 İlk Çalıştırma

İlk kez çalıştırıldığında console'da şunu göreceksiniz:

```
🚀 ═══════════════════════════════════════════
🚀 UYGULAMA BAŞLATILIYOR...
🚀 ═══════════════════════════════════════════
⚠️ Veritabanında bugün için veri yok
⚠️ 2026 yılı için veritabanında yeterli veri yok!
📡 İnternetten yıllık veriler çekiliyor...

📅 ═══════════════════════════════════════════
📅 YILLIK VERİLER ÇEKİLİYOR...
📅 Yıl: 2026
📅 Başlangıç: 2026-01-01
📅 ═══════════════════════════════════════════
🕌 API İsteği Gönderiliyor...
✅ API Yanıtı Başarılı (200)
📦 Veri boyutu: 45231 byte
✅ 365 günlük veri başarıyla çekildi!

💾 ═══════════════════════════════════════════
💾 YILLIK VERİLER VERİTABANINA KAYDEDİLİYOR...
💾 Yıl: 2026
💾 Yer: Denizli
💾 Toplam: 365 gün
💾 ═══════════════════════════════════════════
✅ 365 kayıt veritabanına eklendi!
✅ Yıllık veriler başarıyla kaydedildi!
🎉 Artık internet olmadan çalışabilir!

✅ Veritabanından vakitler yüklendi: 2026-01-08

📊 ═══════════════════════════════════════════
📊 VERİTABANI İSTATİSTİKLERİ
📊 ═══════════════════════════════════════════
📅 Yıl: 2026 - Kayıt: 365 - Tarih: 2026-01-01 ~ 2026-12-31
📊 ═══════════════════════════════════════════
```

## 🧪 Test Senaryoları

### Test 1: İlk Kurulum (Internet Var)
1. Uygulamayı ilk kez çalıştır
2. 365 günlük veri çekilecek (~5-10 saniye)
3. Veritabanına kaydedilecek
4. ✅ Sonuç: Offline çalışmaya hazır

### Test 2: Offline Mod
1. İnternet bağlantısını kes
2. Uygulamayı kapat ve aç
3. ✅ Sonuç: Vakitler veritabanından yükleniyor

### Test 3: Yeni Gün Geçişi
1. Uygulamayı açık tut
2. 5 dakika bekle (veya sistem saatini değiştir)
3. ✅ Sonuç: Yeni günün vakitleri otomatik yüklendi

### Test 4: Yıl Değişimi
1. Sistem tarihini 2027'ye al
2. Uygulamayı aç veya 5 dakika bekle
3. ✅ Sonuç: 2027 yılının verileri otomatik çekildi

### Test 5: Veritabanı İstatistikleri
Console'da her başlangıçta gösterilir:
```
📊 VERİTABANI İSTATİSTİKLERİ
📅 Yıl: 2026 - Kayıt: 365 - Tarih: 2026-01-01 ~ 2026-12-31
```

## 💡 Avantajlar

1. **Hız**: Veritabanından okuma <0.1 saniye
2. **Güvenilirlik**: Internet kesilse de çalışır
3. **Veri Tasarrufu**: Sadece yılda bir kez ~50KB indirir
4. **Otomatik**: Kullanıcı hiçbir şey yapmasına gerek yok
5. **Temiz**: Eski veriler otomatik silinir

## 🔧 Bakım

Veritabanını tamamen sıfırlamak için:

```dart
await StorageService().clearAll();
```

Bu komut:
- Tüm SharedPreferences'ı temizler
- Tüm veritabanı kayıtlarını siler
- Uygulama yeniden başlatılınca baştan kurar

## 📱 Veritabanı Konumu

- **iOS**: `~/Library/Application Support/prayer_times.db`
- **Android**: `/data/data/com.example.app/databases/prayer_times.db`
- **macOS**: `~/Library/Application Support/prayer_times.db`

## 🔍 Debug

Her işlem console'da detaylı loglanır:
- 🚀 Uygulama başlatma
- 📅 Yıllık veri çekme
- 💾 Veritabanı kaydetme
- ✅ Başarılı işlemler
- ❌ Hatalar
- 🔍 Günlük kontroller
- 🎊 Yıl değişimi

---

**Sonuç**: Uygulama artık tam offline çalışabilir! İlk kurulumda internet gerekir (365 günlük veri için), sonrasında tüm yıl boyunca internet olmadan kullanılabilir. 🎉
