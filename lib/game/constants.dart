import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// World & physics
// ---------------------------------------------------------------------------
class GameConstants {
  static const double worldWidth = 3200;
  static const double worldHeight = 3200;
  static const double playerRadius = 20.0;
  static const double baseSpeed = 180.0;

  // Safe zone
  static const double initialSafeRadius = 1400.0;
  static const double safeRadiusShrinkRate = 14.0; // px per second
  static const double safeZoneDps = 8.0; // damage per second outside

  // Enemy AI
  static const int maxEnemies = 22;
  static const double enemySpawnInterval = 3.5;
  static const double enemyDetectRange = 340.0;
  static const double enemyAttackRange = 260.0;
  static const double enemySpeed = 130.0;

  // Scraps
  static const double scrapMagnetRadius = 60.0;
  static const double scrapMagnetSpeed = 220.0;

  // Colors – army-men "sandbox" palette
  static const Color groundSand = Color(0xFFD6B882);
  static const Color groundLine = Color(0xFFC8A870);
  static const Color playerGreen = Color(0xFF3B7A3B);
  static const Color playerGreenLight = Color(0xFF52A852);
  static const Color enemyTan = Color(0xFFB5895A);
  static const Color enemyTanLight = Color(0xFFCBA570);
  static const Color safeZoneEdge = Color(0xFF00E676);
  static const Color dangerZone = Color(0xFFFF1744);
  static const Color obstacleColor = Color(0xFF8B7355);
  static const Color scrapColor = Color(0xFFFFD700);
}

// ---------------------------------------------------------------------------
// Gun tier progression
// ---------------------------------------------------------------------------
class GunTier {
  final String name;
  final int scrapsRequired;
  final double bulletRadius;
  final double bulletSpeed;
  final double bulletDamage;
  final double fireInterval; // seconds between shots
  final double barrelLength;
  final double barrelWidth;
  final double cameraZoom; // <1 zooms out (player sees more)
  final bool explosive;
  final Color bulletColor;
  final Color bulletTrail;

  const GunTier({
    required this.name,
    required this.scrapsRequired,
    required this.bulletRadius,
    required this.bulletSpeed,
    required this.bulletDamage,
    required this.fireInterval,
    required this.barrelLength,
    required this.barrelWidth,
    required this.cameraZoom,
    this.explosive = false,
    required this.bulletColor,
    required this.bulletTrail,
  });

  // ── Tier list ─────────────────────────────────────────────────────────────
  static const List<GunTier> all = [
    GunTier(
      name: 'Pistol',
      scrapsRequired: 0,
      bulletRadius: 4,
      bulletSpeed: 370,
      bulletDamage: 25,
      fireInterval: 0.65,
      barrelLength: 24,
      barrelWidth: 5,
      cameraZoom: 1.0,
      bulletColor: Color(0xFFFFD54F),
      bulletTrail: Color(0x60FFD54F),
    ),
    GunTier(
      name: 'Rifle',
      scrapsRequired: 10,
      bulletRadius: 5,
      bulletSpeed: 500,
      bulletDamage: 35,
      fireInterval: 0.40,
      barrelLength: 34,
      barrelWidth: 6,
      cameraZoom: 0.88,
      bulletColor: Color(0xFFFF9800),
      bulletTrail: Color(0x60FF9800),
    ),
    GunTier(
      name: 'Machine Gun',
      scrapsRequired: 30,
      bulletRadius: 4,
      bulletSpeed: 530,
      bulletDamage: 18,
      fireInterval: 0.12,
      barrelLength: 42,
      barrelWidth: 7,
      cameraZoom: 0.76,
      bulletColor: Color(0xFFFF5722),
      bulletTrail: Color(0x60FF5722),
    ),
    GunTier(
      name: 'Minigun',
      scrapsRequired: 60,
      bulletRadius: 5,
      bulletSpeed: 580,
      bulletDamage: 22,
      fireInterval: 0.07,
      barrelLength: 52,
      barrelWidth: 10,
      cameraZoom: 0.64,
      bulletColor: Color(0xFFF44336),
      bulletTrail: Color(0x60F44336),
    ),
    GunTier(
      name: 'Rocket Launcher',
      scrapsRequired: 100,
      bulletRadius: 10,
      bulletSpeed: 270,
      bulletDamage: 90,
      fireInterval: 1.1,
      barrelLength: 56,
      barrelWidth: 14,
      cameraZoom: 0.55,
      explosive: true,
      bulletColor: Color(0xFFE91E63),
      bulletTrail: Color(0x60E91E63),
    ),
  ];

  static GunTier fromScraps(int scraps) {
    GunTier result = all.first;
    for (final t in all) {
      if (scraps >= t.scrapsRequired) result = t;
    }
    return result;
  }

  /// Returns the scraps threshold for the next tier, or -1 if already maxed.
  static int nextThreshold(int scraps) {
    for (final t in all) {
      if (t.scrapsRequired > scraps) return t.scrapsRequired;
    }
    return -1;
  }
}
