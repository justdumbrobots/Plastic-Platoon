import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../plastic_platoon_game.dart';

/// In-game HUD: health bar, gun tier badge, scrap counter, kill count, minimap,
/// and safe-zone status. Rendered in screen (viewport) space.
class GameHud extends Component with HasGameRef<PlasticPlatoonGame> {
  // ── Internal state (updated by the game) ──────────────────────────────────
  int _scraps = 0;
  int _kills = 0;
  String _tierName = 'Pistol';
  int _nextTierScraps = 10;

  void update_scraps(int scraps) {
    _scraps = scraps;
    _tierName = GunTier.fromScraps(scraps).name;
    _nextTierScraps = GunTier.nextThreshold(scraps);
  }

  void update_kills(int kills) => _kills = kills;

  @override
  void render(Canvas canvas) {
    final size = gameRef.size;
    final player = gameRef.player;

    // ── Top-left: health bar ───────────────────────────────────────────────
    _drawHealthBar(canvas, player.health, player.maxHealth);

    // ── Top-center: gun tier badge ─────────────────────────────────────────
    _drawTierBadge(canvas, size);

    // ── Top-right: kill count ──────────────────────────────────────────────
    _drawKillCount(canvas, size);

    // ── Bottom-center: scrap progress bar ─────────────────────────────────
    _drawScrapBar(canvas, size);

    // ── Bottom-right: minimap ──────────────────────────────────────────────
    _drawMinimap(canvas, size, player);
  }

  // ── Health bar ────────────────────────────────────────────────────────────

  void _drawHealthBar(Canvas canvas, double hp, double maxHp) {
    const x = 16.0, y = 16.0, w = 160.0, h = 16.0;
    final ratio = (hp / maxHp).clamp(0.0, 1.0);
    final hpColor = ratio > 0.6
        ? const Color(0xFF66BB6A)
        : ratio > 0.3
            ? const Color(0xFFFFA726)
            : const Color(0xFFEF5350);

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(4)),
      Paint()..color = Colors.black54,
    );
    // Fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w * ratio, h), const Radius.circular(4)),
      Paint()..color = hpColor,
    );
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(4)),
      Paint()
        ..color = Colors.white30
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // Text
    _drawText(canvas, '${hp.toInt()} / ${maxHp.toInt()}',
        Offset(x + w / 2, y + h / 2), 10, Colors.white, FontWeight.bold,
        centered: true);

    // Label
    _drawText(canvas, 'HP', Offset(x - 24, y + h / 2 - 5), 9, Colors.white70,
        FontWeight.normal);
  }

  // ── Gun tier badge ────────────────────────────────────────────────────────

  void _drawTierBadge(Canvas canvas, Vector2 screenSize) {
    const w = 130.0, h = 32.0;
    final x = (screenSize.x - w) / 2;
    const y = 12.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(6)),
      Paint()..color = Colors.black.withOpacity(0.6),
    );
    _drawText(canvas, _tierName.toUpperCase(), Offset(x + w / 2, y + h / 2),
        11, const Color(0xFFFFD54F), FontWeight.bold,
        centered: true);
  }

  // ── Kill count ────────────────────────────────────────────────────────────

  void _drawKillCount(Canvas canvas, Vector2 screenSize) {
    const w = 80.0, h = 32.0;
    final x = screenSize.x - w - 16;
    const y = 12.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(6)),
      Paint()..color = Colors.black.withOpacity(0.6),
    );
    _drawText(canvas, '☠ $_kills', Offset(x + w / 2, y + h / 2), 13,
        Colors.redAccent, FontWeight.bold,
        centered: true);
  }

  // ── Scrap progress bar ────────────────────────────────────────────────────

  void _drawScrapBar(Canvas canvas, Vector2 screenSize) {
    const w = 220.0, h = 12.0;
    final x = (screenSize.x - w) / 2;
    final y = screenSize.y - 110.0; // above joystick area

    double ratio = 0;
    if (_nextTierScraps > 0) {
      final prevThreshold = _prevTierScraps();
      final range = _nextTierScraps - prevThreshold;
      ratio = (((_scraps - prevThreshold) / range)).clamp(0.0, 1.0);
    } else {
      ratio = 1.0; // max tier
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(3)),
      Paint()..color = Colors.black54,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w * ratio, h), const Radius.circular(3)),
      Paint()..color = GameConstants.scrapColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(3)),
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final label = _nextTierScraps > 0
        ? '$_scraps / $_nextTierScraps scraps'
        : '$_scraps scraps (MAX)';
    _drawText(canvas, label, Offset(x + w / 2, y - 8), 9, Colors.white70,
        FontWeight.normal,
        centered: true);
  }

  int _prevTierScraps() {
    int prev = 0;
    for (final t in GunTier.all) {
      if (t.scrapsRequired < _nextTierScraps) prev = t.scrapsRequired;
    }
    return prev;
  }

  // ── Minimap ───────────────────────────────────────────────────────────────

  void _drawMinimap(Canvas canvas, Vector2 screenSize, dynamic player) {
    const mapSize = 120.0;
    const margin = 12.0;
    final mapX = screenSize.x - mapSize - margin;
    final mapY = screenSize.y - mapSize - margin;
    const scale = mapSize / GameConstants.worldWidth;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(mapX, mapY, mapSize, mapSize), const Radius.circular(6)),
      Paint()..color = Colors.black.withOpacity(0.55),
    );

    // Safe zone ring on minimap
    final sz = gameRef.gameWorld.safeZone;
    final szCx = mapX + sz.center.x * scale;
    final szCy = mapY + sz.center.y * scale;
    final szR = sz.radius * scale;
    canvas.drawCircle(
      Offset(szCx, szCy),
      szR,
      Paint()
        ..color = GameConstants.safeZoneEdge.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Enemies on minimap
    for (final e in gameRef.enemies) {
      if (!e.isAlive) continue;
      canvas.drawCircle(
        Offset(mapX + e.position.x * scale, mapY + e.position.y * scale),
        2.5,
        Paint()..color = GameConstants.enemyTan,
      );
    }

    // Player dot
    canvas.drawCircle(
      Offset(
          mapX + player.position.x * scale, mapY + player.position.y * scale),
      3.5,
      Paint()..color = GameConstants.playerGreen,
    );

    // Minimap border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(mapX, mapY, mapSize, mapSize), const Radius.circular(6)),
      Paint()
        ..color = Colors.white30
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  // ── Text helper ───────────────────────────────────────────────────────────

  void _drawText(Canvas canvas, String text, Offset offset, double fontSize,
      Color color, FontWeight weight,
      {bool centered = false}) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
      ),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout();
    final pos = centered
        ? Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2)
        : offset;
    tp.paint(canvas, pos);
  }
}

