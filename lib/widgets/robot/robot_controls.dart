// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'dart:math' as math;

class RobotControls extends StatefulWidget {
  final Function(String) onDirectionPressed;
  final VoidCallback onStopPressed;
  final VoidCallback? onCapturePressed;
  final bool showCaptureButton;

  const RobotControls({
    super.key,
    required this.onDirectionPressed,
    required this.onStopPressed,
    this.onCapturePressed,
    this.showCaptureButton = true,
  });

  @override
  State<RobotControls> createState() => _RobotControlsState();
}

class _RobotControlsState extends State<RobotControls> {
  String _currentDirection = '';

  void _handleJoystickMove(StickDragDetails details) {
    // Calculer la distance depuis le centre (0-1)
    final distance = math.sqrt(details.x * details.x + details.y * details.y);

    // Ne réagir que si le joystick est suffisamment déplacé
    if (distance < 0.3) {
      if (_currentDirection.isNotEmpty) {
        widget.onStopPressed();
        _currentDirection = '';
      }
      return;
    }

    // Calculer l'angle en degrés
    final degrees = math.atan2(details.y, details.x) * (180 / math.pi);

    // Convertir l'angle en direction (4 directions de base)
    String newDirection;
    if (degrees >= -45 && degrees < 45) {
      newDirection = 'right';
    } else if (degrees >= 45 && degrees < 135) {
      newDirection = 'backward';
    } else if (degrees >= 135 || degrees < -135) {
      newDirection = 'left';
    } else {
      newDirection = 'forward';
    }

    // N'envoyer la commande que si la direction a changé
    if (newDirection != _currentDirection) {
      _currentDirection = newDirection;
      if (newDirection == 'stop') {
        widget.onStopPressed();
      } else {
        widget.onDirectionPressed(_currentDirection);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Joystick
        Container(
          height: 150,
          width: 150,
          decoration: BoxDecoration(
            color: Colors.lightGreen.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Joystick(
            listener: _handleJoystickMove,
            onStickDragEnd: () {
              if (_currentDirection.isNotEmpty) {
                widget.onStopPressed();
                _currentDirection = '';
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        // Bouton Capture (affiché seulement si showCaptureButton est true)
        if (widget.showCaptureButton && widget.onCapturePressed != null)
          ElevatedButton.icon(
            onPressed: widget.onCapturePressed,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Détecter une maladie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
      ],
    );
  }
}
