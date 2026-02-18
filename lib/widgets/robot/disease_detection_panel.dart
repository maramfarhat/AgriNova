import 'package:flutter/material.dart';
import 'package:farm/models/plant_disease.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class DiseaseDetectionPanel extends StatelessWidget {
  final PlantDisease disease;

  const DiseaseDetectionPanel({
    super.key,
    required this.disease,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Maladie Détectée: ${disease.diseaseName}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Type de plante: ${disease.plantType}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Description: ${disease.description}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Solution recommandée:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green,
              ),
            ),
            Text(disease.solution),
            const SizedBox(height: 8),
            Text(
              'Détecté le: ${DateFormat('dd/MM/yyyy HH:mm').format(disease.detectedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (disease.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: disease.imageUrl.startsWith('http')
                  ? Image.network(
                      disease.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(disease.imageUrl),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
              ),
          ],
        ),
      ),
    );
  }
} 