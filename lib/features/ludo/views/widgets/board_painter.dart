import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/ludo_constants.dart';

/// Draws the static board: yards, track, home columns, start squares, stars and the centre.
class BoardPainter extends CustomPainter {
  const BoardPainter();

  static const _gridLine = Color(0xFFC7CCD6);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 15;
    final white = Paint()..color = Colors.white;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _gridLine;

    Rect cell(Offset o) => Rect.fromLTWH(o.dx * u, o.dy * u, u, u);

    canvas.drawRect(Offset.zero & size, white);

    // Yards
    for (var c = 0; c < 4; c++) {
      final o = kYardOrigin[c];
      canvas.drawRect(
        Rect.fromLTWH(o.dx * u, o.dy * u, 6 * u, 6 * u),
        Paint()..color = kColors[c],
      );
      final panel = RRect.fromRectAndRadius(
        Rect.fromLTWH((o.dx + 1) * u, (o.dy + 1) * u, 4 * u, 4 * u),
        Radius.circular(.6 * u),
      );
      canvas.drawRRect(panel, Paint()..color = Colors.white.withAlpha(60));
      canvas.drawRRect(
        panel,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withAlpha(90),
      );
      for (final dy in const [2, 4]) {
        for (final dx in const [2, 4]) {
          canvas.drawCircle(
            Offset((o.dx + dx) * u, (o.dy + dy) * u),
            .55 * u,
            Paint()..color = Colors.black.withAlpha(60),
          );
        }
      }
    }

    // Main track
    for (final p in kPath) {
      canvas.drawRect(cell(p), white);
      canvas.drawRect(cell(p), line);
    }

    // Home columns
    for (var c = 0; c < 4; c++) {
      for (final p in kHome[c]) {
        canvas.drawRect(cell(p), Paint()..color = kColors[c]);
        canvas.drawRect(cell(p), line);
      }
    }

    // Start squares (safe)
    for (var c = 0; c < 4; c++) {
      final p = kPath[kStart[c]];
      canvas.drawRect(cell(p), Paint()..color = kColors[c]);
      canvas.drawRect(cell(p), line);

      // Star box inner border
      canvas.drawRect(
        cell(p).deflate(u * 0.08),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withAlpha(180),
      );

      _drawVectorStar(
        canvas,
        Offset((p.dx + 0.5) * u, (p.dy + 0.5) * u),
        u * 0.32,
        Colors.white,
        fillColor: Colors.white,
      );
    }

    // Safe star boxes (8, 21, 34, 47)
    final starColors = [
      kColors[1], // index 8 (Yellow arm)
      kColors[2], // index 21 (Green arm)
      kColors[3], // index 34 (Red arm)
      kColors[0], // index 47 (Blue arm)
    ];

    for (var idx = 0; idx < kStarCells.length; idx++) {
      final cellIndex = kStarCells[idx];
      final p = kPath[cellIndex];
      final color = starColors[idx];

      // Star box tinted background & border
      canvas.drawRect(
        cell(p),
        Paint()..color = color.withAlpha(45),
      );
      canvas.drawRect(cell(p), line);

      canvas.drawRect(
        cell(p).deflate(u * 0.08),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withAlpha(160),
      );

      _drawVectorStar(
        canvas,
        Offset((p.dx + 0.5) * u, (p.dy + 0.5) * u),
        u * 0.32,
        color,
        fillColor: color,
        strokeColor: Colors.white,
      );
    }

    // Centre triangles (left = Blue, top = Yellow, right = Green, bottom = Red)
    final a = 6 * u, b = 9 * u, m = 7.5 * u;
    final tris = [
      [Offset(a, a), Offset(a, b), Offset(m, m)],
      [Offset(a, a), Offset(b, a), Offset(m, m)],
      [Offset(b, a), Offset(b, b), Offset(m, m)],
      [Offset(a, b), Offset(b, b), Offset(m, m)],
    ];
    for (var c = 0; c < 4; c++) {
      final path = Path()
        ..moveTo(tris[c][0].dx, tris[c][0].dy)
        ..lineTo(tris[c][1].dx, tris[c][1].dy)
        ..lineTo(tris[c][2].dx, tris[c][2].dy)
        ..close();
      canvas.drawPath(path, Paint()..color = kColors[c]);
    }
  }

  void _drawVectorStar(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    required Color fillColor,
    Color? strokeColor,
  }) {
    final path = Path();
    const points = 5;
    final outerRadius = radius;
    final innerRadius = radius * 0.45;
    final halfAngle = pi / points;
    var angle = -pi / 2;

    path.moveTo(
      center.dx + outerRadius * cos(angle),
      center.dy + outerRadius * sin(angle),
    );

    for (var i = 0; i < points; i++) {
      angle += halfAngle;
      path.lineTo(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );
      angle += halfAngle;
      path.lineTo(
        center.dx + outerRadius * cos(angle),
        center.dy + outerRadius * sin(angle),
      );
    }
    path.close();

    canvas.drawPath(path, Paint()..color = fillColor);
    if (strokeColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = strokeColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}