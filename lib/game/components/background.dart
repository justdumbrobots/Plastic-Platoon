import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

/// Draws a sandy tiled floor with faint grid lines – the "sandbox" aesthetic.
class BackgroundGrid extends Component {
  static const double _tileSize = 80.0;

  @override
  void render(Canvas canvas) {
    // Sand base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, GameConstants.worldWidth, GameConstants.worldHeight),
      Paint()..color = GameConstants.groundSand,
    );

    // Subtle tile lines
    final linePaint = Paint()
      ..color = GameConstants.groundLine.withOpacity(0.35)
      ..strokeWidth = 1;

    for (double x = 0; x <= GameConstants.worldWidth; x += _tileSize) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, GameConstants.worldHeight), linePaint);
    }
    for (double y = 0; y <= GameConstants.worldHeight; y += _tileSize) {
      canvas.drawLine(
          Offset(0, y), Offset(GameConstants.worldWidth, y), linePaint);
    }

    // World border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, GameConstants.worldWidth, GameConstants.worldHeight),
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
  }
}
