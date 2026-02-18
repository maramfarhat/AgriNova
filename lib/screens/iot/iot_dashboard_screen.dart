import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/iot_provider.dart';
import 'package:farm/widgets/sensor_card.dart';
import 'package:farm/widgets/sensor_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:farm/models/iot_data.dart';

class IoTDashboardScreen extends StatefulWidget {
  const IoTDashboardScreen({super.key});

  @override
  State<IoTDashboardScreen> createState() => _IoTDashboardScreenState();
}

class _IoTDashboardScreenState extends State<IoTDashboardScreen> {
  bool _alertShown = false;
  String _selectedParameter = 'airTemperature';
  String _selectedParameterTitle = 'Température';
  Color _selectedColor = Colors.orange;

  final Map<String, Map<String, dynamic>> _parameters = {
    'airTemperature': {
      'title': 'Température',
      'color': Colors.orange,
      'unit': '°C'
    },
    'airHumidity': {'title': 'Humidité air', 'color': Colors.blue, 'unit': '%'},
    'soilMoisture': {
      'title': 'Humidité sol',
      'color': Colors.green,
      'unit': '%'
    },
    'waterLevel': {'title': 'Niveau eau', 'color': Colors.purple, 'unit': '%'},
    'phValue': {'title': 'pH de l\'eau', 'color': Colors.red, 'unit': ''},
  };

  Future<void> _makePhoneCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '198');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de lancer l\'appel')),
        );
      }
    }
  }

  void _selectParameter(String parameter) {
    setState(() {
      _selectedParameter = parameter;
      _selectedParameterTitle = _parameters[parameter]!['title'] as String;
      _selectedColor = _parameters[parameter]!['color'] as Color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveillance IoT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/iot/history');
            },
          ),
        ],
      ),
      body: Consumer<IoTProvider>(
        builder: (context, iotProvider, child) {
          final currentData = iotProvider.currentData;

          if (currentData == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (currentData.flameDetected && !_alertShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _alertShown = true;
              });

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5DC),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.block_rounded,
                                color: Colors.red,
                                size: 80,
                              ),
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.red.withOpacity(0.7),
                                size: 40,
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'Alerte Incendie',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'Une flamme a été détectée ! Veuillez vérifier immédiatement.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _makePhoneCall,
                            icon: const Icon(Icons.phone, color: Colors.white),
                            label: const Text(
                              'Appeler le 198',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black54,
                                ),
                                child: const Text(
                                  'Annuler',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'OK',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            });
          } else if (!currentData.flameDetected) {
            _alertShown = false;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentData.flameDetected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      border:
                          Border.all(color: const Color(0xFF2E7D32), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: const Color(0xFF2E7D32), size: 30),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'ALERTE : Flamme détectée !',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  'Données en temps réel',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectParameter('airTemperature'),
                            child: SensorCard(
                              title: _parameters['airTemperature']!['title']
                                  as String,
                              value:
                                  '${_formatValue(currentData, 'airTemperature')}${_parameters['airTemperature']!['unit']}',
                              icon: _getIconForParameter('airTemperature'),
                              color: _parameters['airTemperature']!['color']
                                  as Color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectParameter('airHumidity'),
                            child: SensorCard(
                              title: _parameters['airHumidity']!['title']
                                  as String,
                              value:
                                  '${_formatValue(currentData, 'airHumidity')}${_parameters['airHumidity']!['unit']}',
                              icon: _getIconForParameter('airHumidity'),
                              color:
                                  _parameters['airHumidity']!['color'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectParameter('soilMoisture'),
                            child: SensorCard(
                              title: _parameters['soilMoisture']!['title']
                                  as String,
                              value:
                                  '${_formatValue(currentData, 'soilMoisture')}${_parameters['soilMoisture']!['unit']}',
                              icon: _getIconForParameter('soilMoisture'),
                              color: _parameters['soilMoisture']!['color']
                                  as Color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectParameter('waterLevel'),
                            child: SensorCard(
                              title:
                                  _parameters['waterLevel']!['title'] as String,
                              value:
                                  '${_formatValue(currentData, 'waterLevel')}${_parameters['waterLevel']!['unit']}',
                              icon: _getIconForParameter('waterLevel'),
                              color:
                                  _parameters['waterLevel']!['color'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SensorCard(
                            title: 'Détection de flamme',
                            value: currentData.flameDetected
                                ? 'DÉTECTÉE'
                                : 'Non détectée',
                            icon: Icons.local_fire_department,
                            color: currentData.flameDetected
                                ? const Color(0xFF2E7D32)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectParameter('phValue'),
                            child: SensorCard(
                              title: 'pH de l\'eau',
                              value: currentData.phValue != null
                                  ? currentData.phValue!.toStringAsFixed(1)
                                  : 'N/A',
                              icon: Icons.science,
                              color: _getPhColor(currentData.phValue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Évolution $_selectedParameterTitle',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      'Dernières 24h',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SensorChart(
                  data: iotProvider.dataHistoryAsSensorData,
                  selectedParameter: _selectedParameter,
                  lineColor: _selectedColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForParameter(String parameter) {
    switch (parameter) {
      case 'airTemperature':
        return Icons.thermostat;
      case 'airHumidity':
        return Icons.water;
      case 'soilMoisture':
        return Icons.water_drop;
      case 'waterLevel':
        return Icons.water_damage;
      default:
        return Icons.sensors;
    }
  }

  String _formatValue(IoTData data, String parameter) {
    switch (parameter) {
      case 'airTemperature':
        return data.airTemperature.toStringAsFixed(1);
      case 'airHumidity':
        return data.airHumidity.toStringAsFixed(1);
      case 'soilMoisture':
        return data.soilMoisture?.toStringAsFixed(1) ?? 'N/A';
      case 'waterLevel':
        return data.waterLevel?.toStringAsFixed(1) ?? 'N/A';
      case 'phValue':
        return data.phValue?.toStringAsFixed(1) ?? 'N/A';
      default:
        return 'N/A';
    }
  }

  Color _getPhColor(double? ph) {
    if (ph == null) return Colors.grey;
    if (ph < 6.0) return Colors.red; // Acide
    if (ph > 8.0) return Colors.purple; // Basique
    return Colors.green; // Neutre
  }
}
