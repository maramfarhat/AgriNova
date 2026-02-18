import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'farm.db');
      debugPrint('Initializing database at: $path');
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDb,
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createDb(Database db, int version) async {
    try {
      debugPrint('Creating database tables...');

      // Créer la table weather_records si elle n'existe pas
      await db.execute('''
        CREATE TABLE IF NOT EXISTS weather_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          temperature REAL NOT NULL,
          humidity INTEGER NOT NULL,
          location TEXT NOT NULL,
          weatherDescription TEXT NOT NULL
        )
      ''');
      debugPrint('weather_records table created successfully');
    } catch (e) {
      debugPrint('Error creating database: $e');
      rethrow;
    }
  }

  Future<void> resetWeatherRecords() async {
    try {
      final db = await database;
      debugPrint('Dropping weather_records table...');
      await db.execute('DROP TABLE IF EXISTS weather_records');
      debugPrint('Creating new weather_records table...');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS weather_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          temperature REAL NOT NULL,
          humidity INTEGER NOT NULL,
          location TEXT NOT NULL,
          weatherDescription TEXT NOT NULL
        )
      ''');
      debugPrint('weather_records table reset successfully');
    } catch (e) {
      debugPrint('Error resetting weather_records: $e');
      rethrow;
    }
  }

  Future<bool> isTableExists(String tableName) async {
    final db = await database;
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      debugPrint('Table $tableName exists: ${result.isNotEmpty}');
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking table existence: $e');
      return false;
    }
  }

  Future<void> createWeatherRecordsTable(Database db) async {
    try {
      debugPrint('Creating weather_records table...');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS weather_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          temperature REAL NOT NULL,
          humidity INTEGER NOT NULL,
          location TEXT NOT NULL,
          weatherDescription TEXT NOT NULL
        )
      ''');
      debugPrint('weather_records table created successfully');
    } catch (e) {
      debugPrint('Error creating weather_records table: $e');
      rethrow;
    }
  }
}
