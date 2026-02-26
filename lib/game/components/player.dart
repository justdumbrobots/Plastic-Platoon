import 'dart:math' as math;

import 'package:flame/components.dart';

import '../constants.dart';
import '../plastic_platoon_game.dart';
import 'plastic_scrap.dart';
import 'soldier.dart';

/// The human-controlled soldier. Movement + aiming are driven by two
/// virtual joysticks managed by [PlasticPlatoonGame].
class Player extends Soldier {
  // Inputs – set each frame by the game from joystick deltas
  Vector2 moveInput = Vector2.zero();
  Vector2 aimInput = Vector2.zero();

  // Public so HUD can read it
  int kills = 0;

  Player({required super.position})
      : super(
          maxHealth: 100,
          bodyColor: GameConstants.playerGreen,
          bodyColorLight: GameConstants.playerGreenLight,
          scrapsCollected: 0,
        );

  @override
  bool get isPlayer => true;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;

    // ── Movement ────────────────────────────────────────────────────────────
    if (moveInput.length2 > 0.001) {
      position += moveInput.normalized() * GameConstants.baseSpeed * dt;

      // Face movement direction when not aiming
      if (aimInput.length2 < 0.01) {
        facingAngle = math.atan2(moveInput.y, moveInput.x);
      }
    }

    // ── Aim + auto-fire ─────────────────────────────────────────────────────
    if (aimInput.length2 > 0.01) {
      tryFire(aimInput);
    }

    // ── Camera follows player, zoom reflects gun tier ────────────────────────
    gameRef.cameraComponent.viewfinder.position = position;
    final targetZoom = tier.cameraZoom;
    final curZoom = gameRef.cameraComponent.viewfinder.zoom;
    gameRef.cameraComponent.viewfinder.zoom =
        curZoom + (targetZoom - curZoom) * math.min(1.0, dt * 2.5);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlasticScrap) {
      scrapsCollected += other.value;
      gameRef.onScrapsChanged(scrapsCollected);
      other.removeFromParent();
    }
  }

  @override
  void onDeath() {
    gameRef.onPlayerDied();
  }
}
