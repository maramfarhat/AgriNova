import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/robot_provider.dart';
import 'package:farm/models/plant_disease.dart';
import 'package:farm/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:hex/hex.dart';

// Widget pour afficher l'image en plein écran
class ImageViewerScreen extends StatelessWidget {
  final Widget imageWidget;
  final String title;

  const ImageViewerScreen({
    super.key,
    required this.imageWidget,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: imageWidget,
        ),
      ),
    );
  }
}

class DiseaseHistoryScreen extends StatefulWidget {
  const DiseaseHistoryScreen({super.key});

  @override
  State<DiseaseHistoryScreen> createState() => _DiseaseHistoryScreenState();
}

class _DiseaseHistoryScreenState extends State<DiseaseHistoryScreen> {
  List<PlantDisease>? _diseases;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDiseases();
  }

  Future<void> _loadDiseases() async {
    try {
      final provider = Provider.of<RobotProvider>(context, listen: false);
      final diseases = await provider.getDiseaseHistory();
      setState(() {
        _diseases = diseases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Maladies'),
      ),
      body: Consumer<RobotProvider>(
        builder: (context, provider, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Text('Erreur: $_error'),
            );
          }

          final diseases = _diseases ?? [];

          if (diseases.isEmpty) {
            return const Center(
              child: Text('Aucune maladie détectée'),
            );
          }

          return ListView.builder(
            itemCount: diseases.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final disease = diseases[index];
              return Dismissible(
                key: Key(disease.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: const Color(0xFFE6E3D3),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Confirmer la suppression',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Voulez-vous vraiment supprimer cette entrée ?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF2E7D32),
                                    ),
                                    child: const Text(
                                      'Annuler',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Supprimer',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  provider.deleteDiseaseFromHistory(disease.id);
                  setState(() {
                    _diseases?.removeWhere((d) => d.id == disease.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Entrée supprimée de l\'historique'),
                      action: SnackBarAction(
                        label: 'Annuler',
                        onPressed: () {
                          provider.restoreDeletedDisease();
                          _loadDiseases(); // Recharger les données après restauration
                        },
                      ),
                    ),
                  );
                },
                child: DiseaseHistoryCard(disease: disease),
              );
            },
          );
        },
      ),
    );
  }
}

class DiseaseHistoryCard extends StatelessWidget {
  final PlantDisease disease;

  const DiseaseHistoryCard({
    super.key,
    required this.disease,
  });

  void _openImageViewer(BuildContext context, Widget imageWidget) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imageWidget: imageWidget,
          title: 'Image de ${disease.diseaseName}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.warning, color: Colors.orange),
        title: Text(disease.diseaseName),
        subtitle: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(disease.detectedAt),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Type : ${disease.plantType}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: disease.confidence > 0.8
                          ? Colors.green
                          : disease.confidence > 0.6
                              ? Colors.orange
                              : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Confiance: ${(disease.confidence * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: disease.confidence > 0.8
                                ? Colors.green
                                : disease.confidence > 0.6
                                    ? Colors.orange
                                    : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Description:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(disease.description),
                const SizedBox(height: 8),
                Text(
                  'Solution recommandée:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                      ),
                ),
                Text(disease.solution),
                const SizedBox(height: 8),
                Text(
                  'Localisation: ${disease.location}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (disease.imageBytes != null &&
                    disease.imageBytes!.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      final imageWidget = Image.memory(
                        Uint8List.fromList(
                          HEX.decode(disease.imageBytes!),
                        ),
                        fit: BoxFit.contain,
                      );
                      _openImageViewer(context, imageWidget);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          Uint8List.fromList(
                            HEX.decode(disease.imageBytes!),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                else if (disease.imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      final imageWidget = disease.imageUrl.startsWith('http')
                          ? Image.network(
                              disease.imageUrl,
                              fit: BoxFit.contain,
                            )
                          : Image.file(
                              File(disease.imageUrl),
                              fit: BoxFit.contain,
                            );
                      _openImageViewer(context, imageWidget);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: disease.imageUrl.startsWith('http')
                            ? Image.network(
                                disease.imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                      'Erreur de chargement de l\'image: $error');
                                  return Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red,
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                File(disease.imageUrl),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
