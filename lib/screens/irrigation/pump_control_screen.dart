import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/iot_provider.dart';
import 'package:farm/theme/app_theme.dart';

class PumpControlScreen extends StatelessWidget {
  const PumpControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrôle de l\'irrigation'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<IoTProvider>(
        builder: (context, provider, child) {
          final isManualMode = provider.isManualMode;
          final isPumpActive = provider.isPumpActive;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode de contrôle
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mode de contrôle',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Mode manuel'),
                          subtitle: Text(
                            isManualMode
                                ? 'Contrôle manuel de l\'irrigation'
                                : 'Contrôle automatique basé sur les capteurs',
                          ),
                          value: isManualMode,
                          onChanged: (value) => provider.setManualMode(value),
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // État actuel
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'État actuel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: isPumpActive ? Colors.blue : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isPumpActive
                                  ? 'Irrigation active'
                                  : 'Irrigation inactive',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contrôles manuels
                if (isManualMode)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contrôle manuel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final success =
                                      await provider.togglePump(!isPumpActive);
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isPumpActive
                                              ? 'Irrigation arrêtée'
                                              : 'Irrigation activée',
                                        ),
                                        backgroundColor: isPumpActive
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Erreur lors du contrôle de l\'irrigation',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                isPumpActive ? Icons.stop : Icons.play_arrow,
                                size: 28,
                              ),
                              label: Text(
                                isPumpActive
                                    ? 'Arrêter l\'irrigation'
                                    : 'Activer l\'irrigation',
                                style: const TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPumpActive
                                    ? Colors.red
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Informations sur le mode automatique
                if (!isManualMode)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mode automatique',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'L\'irrigation est contrôlée automatiquement en fonction des données des capteurs et des prévisions météo :',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          _buildSensorInfo(
                            'Humidité du sol',
                            provider.currentData?.soilMoisture?.toString() ??
                                'N/A',
                            '%',
                          ),
                          _buildSensorInfo(
                            'Température',
                            provider.currentData?.airTemperature.toString() ??
                                'N/A',
                            '°C',
                          ),
                          _buildSensorInfo(
                            'Humidité de l\'air',
                            provider.currentData?.airHumidity.toString() ??
                                'N/A',
                            '%',
                          ),
                          _buildSensorInfo(
                            'pH',
                            provider.currentData?.phValue?.toString() ?? 'N/A',
                            '',
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSensorInfo(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('$value $unit'),
        ],
      ),
    );
  }
}
