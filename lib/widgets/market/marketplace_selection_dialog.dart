import 'package:flutter/material.dart';

class MarketplaceSelectionDialog extends StatelessWidget {
  const MarketplaceSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir une plateforme'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Marketplace 1'),
            onTap: () => _shareToMarketplace(context, 'marketplace1'),
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Marketplace 2'),
            onTap: () => _shareToMarketplace(context, 'marketplace2'),
          ),
        ],
      ),
    );
  }

  void _shareToMarketplace(BuildContext context, String marketplace) {
    // TODO: Implémenter le partage
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Catalogue partagé sur $marketplace'),
      ),
    );
  }
}