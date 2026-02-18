import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/weather_provider.dart';
import 'package:farm/models/weather_record.dart';
import 'package:intl/intl.dart';

class WeatherHistoryScreen extends StatelessWidget {
  const WeatherHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique météo'),
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, provider, child) {
          return FutureBuilder<List<WeatherRecord>>(
            future: provider.getWeatherHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }

              final records = snapshot.data!;
              if (records.isEmpty) {
                return const Center(child: Text('Aucun historique disponible'));
              }

              return ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(record.date),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${record.temperature.round()}°C'),
                          Text(record.weatherDescription),
                          Text('Humidité: ${record.humidity}%'),
                          Text(record.location),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 