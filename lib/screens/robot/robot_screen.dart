// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/robot_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farm/screens/robot/disease_history_screen.dart';
import 'package:farm/models/plant_disease.dart';
import 'dart:io';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class RobotScreen extends StatefulWidget {
  const RobotScreen({super.key});

  @override
  State<RobotScreen> createState() => _RobotScreenState();
}

class _RobotScreenState extends State<RobotScreen> {
  bool _isStreamingStarted = false;
  bool _isLoading = true;
  String? _error;
  final String _baseUrl = 'http://192.168.246.189:5000';
  late final WebViewController _controller;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _checkServerStatus();
    // Vérifier périodiquement la connexion au serveur
    _reconnectTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_isStreamingStarted) {
        _checkServerStatus();
      }
    });
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/check_camera'));
      if (response.statusCode == 200) {
        print('Serveur et caméra accessibles');
        setState(() {
          _error = null;
        });
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur de connexion au serveur: $e');
      setState(() {
        _error =
            'Impossible de se connecter au serveur ou à la caméra. Vérifiez que tout est bien connecté.';
        _isStreamingStarted = false;
      });
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..loadRequest(
          Uri.parse('about:blank')) // Charger une page vide initialement
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Chargement du flux vidéo démarré: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print('Flux vidéo chargé avec succès: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print(
                'Erreur WebView détaillée: Code=${error.errorCode}, Description=${error.description}, URL=${error.url}');
            setState(() {
              _error =
                  'Erreur de chargement du flux vidéo: ${error.description}';
              _isLoading = false;
              _isStreamingStarted = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('$_baseUrl/video_feed'));
  }

  Future<void> _retryVideoStream() async {
    if (_isStreamingStarted) {
      print('Tentative de reconnexion au flux vidéo...');
      await Future.delayed(Duration(seconds: 2));
      _controller.loadRequest(Uri.parse('$_baseUrl/video_feed'));
    }
  }

  Future<void> _toggleStreaming() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/${_isStreamingStarted ? "stop_detection" : "start_detection"}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isStreamingStarted = !_isStreamingStarted;
          _error = null;
          if (_isStreamingStarted) {
            print('Chargement du flux vidéo à: $_baseUrl/video_feed');
            _controller.loadRequest(Uri.parse('$_baseUrl/video_feed'));

            // Recharger la page après un court délai si nécessaire
            Future.delayed(Duration(seconds: 1), () {
              if (_isStreamingStarted) {
                print('Rechargement du flux vidéo...');
                _controller.reload();
              }
            });
          }
        });
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors du toggle streaming: $e');
      setState(() {
        _error = 'Erreur de connexion au serveur: $e';
        _isStreamingStarted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Robot Agricole'),
          backgroundColor: const Color(0xFF2E7D32),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Contrôle'),
              Tab(text: 'Détections'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _checkServerStatus,
            ),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DiseaseHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Onglet Contrôle
            Consumer<RobotProvider>(
              builder: (context, robotProvider, child) {
                return Column(
                  children: [
                    // Titre du flux vidéo
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Flux vidéo en direct',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Zone de flux vidéo
                    Container(
                      height: 250,
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Stack(
                          children: [
                            if (_isStreamingStarted)
                              WebViewWidget(
                                controller: _controller,
                              ),
                            if (_isLoading)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            Center(
                              child: Text(
                                'Flux vidéo',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Boutons de contrôle
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _toggleStreaming,
                              icon: Icon(
                                _isStreamingStarted
                                    ? Icons.stop
                                    : Icons.play_arrow,
                                size: 28,
                              ),
                              label: Text(
                                _isStreamingStarted ? 'Arrêter' : 'Démarrer',
                                style: TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () => robotProvider
                                  .analyzeImage(ImageSource.camera),
                              icon: const Icon(
                                Icons.camera_alt,
                                size: 28,
                              ),
                              label: const Text(
                                'Détecter une maladie',
                                style: TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            // Onglet Détections
            Consumer<RobotProvider>(
              builder: (context, robotProvider, child) {
                if (robotProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (robotProvider.error != null) {
                  return Center(
                    child: Text(
                      robotProvider.error!,
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                } else if (robotProvider.lastDetectedDisease != null) {
                  return SingleChildScrollView(
                    child:
                        _buildDiseaseResult(robotProvider.lastDetectedDisease!),
                  );
                } else {
                  return Center(
                    child: Text('Aucune détection récente'),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseResult(PlantDisease disease) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maladie détectée: ${disease.diseaseName}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Type de plante: ${disease.plantType}'),
            const SizedBox(height: 8),
            Text(
                'Niveau de confiance: ${(disease.confidence * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Text('Description: ${disease.description}'),
            const SizedBox(height: 8),
            Text(
              'Solution recommandée:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(disease.solution),
            const SizedBox(height: 8),
            Text('Localisation: ${disease.location}'),
            if (disease.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(disease.imageUrl),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
