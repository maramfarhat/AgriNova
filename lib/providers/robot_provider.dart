import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:farm/models/plant_disease.dart';
import 'package:sqflite/sqflite.dart';
import 'package:farm/services/database_service.dart';
import 'package:farm/services/ai_service.dart';
import 'package:farm/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class RobotProvider with ChangeNotifier {
  final DatabaseService _databaseService;
  final AIService _aiService;
  final String _robotIp = '192.168.246.189'; // IP de pc
  final String _wsServerIp = '192.168.246.189'; // IP dl'ESP32
  // IP du serveur WebSocket
  final int _wsServerPort = 3000;
  WebSocketChannel? _channel;
  bool _isConnected = false;
  final bool _isStreaming = false;
  String? _streamUrl;
  PlantDisease? _lastDetectedDisease;
  PlantDisease? _lastDeletedDisease; // Pour la fonctionnalité d'annulation
  bool _isMoving = false;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _error;
  List<PlantDisease> _diseases = [];
  Timer? _detectionTimer;
  PlantDisease? _currentDetection;

  RobotProvider(this._databaseService) : _aiService = AIService() {
    _initializeDatabase();
    _loadDetections();
    _connectWebSocket();
  }

  bool get isConnected => _isConnected;
  bool get isStreaming => _isStreaming;
  String? get streamUrl => _streamUrl;
  PlantDisease? get lastDetectedDisease => _lastDetectedDisease;
  bool get isMoving => _isMoving;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PlantDisease> get detections => _diseases;

  Future<void> _loadDetections() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'plant_diseases',
        orderBy: 'timestamp DESC',
      );

      _diseases = maps.map((map) => PlantDisease.fromJson(map)).toList();
      print('📱 ${_diseases.length} détections chargées de la base de données');
      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors du chargement des détections: $e');
      _diseases = [];
      notifyListeners();
    }
  }

  Future<void> _initializeDatabase() async {
    final db = await _databaseService.database;

    // Vérifier si la table existe déjà
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='plant_diseases'");

    if (tables.isEmpty) {
      // Créer la table uniquement si elle n'existe pas
      await db.execute('''
        CREATE TABLE plant_diseases (
          id TEXT PRIMARY KEY,
          diseaseName TEXT NOT NULL,
          confidence REAL NOT NULL,
          imageUrl TEXT NOT NULL,
          solution TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          detectedAt TEXT NOT NULL,
          plantType TEXT NOT NULL,
          description TEXT NOT NULL,
          location TEXT NOT NULL,
          imageBytes TEXT
        )
      ''');
      print('✅ Nouvelle table plant_diseases créée');
    } else {
      print('✅ Table plant_diseases existe déjà');
    }

    // Charger les détections existantes
    await _loadDetections();
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://$_wsServerIp:$_wsServerPort'),
      );

      _channel!.stream.listen(
        (message) {
          print('Message reçu du serveur: $message');
        },
        onError: (error) {
          print('Erreur WebSocket: $error');
          _isConnected = false;
          notifyListeners();
          // Tentative de reconnexion après 5 secondes
          Future.delayed(const Duration(seconds: 5), _connectWebSocket);
        },
        onDone: () {
          print('Connexion WebSocket fermée');
          _isConnected = false;
          notifyListeners();
          // Tentative de reconnexion après 5 secondes
          Future.delayed(const Duration(seconds: 5), _connectWebSocket);
        },
      );

      _isConnected = true;
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la connexion WebSocket: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  Future<void> moveRobot(String direction) async {
    if (!_isConnected || _channel == null) return;

    try {
      _isMoving = true;
      notifyListeners();

      // Convertir la direction en coordonnées x,y pour le joystick
      Map<String, int> coordinates = _getCoordinatesFromDirection(direction);

      // Envoyer les coordonnées au serveur WebSocket dans le format attendu par l'Arduino
      _channel!.sink.add('x:${coordinates['x']},y:${coordinates['y']}');

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Erreur de mouvement du robot: $e');
    } finally {
      _isMoving = false;
      notifyListeners();
    }
  }

  Map<String, int> _getCoordinatesFromDirection(String direction) {
    switch (direction) {
      case 'forward':
        return {'x': 0, 'y': 100};
      case 'backward':
        return {'x': 0, 'y': -100};
      case 'left':
        return {'x': -100, 'y': 0};
      case 'right':
        return {'x': 100, 'y': 0};
      default:
        return {'x': 0, 'y': 0};
    }
  }

  Future<void> stopRobot() async {
    if (!_isConnected || _channel == null) return;

    try {
      // Envoyer les coordonnées (0,0) pour arrêter le robot dans le format attendu par l'Arduino
      _channel!.sink.add('x:0,y:0');

      _isMoving = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur d\'arrêt du robot: $e');
    }
  }

  Future<void> analyzeImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        _isLoading = true;
        notifyListeners();

        // Envoyer l'image au serveur Flask pour analyse
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('http://$_robotIp:5000/analyze_image'),
        );

        // Ajouter l'image au formulaire
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            pickedFile.path,
          ),
        );

        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final result = json.decode(responseData);

        if (response.statusCode == 200 && result['status'] == 'detection') {
          print('Réponse du serveur: $result');

          _lastDetectedDisease = PlantDisease(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            diseaseName: result['name'],
            confidence: result['confidence'].toDouble(),
            solution: result['solution'],
            imageUrl: result['image'] != null
                ? 'http://$_robotIp:5000/${result['image']}'
                : '',
            timestamp: DateTime.now(),
            plantType: 'Plante',
            description:
                'Maladie détectée avec (Confiance: ${(result['confidence'] * 100).toStringAsFixed(1)}%)',
            location: 'Détection manuelle',
            detectedAt: DateTime.now(),
          );

          await _saveDiseaseDetection(_lastDetectedDisease!);
          await _loadDetections();
        } else {
          throw Exception('Erreur lors de l\'analyse: ${result['message']}');
        }

        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Erreur lors de l\'analyse de l\'image: $e');
      notifyListeners();
    }
  }

  Future<void> _saveDiseaseDetection(PlantDisease disease) async {
    try {
      final db = await _databaseService.database;

      print('💾 Sauvegarde d\'une nouvelle détection: ${disease.diseaseName}');
      print('📅 Date de détection: ${disease.detectedAt}');
      print('🖼️ URL de l\'image: ${disease.imageUrl}');

      // Vérifier si la détection existe déjà
      final existing = await db.query(
        'plant_diseases',
        where: 'id = ?',
        whereArgs: [disease.id],
      );

      if (existing.isEmpty) {
        // Insérer la nouvelle détection
        await db.insert(
          'plant_diseases',
          disease.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ Nouvelle détection sauvegardée avec succès');
      } else {
        print('ℹ️ Détection déjà existante, mise à jour ignorée');
      }

      // Recharger les détections
      await _loadDetections();
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de la détection: $e');
      print('❌ Détails de l\'erreur: ${e.toString()}');
    }
  }

  Future<List<PlantDisease>> getDiseaseHistory() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'plant_diseases',
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => PlantDisease.fromJson(map)).toList();
    } catch (e) {
      debugPrint('Erreur de récupération de l\'historique: $e');
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> deleteDiseaseFromHistory(String id) async {
    try {
      final db = await _databaseService.database;

      // Sauvegarder l'entrée supprimée pour une possible restauration
      _lastDeletedDisease = _diseases.firstWhere((disease) => disease.id == id);

      // Supprimer de la base de données
      await db.delete(
        'plant_diseases',
        where: 'id = ?',
        whereArgs: [id],
      );

      // Supprimer de la liste en mémoire
      _diseases.removeWhere((disease) => disease.id == id);

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'historique: $e');
      rethrow;
    }
  }

  Future<void> restoreDeletedDisease() async {
    if (_lastDeletedDisease != null) {
      try {
        final db = await _databaseService.database;

        // Réinsérer dans la base de données
        await db.insert(
          'plant_diseases',
          _lastDeletedDisease!.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Réinsérer dans la liste en mémoire
        _diseases.add(_lastDeletedDisease!);

        // Réinitialiser la sauvegarde
        _lastDeletedDisease = null;

        notifyListeners();
      } catch (e) {
        debugPrint('Erreur lors de la restauration de l\'historique: $e');
        rethrow;
      }
    }
  }

  void startDetectionPolling() {
    _detectionTimer?.cancel();

    _detectionTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final response = await http
            .get(Uri.parse('http://$_robotIp:5000/current_detection'))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('Réponse du serveur: $data');

          if (data['status'] == 'detection') {
            // Construire l'URL complète de l'image
            String imageUrl = '';
            if (data['image'] != null && data['image'].toString().isNotEmpty) {
              imageUrl = 'http://$_robotIp:5000/${data['image']}';
              print('URL de l\'image construite: $imageUrl');
            }

            // Créer une nouvelle détection
            final detection = PlantDisease(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              diseaseName: data['name'],
              confidence: data['confidence'].toDouble(),
              solution: data['solution'],
              imageUrl: imageUrl,
              timestamp: DateTime.parse(data['timestamp']),
              plantType: 'Plante',
              description:
                  'Maladie détectée en temps réel avec (Confiance: ${(data['confidence'] * 100).toStringAsFixed(1)}%)',
              location: 'Détection automatique',
              detectedAt: DateTime.now(),
            );

            // Vérifier si c'est une nouvelle détection
            final bool isNewDetection = _currentDetection == null ||
                _currentDetection!.diseaseName != detection.diseaseName ||
                _currentDetection!.timestamp != detection.timestamp;

            if (isNewDetection) {
              print('Nouvelle détection: ${detection.diseaseName}');
              print('URL de l\'image: ${detection.imageUrl}');

              // Vérifier si l'image est accessible
              if (detection.imageUrl.isNotEmpty) {
                try {
                  final imageResponse =
                      await http.head(Uri.parse(detection.imageUrl));
                  if (imageResponse.statusCode != 200) {
                    print(
                        '❌ L\'image n\'est pas accessible: ${detection.imageUrl}');
                  } else {
                    print('✅ Image accessible: ${detection.imageUrl}');
                  }
                } catch (e) {
                  print('❌ Erreur lors de la vérification de l\'image: $e');
                }
              }

              _currentDetection = detection;
              _lastDetectedDisease = detection;

              // Sauvegarder dans l'historique
              await _saveDiseaseDetection(detection);
              await _loadDetections();

              notifyListeners();
            }
          } else {
            // Pas de détection active
            if (_currentDetection != null) {
              _currentDetection = null;
              notifyListeners();
            }
          }
        }
      } on TimeoutException {
        print('Timeout lors de la vérification des détections');
      } on SocketException catch (e) {
        print('Erreur de connexion au serveur: $e');
        await Future.delayed(const Duration(seconds: 5));
      } catch (e) {
        print('Erreur lors de la vérification des détections: $e');
      }
    });
  }

  void stopDetectionPolling() {
    _detectionTimer?.cancel();
    _detectionTimer = null;
    _currentDetection = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _detectionTimer?.cancel();
    super.dispose();
  }
}
