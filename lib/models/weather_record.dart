class WeatherRecord {
  final DateTime date;
  final double temperature;
  final int humidity;
  final String location;
  final String weatherDescription;

  WeatherRecord({
    required this.date,
    required this.temperature,
    required this.humidity,
    required this.location,
    required this.weatherDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'location': location,
      'weatherDescription': weatherDescription,
    };
  }

  factory WeatherRecord.fromMap(Map<String, dynamic> map) {
    return WeatherRecord(
      date: DateTime.parse(map['date']),
      temperature: map['temperature'],
      humidity: map['humidity'],
      location: map['location'],
      weatherDescription: map['weatherDescription'],
    );
  }
} 