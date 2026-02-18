class PlantDisease {
  final String id;
  final String diseaseName;
  final double confidence;
  final String imageUrl;
  final String solution;
  final DateTime timestamp;
  final DateTime detectedAt;
  final String plantType;
  final String description;
  final String location;
  final String? imageBytes;

  PlantDisease({
    String? id,
    required this.diseaseName,
    required this.confidence,
    required this.imageUrl,
    required this.solution,
    required this.timestamp,
    DateTime? detectedAt,
    this.plantType = '',
    this.description = '',
    this.location = '',
    this.imageBytes,
  })  : this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        this.detectedAt = detectedAt ?? DateTime.now();

  factory PlantDisease.fromJson(Map<String, dynamic> json) {
    return PlantDisease(
      id: json['id'] as String?,
      diseaseName: json['diseaseName'] as String? ?? json['name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String? ?? '',
      solution: json['solution'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      detectedAt: json['detectedAt'] != null
          ? DateTime.parse(json['detectedAt'] as String)
          : null,
      plantType: json['plantType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      imageBytes: json['imageBytes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diseaseName': diseaseName,
      'confidence': confidence,
      'imageUrl': imageUrl,
      'solution': solution,
      'timestamp': timestamp.toIso8601String(),
      'detectedAt': detectedAt.toIso8601String(),
      'plantType': plantType,
      'description': description,
      'location': location,
      'imageBytes': imageBytes,
    };
  }

  // Alias for database operations
  Map<String, dynamic> toMap() => toJson();

  factory PlantDisease.fromMap(Map<String, dynamic> map) =>
      PlantDisease.fromJson(map);
}
