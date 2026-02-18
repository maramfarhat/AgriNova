import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/weather_provider.dart';
import 'package:farm/models/weather_forecast.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:farm/providers/iot_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _notificationCount = 0;
  Timer? _notificationTimer;
  bool _isAnimating = false;
  WeatherForecast? _lastCheckedForecast;
  List<String> _notifications = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final weatherProvider = context.read<WeatherProvider>();
      final iotProvider = context.read<IoTProvider>();
      weatherProvider.getCurrentLocation();
      _startNotificationCheck();

      // Écouter les changements de prévisions
      weatherProvider.addListener(() {
        if (weatherProvider.forecast.isNotEmpty) {
          _checkNewForecasts();
        }
      });

      // Écouter les alertes IoT
      iotProvider.addListener(() {
        _checkIoTAlerts(iotProvider);
      });
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startNotificationCheck() {
    // Vérifier les nouvelles prévisions toutes les heures
    _notificationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkNewForecasts();
    });
    // Première vérification immédiate
    _checkNewForecasts();
  }

  void _checkNewForecasts() {
    final weatherProvider = context.read<WeatherProvider>();
    final forecasts = weatherProvider.forecast;
    if (forecasts.isEmpty) return;

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    debugPrint('Checking forecasts for: ${tomorrow.toString()}');

    final tomorrowForecast = forecasts.firstWhere(
      (f) => DateTime(f.date.year, f.date.month, f.date.day)
          .isAtSameMomentAs(tomorrow),
      orElse: () {
        debugPrint('No forecast found for tomorrow');
        return forecasts.first;
      },
    );

    // Vérifier si la prévision a changé
    bool hasChanged = _lastCheckedForecast == null ||
        _lastCheckedForecast!.temperature != tomorrowForecast.temperature ||
        _lastCheckedForecast!.condition != tomorrowForecast.condition ||
        _lastCheckedForecast!.humidity != tomorrowForecast.humidity;

    if (hasChanged) {
      debugPrint('Forecast has changed! Checking conditions...');
      _lastCheckedForecast = tomorrowForecast;

      bool shouldNotify = false;

      if (tomorrowForecast.condition.toLowerCase().contains('pluie')) {
        debugPrint('Notification: Pluie prévue');
        shouldNotify = true;
      }
      if (tomorrowForecast.condition.toLowerCase().contains('orage')) {
        debugPrint('Notification: Orage prévu');
        shouldNotify = true;
      }
      if (tomorrowForecast.humidity > 80) {
        debugPrint(
            'Notification: Humidité élevée: ${tomorrowForecast.humidity}%');
        shouldNotify = true;
      }
      if (tomorrowForecast.temperature < 5) {
        debugPrint(
            'Notification: Température basse: ${tomorrowForecast.temperature}°C');
        shouldNotify = true;
      }
      if (tomorrowForecast.temperature > 30) {
        debugPrint(
            'Notification: Température élevée: ${tomorrowForecast.temperature}°C');
        shouldNotify = true;
      }

      if (shouldNotify) {
        setState(() {
          _notificationCount++;
          _isAnimating = true;
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _isAnimating = false;
              });
            }
          });
        });
      }
    } else {
      debugPrint('No changes in forecast');
    }
  }

  void _checkIoTAlerts(IoTProvider provider) {
    final latestAlert = provider.latestAlert;
    final currentData = provider.currentData;
    if (currentData == null) return;

    // Vérifier la détection de flamme
    if (currentData.flameDetected) {
      String notification = '🔥 ATTENTION : Flamme détectée !';
      if (!_notifications.contains(notification)) {
        setState(() {
          _notifications.insert(0, notification);
          _notificationCount++;
          _isAnimating = true;
        });
      }
    }

    // Vérifier les valeurs critiques des capteurs
    if (currentData.soilMoisture != null && currentData.soilMoisture! < 50) {
      String notification =
          '⚠️ ATTENTION : Humidité du sol critique (${currentData.soilMoisture!.toStringAsFixed(1)}%)';
      if (!_notifications.contains(notification)) {
        setState(() {
          _notifications.insert(0, notification);
          _notificationCount++;
          _isAnimating = true;
        });
      }
    }

    if (currentData.airTemperature < 10 || currentData.airTemperature > 30) {
      String notification =
          '⚠️ ATTENTION : Température hors limite (${currentData.airTemperature.toStringAsFixed(1)}°C)';
      if (!_notifications.contains(notification)) {
        setState(() {
          _notifications.insert(0, notification);
          _notificationCount++;
          _isAnimating = true;
        });
      }
    }

    if (currentData.airHumidity < 40 || currentData.airHumidity > 80) {
      String notification =
          '⚠️ ATTENTION : Humidité de l\'air hors limite (${currentData.airHumidity.toStringAsFixed(1)}%)';
      if (!_notifications.contains(notification)) {
        setState(() {
          _notifications.insert(0, notification);
          _notificationCount++;
          _isAnimating = true;
        });
      }
    }

    if (currentData.phValue != null &&
        (currentData.phValue! < 5.5 || currentData.phValue! > 7.0)) {
      String notification =
          '⚠️ ATTENTION : pH hors limite (${currentData.phValue!.toStringAsFixed(2)})';
      if (!_notifications.contains(notification)) {
        setState(() {
          _notifications.insert(0, notification);
          _notificationCount++;
          _isAnimating = true;
        });
      }
    }

    // Vérifier les alertes d'irrigation
    if (latestAlert != null) {
      String notification = '';
      if (latestAlert.isPumpActive) {
        notification =
            '🚰 Irrigation déclenchée : ${DateFormat('HH:mm').format(latestAlert.timestamp)}\n';
        notification += latestAlert.messages.join('\n');
      } else if (latestAlert.messages
          .any((msg) => msg.contains('Pluie prévue'))) {
        notification =
            '☔ ${latestAlert.messages.firstWhere((msg) => msg.contains('Pluie prévue'))}';
      }

      if (notification.isNotEmpty && !_notifications.contains(notification)) {
        setState(() {
          _notifications.insert(0, notification);
          _notificationCount++;
          _isAnimating = true;
        });
      }
    }

    // Animation de notification
    if (_isAnimating) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeatherCard(context),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Fonctionnalités principales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildMenuItem(
                    'Cultures',
                    'Gérer votre culture',
                    Icons.eco,
                    () => Navigator.pushNamed(context, '/crops'),
                  ),
                  _buildMenuItem(
                    'Irrigation',
                    'Contrôler l\'irrigation',
                    Icons.water_drop,
                    () => Navigator.pushNamed(context, '/irrigation'),
                  ),
                  _buildMenuItem(
                    'les capteurs IoT',
                    'Surveillez les données des capteurs IoT',
                    Icons.sensors,
                    () => Navigator.pushNamed(context, '/iot'),
                  ),
                  _buildMenuItem(
                    'Météo',
                    'Voir la météo actuelle et les prévisions',
                    Icons.wb_sunny,
                    () => Navigator.pushNamed(context, '/weather'),
                  ),
                  _buildMenuItem(
                    'Finances',
                    'Gérer vos finances',
                    Icons.account_balance_wallet,
                    () => Navigator.pushNamed(context, '/finance'),
                  ),
                  _buildMenuItem(
                    'Marché',
                    'Vendre vos produits',
                    Icons.shopping_cart,
                    () => Navigator.pushNamed(context, '/market'),
                  ),
                  _buildMenuItem(
                    'Robot Agricole',
                    'Détecter les anomalies',
                    Icons.smart_toy,
                    () => Navigator.pushNamed(context, '/robot'),
                  ),
                  _buildMenuItem(
                    'AgriBot',
                    'Demandez ce que vous voulez',
                    Icons.chat_bubble_outline,
                    () => Navigator.pushNamed(context, '/agribot'),
                  ),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        final weather = provider.weather;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    weather?.temperature.round().toString() ?? '--',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    '°',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (weather != null)
                    Image.network(
                      weather.iconUrl,
                      width: 50,
                      height: 50,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                provider.location ?? '',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
              Text(
                weather?.condition ?? '',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Accéder',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, true),
          _buildNavItem(Icons.notifications_none, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (icon == Icons.notifications_none) {
          setState(() {
            _notificationCount = 0; // Réinitialiser le compteur
          });
          _showNotifications(context);
        }
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          if (icon == Icons.notifications_none && _notificationCount > 0)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: _isAnimating ? 0.5 : 1.0,
                end: _isAnimating ? 1.0 : 1.0,
              ),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    _notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE8F5E9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _notifications[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
            ),
            if (_notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Aucune notification',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            TextButton(
              onPressed: () {
                setState(() {
                  _notifications.clear();
                  _notificationCount = 0;
                });
                Navigator.pop(context);
              },
              child: const Text('Effacer tout'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showWeatherForecast(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE8F5E9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Consumer<WeatherProvider>(
          builder: (context, provider, child) {
            final forecasts = provider.forecast;
            if (forecasts.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Colors.green,
                  ),
                ),
              );
            }

            // Prendre les prévisions pour demain
            final tomorrowForecast = forecasts.firstWhere(
              (f) => f.date.day == DateTime.now().day + 1,
              orElse: () => forecasts.first,
            );

            // Créer le message avec emoji en fonction des conditions
            String emoji = _getWeatherEmoji(tomorrowForecast.condition);
            String message = _createWeatherMessage(tomorrowForecast);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(
                          fontSize: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildWeatherInfo(
                              Icons.thermostat,
                              '${tomorrowForecast.temperature.round()}°C',
                            ),
                            const SizedBox(width: 24),
                            _buildWeatherInfo(
                              Icons.water_drop,
                              '${tomorrowForecast.humidity.round()}%',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.green,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getWeatherEmoji(String condition) {
    switch (condition.toLowerCase()) {
      case 'dégagé':
        return '☀️';
      case 'peu nuageux':
        return '🌤️';
      case 'partiellement nuageux':
        return '⛅';
      case 'nuageux':
        return '☁️';
      case 'brumeux':
        return '🌫️';
      case 'bruine':
        return '🌧️';
      case 'pluie':
        return '🌧️';
      case 'neige':
        return '🌨️';
      case 'grêle':
        return '🌨️';
      case 'averses':
        return '🌦️';
      case 'orage':
        return '⛈️';
      case 'orage avec grêle':
        return '⛈️';
      default:
        return '🌡️';
    }
  }

  String _createWeatherMessage(WeatherForecast forecast) {
    String baseMessage = "Demain, ";

    // Ajouter la description des conditions
    switch (forecast.condition.toLowerCase()) {
      case 'dégagé':
        baseMessage += "le ciel sera dégagé ☀️";
        break;
      case 'peu nuageux':
      case 'partiellement nuageux':
        baseMessage += "le temps sera légèrement nuageux ⛅";
        break;
      case 'nuageux':
        baseMessage += "le ciel sera couvert ☁️";
        break;
      case 'brumeux':
        baseMessage += "il y aura du brouillard 🌫️";
        break;
      case 'bruine':
      case 'pluie':
      case 'averses':
        baseMessage += "il y aura de la pluie 🌧️";
        break;
      case 'neige':
        baseMessage += "il neigera 🌨️";
        break;
      case 'orage':
      case 'orage avec grêle':
        baseMessage += "des orages sont prévus ⛈️";
        break;
      default:
        baseMessage += forecast.condition.toLowerCase();
    }

    // Ajouter la température
    baseMessage += "\n\nTempérature: ${forecast.temperature.round()}°C 🌡️";

    // Ajouter l'humidité si elle est significative
    if (forecast.humidity > 70) {
      baseMessage += "\nHumidité élevée: ${forecast.humidity.round()}% 💧";
    }

    return baseMessage;
  }
}
