import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeatherDetailsDialog extends StatelessWidget {
  final dynamic weatherData; // Peut être WeatherForecast ou WeatherHour
  final bool isHourly;
  final bool isCurrent;

  const WeatherDetailsDialog({
    super.key,
    required this.weatherData,
    this.isHourly = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    String getTitle() {
      if (isCurrent) {
        return 'Maintenant';
      }
      return isHourly 
        ? DateFormat('EEEE d MMMM à HH:mm', 'fr_FR').format(weatherData.time)
        : DateFormat('EEEE d MMMM', 'fr_FR').format(weatherData.date);
    }

    String getTemperature() {
      if (isCurrent || isHourly) {
        return '${weatherData.temp.round()}°C';
      }
      return '${weatherData.tempMax.round()}°C / ${weatherData.tempMin.round()}°C';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(
              children: [
                Image.network(weatherData.iconUrl, width: 50, height: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTitle(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        weatherData.condition,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Détails
            _buildDetailRow(
              context,
              'Température',
              getTemperature(),
              Icons.thermostat,
            ),
            _buildDetailRow(
              context,
              'Humidité',
              '${weatherData.humidity}%',
              Icons.water_drop,
            ),
            _buildDetailRow(
              context,
              'Vent',
              '${weatherData.windSpeed} km/h ${weatherData.windDirection}',
              Icons.air,
            ),
            _buildDetailRow(
              context,
              'Précipitations',
              '${weatherData.precipitation} mm',
              Icons.umbrella,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}