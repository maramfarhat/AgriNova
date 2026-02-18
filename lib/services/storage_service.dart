import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static Future<String> saveImage(File imageFile) async {
    try {
      // Obtenir le dossier de documents de l'application
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, 'disease_images'));

      // Créer le dossier s'il n'existe pas
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Générer un nom de fichier unique
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final savedPath = path.join(imagesDir.path, fileName);

      // Copier l'image
      await imageFile.copy(savedPath);

      return savedPath;
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'image: $e');
      rethrow;
    }
  }

  static Future<File?> getImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'image: $e');
      return null;
    }
  }
}
