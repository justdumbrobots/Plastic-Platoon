import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import 'components/enemy.dart';
import 'components/player.dart';
import 'components/plastic_scrap.dart';
import 'constants.dart';
import 'ui/hud.dart';
import 'world/game_world.dart';

// ---------------------------------------------------------------------------
// Overlay keys
// ---------------------------------------------------------------------------
const String kGameOverOverlay = 'game_over';
const String kPauseOverlay = 'pause';

/// Main [FlameGame] class – wires together the world, camera, UI, and game loop.
class PlasticPlatoonGame extends FlameGame {
  // ── Sub-systems ───────────────────────────────────────────────────────────
  late GameWorld gameWorld;
  late CameraComponent cameraComponent;
  late Player player;
  late GameHud hud;

  // Joystick components (added to camera viewport so they're in screen space)
  late JoystickComponent _moveJoystick;
  late JoystickComponent _aimJoystick;

  // ── Game state ────────────────────────────────────────────────────────────
  bool _gameOver = false;
  int _kills = 0;
  double _enemySpawnTimer = 0;
  final List<Enemy> _enemies = [];

  List<Enemy> get enemies => List.unmodifiable(_enemies);
  int get killCount => _kills;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Color backgroundColor() => GameConstants.groundSand;

  @override
  Future<void> onLoad() async {
    // ── World ────────────────────────────────────────────────────────────────
    gameWorld = GameWorld();

    // ── Camera ────────────────────────────────────────────────────────────────
    cameraComponent = CameraComponent(world: gameWorld)
      ..viewfinder.anchor = Anchor.center
      ..viewfinder.zoom = 1.0;

    addAll([gameWorld, cameraComponent]);

    // ── Player ────────────────────────────────────────────────────────────────
    player = Player(
      position:
          Vector2(GameConstants.worldWidth / 2, GameConstants.worldHeight / 2),
    );
    gameWorld.add(player);
    cameraComponent.viewfinder.position = player.position;

    // ── Scatter a few scraps at the start ─────────────────────────────────────
    _scatterStartingScraps();

    // ── Joysticks (screen space – added to viewport) ───────────────────────────
    _setupJoysticks();

    // ── HUD ───────────────────────────────────────────────────────────────────
    hud = GameHud();
    cameraComponent.viewport.add(hud);

    // ── Initial enemies ───────────────────────────────────────────────────────
    for (int i = 0; i < 8; i++) {
      _spawnEnemy();
    }
  }

  // ── Per-frame update ──────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver) return;

    // Relay joystick input to player
    player.moveInput = _moveJoystick.relativeDelta;
    player.aimInput = _aimJoystick.relativeDelta;

    // Enemy spawning
    _enemySpawnTimer += dt;
    if (_enemySpawnTimer >= GameConstants.enemySpawnInterval &&
        _enemies.length < GameConstants.maxEnemies) {
      _enemySpawnTimer = 0;
      _spawnEnemy();
    }

    // Prune dead enemy references
    _enemies.removeWhere((e) => !e.isAlive || e.parent == null);
  }

  // ── Public callbacks (called by components) ───────────────────────────────

  void onScrapsChanged(int total) {
    hud.update_scraps(total);
  }

  void onEnemyKilled() {
    _kills++;
    hud.update_kills(_kills);
  }

  void onPlayerDied() {
    if (_gameOver) return;
    _gameOver = true;
    overlays.add(kGameOverOverlay);
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  void _setupJoysticks() {
    final knobPaint = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..style = PaintingStyle.fill;
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    _moveJoystick = JoystickComponent(
      knob: CircleComponent(radius: 28, paint: knobPaint),
      background: CircleComponent(radius: 62, paint: bgPaint),
      margin: const EdgeInsets.only(left: 56, bottom: 56),
    );

    _aimJoystick = JoystickComponent(
      knob: CircleComponent(
          radius: 28,
          paint: Paint()
            ..color = Colors.red.withOpacity(0.75)),
      background: CircleComponent(radius: 62, paint: bgPaint),
      margin: const EdgeInsets.only(right: 56, bottom: 56),
    );

    cameraComponent.viewport.addAll([_moveJoystick, _aimJoystick]);
  }

  void _spawnEnemy() {
    final rng = math.Random();
    // Spawn outside the player's immediate view (at least 400px away)
    Vector2 spawnPos;
    do {
      spawnPos = Vector2(
        GameConstants.playerRadius +
            rng.nextDouble() *
                (GameConstants.worldWidth - GameConstants.playerRadius * 2),
        GameConstants.playerRadius +
            rng.nextDouble() *
                (GameConstants.worldHeight - GameConstants.playerRadius * 2),
      );
    } while (spawnPos.distanceTo(player.position) < 400);

    final enemy = Enemy(
      position: spawnPos,
      startScraps: rng.nextInt(15),
    );
    gameWorld.add(enemy);
    _enemies.add(enemy);
  }

  void _scatterStartingScraps() {
    final rng = math.Random();
    final center =
        Vector2(GameConstants.worldWidth / 2, GameConstants.worldHeight / 2);
    for (int i = 0; i < 20; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = 60 + rng.nextDouble() * 200;
      gameWorld.add(PlasticScrap(
        position: center +
            Vector2(math.cos(angle) * dist, math.sin(angle) * dist),
        value: 1,
      ));
    }
  }

  /// Restart – clears every sub-system and re-runs [onLoad].
  void restart() {
    overlays.remove(kGameOverOverlay);
    _gameOver = false;
    _kills = 0;
    _enemySpawnTimer = 0;
    _enemies.clear();

    // Remove world and camera; onLoad will recreate them.
    removeWhere((c) => true);
    onLoad();
  }
}
