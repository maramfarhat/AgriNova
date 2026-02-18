import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/iot_data.dart';
import '../services/esp32_service.dart';
import '../models/irrigation_alert.dart';
import '../providers/weather_provider.dart';
import 'package:intl/intl.dart';

class IoTProvider with ChangeNotifier {
  final ESP32Service _esp32Service = ESP32Service();
  final WeatherProvider _weatherProvider;
  IoTData? _currentData;
  List<IoTData> _dataHistory = [];
  List<IrrigationAlert> _alerts = [];
  Timer? _updateTimer;
  bool _isPumpCurrentlyActive = false;
  bool _isManualMode = false;

  IoTProvider(this._weatherProvider) {
    debugPrint('🔄 IoTProvider initialisé');
    _loadInitialState();
  }

  IoTData? get currentData => _currentData;
  List<IoTData> get dataHistory => _dataHistory;
  List<IrrigationAlert> get alerts => _alerts;
  IrrigationAlert? get latestAlert => _alerts.isNotEmpty ? _alerts.first : null;

  ESP32Service get esp32Service => _esp32Service;

  List<Map<String, dynamic>> get dataHistoryAsSensorData {
    debugPrint(
        '📊 Préparation des données pour le graphique. Nombre de points: ${_dataHistory.length}');
    final data = _dataHistory.map((data) {
      final map = {
        'timestamp': data.timestamp,
        'airTemperature': data.airTemperature,
        'airHumidity': data.airHumidity,
        'soilMoisture': data.soilMoisture ?? 0.0,
        'waterLevel': data.waterLevel ?? 0.0,
        'phValue': data.phValue ?? 0.0,
      };
      debugPrint('📊 Point de données: ${map.toString()}');
      return map;
    }).toList();

    // Trier les données par timestamp
    data.sort((a, b) =>
        (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
    return data;
  }

  void startUpdates() {
    debugPrint('🔄 Démarrage des mises à jour périodiques');
    // Mettre à jour les données toutes les 5 secondes
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchData();
    });
  }

  Future<bool> _checkForUpcomingRain() async {
    try {
      final hourlyForecasts = _weatherProvider.hourlyForecasts;
      // Vérifier les prochaines 6 heures
      final nextSixHours = hourlyForecasts.take(6);

      for (var forecast in nextSixHours) {
        if (forecast.condition.toLowerCase().contains('pluie') ||
            forecast.condition.toLowerCase().contains('averse')) {
          final formattedTime = DateFormat('HH:mm').format(forecast.date);
          final formattedDate = DateFormat('dd/MM').format(forecast.date);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint(
          '❌ Erreur lors de la vérification des prévisions de pluie: $e');
      return false;
    }
  }

  Future<String?> _getNextRainTime() async {
    try {
      final hourlyForecasts = _weatherProvider.hourlyForecasts;
      // Vérifier les prochaines 24 heures
      for (var forecast in hourlyForecasts) {
        if (forecast.condition.toLowerCase().contains('pluie') ||
            forecast.condition.toLowerCase().contains('averse')) {
          final formattedTime = DateFormat('HH:mm').format(forecast.date);
          final formattedDate = DateFormat('dd/MM').format(forecast.date);
          return 'le $formattedDate à $formattedTime';
        }
      }
      return null;
    } catch (e) {
      debugPrint(
          '❌ Erreur lors de la récupération de l\'heure de la prochaine pluie: $e');
      return null;
    }
  }

  Future<void> _loadInitialState() async {
    try {
      await fetchData();
      startUpdates();
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement initial: $e');
    }
  }

  void setManualMode(bool value) {
    _isManualMode = value;
    if (!value && _isPumpCurrentlyActive) {
      // Si on passe en mode automatique et que la pompe est active,
      // on la désactive pour laisser le contrôle automatique prendre le relais
      togglePump(false);
    }
    debugPrint('🔄 Mode manuel ${value ? "activé" : "désactivé"}');
    notifyListeners();
  }

  Future<bool> togglePump(bool activate) async {
    try {
      debugPrint(
          '🚰 Tentative de ${activate ? "démarrage" : "arrêt"} de la pompe');
      final success = await _esp32Service.controlPump(activate: activate);

      if (success) {
        _isPumpCurrentlyActive = activate;
        if (_isManualMode) {
          _alerts = [
            IrrigationAlert(
              timestamp: DateTime.now(),
              messages: [
                activate
                    ? 'Pompe activée manuellement'
                    : 'Pompe désactivée manuellement'
              ],
              isPumpActive: activate,
              sensorData: {
                'temperature': _currentData?.airTemperature,
                'humidity': _currentData?.airHumidity,
                'soilMoisture': _currentData?.soilMoisture,
                'phValue': _currentData?.phValue,
              },
            )
          ];
        }
        notifyListeners();
        debugPrint(
            '✅ Pompe ${activate ? "activée" : "désactivée"} avec succès');
      } else {
        debugPrint('❌ Échec du contrôle de la pompe');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Erreur lors du contrôle de la pompe: $e');
      return false;
    }
  }

  Future<void> fetchData() async {
    try {
      debugPrint('🔄 Récupération des données des capteurs...');
      final newData = await _esp32Service.getSensorData();
      _currentData = newData;
      _dataHistory.add(newData);
      debugPrint('✅ Données des capteurs mises à jour');

      // Vérifier les prévisions météo et les envoyer à l'ESP32
      final willRain = await _checkForUpcomingRain();
      await _esp32Service.sendWeatherForecast(willRain);

      // Ne pas vérifier les conditions si en mode manuel
      if (!_isManualMode) {
        List<String> alertMessages = [];
        bool shouldActivatePump = false;

        // Vérifier l'humidité du sol
        if (newData.soilMoisture != null && newData.soilMoisture! < 50) {
          alertMessages.add(
              '💧 Humidité du sol faible (${newData.soilMoisture!.toStringAsFixed(1)}%)');
          shouldActivatePump = true;
        }

        // Vérifier la température
        if (newData.airTemperature < 10 || newData.airTemperature > 30) {
          alertMessages.add(
              '🌡️ Température hors limites (${newData.airTemperature.toStringAsFixed(1)}°C)');
          shouldActivatePump = true;
        }

        // Vérifier l'humidité de l'air
        if (newData.airHumidity < 40 || newData.airHumidity > 80) {
          alertMessages.add(
              '💦 Humidité de l\'air hors limites (${newData.airHumidity.toStringAsFixed(1)}%)');
          shouldActivatePump = true;
        }

        // Vérifier le pH
        if (newData.phValue != null &&
            (newData.phValue! < 5.5 || newData.phValue! > 7.0)) {
          alertMessages.add(
              '🧪 pH hors limites (${newData.phValue!.toStringAsFixed(2)})');
          shouldActivatePump = true;
        }

        // Si on doit activer la pompe, vérifier d'abord les prévisions météo
        if (shouldActivatePump && !_isPumpCurrentlyActive) {
          final rainTime = await _getNextRainTime();

          if (rainTime != null) {
            // Pluie prévue, ne pas activer la pompe
            _alerts = [
              IrrigationAlert(
                timestamp: DateTime.now(),
                messages: [
                  '☔ Irrigation non nécessaire - Pluie prévue $rainTime',
                  ...alertMessages.map((msg) => '📊 $msg'),
                ],
                isPumpActive: false,
                sensorData: {
                  'temperature': newData.airTemperature,
                  'humidity': newData.airHumidity,
                  'soilMoisture': newData.soilMoisture,
                  'phValue': newData.phValue,
                },
              )
            ];
            shouldActivatePump = false;
          } else {
            // Pas de pluie prévue, activer la pompe
            alertMessages
                .add('☀️ Aucune pluie prévue dans les prochaines 24 heures');
          }
        }

        // Mettre à jour l'état de la pompe si nécessaire
        if (shouldActivatePump != _isPumpCurrentlyActive) {
          debugPrint(
              '🚰 Changement d\'état de la pompe: ${shouldActivatePump ? "activée" : "désactivée"}');

          final success = await togglePump(shouldActivatePump);
          if (success) {
            _alerts = [
              IrrigationAlert(
                timestamp: DateTime.now(),
                messages: shouldActivatePump
                    ? alertMessages
                    : ['✅ Irrigation terminée - Conditions normales'],
                isPumpActive: shouldActivatePump,
                sensorData: {
                  'temperature': newData.airTemperature,
                  'humidity': newData.airHumidity,
                  'soilMoisture': newData.soilMoisture,
                  'phValue': newData.phValue,
                },
              )
            ];
          }
        }
      }

      // Garder seulement les 24 dernières heures de données
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      _dataHistory.removeWhere((data) => data.timestamp.isBefore(cutoffTime));

      notifyListeners();
    } catch (e) {
      debugPrint(
          '❌ Erreur lors de la récupération des données des capteurs: $e');
    }
  }

  // Méthode pour forcer une mise à jour des données
  Future<void> refreshData() async {
    debugPrint('🔄 Rafraîchissement forcé des données');
    await fetchData();
  }

  @override
  void dispose() {
    debugPrint('🛑 Arrêt des mises à jour périodiques');
    _updateTimer?.cancel();
    super.dispose();
  }

  // Méthodes de simulation
  void simulateIrrigation() {
    if (_currentData != null) {
      _currentData = IoTData(
        timestamp: DateTime.now(),
        airTemperature: _currentData!.airTemperature,
        airHumidity: _currentData!.airHumidity,
        soilMoisture: (_currentData!.soilMoisture ?? 0) + 15,
        waterLevel: (_currentData!.waterLevel ?? 0) - 10,
        flameDetected: _currentData!.flameDetected,
        phValue: _currentData!.phValue,
        phImmersed: _currentData!.phImmersed,
      );
      notifyListeners();
    }
  }

  void simulateHotDay() {
    if (_currentData != null) {
      _currentData = IoTData(
        timestamp: DateTime.now(),
        airTemperature: _currentData!.airTemperature + 5,
        airHumidity: _currentData!.airHumidity - 10,
        soilMoisture: (_currentData!.soilMoisture ?? 0) - 8,
        flameDetected: _currentData!.flameDetected,
        phValue: _currentData!.phValue,
        phImmersed: _currentData!.phImmersed,
      );
      notifyListeners();
    }
  }

  void simulateRainyDay() {
    if (_currentData != null) {
      _currentData = IoTData(
        timestamp: DateTime.now(),
        airTemperature: _currentData!.airTemperature - 3,
        airHumidity: _currentData!.airHumidity + 20,
        soilMoisture: (_currentData!.soilMoisture ?? 0) + 20,
        waterLevel: (_currentData!.waterLevel ?? 0) + 15,
        flameDetected: _currentData!.flameDetected,
        phValue: _currentData!.phValue,
        phImmersed: _currentData!.phImmersed,
      );
      notifyListeners();
    }
  }

  bool get isPumpActive => _isPumpCurrentlyActive;
  bool get isManualMode => _isManualMode;
}
