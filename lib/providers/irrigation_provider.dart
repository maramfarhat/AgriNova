import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:farm/models/irrigation_config.dart';
import 'package:farm/models/irrigation_record.dart';
import 'package:farm/providers/iot_provider.dart';
import 'package:farm/services/database_helper.dart';
import 'package:farm/services/esp32_service.dart';
import 'dart:async';

class IrrigationProvider with ChangeNotifier {
  final IoTProvider _iotProvider;
  final DatabaseHelper _db = DatabaseHelper();
  final ESP32Service _esp32Service = ESP32Service();
  bool _isIrrigationActive = false;
  List<IrrigationConfig> _configs = [];
  List<IrrigationRecord> _history = [];
  Timer? _configCheckTimer;
  bool _isInitialized = false;

  IrrigationProvider(this._iotProvider) {
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('🔄 Initialisation du IrrigationProvider...');
    try {
      await _loadConfigs();
      await _loadHistory();
      _startConfigCheck();
      _isInitialized = true;
      debugPrint('✅ IrrigationProvider initialisé avec succès');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de l\'initialisation: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  bool get isIrrigationActive => _isIrrigationActive;
  IoTProvider get iotProvider => _iotProvider;
  List<IrrigationConfig> get configs => [..._configs];
  bool get isInitialized => _isInitialized;

  void _startConfigCheck() {
    // Vérifier les configurations toutes les minutes
    _configCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkScheduledConfigs();
    });
  }

  Future<void> _checkScheduledConfigs() async {
    final now = DateTime.now();

    for (var config in _configs) {
      if (!config.isActive) continue;

      for (var scheduledDate in config.scheduledDates) {
        // Vérifier si c'est le moment d'irriguer
        if (scheduledDate.isAfter(now) &&
            scheduledDate.difference(now).inMinutes <= 1) {
          debugPrint(
              '🌿 Configuration d\'irrigation programmée trouvée: ${config.id}');
          await _activateScheduledIrrigation(config);
          break;
        }
      }
    }
  }

  Future<void> _activateScheduledIrrigation(IrrigationConfig config) async {
    try {
      debugPrint(
          '🚰 Activation de l\'irrigation programmée pour la configuration: ${config.id}');

      final success = await _esp32Service.controlPump(
        activate: true,
      );

      if (success) {
        // Créer un enregistrement d'irrigation
        final record = IrrigationRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          configId: config.id,
          date: DateTime.now(),
          endTime: DateTime.now().add(Duration(minutes: config.duration)),
          waterVolume: config.waterVolume,
          duration: config.duration,
          zone: config.zone,
          soilMoisture: _iotProvider.currentData?.soilMoisture ?? 0.0,
          status: 'in_progress',
        );

        await saveIrrigationRecord(record);
        debugPrint('✅ Irrigation programmée activée avec succès');

        // Programmer la désactivation de la pompe
        Future.delayed(Duration(minutes: config.duration), () async {
          await _esp32Service.controlPump(
            activate: false,
          );

          // Mettre à jour le statut de l'enregistrement
          final updatedRecord = IrrigationRecord(
            id: record.id,
            configId: record.configId,
            date: record.date,
            endTime: DateTime.now(),
            waterVolume: record.waterVolume,
            duration: record.duration,
            zone: record.zone,
            soilMoisture: _iotProvider.currentData?.soilMoisture ?? 0.0,
            status: 'completed',
          );

          await updateIrrigationRecord(updatedRecord);
          debugPrint('✅ Irrigation programmée terminée');
        });
      } else {
        debugPrint('❌ Échec de l\'activation de l\'irrigation programmée');
      }
    } catch (e) {
      debugPrint(
          '❌ Erreur lors de l\'activation de l\'irrigation programmée: $e');
    }
  }

  Future<void> _loadConfigs() async {
    try {
      debugPrint('🔄 Chargement des configurations...');
      _configs = await _db.getConfigs();
      debugPrint('📋 Nombre de configurations chargées: ${_configs.length}');
      if (_configs.isNotEmpty) {
        debugPrint('📄 Première configuration: ${_configs.first.toJson()}');
      }
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors du chargement des configurations: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _loadHistory() async {
    _history = await _db.getRecords();
    notifyListeners();
  }

  Future<List<IrrigationRecord>> getIrrigationHistory() async {
    return _history;
  }

  Future<void> addConfig(IrrigationConfig config) async {
    try {
      debugPrint('🔄 Ajout d\'une nouvelle configuration...');
      debugPrint('📝 Détails de la configuration:');
      debugPrint('  - ID: ${config.id}');
      debugPrint('  - Nom: ${config.name}');
      debugPrint('  - Zone: ${config.zone}');
      debugPrint('  - Culture ID: ${config.cropId}');
      debugPrint('  - Durée: ${config.duration}');
      debugPrint('  - Volume: ${config.waterVolume}');

      await _db.insertConfig(config);
      debugPrint('✅ Configuration insérée dans la base de données');

      await _loadConfigs();
      debugPrint('✅ Configurations rechargées avec succès');
      debugPrint('📊 Nombre total de configurations: ${_configs.length}');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de l\'ajout de la configuration:');
      debugPrint('Message d\'erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateConfig(IrrigationConfig config) async {
    try {
      await _db.updateConfig(config);
      await _loadConfigs();
    } catch (e) {
      debugPrint('Error updating config: $e');
      rethrow;
    }
  }

  Future<void> deleteConfig(String configId) async {
    await _db.deleteConfig(configId);
    await _loadConfigs();
  }

  Future<void> saveIrrigationRecord(IrrigationRecord record) async {
    await _db.insertRecord(record);
    await _loadHistory();
  }

  Future<void> updateIrrigationRecord(IrrigationRecord record) async {
    await _db.updateRecord(record);
    await _loadHistory();
  }

  @override
  void dispose() {
    _configCheckTimer?.cancel();
    super.dispose();
  }
}
