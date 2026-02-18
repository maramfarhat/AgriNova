// ignore_for_file: unused_import

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:farm/models/irrigation_config.dart';
import 'package:farm/models/irrigation_record.dart';
import 'package:farm/models/market_product.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      debugPrint('📦 Base de données existante utilisée');
      return _database!;
    }
    debugPrint('📦 Initialisation de la base de données...');
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'farm.db');
      debugPrint('📂 Chemin de la base de données: $path');

      final db = await openDatabase(
        path,
        version: 2,
        onCreate: _createDb,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          debugPrint('🔓 Base de données ouverte');
          // Vérifier si les tables existent
          final tables = await db.query('sqlite_master', columns: ['name']);
          debugPrint(
              '📋 Tables existantes: ${tables.map((e) => e['name']).join(', ')}');
        },
      );

      debugPrint('✅ Base de données initialisée avec succès');
      return db;
    } catch (e, stackTrace) {
      debugPrint(
          '❌ Erreur lors de l\'initialisation de la base de données: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Backup old data
      final List<Map<String, dynamic>> oldConfigs =
          await db.query('irrigation_configs');

      // Drop and recreate the table with new schema
      await db.execute('DROP TABLE IF EXISTS irrigation_configs');
      await db.execute('''
        CREATE TABLE irrigation_configs(
          id TEXT PRIMARY KEY,
          cropId TEXT NOT NULL,
          name TEXT NOT NULL,
          zone TEXT NOT NULL,
          duration INTEGER NOT NULL,
          waterVolume REAL NOT NULL,
          isActive INTEGER NOT NULL,
          isAutomatic INTEGER NOT NULL,
          scheduledDates TEXT NOT NULL,
          schedule TEXT NOT NULL
        )
      ''');

      // Restore data without moisture fields
      for (var oldConfig in oldConfigs) {
        await db.insert('irrigation_configs', {
          'id': oldConfig['id'],
          'cropId': oldConfig['cropId'],
          'name': oldConfig['name'],
          'zone': oldConfig['zone'],
          'duration': oldConfig['duration'],
          'waterVolume': oldConfig['waterVolume'],
          'isActive': oldConfig['isActive'],
          'isAutomatic': oldConfig['isAutomatic'],
          'scheduledDates': oldConfig['scheduledDates'],
          'schedule': oldConfig['schedule'],
        });
      }
    }
  }

  Future<void> _createDb(Database db, int version) async {
    try {
      debugPrint('Creating database tables...');

      // Créer la table crops
      await db.execute('''
        CREATE TABLE IF NOT EXISTS crops(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          plantingDate TEXT NOT NULL,
          harvestDate TEXT,
          area REAL NOT NULL,
          status TEXT NOT NULL
        )
      ''');
      debugPrint('crops table created');

      // Créer la table weather_records
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
      debugPrint('weather_records table created');

      // Créer la table irrigation_configs
      await db.execute('''
        CREATE TABLE IF NOT EXISTS irrigation_configs(
          id TEXT PRIMARY KEY,
          cropId TEXT NOT NULL,
          name TEXT NOT NULL,
          zone TEXT NOT NULL,
          duration INTEGER NOT NULL,
          waterVolume REAL NOT NULL,
          isActive INTEGER NOT NULL,
          isAutomatic INTEGER NOT NULL,
          scheduledDates TEXT NOT NULL,
          schedule TEXT NOT NULL
        )
      ''');
      debugPrint('irrigation_configs table created');

      // Créer la table market_products
      await db.execute('''
        CREATE TABLE IF NOT EXISTS market_products(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          price REAL NOT NULL,
          category TEXT NOT NULL,
          availability INTEGER NOT NULL,
          quantity REAL NOT NULL,
          unit TEXT NOT NULL,
          imageUrl TEXT NOT NULL,
          phone TEXT
        )
      ''');
      debugPrint('market_products table created');

      // Créer la table irrigation_records
      await db.execute('''
        CREATE TABLE IF NOT EXISTS irrigation_records(
          id TEXT PRIMARY KEY,
          configId TEXT NOT NULL,
          date TEXT NOT NULL,
          endTime TEXT,
          waterVolume REAL NOT NULL,
          duration INTEGER NOT NULL,
          zone TEXT NOT NULL,
          soilMoisture REAL NOT NULL,
          status TEXT NOT NULL
        )
      ''');
      debugPrint('irrigation_records table created');

      debugPrint('All tables created successfully');
    } catch (e) {
      debugPrint('Error creating database tables: $e');
      rethrow;
    }
  }

  Future<void> insertConfig(IrrigationConfig config) async {
    try {
      final db = await database;
      final configJson = config.toJson();
      debugPrint('🔄 Insertion de la configuration: ${config.id}');
      debugPrint('📝 Données à insérer: $configJson');

      await db.insert(
        'irrigation_configs',
        configJson,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Vérifier que l'insertion a réussi
      final inserted = await db.query(
        'irrigation_configs',
        where: 'id = ?',
        whereArgs: [config.id],
      );

      if (inserted.isNotEmpty) {
        debugPrint('✅ Configuration insérée avec succès');
        debugPrint('📄 Données insérées: ${inserted.first}');
      } else {
        throw Exception('La configuration n\'a pas été insérée');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de l\'insertion de la configuration: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<IrrigationConfig>> getConfigs() async {
    try {
      final db = await database;
      debugPrint('🔄 Récupération des configurations...');

      final List<Map<String, dynamic>> maps =
          await db.query('irrigation_configs');
      debugPrint('📋 Nombre de configurations trouvées: ${maps.length}');

      if (maps.isNotEmpty) {
        debugPrint('📄 Première configuration: ${maps.first}');
      }

      return List.generate(maps.length, (i) {
        return IrrigationConfig.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la récupération des configurations: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateConfig(IrrigationConfig config) async {
    final db = await database;
    debugPrint('Updating config with ID: ${config.id}');

    try {
      final count = await db.update(
        'irrigation_configs',
        config.toJson(),
        where: 'id = ?',
        whereArgs: [config.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (count == 0) {
        throw Exception(
            'Aucune configuration trouvée avec l\'ID: ${config.id}');
      }

      debugPrint('Config updated successfully');
    } catch (e) {
      debugPrint('Error updating config: $e');
      rethrow;
    }
  }

  Future<void> deleteConfig(String id) async {
    final db = await database;
    await db.delete(
      'irrigation_configs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertRecord(IrrigationRecord record) async {
    final db = await database;
    await db.insert(
      'irrigation_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRecord(IrrigationRecord record) async {
    final db = await database;
    await db.update(
      'irrigation_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<List<IrrigationRecord>> getRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('irrigation_records');
    return List.generate(
        maps.length, (i) => IrrigationRecord.fromJson(maps[i]));
  }

  Future<List<Map<String, dynamic>>> query(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(String table, Map<String, dynamic> data,
      {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table,
      {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
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

  Future<void> resetDatabase() async {
    try {
      debugPrint('Resetting database...');
      await _deleteDatabase();
      await database;
      debugPrint('Database reset completed');
    } catch (e) {
      debugPrint('Error resetting database: $e');
      rethrow;
    }
  }

  Future<void> _deleteDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'farm.db');
      debugPrint('Deleting database at: $path');
      await deleteDatabase(path);
      _database = null;
      debugPrint('Database deleted successfully');
    } catch (e) {
      debugPrint('Error deleting database: $e');
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

  Future<void> updateMarketProductsTable() async {
    try {
      final db = await database;

      // Vérifier si la colonne phone existe déjà
      var tableInfo = await db.rawQuery('PRAGMA table_info(market_products)');
      bool hasPhoneColumn =
          tableInfo.any((column) => column['name'] == 'phone');

      if (!hasPhoneColumn) {
        debugPrint('Adding phone column to market_products table...');
        await db.execute('ALTER TABLE market_products ADD COLUMN phone TEXT');
        debugPrint('Phone column added successfully');
      }
    } catch (e) {
      debugPrint('Error updating market_products table: $e');
      rethrow;
    }
  }

  Future<void> resetMarketProductsTable() async {
    try {
      final db = await database;
      await db.execute('DROP TABLE IF EXISTS market_products');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS market_products(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          price REAL NOT NULL,
          category TEXT NOT NULL,
          availability INTEGER NOT NULL,
          quantity REAL NOT NULL,
          unit TEXT NOT NULL,
          imageUrl TEXT NOT NULL,
          phone TEXT
        )
      ''');
      debugPrint('Table market_products reset successfully');
    } catch (e) {
      debugPrint('Error resetting market_products table: $e');
      rethrow;
    }
  }
}
