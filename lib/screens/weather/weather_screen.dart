import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/weather_provider.dart';
import 'package:intl/intl.dart';
import 'package:farm/widgets/weather/city_search_delegate.dart';
import 'package:farm/models/weather_hour.dart';
import 'package:farm/models/weather.dart';
import 'package:farm/widgets/weather/daily_forecast.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: _buildTitle(provider),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () async {
                  final selectedLocation = await showSearch(
                    context: context,
                    delegate: CitySearchDelegate(provider.apiKey),
                  );
                  if (selectedLocation != null && selectedLocation.isNotEmpty) {
                    provider.fetchWeatherByCity(selectedLocation);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  Navigator.pushNamed(context, '/weather/history');
                },
              ),
            ],
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(WeatherProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchWeatherByLocation(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (provider.weather == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Aucune donnée météo disponible'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchWeatherByLocation(),
              child: const Text('Obtenir la météo'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchWeatherByLocation(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCurrentWeather(provider.weather!),
          const SizedBox(height: 16),
          _buildHourlyForecast(provider.hourlyForecasts),
          const SizedBox(height: 16),
          DailyForecast(dailyForecast: provider.dailyForecasts),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather(Weather weather) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperature.round()}°C',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      weather.condition,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Image.network(
                  weather.iconUrl,
                  width: 80,
                  height: 80,
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherInfo(
                  Icons.water_drop,
                  '${weather.humidity}%',
                  'Humidité',
                ),
                _buildWeatherInfo(
                  Icons.air,
                  '${weather.windSpeed} km/h',
                  weather.windDirection,
                ),
                _buildWeatherInfo(
                  Icons.umbrella,
                  '${weather.precipitation} mm',
                  'Précipitations',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyForecast(List<WeatherHour> hourlyForecast) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyForecast.length,
        itemBuilder: (context, index) {
          final hour = hourlyForecast[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('HH:mm').format(hour.date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Image.network(
                    hour.iconUrl,
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, size: 50);
                    },
                  ),
                  Text('${hour.temperature.round()}°C'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(value),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(WeatherProvider provider) {
    return Text(provider.location ?? 'Météo');
  }
}