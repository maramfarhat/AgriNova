import 'package:flutter/material.dart';
import 'package:farm/models/weather_data.dart';
import 'package:intl/intl.dart';

class WeatherForecastList extends StatelessWidget {
  final List<WeatherData> forecast;

  const WeatherForecastList({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    // Grouper les prévisions par jour
    final groupedForecast = _groupForecastByDay();

    return Column(
      children: groupedForecast.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatDate(entry.key),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: entry.value.length,
                itemBuilder: (context, index) {
                  final weather = entry.value[index];
                  return _HourlyForecastCard(weather: weather);
                },
              ),
            ),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }

  Map<DateTime, List<WeatherData>> _groupForecastByDay() {
    final grouped = <DateTime, List<WeatherData>>{};
    
    for (var weather in forecast) {
      final date = DateTime(
        weather.date.year,
        weather.date.month,
        weather.date.day,
      );
      
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(weather);
    }
    
    return grouped;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (date == today) {
      return "Aujourd'hui";
    } else if (date == tomorrow) {
      return "Demain";
    } else {
      return DateFormat('EEEE dd MMMM', 'fr_FR').format(date);
    }
  }
}

class _HourlyForecastCard extends StatelessWidget {
  final WeatherData weather;

  const _HourlyForecastCard({
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              DateFormat('HH:mm').format(weather.date),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            _getWeatherIcon(),
            Text(
              '${weather.temperature.toStringAsFixed(1)}°C',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (weather.rainProbability > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water_drop, size: 14),
                  Text('${weather.rainProbability.toStringAsFixed(0)}%'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _getWeatherIcon() {
    IconData icon;
    Color color;
    
    switch (weather.condition.toLowerCase()) {
      case 'glacial':
        icon = Icons.ac_unit;
        color = Colors.blue;
        break;
      case 'froid':
        icon = Icons.thermostat;
        color = Colors.lightBlue;
        break;
      case 'frais':
        icon = Icons.cloud;
        color = Colors.grey;
        break;
      case 'agréable':
        icon = Icons.wb_sunny_outlined;
        color = Colors.orange;
        break;
      case 'chaud':
        icon = Icons.wb_sunny;
        color = Colors.orange;
        break;
      case 'très chaud':
        icon = Icons.whatshot;
        color = Colors.red;
        break;
      default:
        icon = Icons.question_mark;
        color = Colors.grey;
    }

    return Icon(
      icon,
      size: 32,
      color: color,
    );
  }
} 