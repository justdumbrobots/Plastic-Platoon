import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../plastic_platoon_game.dart';
import 'obstacle.dart';
import 'plastic_scrap.dart';
import 'soldier.dart';

/// A projectile fired by a soldier. Handles collision, damage, and explosions.
class Bullet extends PositionComponent
    with HasGameRef<PlasticPlatoonGame>, CollisionCallbacks {
  final Vector2 velocity;
  final double damage;
  final bool fromPlayer;
  final double radius;
  final Color color;
  final Color trailColor;
  final bool explosive;

  bool _spent = false;
  double _lifetime = 3.0; // auto-remove after 3 seconds

  Bullet({
    required super.position,
    required this.velocity,
    required this.damage,
    required this.fromPlayer,
    required this.radius,
    required this.color,
    required this.trailColor,
    this.explosive = false,
  }) : super(
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: radius)..collisionType = CollisionType.active);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    _lifetime -= dt;

    // Out of world or timed out
    if (_lifetime <= 0 ||
        position.x < 0 ||
        position.x > GameConstants.worldWidth ||
        position.y < 0 ||
        position.y > GameConstants.worldHeight) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Trail
    final trailDir = -velocity.normalized();
    final trailLen = radius * 3.5;
    canvas.drawLine(
      Offset(radius, radius),
      Offset(radius + trailDir.x * trailLen, radius + trailDir.y * trailLen),
      Paint()
        ..color = trailColor
        ..strokeWidth = radius * 1.2
        ..strokeCap = StrokeCap.round,
    );

    // Core
    canvas.drawCircle(Offset(radius, radius), radius, Paint()..color = color);

    // Specular
    canvas.drawCircle(
      Offset(radius - radius * 0.3, radius - radius * 0.3),
      radius * 0.3,
      Paint()..color = Colors.white.withOpacity(0.5),
    );
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (_spent) return;

    if (other is Soldier) {
      // Player bullets hit enemies; enemy bullets hit the player.
      // (No friendly-fire between AI soldiers.)
      final shouldHit =
          (fromPlayer && !other.isPlayer) || (!fromPlayer && other.isPlayer);
      if (!shouldHit) return;

      _spent = true;
      other.takeDamage(damage);
      if (explosive) _explode();
      removeFromParent();
      return;
    }

    if (other is Obstacle) {
      _spent = true;
      if (explosive) _explode();
      removeFromParent();
    }
  }

  // ── Rocket explosion ──────────────────────────────────────────────────────

  void _explode() {
    const explosionRadius = 85.0;

    // Damage all soldiers in blast radius
    final soldiers =
        gameRef.gameWorld.children.whereType<Soldier>().toList();
    for (final s in soldiers) {
      final dist = position.distanceTo(s.position);
      if (dist < explosionRadius) {
        final falloff = 1 - (dist / explosionRadius);
        s.takeDamage(damage * falloff);
      }
    }

    // Scatter some bonus scraps from the explosion
    final rng = math.Random();
    for (int i = 0; i < 4; i++) {
      gameRef.gameWorld.add(PlasticScrap(
        position: position +
            Vector2(
              rng.nextDouble() * explosionRadius - explosionRadius / 2,
              rng.nextDouble() * explosionRadius - explosionRadius / 2,
            ),
        value: 1,
      ));
    }

    // Visual effect
    gameRef.gameWorld.add(_ExplosionEffect(position: position.clone()));
  }
}

// ---------------------------------------------------------------------------
// Short-lived visual-only explosion ring
// ---------------------------------------------------------------------------
class _ExplosionEffect extends PositionComponent {
  static const double _maxR = 85.0;
  static const double _dur = 0.38;
  double _t = 0;

  _ExplosionEffect({required super.position})
      : super(size: Vector2.all(_maxR * 2), anchor: Anchor.center);

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _dur) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = (_t / _dur).clamp(0.0, 1.0);
    final r = _maxR * progress;
    final opacity = 1 - progress;

    canvas.drawCircle(
      Offset(_maxR, _maxR),
      r,
      Paint()..color = Colors.orange.withOpacity(opacity * 0.5),
    );
    canvas.drawCircle(
      Offset(_maxR, _maxR),
      r * 0.5,
      Paint()..color = Colors.yellow.withOpacity(opacity * 0.7),
    );
    canvas.drawCircle(
      Offset(_maxR, _maxR),
      r,
      Paint()
        ..color = Colors.red.withOpacity(opacity * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}
