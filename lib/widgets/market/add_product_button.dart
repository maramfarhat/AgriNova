// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:farm/screens/market/market_product_form_screen.dart';

class AddProductButton extends StatelessWidget {
  const AddProductButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showAddProductDialog(context),
      child: const Icon(Icons.add),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MarketProductFormScreen(),
      ),
    );
  }
}
