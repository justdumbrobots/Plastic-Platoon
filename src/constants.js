const C = {
  // World
  WORLD_W: 3200,
  WORLD_H: 3200,

  // Player
  PLAYER_RADIUS: 20,
  PLAYER_SPEED: 180,
  PLAYER_MAX_HP: 100,
  PLAYER_COLOR: 0x3B7A3B,
  PLAYER_HIGHLIGHT: 0x52A852,

  // Enemy
  ENEMY_RADIUS: 20,
  ENEMY_SPEED: 130,
  ENEMY_MAX_HP: 80,
  ENEMY_COLOR: 0xB5895A,
  ENEMY_HIGHLIGHT: 0xCBA570,
  ENEMY_MAX_COUNT: 22,
  ENEMY_SPAWN_INTERVAL: 3500,
  ENEMY_DETECT_RANGE: 340,
  ENEMY_ATTACK_RANGE: 260,

  // Safe zone
  SAFE_INITIAL_RADIUS: 1400,
  SAFE_SHRINK_RATE: 14,   // px/s
  SAFE_DAMAGE: 8,          // HP/s
  SAFE_DAMAGE_INTERVAL: 250, // ms

  // Scrap
  SCRAP_RADIUS: 7,
  SCRAP_MAGNET_RANGE: 60,
  SCRAP_MAGNET_SPEED: 220,
  SCRAP_COLOR: 0xFFD700,

  // Recoil
  RECOIL_IMPULSE: 50,
  RECOIL_FRICTION: 9,

  // Dash
  DASH_IMPULSE: 560,
  DASH_COOLDOWN: 0.85,

  // Bullet
  BULLET_LIFETIME: 3000, // ms

  // Explosion
  EXPLOSION_RADIUS: 85,
  EXPLOSION_DURATION: 380, // ms

  // Gun tiers
  GUNS: [
    { name: 'PISTOL',   scraps: 0,   damage: 25, speed: 370, fireRate: 650,  bRadius: 4,  barrelW: 24, barrelH: 5,  zoom: 1.0,  color: 0xFFD700, explosive: false },
    { name: 'RIFLE',    scraps: 10,  damage: 35, speed: 500, fireRate: 400,  bRadius: 5,  barrelW: 34, barrelH: 6,  zoom: 0.88, color: 0xFF8C00, explosive: false },
    { name: 'MACH.GUN', scraps: 30,  damage: 18, speed: 530, fireRate: 120,  bRadius: 4,  barrelW: 42, barrelH: 7,  zoom: 0.76, color: 0xFF4500, explosive: false },
    { name: 'MINIGUN',  scraps: 60,  damage: 22, speed: 580, fireRate: 70,   bRadius: 5,  barrelW: 52, barrelH: 10, zoom: 0.64, color: 0xCC2200, explosive: false },
    { name: 'ROCKET',   scraps: 100, damage: 90, speed: 270, fireRate: 1100, bRadius: 10, barrelW: 56, barrelH: 14, zoom: 0.55, color: 0xFF00FF, explosive: true  },
  ],

  // Colors
  SAND_COLOR: 0xD6B882,
  SAND_LINE: 0xC8A870,
  BG_COLOR: 0x1A2A1A,
  SAFE_RING_COLOR: 0x00E676,
  DANGER_COLOR: 0xFF1744,
  DANGER_ALPHA: 0.18,
};
