import 'dart:math' as math;

import 'package:flame/components.dart';

import '../constants.dart';
import '../plastic_platoon_game.dart';
import 'plastic_scrap.dart';
import 'soldier.dart';

enum _AiState { wander, chase, attack, flee }

/// AI-controlled enemy soldier with a simple FSM.
///
/// States:
///   wander  – random patrol when no player in range
///   chase   – move toward player when detected
///   attack  – stop and fire when in attack range
///   flee    – run away when health is critically low
class Enemy extends Soldier {
  static final _rng = math.Random();

  _AiState _state = _AiState.wander;
  double _stateTimer = 0; // time spent in current state
  Vector2 _wanderTarget = Vector2.zero();
  double _wanderCooldown = 0;

  // How long the enemy stays in attack stance before re-evaluating
  static const double _attackHoldTime = 0.6;

  Enemy({required super.position, int startScraps = 0})
      : super(
          maxHealth: 80,
          bodyColor: GameConstants.enemyTan,
          bodyColorLight: GameConstants.enemyTanLight,
          scrapsCollected: startScraps,
        ) {
    // Initial random facing
    facingAngle = _rng.nextDouble() * math.pi * 2;
    _pickWanderTarget();
  }

  @override
  bool get isPlayer => false;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;

    _stateTimer += dt;
    _wanderCooldown -= dt;

    final player = gameRef.player;
    if (!player.isAlive) {
      _setState(_AiState.wander);
      _doWander(dt);
      return;
    }

    final distToPlayer = position.distanceTo(player.position);
    final hpRatio = health / maxHealth;

    // ── State transitions ──────────────────────────────────────────────────
    if (hpRatio < 0.25 && _state != _AiState.flee) {
      _setState(_AiState.flee);
    } else if (_state == _AiState.flee && hpRatio > 0.4) {
      _setState(_AiState.wander);
    } else if (_state != _AiState.flee) {
      if (distToPlayer < GameConstants.enemyAttackRange) {
        if (_state != _AiState.attack) _setState(_AiState.attack);
      } else if (distToPlayer < GameConstants.enemyDetectRange) {
        if (_state != _AiState.chase) _setState(_AiState.chase);
      } else if (_state != _AiState.wander) {
        _setState(_AiState.wander);
      }
    }

    // ── Behaviour per state ────────────────────────────────────────────────
    switch (_state) {
      case _AiState.wander:
        _doWander(dt);
      case _AiState.chase:
        _doChase(dt, player.position);
      case _AiState.attack:
        _doAttack(dt, player.position);
      case _AiState.flee:
        _doFlee(dt, player.position);
    }
  }

  // ── Behaviours ──────────────────────────────────────────────────────────

  void _doWander(double dt) {
    if (_wanderCooldown <= 0 ||
        position.distanceTo(_wanderTarget) < 30) {
      _pickWanderTarget();
    }
    _moveToward(_wanderTarget, GameConstants.enemySpeed * 0.55, dt);
  }

  void _doChase(double dt, Vector2 target) {
    _moveToward(target, GameConstants.enemySpeed, dt);
  }

  void _doAttack(double dt, Vector2 target) {
    final dir = (target - position);
    if (dir.length2 > 0.01) {
      tryFire(dir);
    }
    // Strafe slightly to make enemy harder to hit
    if (_stateTimer > _attackHoldTime) {
      _stateTimer = 0;
      final strafe = Vector2(-dir.y, dir.x).normalized();
      final side = _rng.nextBool() ? 1.0 : -1.0;
      position +=
          strafe * side * GameConstants.enemySpeed * 0.4 * _attackHoldTime;
    }
  }

  void _doFlee(double dt, Vector2 threat) {
    final away = (position - threat);
    if (away.length2 > 0.01) {
      _moveToward(
          position + away.normalized() * 200, GameConstants.enemySpeed * 1.25, dt);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _moveToward(Vector2 target, double speed, double dt) {
    final dir = (target - position);
    if (dir.length2 < 1) return;
    final move = dir.normalized() * speed * dt;
    position += move;
    facingAngle = math.atan2(dir.y, dir.x);
  }

  void _setState(_AiState s) {
    _state = s;
    _stateTimer = 0;
  }

  void _pickWanderTarget() {
    _wanderTarget = Vector2(
      GameConstants.playerRadius +
          _rng.nextDouble() *
              (GameConstants.worldWidth - GameConstants.playerRadius * 2),
      GameConstants.playerRadius +
          _rng.nextDouble() *
              (GameConstants.worldHeight - GameConstants.playerRadius * 2),
    );
    _wanderCooldown = 3 + _rng.nextDouble() * 4;
  }

  @override
  void onDeath() {
    gameRef.onEnemyKilled();
    // Enemies also drop a guaranteed scrap cluster
    final rng = math.Random();
    for (int i = 0; i < 3; i++) {
      gameRef.gameWorld.add(PlasticScrap(
        position: position +
            Vector2(rng.nextDouble() * 60 - 30, rng.nextDouble() * 60 - 30),
        value: 2,
      ));
    }
  }
}
