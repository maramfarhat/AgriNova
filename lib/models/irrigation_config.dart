import 'package:flutter/foundation.dart';

class IrrigationConfig {
  final String id;
  final String cropId;
  final String name;
  final String zone;
  final int duration;
  final double waterVolume;
  final bool isActive;
  final bool isAutomatic;
  final List<DateTime> scheduledDates;
  final String schedule;

  IrrigationConfig({
    required this.id,
    required this.cropId,
    required this.name,
    required this.zone,
    required this.duration,
    required this.waterVolume,
    required this.isActive,
    required this.isAutomatic,
    required this.scheduledDates,
    required this.schedule,
  });

  IrrigationConfig copyWith({
    String? id,
    String? cropId,
    String? name,
    String? zone,
    int? duration,
    double? waterVolume,
    bool? isActive,
    bool? isAutomatic,
    List<DateTime>? scheduledDates,
    String? schedule,
  }) {
    return IrrigationConfig(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      name: name ?? this.name,
      zone: zone ?? this.zone,
      duration: duration ?? this.duration,
      waterVolume: waterVolume ?? this.waterVolume,
      isActive: isActive ?? this.isActive,
      isAutomatic: isAutomatic ?? this.isAutomatic,
      scheduledDates: scheduledDates ?? this.scheduledDates,
      schedule: schedule ?? this.schedule,
    );
  }

  factory IrrigationConfig.fromJson(Map<String, dynamic> json) {
    debugPrint('🔄 Conversion JSON vers IrrigationConfig');
    debugPrint('📝 Données JSON reçues: $json');

    try {
      // Validation des champs requis
      final requiredFields = [
        'id',
        'cropId',
        'name',
        'zone',
        'duration',
        'waterVolume'
      ];
      for (final field in requiredFields) {
        if (!json.containsKey(field)) {
          throw Exception('Champ requis manquant: $field');
        }
      }

      // Conversion des dates programmées
      List<DateTime> dates = [];
      if (json['scheduledDates'] != null &&
          json['scheduledDates'].toString().isNotEmpty) {
        dates = json['scheduledDates']
            .toString()
            .split(',')
            .where((date) => date.isNotEmpty)
            .map<DateTime>((date) {
          try {
            return DateTime.parse(date);
          } catch (e) {
            debugPrint('⚠️ Erreur lors de la conversion de la date: $date');
            return DateTime.now(); // Date par défaut en cas d'erreur
          }
        }).toList();
      }

      final config = IrrigationConfig(
        id: json['id'].toString(),
        cropId: json['cropId'].toString(),
        name: json['name'].toString(),
        zone: json['zone'].toString(),
        duration: int.parse(json['duration'].toString()),
        waterVolume: double.parse(json['waterVolume'].toString()),
        isActive: json['isActive'] == 1,
        isAutomatic: json['isAutomatic'] == 1,
        scheduledDates: dates,
        schedule: json['schedule']?.toString() ?? '',
      );

      debugPrint('✅ Conversion réussie:');
      debugPrint('  - ID: ${config.id}');
      debugPrint('  - Nom: ${config.name}');
      debugPrint('  - Zone: ${config.zone}');
      debugPrint('  - Dates programmées: ${config.scheduledDates.length}');

      return config;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la conversion JSON:');
      debugPrint('Message d\'erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    try {
      debugPrint('🔄 Conversion de IrrigationConfig en JSON');
      debugPrint('  - ID: $id');
      debugPrint('  - Nom: $name');
      debugPrint('  - Zone: $zone');

      final json = {
        'id': id,
        'cropId': cropId,
        'name': name,
        'zone': zone,
        'duration': duration,
        'waterVolume': waterVolume,
        'isActive': isActive ? 1 : 0,
        'isAutomatic': isAutomatic ? 1 : 0,
        'scheduledDates': scheduledDates
            .map((date) => date.toIso8601String())
            .toList()
            .join(','),
        'schedule': schedule,
      };

      debugPrint('✅ JSON généré avec succès');
      return json;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la conversion en JSON:');
      debugPrint('Message d\'erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
