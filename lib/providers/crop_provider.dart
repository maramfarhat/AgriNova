import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:farm/models/crop.dart';
import 'package:farm/services/database_helper.dart';

class CropProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Crop> _crops = [];
  bool _isInitialized = false;

  CropProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('🔄 Initialisation du CropProvider...');
    try {
      await _loadCrops();
      _isInitialized = true;
      debugPrint('✅ CropProvider initialisé avec succès');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de l\'initialisation du CropProvider:');
      debugPrint('Message d\'erreur: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  List<Crop> get crops => [..._crops];
  bool get isInitialized => _isInitialized;

  Future<void> _loadCrops() async {
    try {
      debugPrint('🔄 Chargement des cultures...');
      final List<Map<String, dynamic>> maps = await _db.query('crops');
      debugPrint('📋 Nombre de cultures trouvées: ${maps.length}');

      _crops = maps.map((map) => Crop.fromMap(map)).toList();
      notifyListeners();
      debugPrint('✅ Cultures chargées avec succès');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors du chargement des cultures:');
      debugPrint('Message d\'erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> addCrop(Crop crop) async {
    try {
      debugPrint('🔄 Ajout d\'une nouvelle culture...');
      debugPrint('📝 Détails de la culture:');
      debugPrint('  - ID: ${crop.id}');
      debugPrint('  - Nom: ${crop.name}');
      debugPrint('  - Type: ${crop.type}');
      debugPrint('  - Surface: ${crop.area}');

      await _db.insert('crops', crop.toMap());
      debugPrint('✅ Culture insérée dans la base de données');

      await _loadCrops();
      debugPrint('✅ Cultures rechargées avec succès');
      debugPrint('📊 Nombre total de cultures: ${_crops.length}');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de l\'ajout de la culture:');
      debugPrint('Message d\'erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateCrop(Crop crop) async {
    try {
      debugPrint('🔄 Mise à jour de la culture: ${crop.id}');
      await _db.update(
        'crops',
        crop.toMap(),
        where: 'id = ?',
        whereArgs: [crop.id],
      );
      await _loadCrops();
      debugPrint('✅ Culture mise à jour avec succès');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la mise à jour de la culture:');
      debugPrint('Message d\'erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteCrop(String id) async {
    try {
      debugPrint('🔄 Suppression de la culture: $id');
      await _db.delete(
        'crops',
        where: 'id = ?',
        whereArgs: [id],
      );
      await _loadCrops();
      debugPrint('✅ Culture supprimée avec succès');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la suppression de la culture:');
      debugPrint('Message d\'erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Helper method to get crops by status
  List<Crop> getCropsByStatus(CropStatus status) {
    return _crops.where((crop) => crop.status == status).toList();
  }
}
