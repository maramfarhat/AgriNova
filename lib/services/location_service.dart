import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class LocationService {
  Future<Map<String, dynamic>> getLocationInfo() async {
    try {
      final position = await _determinePosition();
      
      try {
        final response = await http.get(
          Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather'
            '?lat=${position.latitude}'
            '&lon=${position.longitude}'
            '&appid=eff949be0efadb5f0f4eec129bc46d8a'
            '&units=metric'
            '&lang=fr'
          ),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return {
            'lat': position.latitude,
            'lon': position.longitude,
            'city': data['name'] ?? 'Inconnu',
          };
        }
      } catch (e) {
        debugPrint('Erreur API météo: $e');
      }

      // Fallback à geocoding local
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          return {
            'lat': position.latitude,
            'lon': position.longitude,
            'city': placemarks.first.locality ?? 'Inconnu',
          };
        }
      } catch (e) {
        debugPrint('Erreur geocoding local: $e');
      }

      // Si tout échoue, retourner au moins les coordonnées
      return {
        'lat': position.latitude,
        'lon': position.longitude,
        'city': 'Inconnu',
      };
    } catch (e) {
      debugPrint('Erreur location: $e');
      rethrow;
    }
  }

  Future<Position> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Les services de localisation sont désactivés.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Les permissions de localisation ont été refusées');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Les permissions de localisation sont définitivement refusées.'
        );
      }

      // Ajouter un timeout de 5 secondes
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Erreur position: $e');
      rethrow;
    }
  }

  Future<void> requestPermission() async {
    try {
      await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('Erreur permission: $e');
      rethrow;
    }
  }
}