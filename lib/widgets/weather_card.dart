import 'package:flutter/material.dart';
import 'package:farm/models/weather_data.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData weather;

  const WeatherCard({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getBackgroundColor().withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maintenant',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        weather.condition,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  _getWeatherIcon(),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoColumn(
                    context,
                    '${weather.temperature.toStringAsFixed(1)}°C',
                    'Température',
                    Icons.thermostat,
                  ),
                  _buildInfoColumn(
                    context,
                    '${weather.humidity.toStringAsFixed(0)}%',
                    'Humidité',
                    Icons.water_drop,
                  ),
                  _buildInfoColumn(
                    context,
                    '${weather.windSpeed.toStringAsFixed(1)} km/h',
                    'Vent',
                    Icons.air,
                  ),
                ],
              ),
              if (weather.rainProbability > 0) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.umbrella, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Probabilité de pluie: ${weather.rainProbability.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (weather.rainAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(
                      'Quantité: ${weather.rainAmount.toStringAsFixed(1)} mm',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    final condition = weather.condition.toLowerCase();
    
    if (condition.contains('soleil') || condition.contains('clair') || condition.contains('dégagé')) {
      return Colors.yellow;
    } else if (condition.contains('nuag')) {
      if (condition.contains('peu') || condition.contains('partiellement')) {
        return Colors.orange.shade300;
      } else {
        return Colors.grey;
      }
    } else if (condition.contains('pluie') || condition.contains('averse') || condition.contains('bruine')) {
      return Colors.blue;
    } else if (condition.contains('orage')) {
      return Colors.deepPurple;
    } else if (condition.contains('neige')) {
      return Colors.lightBlue;
    } else if (condition.contains('brume') || condition.contains('brouillard')) {
      return Colors.blueGrey;
    } else if (condition.contains('grêle') || condition.contains('grele')) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  Widget _buildInfoColumn(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    Color iconColor;
    switch (icon) {
      case Icons.thermostat:
        iconColor = Colors.red;
        break;
      case Icons.water_drop:
        iconColor = Colors.blue;
        break;
      case Icons.air:
        iconColor = Colors.blueGrey;
        break;
      default:
        iconColor = Theme.of(context).iconTheme.color ?? Colors.black;
    }

    return Column(
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _getWeatherIcon() {
    IconData icon;
    Color color;
    Color backgroundColor;
    
    final condition = weather.condition.toLowerCase();
    
    if (condition.contains('soleil') || condition.contains('clair') || condition.contains('dégagé')) {
      icon = Icons.wb_sunny;
      color = Colors.orange;
      backgroundColor = Colors.yellow.withOpacity(0.1);
    } else if (condition.contains('nuag')) {
      if (condition.contains('peu') || condition.contains('partiellement')) {
        icon = Icons.wb_cloudy;
        color = Colors.orange.shade300;
        backgroundColor = Colors.orange.withOpacity(0.1);
      } else {
        icon = Icons.cloud;
        color = Colors.grey;
        backgroundColor = Colors.grey.withOpacity(0.1);
      }
    } else if (condition.contains('pluie') || condition.contains('averse') || condition.contains('bruine')) {
      icon = Icons.water_drop;
      color = Colors.blue;
      backgroundColor = Colors.blue.withOpacity(0.1);
    } else if (condition.contains('orage')) {
      icon = Icons.thunderstorm;
      color = Colors.deepPurple;
      backgroundColor = Colors.deepPurple.withOpacity(0.1);
    } else if (condition.contains('neige')) {
      icon = Icons.ac_unit;
      color = Colors.lightBlue;
      backgroundColor = Colors.lightBlue.withOpacity(0.1);
    } else if (condition.contains('brume') || condition.contains('brouillard')) {
      icon = Icons.cloud_queue;
      color = Colors.blueGrey;
      backgroundColor = Colors.blueGrey.withOpacity(0.1);
    } else if (condition.contains('grêle') || condition.contains('grele')) {
      icon = Icons.ac_unit;
      color = Colors.blue;
      backgroundColor = Colors.blue.withOpacity(0.1);
    } else {
      icon = Icons.wb_sunny;
      color = Colors.grey;
      backgroundColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 48,
        color: color,
      ),
    );
  }
} 