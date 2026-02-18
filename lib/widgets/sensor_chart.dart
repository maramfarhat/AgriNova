import 'package:flutter/material.dart';

class SensorChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String selectedParameter;
  final Color lineColor;

  const SensorChart({
    super.key,
    required this.data,
    required this.selectedParameter,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 20, 20, 30),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: data.isEmpty
          ? const Center(child: Text('Aucune donnée disponible'))
          : CustomPaint(
              size: Size.infinite,
              painter: _ChartPainter(
                data: data,
                parameter: selectedParameter,
                lineColor: lineColor,
              ),
            ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final String parameter;
  final Color lineColor;

  _ChartPainter({
    required this.data,
    required this.parameter,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final points = <Offset>[];
    final timestamps = data.map((d) => d['timestamp'] as DateTime).toList();
    final values = data.map((d) => d[parameter] as double).toList();

    final minTime = timestamps.first.millisecondsSinceEpoch.toDouble();
    final maxTime = timestamps.last.millisecondsSinceEpoch.toDouble();
    final timeRange = maxTime - minTime;

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final valueRange = maxValue - minValue;

    // Dessiner les axes
    final axisPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    // Axe Y
    canvas.drawLine(
      Offset(0, 0),
      Offset(0, size.height),
      axisPaint,
    );

    // Axe X
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );

    // Dessiner les graduations de l'axe X
    final numTimeLabels = 4;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (var i = 0; i <= numTimeLabels; i++) {
      final x = (size.width * i) / numTimeLabels;
      final time = DateTime.fromMillisecondsSinceEpoch(
        (minTime + (timeRange * i) / numTimeLabels).round(),
      );

      // Dessiner le trait de graduation
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height + 5),
        axisPaint,
      );

      // Afficher l'heure
      final timeText = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      textPainter.text = TextSpan(
        text: timeText,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height + 8),
      );
    }

    // Dessiner la ligne des données
    for (var i = 0; i < data.length; i++) {
      final x = (timestamps[i].millisecondsSinceEpoch - minTime) /
          timeRange *
          size.width;
      final y = size.height -
          ((values[i] - minValue) /
              (valueRange == 0 ? 1 : valueRange) *
              size.height);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);

      // Dessiner les points
      final pointPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      for (var point in points) {
        canvas.drawCircle(point, 3, pointPaint);
      }
    }

    // Ajouter les valeurs min et max sur l'axe Y
    textPainter.text = TextSpan(
      text: maxValue.toStringAsFixed(1),
      style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width - 5, 0));

    textPainter.text = TextSpan(
      text: minValue.toStringAsFixed(1),
      style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width - 5, size.height - textPainter.height),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
