import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../plastic_platoon_game.dart';
import 'bullet.dart';
import 'plastic_scrap.dart';

// ---------------------------------------------------------------------------
// Helper – darken a colour by a factor (0 = black, 1 = original)
// ---------------------------------------------------------------------------
Color _darken(Color c, double factor) => Color.fromARGB(
      c.alpha,
      (c.red * factor).round(),
      (c.green * factor).round(),
      (c.blue * factor).round(),
    );

// ---------------------------------------------------------------------------
// Abstract base class shared by Player and Enemy
// ---------------------------------------------------------------------------
abstract class Soldier extends PositionComponent
    with HasGameRef<PlasticPlatoonGame>, CollisionCallbacks {
  // ── State ─────────────────────────────────────────────────────────────────
  double health;
  final double maxHealth;
  int scrapsCollected;
  bool isAlive = true;

  /// Facing direction in radians (0 = right, clockwise positive).
  double facingAngle = 0;

  final Color bodyColor;
  final Color bodyColorLight;

  // Internal
  double _fireTimer = 0;
  Vector2 _recoilVel = Vector2.zero();

  // ── Constructor ───────────────────────────────────────────────────────────
  Soldier({
    required super.position,
    required this.maxHealth,
    required this.bodyColor,
    required this.bodyColorLight,
    this.scrapsCollected = 0,
  })  : health = maxHealth,
        super(
          size: Vector2.all(GameConstants.playerRadius * 2),
          anchor: Anchor.center,
        );

  // ── Subclass contract ─────────────────────────────────────────────────────
  bool get isPlayer;

  // ── Derived properties ────────────────────────────────────────────────────
  GunTier get tier => GunTier.fromScraps(scrapsCollected);

  // ── Flame lifecycle ───────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: GameConstants.playerRadius));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;

    if (_fireTimer > 0) _fireTimer -= dt;

    // Recoil impulse decays quickly (exponential friction)
    if (_recoilVel.length > 0.5) {
      position += _recoilVel * dt;
      _recoilVel -= _recoilVel * math.min(1.0, dt * 9);
    } else {
      _recoilVel.setZero();
    }

    _clampToWorld();
  }

  // ── Shared actions ────────────────────────────────────────────────────────

  /// Attempts to fire toward [direction]. Returns true if a shot was fired.
  bool tryFire(Vector2 direction) {
    if (_fireTimer > 0 || !isAlive || direction.length2 < 0.01) return false;
    final t = tier;
    _fireTimer = t.fireInterval;

    final dir = direction.normalized();
    facingAngle = math.atan2(dir.y, dir.x);

    final tipPos =
        position + dir * (GameConstants.playerRadius + t.barrelLength);
    gameRef.gameWorld.add(Bullet(
      position: tipPos,
      velocity: dir * t.bulletSpeed,
      damage: t.bulletDamage,
      fromPlayer: isPlayer,
      radius: t.bulletRadius,
      color: t.bulletColor,
      trailColor: t.bulletTrail,
      explosive: t.explosive,
    ));

    // Recoil-dash backwards
    _recoilVel += -dir * 110;
    return true;
  }

  void takeDamage(double amount) {
    if (!isAlive) return;
    health = (health - amount).clamp(0, maxHealth);
    if (health == 0) die();
  }

  void heal(double amount) {
    health = (health + amount).clamp(0, maxHealth);
  }

  void die() {
    if (!isAlive) return;
    isAlive = false;
    _dropScraps();
    onDeath();
    removeFromParent();
  }

  /// Override to react to death (e.g., player triggers game-over).
  void onDeath() {}

  // ── Internal helpers ──────────────────────────────────────────────────────

  void _clampToWorld() {
    const r = GameConstants.playerRadius;
    position.x = position.x.clamp(r, GameConstants.worldWidth - r);
    position.y = position.y.clamp(r, GameConstants.worldHeight - r);
  }

  void _dropScraps() {
    final rng = math.Random();
    final count = math.min(8, math.max(1, scrapsCollected ~/ 4));
    for (int i = 0; i < count; i++) {
      gameRef.gameWorld.add(PlasticScrap(
        position: position +
            Vector2(
              rng.nextDouble() * 90 - 45,
              rng.nextDouble() * 90 - 45,
            ),
        value: rng.nextInt(3) + 1,
      ));
    }
  }

  // ── Rendering ─────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (!isAlive) return;

    final t = tier;
    const r = GameConstants.playerRadius;
    const cx = r, cy = r; // local-space centre
    final dark = _darken(bodyColor, 0.68);

    // ── Barrel ────────────────────────────────────────────────────────────
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(facingAngle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r - 4, -t.barrelWidth / 2, t.barrelLength, t.barrelWidth),
        const Radius.circular(2),
      ),
      Paint()..color = dark,
    );
    // Barrel-tip cap
    canvas.drawCircle(
      Offset(r - 4 + t.barrelLength, 0),
      t.barrelWidth / 2,
      Paint()..color = Colors.black45,
    );
    canvas.restore();

    // ── Body shadow ───────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx + 2, cy + 4),
      r,
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ── Body fill ─────────────────────────────────────────────────────────
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = bodyColor);

    // ── Body rim ──────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ── Helmet highlight ──────────────────────────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(cx - r * 0.2, cy - r * 0.2), radius: r * 0.55),
      -math.pi * 0.85,
      math.pi * 0.65,
      false,
      Paint()
        ..color = bodyColorLight.withOpacity(0.35)
        ..style = PaintingStyle.fill,
    );

    // ── Health bar ────────────────────────────────────────────────────────
    _renderHealthBar(canvas, cx, cy, r);
  }

  void _renderHealthBar(Canvas canvas, double cx, double cy, double r) {
    const bw = 40.0, bh = 5.0;
    final by = -r - 10.0;
    final ratio = (health / maxHealth).clamp(0.0, 1.0);
    final hpCol = ratio > 0.6
        ? const Color(0xFF66BB6A)
        : ratio > 0.3
            ? const Color(0xFFFFA726)
            : const Color(0xFFEF5350);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - bw / 2, by, bw, bh), const Radius.circular(2)),
      Paint()..color = Colors.black54,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - bw / 2, by, bw * ratio, bh),
          const Radius.circular(2)),
      Paint()..color = hpCol,
    );
  }
}
