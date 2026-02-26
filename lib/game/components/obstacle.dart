import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

enum ObstacleType { sodaCan, toyBlock, pencil }

/// Static cover objects on the battlefield (soda cans, toy blocks, pencils).
/// Bullets are destroyed when they hit an obstacle; soldiers cannot pass through.
class Obstacle extends PositionComponent with CollisionCallbacks {
  final ObstacleType type;
  final Color _color;

  Obstacle._({
    required super.position,
    required super.size,
    required super.angle,
    required this.type,
    required Color color,
    super.anchor = Anchor.center,
  }) : _color = color;

  // ── Factories ──────────────────────────────────────────────────────────────

  factory Obstacle.sodaCan({required Vector2 position}) {
    return Obstacle._(
      position: position,
      size: Vector2(28, 50),
      angle: 0,
      type: ObstacleType.sodaCan,
      color: const Color(0xFFCC3333),
    );
  }

  factory Obstacle.toyBlock(
      {required Vector2 position, required Vector2 blockSize}) {
    return Obstacle._(
      position: position,
      size: blockSize,
      angle: 0,
      type: ObstacleType.toyBlock,
      color: const Color(0xFF5B9BD5),
    );
  }

  factory Obstacle.pencil({required Vector2 position, double rotation = 0}) {
    return Obstacle._(
      position: position,
      size: Vector2(120, 10),
      angle: rotation,
      type: ObstacleType.pencil,
      color: const Color(0xFFFFD700),
    );
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  // ── Rendering ─────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    switch (type) {
      case ObstacleType.sodaCan:
        _renderSodaCan(canvas);
      case ObstacleType.toyBlock:
        _renderToyBlock(canvas);
      case ObstacleType.pencil:
        _renderPencil(canvas);
    }
  }

  void _renderSodaCan(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Can body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h),
          Radius.circular(w / 2)),
      Paint()..color = _color,
    );
    // Label stripe
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.3, w, h * 0.4),
      Paint()..color = Colors.white.withOpacity(0.2),
    );
    // Top rim
    canvas.drawOval(
      Rect.fromLTWH(0, 0, w, w * 0.35),
      Paint()..color = const Color(0xFFAAAAAA),
    );
    // Shadow
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _renderToyBlock(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final dark = Color.fromARGB(
      _color.alpha,
      (_color.red * 0.65).round(),
      (_color.green * 0.65).round(),
      (_color.blue * 0.65).round(),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h),
          const Radius.circular(4)),
      Paint()..color = _color,
    );
    // Top face highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(4, 4, w - 8, h * 0.4), const Radius.circular(3)),
      Paint()..color = Colors.white.withOpacity(0.15),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h),
          const Radius.circular(4)),
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _renderPencil(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    // Body
    canvas.drawRect(Rect.fromLTWH(h, 0, w - h * 2, h),
        Paint()..color = _color);
    // Tip
    final tipPath = Path()
      ..moveTo(0, h / 2)
      ..lineTo(h, 0)
      ..lineTo(h, h)
      ..close();
    canvas.drawPath(tipPath, Paint()..color = const Color(0xFFE8C060));
    // Eraser
    canvas.drawRect(
      Rect.fromLTWH(w - h, 0, h, h),
      Paint()..color = const Color(0xFFFF9090),
    );
    // Outline
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..color = Colors.black38
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
