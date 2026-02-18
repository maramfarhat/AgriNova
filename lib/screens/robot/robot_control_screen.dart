// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/robot_provider.dart';
import 'package:farm/widgets/robot/robot_controls.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'dart:math' as math;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class RobotControlScreen extends StatefulWidget {
  const RobotControlScreen({super.key});

  @override
  State<RobotControlScreen> createState() => _RobotControlScreenState();
}

class _RobotControlScreenState extends State<RobotControlScreen> {
  bool _isStreamingStarted = false;
  bool _isLoading = true;
  String? _error;
  final String _baseUrl = 'http://192.168.246.189:5000';
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
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
              _isStreamingStarted = true;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('Erreur WebView: ${error.description}');
            setState(() {
              _error = 'Erreur de chargement: ${error.description}';
              _isLoading = false;
              _isStreamingStarted = false;
            });
          },
        ),
      );

    // Charger immédiatement le flux vidéo
    _startVideoStream();
  }

  Future<void> _startVideoStream() async {
    try {
      print('Démarrage du flux vidéo: $_baseUrl/video_feed');
      await _controller.loadRequest(Uri.parse('$_baseUrl/video_feed'));

      // Démarrer la détection des maladies
      final response = await http.get(Uri.parse('$_baseUrl/start_detection'));
      if (response.statusCode == 200) {
        setState(() {
          _isStreamingStarted = true;
          _error = null;
        });

        // Démarrer la vérification des détections
        Provider.of<RobotProvider>(context, listen: false)
            .startDetectionPolling();
      } else {
        throw Exception('Erreur lors du démarrage de la détection');
      }
    } catch (e) {
      print('Erreur lors du démarrage du flux: $e');
      setState(() {
        _error = 'Erreur de connexion: $e';
        _isStreamingStarted = false;
      });
    }
  }

  Future<void> _stopVideoStream() async {
    try {
      // Arrêter la détection
      await http.get(Uri.parse('$_baseUrl/stop_detection'));

      // Arrêter la vérification des détections
      Provider.of<RobotProvider>(context, listen: false).stopDetectionPolling();

      setState(() {
        _isStreamingStarted = false;
        _error = null;
      });
    } catch (e) {
      print('Erreur lors de l\'arrêt du flux: $e');
      setState(() {
        _error = 'Erreur lors de l\'arrêt du flux: $e';
      });
    }
  }

  @override
  void dispose() {
    // Arrêter la détection lors de la fermeture de l'écran
    _stopVideoStream();
    super.dispose();
  }

  Future<void> _showImageSourceDialog(
      BuildContext context, RobotProvider provider) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Choisir la source',
            style: TextStyle(color: Colors.green),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.lightGreen),
                title: const Text('Prendre une photo'),
                tileColor: Colors.lightGreen.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  Navigator.pop(context);
                  provider.analyzeImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 20), // Plus d'espace entre les options
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Colors.lightGreen),
                title: const Text('Choisir depuis la galerie'),
                tileColor: Colors.lightGreen.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  Navigator.pop(context);
                  provider.analyzeImage(ImageSource.gallery);
                },
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: isLandscape
            ? null
            : AppBar(
                title: const Text('Robot Agricole'),
                backgroundColor: const Color(0xFF2E7D32),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Contrôle'),
                    Tab(text: 'Détections'),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                        _isStreamingStarted ? Icons.stop : Icons.play_arrow),
                    onPressed: () {
                      if (_isStreamingStarted) {
                        _stopVideoStream();
                      } else {
                        _startVideoStream();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _startVideoStream,
                  ),
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/disease-history'),
                  ),
                ],
              ),
        body: TabBarView(
          children: [
            // Onglet de contrôle
            OrientationBuilder(
              builder: (context, orientation) {
                final isLandscape = orientation == Orientation.landscape;
                if (isLandscape) {
                  return Stack(
                    children: [
                      // Flux vidéo en plein écran
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black,
                        child: Stack(
                          children: [
                            if (_isStreamingStarted)
                              WebViewWidget(controller: _controller),
                            if (_isLoading && !_isStreamingStarted)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.green,
                                ),
                              ),
                            if (!_isStreamingStarted && !_isLoading)
                              const Center(
                                child: Text(
                                  'En attente du flux vidéo...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            if (_error != null)
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _error!,
                                      style: TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _startVideoStream,
                                      child: Text('Réessayer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Joystick en overlay
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Consumer<RobotProvider>(
                          builder: (context, provider, _) {
                            return RobotControls(
                              onDirectionPressed: provider.moveRobot,
                              onStopPressed: provider.stopRobot,
                              onCapturePressed:
                                  null, // Pas de bouton en paysage
                              showCaptureButton: false,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mode portrait
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Flux vidéo ESP32-CAM
                          Card(
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Flux vidéo en direct',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 240,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Stack(
                                    children: [
                                      if (_isStreamingStarted)
                                        WebViewWidget(controller: _controller),
                                      if (_isLoading && !_isStreamingStarted)
                                        const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.green,
                                          ),
                                        ),
                                      if (!_isStreamingStarted && !_isLoading)
                                        const Center(
                                          child: Text(
                                            'En attente du flux vidéo...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      if (_error != null)
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _error!,
                                                style: TextStyle(
                                                    color: Colors.red),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 16),
                                              ElevatedButton(
                                                onPressed: _startVideoStream,
                                                child: Text('Réessayer'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Contrôles
                          Consumer<RobotProvider>(
                            builder: (context, provider, _) {
                              return RobotControls(
                                onDirectionPressed: provider.moveRobot,
                                onStopPressed: provider.stopRobot,
                                onCapturePressed: () =>
                                    _showImageSourceDialog(context, provider),
                                showCaptureButton: true,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
            // Onglet des détections
            Consumer<RobotProvider>(
              builder: (context, provider, _) {
                if (provider.detections.isEmpty) {
                  return const Center(
                    child: Text('Aucune détection'),
                  );
                }
                return ListView.builder(
                  itemCount: provider.detections.length,
                  itemBuilder: (context, index) {
                    final detection = provider.detections[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: const Icon(Icons.bug_report),
                        title: Text(detection.diseaseName),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(detection.detectedAt),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
