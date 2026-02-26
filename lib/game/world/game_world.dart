import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../components/background.dart';
import '../components/obstacle.dart';
import '../components/safe_zone.dart';
import '../constants.dart';

/// The game world – all battlefield entities live here.
/// HasCollisionDetection must be on the World when using CameraComponent.
class GameWorld extends World with HasCollisionDetection {
  late SafeZone safeZone;

  @override
  Future<void> onLoad() async {
    // Tiled sand background
    add(BackgroundGrid());

    // Place procedurally-generated obstacles (cover objects)
    _spawnObstacles();

    // Shrinking danger ring
    safeZone = SafeZone();
    add(safeZone);
  }

  void _spawnObstacles() {
    final rng = math.Random(42); // deterministic seed for consistent layout
    const cx = GameConstants.worldWidth / 2;
    const cy = GameConstants.worldHeight / 2;

    // ── Soda cans ──
    for (int i = 0; i < 18; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = 200 + rng.nextDouble() * 1200;
      final pos = Vector2(
        cx + math.cos(angle) * dist,
        cy + math.sin(angle) * dist,
      );
      add(Obstacle.sodaCan(position: pos));
    }

    // ── Toy blocks ──
    for (int i = 0; i < 24; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = 100 + rng.nextDouble() * 1300;
      final pos = Vector2(
        cx + math.cos(angle) * dist,
        cy + math.sin(angle) * dist,
      );
      final size = Vector2(
        40 + rng.nextDouble() * 60,
        30 + rng.nextDouble() * 50,
      );
      add(Obstacle.toyBlock(position: pos, blockSize: size));
    }

    // ── Pencils (long thin barriers) ──
    for (int i = 0; i < 12; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = 150 + rng.nextDouble() * 1100;
      final pos = Vector2(
        cx + math.cos(angle) * dist,
        cy + math.sin(angle) * dist,
      );
      add(Obstacle.pencil(position: pos, rotation: rng.nextDouble() * math.pi));
    }
  }
}
