import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../models/prayer_time_db_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static bool _isInitialized = false;

  /// Platform türünü kontrol et - Desktop platformlar için true döner
  bool _isDesktop() {
    if (kIsWeb) {
      return false; // Web platformu
    }

    // Flutter'ın defaultTargetPlatform'unu kullan
    return defaultTargetPlatform == TargetPlatform.macOS ||
           defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Platform için veritabanı factory'yi başlat
  void _initializeDatabaseFactory() {
    if (_isInitialized) return;

    // Desktop platformlar için sqflite_common_ffi kullan
    if (_isDesktop()) {
      print('🖥️ Desktop platform tespit edildi, sqflite_common_ffi kullanılıyor...');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } else if (kIsWeb) {
      print('🌐 Web platform tespit edildi, veritabanı kullanılamaz.');
      // Web'de SQLite kullanılamaz, IndexedDB gibi alternatifler gerekir
    } else {
      print('📱 Mobil platform tespit edildi, standart sqflite kullanılıyor...');
    }

    _isInitialized = true;
  }

  /// Veritabanı bağlantısını al
  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Web platformunda SQLite desteklenmez');
    }

    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Veritabanını başlat
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Web platformunda SQLite desteklenmez');
    }

    _initializeDatabaseFactory();

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'prayer_times.db');

    print('📁 Veritabanı yolu: $path');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Veritabanı tablolarını oluştur
  Future<void> _createDatabase(Database db, int version) async {
    print('🗄️ Veritabanı tabloları oluşturuluyor...');

    await db.execute('''
      CREATE TABLE prayer_times (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        day INTEGER NOT NULL,
        fajr TEXT NOT NULL,
        sunrise TEXT NOT NULL,
        dhuhr TEXT NOT NULL,
        asr TEXT NOT NULL,
        maghrib TEXT NOT NULL,
        isha TEXT NOT NULL,
        place_id TEXT NOT NULL,
        place_name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        created_at TEXT NOT NULL,
        hijri_day INTEGER,
        hijri_month INTEGER,
        hijri_year INTEGER,
        UNIQUE(date, place_id)
      )
    ''');

    // İndeksler oluştur
    await db.execute('''
      CREATE INDEX idx_date ON prayer_times(date)
    ''');

    await db.execute('''
      CREATE INDEX idx_year ON prayer_times(year)
    ''');

    print('✅ Veritabanı tabloları başarıyla oluşturuldu!');
  }

  /// Veritabanı sürüm yükseltme (v1 → v2: Hicri tarih sütunları eklendi)
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('🔄 Veritabanı güncelleniyor: v$oldVersion → v$newVersion');

    if (oldVersion < 2) {
      // Hicri tarih sütunlarını ekle
      await db.execute('ALTER TABLE prayer_times ADD COLUMN hijri_day INTEGER');
      await db.execute('ALTER TABLE prayer_times ADD COLUMN hijri_month INTEGER');
      await db.execute('ALTER TABLE prayer_times ADD COLUMN hijri_year INTEGER');

      // Eski verileri temizle ki yeni API'den Hicri tarihleriyle birlikte tekrar çekilsin
      await db.delete('prayer_times');
      print('✅ Hicri tarih sütunları eklendi, veriler yenilenecek');
    }
  }

  /// Namaz vakitlerini kaydet (toplu ekleme)
  Future<int> insertPrayerTimes(List<PrayerTimeDB> prayerTimes) async {
    final db = await database;
    int insertedCount = 0;

    await db.transaction((txn) async {
      for (var prayerTime in prayerTimes) {
        try {
          await txn.insert(
            'prayer_times',
            prayerTime.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          insertedCount++;
        } catch (e) {
          print('❌ Kayıt hatası: ${prayerTime.date} - $e');
        }
      }
    });

    print('✅ $insertedCount namaz vakti kaydedildi');
    return insertedCount;
  }

  /// Belirli bir tarihteki namaz vaktini getir
  Future<PrayerTimeDB?> getPrayerTimeByDate(String date, String placeId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'prayer_times',
      where: 'date = ? AND place_id = ?',
      whereArgs: [date, placeId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return PrayerTimeDB.fromMap(maps.first);
  }

  /// Belirli bir yılın tüm verilerini getir
  Future<List<PrayerTimeDB>> getPrayerTimesByYear(int year, String placeId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'prayer_times',
      where: 'year = ? AND place_id = ?',
      whereArgs: [year, placeId],
      orderBy: 'date ASC',
    );

    return maps.map((map) => PrayerTimeDB.fromMap(map)).toList();
  }

  /// Belirli bir tarih aralığındaki verileri getir
  Future<List<PrayerTimeDB>> getPrayerTimesByDateRange(
    String startDate,
    String endDate,
    String placeId,
  ) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'prayer_times',
      where: 'date BETWEEN ? AND ? AND place_id = ?',
      whereArgs: [startDate, endDate, placeId],
      orderBy: 'date ASC',
    );

    return maps.map((map) => PrayerTimeDB.fromMap(map)).toList();
  }

  /// Veritabanında belirli bir yıl için veri var mı kontrol et
  Future<bool> hasDataForYear(int year, String placeId) async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_times WHERE year = ? AND place_id = ?',
      [year, placeId],
    );

    final count = Sqflite.firstIntValue(result) ?? 0;
    print('📊 $year yılı için veritabanında $count kayıt var');

    // En az 360 kayıt olması beklenir (365 günün ~%99'u)
    return count >= 360;
  }

  /// Belirli bir tarihteki Hicri tarihi getir
  Future<Map<String, int>?> getHijriDateByDate(String date) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'prayer_times',
      columns: ['hijri_day', 'hijri_month', 'hijri_year'],
      where: 'date = ? AND hijri_day IS NOT NULL',
      whereArgs: [date],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final row = maps.first;
    if (row['hijri_day'] == null) return null;

    return {
      'day': row['hijri_day'] as int,
      'month': row['hijri_month'] as int,
      'year': row['hijri_year'] as int,
    };
  }

  /// Eski yılların verilerini temizle (mevcut yıl hariç)
  Future<int> deleteOldYearData(int currentYear) async {
    final db = await database;

    final deletedCount = await db.delete(
      'prayer_times',
      where: 'year < ?',
      whereArgs: [currentYear],
    );

    print('🗑️ $deletedCount eski kayıt silindi (yıl < $currentYear)');
    return deletedCount;
  }

  /// Tüm verileri temizle
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('prayer_times');
    print('🗑️ Tüm veriler temizlendi');
  }

  /// Veritabanı istatistiklerini göster
  Future<void> printDatabaseStats() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT
        year,
        COUNT(*) as count,
        MIN(date) as first_date,
        MAX(date) as last_date
      FROM prayer_times
      GROUP BY year
      ORDER BY year DESC
    ''');

    print('');
    print('📊 ═══════════════════════════════════════════');
    print('📊 VERİTABANI İSTATİSTİKLERİ');
    print('📊 ═══════════════════════════════════════════');

    for (var row in result) {
      print('📅 Yıl: ${row['year']} - Kayıt: ${row['count']} - Tarih: ${row['first_date']} ~ ${row['last_date']}');
    }

    print('📊 ═══════════════════════════════════════════');
    print('');
  }

  /// Veritabanını kapat
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
