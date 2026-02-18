import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:farm/models/weather_data.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1';

  Future<Position> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Les services de localisation sont désactivés.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Les permissions de localisation sont refusées.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Les permissions de localisation sont définitivement refusées.');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Erreur de localisation: $e');
      rethrow;
    }
  }

  Future<WeatherData> getCurrentWeather() async {
    try {
      final position = await _getCurrentLocation();

      final url = Uri.parse(
        '$_baseUrl/forecast?'
        'latitude=${position.latitude}&'
        'longitude=${position.longitude}&'
        'temperature_unit=celsius&'
        'windspeed_unit=kmh&'
        'current=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation,weather_code&'
        'timezone=auto'
      );

      print('URL requête: $url');
      final response = await http.get(url);
      print('Réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['current'] == null) {
          throw Exception('Données météo non disponibles');
        }
        return _parseCurrentWeather(data);
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getCurrentWeather: $e');
      rethrow;
    }
  }

  Future<List<WeatherData>> getForecast() async {
    try {
      final position = await _getCurrentLocation();

      final url = Uri.parse(
        '$_baseUrl/forecast?'
        'latitude=${position.latitude}&'
        'longitude=${position.longitude}&'
        'temperature_unit=celsius&'
        'windspeed_unit=kmh&'
        'hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation_probability,precipitation,weather_code&'
        'forecast_days=5&'
        'timezone=auto'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['hourly'] == null) {
          throw Exception('Données de prévision non disponibles');
        }
        return _parseForecastData(data);
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getForecast: $e');
      rethrow;
    }
  }

  WeatherData _parseCurrentWeather(Map<String, dynamic> data) {
    final current = data['current'];
    return WeatherData(
      date: DateTime.now(),
      temperature: current['temperature_2m']?.toDouble() ?? 0.0,
      humidity: current['relative_humidity_2m']?.toDouble() ?? 0.0,
      windSpeed: current['wind_speed_10m']?.toDouble() ?? 0.0,
      condition: _getConditionFromCode(current['weather_code'] ?? 0),
      rainProbability: 0.0,
      rainAmount: current['precipitation']?.toDouble() ?? 0.0,
    );
  }

  List<WeatherData> _parseForecastData(Map<String, dynamic> data) {
    final hourly = data['hourly'];
    final times = hourly['time'] as List;
    final temperatures = hourly['temperature_2m'] as List;
    final humidities = hourly['relative_humidity_2m'] as List;
    final windSpeeds = hourly['wind_speed_10m'] as List;
    final precipProbs = hourly['precipitation_probability'] as List? ?? List.filled(times.length, 0.0);
    final precips = hourly['precipitation'] as List;
    final weatherCodes = hourly['weather_code'] as List;

    List<WeatherData> forecast = [];
    for (int i = 0; i < times.length; i++) {
      forecast.add(WeatherData(
        date: DateTime.parse(times[i]),
        temperature: temperatures[i]?.toDouble() ?? 0.0,
        humidity: humidities[i]?.toDouble() ?? 0.0,
        windSpeed: windSpeeds[i]?.toDouble() ?? 0.0,
        condition: _getConditionFromCode(weatherCodes[i] ?? 0),
        rainProbability: precipProbs[i]?.toDouble() ?? 0.0,
        rainAmount: precips[i]?.toDouble() ?? 0.0,
      ));
    }
    return forecast;
  }

  String _getConditionFromCode(int code) {
    switch (code) {
      case 0:
        return 'Dégagé';
      case 1:
        return 'Peu nuageux';
      case 2:
        return 'Partiellement nuageux';
      case 3:
        return 'Nuageux';
      case 45:
      case 48:
        return 'Brumeux';
      case 51:
      case 53:
      case 55:
        return 'Bruine';
      case 61:
      case 63:
      case 65:
        return 'Pluie';
      case 71:
      case 73:
      case 75:
        return 'Neige';
      case 77:
        return 'Grêle';
      case 80:
      case 81:
      case 82:
        return 'Averses';
      case 85:
      case 86:
        return 'Neige forte';
      case 95:
        return 'Orage';
      case 96:
      case 99:
        return 'Orage avec grêle';
      default:
        return 'Inconnu';
    }
  }
}