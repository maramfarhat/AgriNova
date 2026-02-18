import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/irrigation_provider.dart';
import 'package:farm/models/irrigation_record.dart';
import 'package:intl/intl.dart';

class IrrigationHistoryScreen extends StatelessWidget {
  const IrrigationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique d\'irrigation'),
      ),
      body: FutureBuilder<List<IrrigationRecord>>(
        future: Provider.of<IrrigationProvider>(context, listen: false)
            .getIrrigationHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final records = snapshot.data ?? [];
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
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(record.status).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.water_drop,
                      color: _getStatusColor(record.status),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(record.date),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(record.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record.status,
                          style: TextStyle(
                            color: _getStatusColor(record.status),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Zone: ${record.zone}'),
                      Text(
                        'Volume: ${record.waterVolume}L | '
                        'Durée: ${record.duration}min',
                      ),
                      Text('Humidité du sol: ${record.soilMoisture}%'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}