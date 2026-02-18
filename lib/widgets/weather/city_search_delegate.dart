import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CitySearchDelegate extends SearchDelegate<String> {
  final String apiKey;

  CitySearchDelegate(this.apiKey);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _searchLocations(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun résultat trouvé'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final location = snapshot.data![index];
            final name = location['name'] as String;
            final state = location['state'] as String?;
            final country = location['country'] as String;
            
            // Construire le nom complet de la localisation
            String displayName = name;
            if (state != null && state.isNotEmpty) {
              displayName += ', $state';
            }
            displayName += ', $country';

            return ListTile(
              title: Text(name),
              subtitle: Text('$state, $country'),
              onTap: () => close(context, displayName),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Text('Entrez au moins 2 caractères pour rechercher'),
      );
    }

    return buildResults(context);
  }

  Future<List<dynamic>> _searchLocations(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(Uri.parse(
        'http://api.openweathermap.org/geo/1.0/direct?q=$query&limit=10&appid=$apiKey'
      ));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Trier les résultats par pertinence
        data.sort((a, b) {
          // Priorité aux correspondances exactes du nom
          final aExactMatch = a['name'].toString().toLowerCase() == query.toLowerCase();
          final bExactMatch = b['name'].toString().toLowerCase() == query.toLowerCase();
          if (aExactMatch != bExactMatch) return aExactMatch ? -1 : 1;

          // Ensuite par population si disponible
          final aPop = a['population'] ?? 0;
          final bPop = b['population'] ?? 0;
          return (bPop as int).compareTo(aPop as int);
        });

        return data;
      } else {
        throw 'Erreur de recherche: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Erreur lors de la recherche: $e');
      rethrow;
    }
  }
}