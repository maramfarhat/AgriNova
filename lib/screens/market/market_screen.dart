// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/market_provider.dart';
import 'package:farm/models/market_product.dart';
import 'package:farm/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenir les dimensions de l'écran
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculer les valeurs dynamiques
    final double padding = screenWidth < 360 ? 4.0 : 8.0;
    final double spacing = screenWidth < 360 ? 4.0 : 8.0;
    final double avatarRadius = screenWidth < 360
        ? 20.0
        : screenWidth < 400
            ? 25.0
            : 30.0;
    final double fontSize = screenWidth < 360
        ? 11.0
        : screenWidth < 400
            ? 12.0
            : 14.0;
    final double childRatio = screenHeight < 600
        ? 0.9
        : screenHeight < 800
            ? 0.8
            : 0.75;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marché'),
      ),
      body: Consumer<MarketProvider>(
        builder: (context, marketProvider, child) {
          final products = marketProvider.products;

          if (products.isEmpty) {
            return const Center(
              child: Text('Aucun produit disponible'),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.all(padding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth > 600 ? 3 : 2,
              childAspectRatio: childRatio,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Dismissible(
                key: Key(product.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: const Color(0xFFE8DCC4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        title: const Text(
                          'Confirmer la suppression',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: const Text(
                          'Voulez-vous vraiment supprimer ce produit ?',
                          style: TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2E7D32),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
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
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  marketProvider.deleteProduct(product.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produit supprimé'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: product.imageUrl.isNotEmpty
                              ? Container(
                                  width: avatarRadius * 2,
                                  height: avatarRadius * 2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: FileImage(File(product.imageUrl)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundColor: const Color(0xFF2E7D32),
                                  child: Icon(
                                    Icons.agriculture,
                                    color: Colors.white,
                                    size: avatarRadius * 0.8,
                                  ),
                                ),
                        ),
                        SizedBox(height: padding),
                        Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: padding / 2),
                        Text(
                          '${product.price} DT/${product.unit}',
                          style: TextStyle(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize - 1,
                          ),
                        ),
                        SizedBox(height: padding / 2),
                        Text(
                          'Quantité: ${product.quantity} ${product.unit}',
                          style: TextStyle(fontSize: fontSize - 2),
                        ),
                        SizedBox(height: padding / 2),
                        Text(
                          'Catégorie: ${product.category}',
                          style: TextStyle(
                            fontSize: fontSize - 2,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.phone != null && product.phone!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: padding / 2),
                            child: InkWell(
                              onTap: () async {
                                final status = await Permission.phone.request();
                                if (status.isGranted) {
                                  try {
                                    final phoneUrl = 'tel:${product.phone}';
                                    if (!await launchUrl(
                                      Uri.parse(phoneUrl),
                                      mode: LaunchMode.platformDefault,
                                    )) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Impossible de lancer l\'appel'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Erreur: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Permission d\'appel refusée. Veuillez l\'activer dans les paramètres.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: fontSize,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                  SizedBox(width: padding / 2),
                                  Expanded(
                                    child: Text(
                                      product.phone!,
                                      style: TextStyle(
                                        fontSize: fontSize - 2,
                                        color: const Color(0xFF2E7D32),
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/market/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
