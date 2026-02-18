import 'package:flutter/foundation.dart';
import 'package:farm/models/market_product.dart';
import 'package:farm/services/database_helper.dart';

class MarketProvider extends ChangeNotifier {
  final List<MarketProduct> _products = [];
  final DatabaseHelper _db = DatabaseHelper();
  bool _isInitialized = false;

  MarketProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      debugPrint('🔄 Initialisation du MarketProvider...');
      await loadProducts();
      _isInitialized = true;
      debugPrint('✅ MarketProvider initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation du MarketProvider: $e');
    }
  }

  List<MarketProduct> get products => _products;
  bool get isInitialized => _isInitialized;

  Future<void> loadProducts() async {
    try {
      debugPrint('🔄 Chargement des produits...');
      final List<Map<String, dynamic>> maps =
          await _db.query('market_products');
      debugPrint('📋 Nombre de produits trouvés: ${maps.length}');
      _products.clear();
      _products.addAll(maps.map((map) => MarketProduct.fromJson(map)).toList());
      notifyListeners();
      debugPrint('✅ Produits chargés avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des produits: $e');
      rethrow;
    }
  }

  Future<void> addProduct(MarketProduct product) async {
    try {
      debugPrint('🔄 Ajout d\'un nouveau produit...');
      debugPrint('📝 Détails du produit:');
      debugPrint('  - ID: ${product.id}');
      debugPrint('  - Nom: ${product.name}');
      debugPrint('  - Catégorie: ${product.category}');

      await _db.insert('market_products', product.toJson());
      debugPrint('✅ Produit inséré dans la base de données');

      await loadProducts();
      debugPrint('✅ Produits rechargés avec succès');
      debugPrint('📊 Nombre total de produits: ${_products.length}');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ajout du produit: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(MarketProduct product) async {
    try {
      debugPrint('🔄 Mise à jour du produit: ${product.id}');
      await _db.update(
        'market_products',
        product.toJson(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
      await loadProducts();
      debugPrint('✅ Produit mis à jour avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du produit: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      debugPrint('🔄 Suppression du produit: $id');
      await _db.delete(
        'market_products',
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadProducts();
      debugPrint('✅ Produit supprimé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression du produit: $e');
      rethrow;
    }
  }

  Future<void> toggleAvailability(String id, bool availability) async {
    try {
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        final product = _products[index].copyWith(availability: availability);
        await updateProduct(product);
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du changement de disponibilité: $e');
    }
  }

  List<MarketProduct> getProductsByCategory(String category) {
    return _products
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }
}
