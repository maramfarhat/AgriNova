import 'package:uuid/uuid.dart';

enum CropType {
  cereals,    // Céréales
  vegetables, // Légumes
  fruits,     // Fruits
  legumes,    // Légumineuses
  other       // Autres
}

enum CropStatus {
  sown,         // Semée
  growing,      // En croissance
  flowering,    // Floraison
  fruiting,     // Fructification
  harvested     // Récoltée
}

class Crop {
  final String id;
  final String name;
  final CropType type;
  final DateTime plantingDate;
  final DateTime? harvestDate;
  final double area;
  final CropStatus status;

  Crop({
    String? id,
    required this.name,
    required this.type,
    required this.plantingDate,
    this.harvestDate,
    required this.area,
    required this.status,
  }) : id = id ?? const Uuid().v4();

  factory Crop.fromMap(Map<String, dynamic> map) {
    return Crop(
      id: map['id'],
      name: map['name'],
      type: CropType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      plantingDate: DateTime.parse(map['plantingDate']),
      harvestDate: map['harvestDate'] != null 
        ? DateTime.parse(map['harvestDate'])
        : null,
      area: map['area'],
      status: CropStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => CropStatus.sown,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'plantingDate': plantingDate.toIso8601String(),
      'harvestDate': harvestDate?.toIso8601String(),
      'area': area,
      'status': status.toString(),
    };
  }
}