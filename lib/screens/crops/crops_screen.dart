import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/crop_provider.dart';
import 'package:farm/widgets/crop_card.dart';
import 'package:farm/theme/app_theme.dart';

class CropsScreen extends StatelessWidget {
  const CropsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mes Cultures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/crops/add');
            },
          ),
        ],
      ),
      body: Consumer<CropProvider>(
        builder: (context, cropProvider, child) {
          if (cropProvider.crops.isEmpty) {
            return const Center(
              child: Text('Aucune culture'),
            );
          }

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Cultures',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  itemCount: cropProvider.crops.length,
                  itemBuilder: (context, index) {
                    final crop = cropProvider.crops[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: CropCard(
                        crop: crop,
                        onEdit: () {
                          Navigator.pushNamed(
                            context,
                            '/crops/edit',
                            arguments: crop,
                          );
                        },
                        onDelete: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFFE8DCC4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                title: const Text(
                                  'Supprimer la culture',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'Êtes-vous sûr de vouloir supprimer ${crop.name} ?',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF2E7D32),
                                    ),
                                    child: const Text(
                                      'Annuler',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Supprimer',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          if (shouldDelete == true) {
                            // ignore: use_build_context_synchronously
                            await Provider.of<CropProvider>(context,
                                    listen: false)
                                .deleteCrop(crop.id);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
