import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  static const String _baseUrl =
      'http://172.16.20.172:5000'; // Nouvelle IP du serveur Flask

  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      // Créer une requête multipart pour envoyer l'image
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/analyze'),
      );

      // Ajouter l'image à la requête
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      // Envoyer la requête
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      return {
        'diseaseName': jsonResponse['disease_name'],
        'plantType': jsonResponse['plant_type'],
        'description': jsonResponse['description'],
        'solution': jsonResponse['solution'],
        'confidence': jsonResponse['confidence'],
        'image_bytes': jsonResponse['image_bytes'],
      };
    } catch (e) {
      print('Erreur lors de l\'analyse de l\'image: $e');
      throw Exception('Erreur lors de l\'analyse de l\'image: $e');
    }
  }
}
