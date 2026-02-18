// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/market_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class SupplierMarketScreen extends StatelessWidget {
  const SupplierMarketScreen({super.key});

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

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/user-type');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Marché Agricole'),
          backgroundColor: const Color(0xFF2E7D32),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/user-type'),
          ),
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
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image ou Icon
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
                        // Nom du produit
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
                        // Prix et unité
                        Text(
                          '${product.price} DT/${product.unit}',
                          style: TextStyle(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize - 1,
                          ),
                        ),
                        SizedBox(height: padding / 2),
                        // Quantité
                        Text(
                          'Quantité: ${product.quantity} ${product.unit}',
                          style: TextStyle(fontSize: fontSize - 2),
                        ),
                        SizedBox(height: padding / 2),
                        // Catégorie
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
                                          SnackBar(
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
