import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farm/models/weather_forecast.dart';

class DailyForecast extends StatelessWidget {
  final List<WeatherForecast> dailyForecast;

  const DailyForecast({
    Key? key,
    required this.dailyForecast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dailyForecast.isEmpty) {
      return const SizedBox(); // Ne rien afficher si pas de données
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Prévisions sur 5 jours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dailyForecast.length,
            itemBuilder: (context, index) {
              final forecast = dailyForecast[index];
              
              return ListTile(
                leading: Image.network(
                  forecast.iconUrl,
                  width: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error);
                  },
                ),
                title: Text(
                  DateFormat('EEEE', 'fr_FR').format(forecast.date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(forecast.condition),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${forecast.temperature.round()}°C',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${forecast.humidity}%',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 