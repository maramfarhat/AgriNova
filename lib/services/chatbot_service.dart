import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class ChatbotService {
  // Clé API Google Gemini
  static const String _apiKey = 'AIzaSyBABSHikjf7ttFhjioncvfjCQbunyCj7Qo';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';

  // Configuration des retries
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  Future<String> getResponse(String userMessage,
      List<Map<String, dynamic>> conversationHistory) async {
    int retryCount = 0;

    while (retryCount < _maxRetries) {
      try {
        print(
            'Début de la requête API Gemini... (Tentative ${retryCount + 1}/$_maxRetries)');
        print('URL de l\'API: $_apiUrl');
dr''
        // Construire le contexte de la conversation
        String conversationContext =
            "Vous êtes AgriBot, un assistant spécialisé en agriculture et jardinage. "
            "Vous donnez des conseils précis sur les cultures, l'arrosage, les maladies des plantes, "
            "la préparation du sol et le calendrier de plantation. Vos réponses sont concises, "
            "techniques et adaptées aux besoins des agriculteurs et jardiniers. "
            "Répondez toujours en français.\n\n";

        // Ajouter l'historique de conversation
        for (var message in conversationHistory) {
          conversationContext +=
              "${message["isUser"] ? "Utilisateur" : "AgriBot"}: ${message["text"]}\n";
        }

        // Ajouter le message actuel
        conversationContext += "Utilisateur: $userMessage\n";
        conversationContext += "AgriBot:";

        // Préparer le corps de la requête
        final requestBody = {
          "contents": [
            {
              "parts": [
                {"text": conversationContext}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 1000,
          },
          "safetySettings": [
            {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
            {
              "category": "HARM_CATEGORY_HATE_SPEECH",
              "threshold": "BLOCK_NONE"
            },
            {
              "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              "threshold": "BLOCK_NONE"
            },
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_NONE"
            }
          ]
        };

        // Préparer la requête
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data.containsKey('candidates') &&
              data['candidates'].isNotEmpty &&
              data['candidates'][0].containsKey('content') &&
              data['candidates'][0]['content'].containsKey('parts') &&
              data['candidates'][0]['content']['parts'].isNotEmpty) {
            return data['candidates'][0]['content']['parts'][0]['text'];
          }
        } else if (response.statusCode == 429) {
          // Erreur de quota - attendre et réessayer
          print(
              'Quota dépassé, attente de $_retryDelay avant nouvelle tentative...');
          await Future.delayed(_retryDelay);
          retryCount++;
          continue;
        }

        // Si on arrive ici, c'est une erreur non gérée
        print('Erreur API (${response.statusCode}): ${response.body}');
        if (retryCount < _maxRetries - 1) {
          await Future.delayed(_retryDelay);
          retryCount++;
          continue;
        }

        return "Désolé, je rencontre des difficultés techniques. Veuillez réessayer dans quelques instants.";
      } catch (e, stackTrace) {
        print('Erreur lors de la communication avec l\'API:');
        print('Exception: $e');
        print('Stack trace: $stackTrace');

        if (retryCount < _maxRetries - 1) {
          await Future.delayed(_retryDelay);
          retryCount++;
          continue;
        }

        return "Désolé, je rencontre des difficultés techniques. Veuillez réessayer dans quelques instants.";
      }
    }

    return "Désolé, je n'ai pas pu obtenir de réponse après plusieurs tentatives. Veuillez réessayer plus tard.";
  }
}
