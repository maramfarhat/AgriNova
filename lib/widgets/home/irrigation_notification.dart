import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/iot_provider.dart';
import 'package:farm/theme/app_theme.dart';
import 'package:intl/intl.dart';

class IrrigationNotification extends StatelessWidget {
  const IrrigationNotification({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IoTProvider>(
      builder: (context, provider, child) {
        final latestAlert = provider.latestAlert;

        if (latestAlert == null || !latestAlert.isPumpActive) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.cardColor,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/irrigation');
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.water_drop,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Irrigation en cours',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm').format(latestAlert.timestamp),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  if (latestAlert.messages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Raisons de l\'irrigation :',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...latestAlert.messages.take(2).map(
                          (message) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                    if (latestAlert.messages.length > 2)
                      Text(
                        '... et ${latestAlert.messages.length - 2} autres',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
