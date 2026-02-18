import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:farm/models/weather.dart';
import 'package:farm/models/weather_forecast.dart';
import 'package:farm/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:farm/models/weather_hour.dart';
import 'package:farm/services/database_service.dart';
import 'package:farm/models/weather_record.dart';
import 'package:sqflite/sqflite.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();
  final String _apiKey = 'dba490aede619e8fc690967eae0b7371';
  final String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _hourlyForecast = [];
  List<Map<String, dynamic>> _dailyForecast = [];
  String _currentCity = '';
  bool _isLoading = false;
  String? _error;
  bool _hasLocationPermission = false;
  static const String _lastCityKey = 'last_city';
  static const String _lastLatKey = 'last_lat';
  static const String _lastLonKey = 'last_lon';

  Map<String, dynamic>? get currentWeather => _currentWeather;
  List<Map<String, dynamic>> get hourlyForecast => _hourlyForecast;
  List<Map<String, dynamic>> get dailyForecast => _dailyForecast;
  String get currentCity => _currentCity;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocationPermission => _hasLocationPermission;

  Weather? get weather => _currentWeather != null 
    ? Weather.fromJson(_currentWeather!) 
    : null;
    
  String? get location => _currentCity;
  
  List<WeatherForecast> get forecast => _dailyForecast
    .map((f) => WeatherForecast.fromJson(f))
    .toList();

  List<WeatherForecast> get dailyForecasts => _dailyForecast
    .map((f) => WeatherForecast.fromJson(f))
    .toList();

  List<WeatherHour> get hourlyForecasts => _hourlyForecast
    .map((h) => WeatherHour.fromJson(h))
    .toList();

  String get apiKey => _apiKey;

  WeatherProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      debugPrint('Initializing WeatherProvider...');
      await _initWeatherDatabase();
      
      // Charger la dernière ville consultée
      final prefs = await SharedPreferences.getInstance();
      final lastCity = prefs.getString(_lastCityKey);
      final lastLat = prefs.getDouble(_lastLatKey);
      final lastLon = prefs.getDouble(_lastLonKey);

      if (lastCity != null && lastLat != null && lastLon != null) {
        debugPrint('Loading last known location: $lastCity');
        _currentCity = lastCity;
        await getWeatherData(lastLat, lastLon);
      } else {
        debugPrint('No last known location, getting current location...');
        await getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Error initializing WeatherProvider: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _initWeatherDatabase() async {
    try {
      debugPrint('Initializing weather database...');
      await _databaseService.resetWeatherRecords();
      debugPrint('Weather database initialized');
    } catch (e) {
      debugPrint('Error initializing weather database: $e');
      _error = e.toString();
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permission de localisation refusée';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Les permissions de localisation sont définitivement refusées. Veuillez les activer dans les paramètres.';
      }

      // Obtenir la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('Position obtained: ${position.latitude}, ${position.longitude}');

      // Obtenir le nom de la ville
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _currentCity = place.locality ?? place.subLocality ?? place.name ?? '';
        
        // Sauvegarder la localisation actuelle
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastCityKey, _currentCity);
        await prefs.setDouble(_lastLatKey, position.latitude);
        await prefs.setDouble(_lastLonKey, position.longitude);
        
        debugPrint('Current location saved: $_currentCity');
        await getWeatherData(position.latitude, position.longitude);
      } else {
        throw 'Impossible de déterminer la ville';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error getting location: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchCity(String city) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Searching for location: $city');
      
      final parts = city.split(',').map((e) => e.trim()).toList();
      final cityName = parts[0];
      final state = parts.length > 1 ? parts[1] : '';
      final country = parts.length > 2 ? parts[2] : '';

      final response = await http.get(Uri.parse(
        'http://api.openweathermap.org/geo/1.0/direct'
        '?q=$cityName${state.isNotEmpty ? ",$state" : ""}'
        '${country.isNotEmpty ? ",$country" : ""}'
        '&limit=1&appid=$_apiKey'
      ));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final location = data.first;
          _currentCity = city;
          
          final lat = location['lat'] as double;
          final lon = location['lon'] as double;

          // Sauvegarder la localisation
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_lastCityKey, city);
          await prefs.setDouble(_lastLatKey, lat);
          await prefs.setDouble(_lastLonKey, lon);
          
          debugPrint('Location saved: $_currentCity ($lat, $lon)');
          await getWeatherData(lat, lon);
        } else {
          throw 'Localisation non trouvée';
        }
      } else {
        throw 'Erreur de recherche de localisation: ${response.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error searching location: $_error');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getWeatherData(double lat, double lon) async {
    try {
      debugPrint('Fetching weather data for lat: $lat, lon: $lon');
      
      // Obtenir la météo actuelle
      final currentResponse = await http.get(Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&units=metric&lang=fr&appid=$_apiKey'
      ));

      // Obtenir les prévisions
      final forecastResponse = await http.get(Uri.parse(
        '$_baseUrl/forecast?lat=$lat&lon=$lon&units=metric&lang=fr&appid=$_apiKey'
      ));

      if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        debugPrint('Weather data received successfully');
        _currentWeather = json.decode(currentResponse.body);
        final forecastData = json.decode(forecastResponse.body);
        
        debugPrint('Processing forecast data...');
        final List<dynamic> list = forecastData['list'];
        
        // Prévisions horaires (prochaines 24h)
        _hourlyForecast = list.where((item) {
          final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          return date.difference(DateTime.now()).inHours <= 24;
        }).map((item) {
          return <String, dynamic>{
            'dt': item['dt'],
            'temp': item['main']['temp'],
            'weather': item['weather'],
            'main': item['main'],
          };
        }).toList();

        // Prévisions journalières (prochains 5 jours)
        _dailyForecast = [];
        Map<String, bool> processedDays = {};
        
        for (var item in list) {
          final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dayKey = DateFormat('yyyy-MM-dd').format(date);
          
          // Ne prendre qu'une prévision par jour (celle de midi)
          if (!processedDays.containsKey(dayKey) && date.hour >= 11 && date.hour <= 13) {
            processedDays[dayKey] = true;
            _dailyForecast.add({
              'dt': item['dt'],
              'temp': {
                'day': item['main']['temp'],
              },
              'humidity': item['main']['humidity'],
              'weather': item['weather'],
            });
          }
        }

        debugPrint('Daily forecasts count: ${_dailyForecast.length}');
        debugPrint('Sample daily forecast: ${_dailyForecast.firstOrNull}');

        // Sauvegarder dans l'historique
        if (_currentWeather != null) {
          await saveWeatherRecord(WeatherRecord(
            date: DateTime.now(),
            temperature: (_currentWeather!['main']['temp'] as num).toDouble(),
            humidity: _currentWeather!['main']['humidity'],
            location: _currentCity,
            weatherDescription: _currentWeather!['weather'][0]['description'],
          ));
        }

        debugPrint('Weather data processed. Daily forecasts: ${_dailyForecast.length}, Hourly forecasts: ${_hourlyForecast.length}');
        notifyListeners();
      } else {
        throw 'Erreur de récupération des données météo: ${currentResponse.statusCode}, ${forecastResponse.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error getting weather data: $_error');
      rethrow;
    }
  }

  Future<void> checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      _hasLocationPermission = permission == LocationPermission.always || 
                              permission == LocationPermission.whileInUse;
      notifyListeners();
    } catch (e) {
      print('Erreur vérification permission: $e');
    }
  }

  Future<void> requestLocationPermission() async {
    try {
      await _locationService.requestPermission();
      await checkLocationPermission();
      if (_hasLocationPermission) {
        await getCurrentLocation();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  String _getIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  String _getWindDirection(int degrees) {
    final directions = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    final index = ((degrees + 22.5) % 360) ~/ 45;
    return directions[index];
  }

  Future<void> refreshLocation() async {
    try {
      debugPrint('Rafraîchissement de la localisation...');
      await getCurrentLocation();
    } catch (e) {
      debugPrint('Erreur de rafraîchissement: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> saveWeatherRecord(WeatherRecord record) async {
    try {
      final db = await _databaseService.database;
      
      // Vérifier si la table existe
      final tableExists = await _databaseService.isTableExists('weather_records');
      if (!tableExists) {
        debugPrint('Table weather_records does not exist, creating it...');
        await _databaseService.resetWeatherRecords();
      }
      
      debugPrint('Saving weather record: ${record.toMap()}');
      await db.insert(
        'weather_records',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Weather record saved successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving weather record: $e');
      rethrow;
    }
  }

  Future<List<WeatherRecord>> getWeatherHistory() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'weather_records',
        orderBy: 'date DESC',
        limit: 50,
      );
      
      return maps.map((map) {
        try {
          return WeatherRecord.fromMap(map);
        } catch (e) {
          debugPrint('Erreur lors du parsing d\'un enregistrement: $e');
          rethrow;
        }
      }).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'historique: $e');
      rethrow;
    }
  }

  Future<void> fetchWeatherByLocation() async {
    await getCurrentLocation();
  }

  Future<void> fetchWeatherByCity(String city) async {
    await searchCity(city);
  }
}