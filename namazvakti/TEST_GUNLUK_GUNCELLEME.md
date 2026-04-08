# Günlük Vakitleri Güncelleme Testi

## 🔍 Test Adımları

### Test 1: İlk Başlatma
1. Uygulamayı tamamen kapatın
2. Uygulamanın cache'ini temizleyin (opsiyonel)
3. Uygulamayı başlatın
4. Console'da şu logları görmelisiniz:

```
🚀 ═══════════════════════════════════════════
🚀 UYGULAMA BAŞLATILIYOR...
🚀 ═══════════════════════════════════════════
⚠️ Cache bulunamadı, ilk defa vakitler çekilecek.
💡 _lastUpdateDate boş bırakıldı, API çekimi yapılacak

═══════════════════════════════════════════
🔄 Namaz Vakitleri Güncelleniyor...
📅 Bugünün Tarihi: 2026-01-08
📍 Konum: Denizli
═══════════════════════════════════════════
🕌 API İsteği Gönderiliyor...
📍 URL: https://vakit.vercel.app/api/timesForGPS?...
📅 Tarih: 2026-01-08
✅ API Yanıtı Başarılı (200)
📦 Ham Veri: {...}
🕐 Fecr: XX:XX
☀️ Güneş: XX:XX
🕐 Öğle: XX:XX  ← Bu Öğle vaktinin gerçek saati
🕐 İkindi: XX:XX
🌙 Akşam: XX:XX
⭐ Yatsı: XX:XX

✅ Vakitler Başarıyla Güncellendi!
═══════════════════════════════════════════
```

### Test 2: Aynı Gün Tekrar Açma
1. Uygulamayı kapatın
2. Uygulamayı tekrar açın (aynı gün içinde)
3. Console'da şu logları görmelisiniz:

```
🚀 UYGULAMA BAŞLATILIYOR...
📂 Cache tarihi: 2026-01-08
📅 Bugünün tarihi: 2026-01-08
✅ Cache güncel, önbellekten yükleniyor
```

API çağrısı YAPILMAMALI çünkü cache güncel.

### Test 3: 5 Dakikalık Kontroller
1. Uygulamayı açık tutun
2. Her 5 dakikada bir console'da şu logları görmelisiniz:

```
🔍 ═══════════════════════════════════════════
🔍 GÜNLÜK KONTROL YAPILIYOR...
🔍 Saat: 14:35
📅 Son Güncelleme: 2026-01-08
📅 Bugünün Tarihi: 2026-01-08
🔍 ═══════════════════════════════════════════
✅ Vakitler güncel, güncellemeye gerek yok.
```

### Test 4: Yeni Gün Geçişi (Kritik Test!)
Bu testi yapmak için sisteminizin tarihini manuel değiştirmeniz gerekiyor:

1. Uygulamayı açık tutun
2. Sistem tarihini 1 gün ileriye alın (örn: 2026-01-08 → 2026-01-09)
3. En fazla 5 dakika bekleyin
4. Console'da şu logları görmelisiniz:

```
🔍 GÜNLÜK KONTROL YAPILIYOR...
📅 Son Güncelleme: 2026-01-08
📅 Bugünün Tarihi: 2026-01-09
🔍 ═══════════════════════════════════════════

🌅 ═══════════════════════════════════════════
🌅 YENİ GÜN TESPİT EDİLDİ!
🌅 ═══════════════════════════════════════════
⏰ Son Güncelleme: 2026-01-08
📅 Bugün: 2026-01-09
🔄 Vakitler otomatik güncelleniyor...

═══════════════════════════════════════════
🔄 Namaz Vakitleri Güncelleniyor...
📅 Bugünün Tarihi: 2026-01-09
📍 Konum: Denizli
═══════════════════════════════════════════
[API çağrısı yapılıyor...]
✅ Vakitler Başarıyla Güncellendi!
```

### Test 5: Eski Cache ile Başlatma
1. Uygulamayı kapatın
2. Sistem tarihini 1 gün ileriye alın
3. Uygulamayı tekrar açın
4. Console'da şu logları görmelisiniz:

```
🚀 UYGULAMA BAŞLATILIYOR...
📂 Cache tarihi: 2026-01-08
📅 Bugünün tarihi: 2026-01-09
⚠️ Cache ESKİ! Yeni vakitler çekilecek.
💡 _lastUpdateDate boş bırakıldı, API çekimi yapılacak

[API çağrısı yapılıyor ve yeni vakitler çekiliyor...]
```

## ✅ Başarı Kriterleri

- [ ] İlk başlatmada API'den vakitler çekiliyor
- [ ] Aynı gün tekrar açılınca cache'ten yükleniyor (API çağrısı yok)
- [ ] Her 5 dakikada kontrol yapılıyor
- [ ] Yeni gün başladığında otomatik güncelleniyor
- [ ] Eski cache ile başlatılınca yeni vakitler çekiliyor
- [ ] Öğle vaktinin doğru saati görünüyor (13:17 veya 13:15?)

## 🐛 Sorun Varsa

Eğer günlük güncelleme çalışmıyorsa:
1. Console loglarını kontrol edin
2. `_lastUpdateDate` değerini kontrol edin
3. Timer'ın düzgün çalıştığını kontrol edin
4. Cache tarihini kontrol edin

## 📊 Günlük Güncelleme Mekanizması

```
Uygulama Başlatma
    ↓
Cache Kontrolü
    ↓
├─ Cache güncel → Cache'ten yükle → _lastUpdateDate = bugün
└─ Cache eski/yok → API çek → _lastUpdateDate = bugün
    ↓
Her 5 dakikada
    ↓
_checkAndUpdateIfNewDay()
    ↓
_lastUpdateDate ≠ bugün?
    ↓
├─ EVET → API'den yeni vakitler çek
└─ HAYIR → Hiçbir şey yapma
```
