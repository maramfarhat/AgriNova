import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farm/models/irrigation_alert.dart';
import 'package:farm/theme/app_theme.dart';

class IrrigationAlertWidget extends StatelessWidget {
  final IrrigationAlert alert;
  final bool isExpanded;
  final VoidCallback? onTap;

  const IrrigationAlertWidget({
    super.key,
    required this.alert,
    this.isExpanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '🔄 Construction du widget d\'alerte: ${alert.messages.join(", ")}');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: alert.isPumpActive ? AppTheme.cardColor : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: alert.isPumpActive ? Colors.orange : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(alert.timestamp),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (alert.isPumpActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.water_drop,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Pompe active',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                ...alert.messages.map((message) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(message),
                    )),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Données des capteurs:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _buildSensorData('Température',
                    '${alert.sensorData['temperature'].toStringAsFixed(1)}°C'),
                _buildSensorData('Humidité air',
                    '${alert.sensorData['humidity'].toStringAsFixed(1)}%'),
                if (alert.sensorData['soilMoisture'] != null)
                  _buildSensorData('Humidité sol',
                      '${alert.sensorData['soilMoisture'].toStringAsFixed(1)}%'),
                if (alert.sensorData['phValue'] != null)
                  _buildSensorData(
                      'pH', alert.sensorData['phValue'].toStringAsFixed(2)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorData(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }
}
