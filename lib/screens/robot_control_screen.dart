import 'package:flutter/material.dart';
import '../models/plant_disease.dart';

Widget _buildDetectionPanel(PlantDisease? detection) {
  if (detection == null) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No disease detected'),
      ),
    );
  }

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Disease: ${detection.diseaseName}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recommended Solution:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            detection.solution,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (detection.imageUrl.isNotEmpty)
            Image.network(
              detection.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text('Failed to load image'),
                );
              },
            ),
        ],
      ),
    ),
  );
}
