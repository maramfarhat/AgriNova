import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/crop_provider.dart';
import 'package:farm/providers/iot_provider.dart';
import 'package:farm/providers/irrigation_provider.dart';
import 'package:farm/providers/finance_provider.dart';
import 'package:farm/providers/weather_provider.dart';
import 'package:farm/providers/market_provider.dart';
import 'package:farm/providers/robot_provider.dart';
import 'package:farm/providers/agribot_provider.dart';
import 'package:farm/services/database_service.dart';
import 'package:farm/routes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:farm/theme/app_theme.dart';
import 'package:farm/services/database_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:farm/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialiser et mettre à jour la base de données
  final dbHelper = DatabaseHelper();
  debugPrint('🔄 Initialisation de la base de données...');

  // S'assurer que la base de données est créée
  final db = await dbHelper.database;
  debugPrint('✅ Base de données initialisée');

  // Vérifier et créer les tables nécessaires
  debugPrint('🔄 Vérification des tables...');

  // Vérifier la table crops
  if (!await dbHelper.isTableExists('crops')) {
    debugPrint('📦 Création de la table crops...');
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
    debugPrint('✅ Table crops créée');
  }

  // Vérifier la table irrigation_configs
  if (!await dbHelper.isTableExists('irrigation_configs')) {
    debugPrint('📦 Création de la table irrigation_configs...');
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
    debugPrint('✅ Table irrigation_configs créée');
  }

  // Vérifier la table irrigation_records
  if (!await dbHelper.isTableExists('irrigation_records')) {
    debugPrint('📦 Création de la table irrigation_records...');
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
    debugPrint('✅ Table irrigation_records créée');
  }

  // Vérifier la table market_products
  if (!await dbHelper.isTableExists('market_products')) {
    debugPrint('📦 Création de la table market_products...');
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
    debugPrint('✅ Table market_products créée');
  }

  await dbHelper.updateMarketProductsTable();
  debugPrint('✅ Mise à jour de la table market_products');

  await initializeDateFormatting('fr_FR', null);
  debugPrint('✅ Format de date initialisé');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => CropProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProxyProvider<WeatherProvider, IoTProvider>(
          create: (context) {
            debugPrint('🔄 Création du IoTProvider...');
            return IoTProvider(context.read<WeatherProvider>());
          },
          update: (context, weatherProvider, previous) {
            debugPrint('🔄 Mise à jour du IoTProvider...');
            return previous ?? IoTProvider(weatherProvider);
          },
        ),
        ChangeNotifierProxyProvider<IoTProvider, IrrigationProvider>(
          create: (context) {
            debugPrint('🔄 Création du IrrigationProvider...');
            return IrrigationProvider(context.read<IoTProvider>());
          },
          update: (context, iotProvider, previous) {
            debugPrint('🔄 Mise à jour du IrrigationProvider...');
            return previous ?? IrrigationProvider(iotProvider);
          },
        ),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => MarketProvider()),
        ChangeNotifierProvider(create: (_) => RobotProvider(DatabaseService())),
        ChangeNotifierProvider(create: (_) => AgribotProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Farm',
        theme: AppTheme.theme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', ''),
        ],
        routes: routes,
        initialRoute: '/',
      ),
    );
  }
}
