import 'package:flutter/foundation.dart';
import 'package:farm/services/chatbot_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AgribotProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final ChatbotService _chatbotService = ChatbotService();

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  AgribotProvider() {
    _messages.add(
      ChatMessage(
        text: 'Bonjour ! Je suis AgriBot 🌱\n\n'
            'Je peux vous aider avec :\n'
            '• 🌿 Conseils de culture\n'
            '• 💧 Plans d\'arrosage\n'
            '• 🦠 Diagnostic des maladies\n'
            '• 🌍 Préparation du sol\n'
            '• 📅 Calendrier de plantation\n\n'
            'Comment puis-je vous aider aujourd\'hui ?',
        isUser: false,
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(text: text, isUser: true));
    notifyListeners();

    _isTyping = true;
    notifyListeners();

    try {
      // Convertir l'historique des messages au format attendu par l'API
      List<Map<String, dynamic>> conversationHistory = _messages
          .map((msg) => {
                "text": msg.text,
                "isUser": msg.isUser,
              })
          .toList();

      // Obtenir la réponse de l'API
      String response =
          await _chatbotService.getResponse(text, conversationHistory);

      _messages.add(ChatMessage(text: response, isUser: false));
    } catch (e) {
      // En cas d'erreur, utiliser une réponse de secours
      _messages.add(
        ChatMessage(
          text:
              "Désolé, je rencontre des difficultés techniques. Veuillez réessayer plus tard.",
          isUser: false,
        ),
      );
      debugPrint('Erreur lors de l\'envoi du message: $e');
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    _messages.add(
      ChatMessage(
        text: '🔄 Historique effacé.\n\n'
            'Je suis là pour vous aider avec :\n'
            '• 🌿 Conseils de culture\n'
            '• 💧 Plans d\'arrosage\n'
            '• 🦠 Diagnostic des maladies\n'
            '• 🌍 Préparation du sol\n'
            'Quelle est votre question ?',
        isUser: false,
      ),
    );
    notifyListeners();
  }
}
