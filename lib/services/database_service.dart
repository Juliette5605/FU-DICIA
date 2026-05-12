// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fu_dicia.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE collectes_local (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            collectrice_id TEXT NOT NULL,
            client_nom TEXT NOT NULL,
            client_qr_code TEXT,
            montant_reel REAL NOT NULL,
            montant_attendu REAL DEFAULT 5000,
            latitude REAL,
            longitude REAL,
            photo_path TEXT,
            statut TEXT DEFAULT 'validee',
            collected_at TEXT NOT NULL,
            synced INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE gps_points_local (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            collectrice_id TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            recorded_at TEXT NOT NULL,
            synced INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE clients_scanned_today (
            qr_code TEXT PRIMARY KEY,
            client_nom TEXT,
            scan_date TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ── COLLECTES ──────────────────────────────────────────────
  static Future<int> insertCollecte(Collecte c) async {
    final db = await database;
    return db.insert('collectes_local', {
      'collectrice_id': c.collectriceId,
      'client_nom': c.clientNom,
      'client_qr_code': c.clientQrCode,
      'montant_reel': c.montantReel,
      'montant_attendu': c.montantAttendu,
      'latitude': c.latitude,
      'longitude': c.longitude,
      'photo_path': c.photoPath,
      'statut': c.statut,
      'collected_at': c.collectedAt.toIso8601String(),
      'synced': 0,
    });
  }

  static Future<List<Collecte>> getCollectesToday(String collectriceId) async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();

    final rows = await db.query(
      'collectes_local',
      where: 'collectrice_id = ? AND collected_at >= ?',
      whereArgs: [collectriceId, startOfDay],
      orderBy: 'collected_at DESC',
    );
    return rows.map((r) => Collecte.fromMap(r)).toList();
  }

  static Future<List<Collecte>> getUnsyncedCollectes() async {
    final db = await database;
    final rows = await db.query(
      'collectes_local',
      where: 'synced = 0',
    );
    return rows.map((r) => Collecte.fromMap(r)).toList();
  }

  static Future<void> markCollecteSynced(int localId) async {
    final db = await database;
    await db.update(
      'collectes_local',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  static Future<int> countCollectesToday(String collectriceId) async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM collectes_local WHERE collectrice_id = ? AND collected_at >= ?',
      [collectriceId, startOfDay],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  static Future<double> totalCollectesToday(String collectriceId) async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final result = await db.rawQuery(
      'SELECT SUM(montant_reel) as total FROM collectes_local WHERE collectrice_id = ? AND collected_at >= ?',
      [collectriceId, startOfDay],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // ── GPS POINTS ─────────────────────────────────────────────
  static Future<void> insertGpsPoint(GpsPoint p) async {
    final db = await database;
    await db.insert('gps_points_local', {
      'collectrice_id': p.collectriceId,
      'latitude': p.latitude,
      'longitude': p.longitude,
      'recorded_at': p.recordedAt.toIso8601String(),
      'synced': 0,
    });
  }

  // ── QR ANTI-DOUBLE SCAN ────────────────────────────────────
  static Future<bool> isAlreadyScannedToday(String qrCode) async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();

    final rows = await db.query(
      'clients_scanned_today',
      where: 'qr_code = ? AND scan_date >= ?',
      whereArgs: [qrCode, startOfDay],
    );
    return rows.isNotEmpty;
  }

  static Future<void> markScannedToday(
      String qrCode, String clientNom) async {
    final db = await database;
    await db.insert(
      'clients_scanned_today',
      {
        'qr_code': qrCode,
        'client_nom': clientNom,
        'scan_date': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
