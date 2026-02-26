import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import 'soldier.dart';

/// The shrinking battle-royale ring. Soldiers outside it take damage.
/// Accesses siblings via [parent] rather than [HasGameRef] to avoid
/// a circular-import chain through game_world → safe_zone → game.
class SafeZone extends Component {
  double radius;
  final Vector2 center;
  double _damageTimer = 0;

  SafeZone()
      : radius = GameConstants.initialSafeRadius,
        center = Vector2(
            GameConstants.worldWidth / 2, GameConstants.worldHeight / 2);

  bool get isFullyShrunk => radius < 30;

  @override
  void update(double dt) {
    if (!isFullyShrunk) {
      radius =
          math.max(30, radius - GameConstants.safeRadiusShrinkRate * dt);
    }

    _damageTimer += dt;
    if (_damageTimer >= 0.25) {
      _damageTimer = 0;
      _applyOutsideDamage(0.25);
    }
  }

  void _applyOutsideDamage(double elapsed) {
    if (parent == null) return;
    for (final comp in parent!.children) {
      if (comp is Soldier && comp.isAlive) {
        if (comp.position.distanceTo(center) > radius) {
          comp.takeDamage(GameConstants.safeZoneDps * elapsed);
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Danger fill – everything outside the circle
    final path = Path()
      ..addRect(Rect.fromLTWH(
          -GameConstants.worldWidth,
          -GameConstants.worldHeight,
          GameConstants.worldWidth * 3,
          GameConstants.worldHeight * 3))
      ..addOval(
          Rect.fromCircle(center: Offset(center.x, center.y), radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = GameConstants.dangerZone.withOpacity(0.18));

    // Edge glow
    canvas.drawCircle(
      Offset(center.x, center.y),
      radius,
      Paint()
        ..color = GameConstants.safeZoneEdge.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}
