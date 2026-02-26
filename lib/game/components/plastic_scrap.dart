import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../plastic_platoon_game.dart';
import 'player.dart';

/// A collectible plastic scrap (dropped by dying soldiers or scattered on the map).
/// When the player gets within [GameConstants.scrapMagnetRadius] it flies toward them.
class PlasticScrap extends PositionComponent
    with HasGameRef<PlasticPlatoonGame>, CollisionCallbacks {
  final int value;
  static const double _radius = 7.0;
  double _bobTimer = 0;

  PlasticScrap({required super.position, this.value = 1})
      : super(
          size: Vector2.all(_radius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: _radius)..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bobTimer += dt;

    // Magnetic pull toward player
    final player = gameRef.player;
    if (!player.isAlive) return;
    final dist = position.distanceTo(player.position);
    if (dist < GameConstants.scrapMagnetRadius) {
      final dir = (player.position - position).normalized();
      position += dir * GameConstants.scrapMagnetSpeed * dt;
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      other.scrapsCollected += value;
      gameRef.onScrapsChanged(other.scrapsCollected);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Gentle vertical bob
    final bob = math.sin(_bobTimer * 3) * 1.5;
    const cx = _radius;
    final cy = _radius + bob;

    // Glow
    canvas.drawCircle(
      Offset(cx, cy),
      _radius + 3,
      Paint()
        ..color = GameConstants.scrapColor.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Diamond body
    final path = Path();
    path.moveTo(cx, cy - _radius);
    path.lineTo(cx + _radius, cy);
    path.lineTo(cx, cy + _radius);
    path.lineTo(cx - _radius, cy);
    path.close();

    canvas.drawPath(path, Paint()..color = GameConstants.scrapColor);

    // Highlight facet
    final highlightPath = Path();
    highlightPath.moveTo(cx, cy - _radius);
    highlightPath.lineTo(cx + _radius, cy);
    highlightPath.lineTo(cx, cy);
    highlightPath.close();
    canvas.drawPath(
      highlightPath,
      Paint()..color = Colors.white.withOpacity(0.35),
    );

    // Value label (only for multi-value scraps)
    if (value > 1) {
      final textSpan = TextSpan(
        text: '+$value',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }
}
