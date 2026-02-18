import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationSelector extends StatefulWidget {
  final Function(Position) onLocationSelected;

  const LocationSelector({Key? key, required this.onLocationSelected}) : super(key: key);

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<Location> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final locations = await locationFromAddress(query);
      setState(() {
        _searchResults = locations;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur de recherche: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Rechercher une ville',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _searchLocation(_searchController.text),
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: _searchLocation,
          ),
        ),
        if (_isLoading)
          const CircularProgressIndicator()
        else
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final location = _searchResults[index];
                return ListTile(
                  title: Text('${location.latitude}, ${location.longitude}'),
                  subtitle: Text(_searchController.text),
                  onTap: () {
                    widget.onLocationSelected(
                      Position(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        timestamp: DateTime.now(),
                        accuracy: 0,
                        altitudeAccuracy: 0,
                        headingAccuracy: 0,
                        altitude: 0,
                        heading: 0,
                        speed: 0,
                        speedAccuracy: 0,
                      ),
                    );
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}