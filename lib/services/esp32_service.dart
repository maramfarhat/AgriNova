import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/iot_data.dart';
import 'package:flutter/foundation.dart';

class ESP32Service {
  // Adresse IP de l'ESP32 - à ajuster selon votre configuration
  static const String baseUrl = 'http://192.168.246.112';
  static const Duration timeout = Duration(seconds: 5);
  int _retryCount = 0;
  static const int maxRetries = 3;

  Future<IoTData> getSensorData() async {
    _retryCount = 0;
    while (_retryCount < maxRetries) {
      try {
        debugPrint(
            '🌐 Tentative de connexion à $baseUrl/data (essai ${_retryCount + 1})');
        final response =
            await http.get(Uri.parse('$baseUrl/data')).timeout(timeout);

        if (response.statusCode == 200) {
          debugPrint('✅ Données reçues: ${response.body}');
          final jsonData = json.decode(response.body);

          // Traiter la valeur du pH
          var phValue = jsonData['ph_value'];
          double? parsedPhValue;
          if (phValue != null && phValue != "N/A") {
            if (phValue is String) {
              parsedPhValue = double.tryParse(phValue);
            } else if (phValue is num) {
              parsedPhValue = phValue.toDouble();
            }
          }
          debugPrint('📊 Valeur pH reçue: $phValue, parsée: $parsedPhValue');

          // Créer un objet IoTData avec toutes les données des capteurs
          final data = IoTData(
            airTemperature: jsonData['temperature']?.toDouble() ?? 0.0,
            airHumidity: jsonData['humidity']?.toDouble() ?? 0.0,
            soilMoisture: jsonData['soil_moisture_percent']?.toDouble() ?? 0.0,
            waterLevel: jsonData['water_level_percent']?.toDouble() ?? 0.0,
            lightLevel: 0.0, // Pas de capteur de lumière pour le moment
            flameDetected: jsonData['flame_detected'] ?? false,
            phValue: parsedPhValue,
            phImmersed: true, // On considère toujours la sonde comme immergée
            timestamp: DateTime.now(),
          );

          debugPrint(
              '📊 Données traitées: Température=${data.airTemperature}°C, Humidité=${data.airHumidity}%, Humidité sol=${data.soilMoisture}%, pH=${data.phValue}');
          return data;
        } else {
          throw Exception('Erreur HTTP: ${response.statusCode}');
        }
      } on TimeoutException {
        debugPrint('⚠️ Timeout de la requête (essai ${_retryCount + 1})');
        _retryCount++;
        if (_retryCount >= maxRetries) {
          throw Exception('Timeout après $maxRetries tentatives');
        }
        await Future.delayed(
            Duration(seconds: 1)); // Attendre avant de réessayer
        continue;
      } catch (e) {
        debugPrint('❌ Erreur de connexion à l\'ESP32: $e');
        _retryCount++;
        if (_retryCount >= maxRetries) {
          throw Exception('Erreur après $maxRetries tentatives: $e');
        }
        await Future.delayed(Duration(seconds: 1));
        continue;
      }
    }
    throw Exception('Erreur inattendue après $maxRetries tentatives');
  }

  Future<bool> controlPump({required bool activate}) async {
    _retryCount = 0;
    while (_retryCount < maxRetries) {
      try {
        debugPrint(
            '🚿 Envoi de la commande de pompe (${activate ? "ON" : "OFF"}) - essai ${_retryCount + 1}');
        final response = await http
            .post(
              Uri.parse('$baseUrl/control'),
              body: jsonEncode({'activate': activate}),
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          debugPrint('✅ Commande de pompe envoyée avec succès');
          return true;
        } else {
          throw Exception('Erreur HTTP: ${response.statusCode}');
        }
      } on TimeoutException {
        debugPrint(
            '⚠️ Timeout de la commande pompe (essai ${_retryCount + 1})');
        _retryCount++;
        if (_retryCount >= maxRetries) {
          throw Exception('Timeout après $maxRetries tentatives');
        }
        await Future.delayed(Duration(seconds: 1));
        continue;
      } catch (e) {
        debugPrint('❌ Erreur lors du contrôle de la pompe: $e');
        _retryCount++;
        if (_retryCount >= maxRetries) {
          throw Exception('Erreur après $maxRetries tentatives: $e');
        }
        await Future.delayed(Duration(seconds: 1));
        continue;
      }
    }
    return false;
  }

  Future<bool> sendWeatherForecast(bool willRain) async {
    _retryCount = 0;
    while (_retryCount < maxRetries) {
      try {
        debugPrint(
            '🌧️ Envoi des prévisions météo (Pluie: ${willRain ? "OUI" : "NON"}) - essai ${_retryCount + 1}');
        final response = await http
            .post(
              Uri.parse('$baseUrl/weather'),
              body: jsonEncode({'will_rain': willRain}),
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          debugPrint('✅ Prévisions météo envoyées avec succès');
          return true;
        } else {
          throw Exception('Erreur HTTP: ${response.statusCode}');
        }
      } on TimeoutException {
        debugPrint(
            '⚠️ Timeout de l\'envoi des prévisions (essai ${_retryCount + 1})');
        _retryCount++;
        if (_retryCount >= maxRetries) {
          throw Exception('Timeout après $maxRetries tentatives');
        }
        await Future.delayed(Duration(seconds: 1));
        continue;
      } catch (e) {
        debugPrint('❌ Erreur lors de l\'envoi des prévisions météo: $e');
        _retryCount++;
        if (_retryCount >= maxRetries) {
          throw Exception('Erreur après $maxRetries tentatives: $e');
        }
        await Future.delayed(Duration(seconds: 1));
        continue;
      }
    }
    return false;
  }
}
