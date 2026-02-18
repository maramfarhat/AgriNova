import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionRequest extends StatelessWidget {
  final VoidCallback onRequestPermission;

  const LocationPermissionRequest({
    super.key,
    required this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              size: 70,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Accès à la localisation requis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Pour obtenir la météo de votre position actuelle, '
              'nous avons besoin d\'accéder à votre localisation.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRequestPermission,
              icon: const Icon(Icons.location_searching),
              label: const Text('Autoriser la localisation'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings();
              },
              child: const Text('Ouvrir les paramètres'),
            ),
          ],
        ),
      ),
    );
  }
} 