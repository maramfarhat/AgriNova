import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/irrigation_provider.dart';
import 'package:farm/providers/iot_provider.dart';
import 'package:intl/intl.dart';
import 'package:farm/theme/app_theme.dart';
import 'package:farm/widgets/irrigation/irrigation_alert_widget.dart';
import 'package:farm/screens/irrigation/pump_control_screen.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _expandedAlertIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    debugPrint('🔄 IrrigationScreen initialisé');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irrigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.water),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PumpControlScreen(),
                ),
              );
            },
            tooltip: 'Contrôle de la pompe',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Configurations'),
            Tab(text: 'Alertes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConfigurationsTab(),
          _buildAlertsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/irrigation/config'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildConfigurationsTab() {
    return Consumer<IrrigationProvider>(
      builder: (context, provider, child) {
        final configs = provider.configs;

        if (configs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Aucune configuration d\'irrigation'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/irrigation/config'),
                  child: const Text('Ajouter une configuration'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          itemCount: configs.length,
          itemBuilder: (context, index) {
            final config = configs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 0,
                color: AppTheme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.water_drop,
                      color:
                          config.isActive ? AppTheme.primaryColor : Colors.grey,
                    ),
                  ),
                  title: Text(config.name),
                  subtitle: Text(config.zone),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Volume d\'eau: ${config.waterVolume} L'),
                          const SizedBox(height: 8),
                          Text('Durée: ${config.duration} minutes'),
                          const SizedBox(height: 8),
                          Text(
                            'Dates programmées:\n${_formatScheduledDates(config.scheduledDates)}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'Mode: ${config.isAutomatic ? 'Automatique' : 'Manuel'}'),
                          const SizedBox(height: 16),
                          if (!config.isAutomatic) ...[
                            Consumer<IoTProvider>(
                              builder: (context, iotProvider, child) {
                                final isPumpActive = iotProvider.isPumpActive;
                                return SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final success = await iotProvider
                                            .togglePump(!isPumpActive);

                                        if (success) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isPumpActive
                                                    ? 'Pompe arrêtée'
                                                    : 'Pompe activée',
                                              ),
                                              backgroundColor: isPumpActive
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Erreur lors du contrôle de la pompe'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Erreur: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      isPumpActive
                                          ? Icons.stop
                                          : Icons.play_arrow,
                                      size: 28,
                                    ),
                                    label: Text(
                                      isPumpActive
                                          ? 'Arrêter la pompe'
                                          : 'Activer la pompe',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPumpActive
                                          ? Colors.red
                                          : AppTheme.primaryColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/irrigation/config',
                                    arguments: config,
                                  );
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Modifier'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    provider.deleteConfig(config.id),
                                icon: const Icon(Icons.delete),
                                label: const Text('Supprimer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    return Consumer<IoTProvider>(
      builder: (context, iotProvider, child) {
        final alerts = iotProvider.alerts;
        debugPrint(
            '🔄 Construction de l\'onglet Alertes. Nombre d\'alertes: ${alerts.length}');

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alertes d\'irrigation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      debugPrint('🔄 Rafraîchissement manuel des données');
                      await iotProvider.refreshData();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rafraîchir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: alerts.isEmpty
                  ? const Center(
                      child: Text('Aucune alerte'),
                    )
                  : ListView.builder(
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        debugPrint(
                            '📝 Alerte ${index + 1}/${alerts.length}: ${alert.messages.join(", ")}');
                        return IrrigationAlertWidget(
                          alert: alert,
                          isExpanded: _expandedAlertIndex == index,
                          onTap: () {
                            setState(() {
                              if (_expandedAlertIndex == index) {
                                _expandedAlertIndex = null;
                              } else {
                                _expandedAlertIndex = index;
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _formatScheduledDates(List<DateTime> dates) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    return dates.map((date) => formatter.format(date)).join('\n');
  }
}

class IrrigationZoneCard extends StatelessWidget {
  final String zoneName;
  final VoidCallback onTap;

  const IrrigationZoneCard({
    required this.zoneName,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                zoneName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
