// ─────────────────────────────────────────────────────────────
//  Utility helpers
// ─────────────────────────────────────────────────────────────
function hexToRgb(hex) {
  return { r: (hex >> 16) & 0xff, g: (hex >> 8) & 0xff, b: hex & 0xff };
}
function lerpColor(a, b, t) {
  const ca = hexToRgb(a), cb = hexToRgb(b);
  const r = Math.round(ca.r + (cb.r - ca.r) * t);
  const g = Math.round(ca.g + (cb.g - ca.g) * t);
  const bl = Math.round(ca.b + (cb.b - ca.b) * t);
  return (r << 16) | (g << 8) | bl;
}

// ─────────────────────────────────────────────────────────────
//  GameScene
// ─────────────────────────────────────────────────────────────
class GameScene extends Phaser.Scene {
  constructor() { super('GameScene'); }

  // ── init ──────────────────────────────────────────────────
  init() {
    this.scraps      = 0;
    this.kills       = 0;
    this.tierIndex   = 0;
    this.gameOver    = false;
    this.enemies     = [];
    this.bullets     = [];
    this.scrapsGroup = [];
    this.obstacles   = [];
    this.explosions  = [];
    this._safeTimer  = 0;
    this._spawnTimer = 0;
    this._fireTimer  = 0;
    this._aimAngle   = 0;
    this._recoilVx   = 0;
    this._recoilVy   = 0;
  }

  // ── create ────────────────────────────────────────────────
  create() {
    try {
      this._createInner();
    } catch (err) {
      console.error('GameScene create() crashed:', err);
      // Stop update() from running (this.player may be undefined)
      this.gameOver = true;
      this.add.text(20, 20,
        'GAME FAILED TO START\n\n' + String(err) + '\n\n' + (err.stack || ''),
        { fontSize: '13px', fontFamily: 'monospace', fill: '#ff4444',
          backgroundColor: '#000000e0', padding: { x: 10, y: 10 },
          wordWrap: { width: this.scale.width - 40 } }
      );
    }
  }

  _createInner() {
    const WW = C.WORLD_W, WH = C.WORLD_H;
    const cx = WW / 2, cy = WH / 2;

    // Background
    this._drawBackground();

    // Obstacles
    this._spawnObstacles();

    // Safe zone graphics (ring only — no geometry mask needed)
    this.safeGfx    = this.add.graphics().setDepth(6);
    this.safeRadius = C.SAFE_INITIAL_RADIUS;
    this.safeCx     = cx;
    this.safeCy     = cy;

    // Scrap container
    this.scrapContainer = this.add.container(0, 0).setDepth(10);

    // Bullet container
    this.bulletContainer = this.add.container(0, 0).setDepth(15);

    // Player
    this._createPlayer(cx, cy);

    // Spawn initial scraps
    for (let i = 0; i < 20; i++) this._spawnScrap(cx, cy, 60, 260, 1);

    // Spawn initial enemies
    for (let i = 0; i < 8; i++) {
      const angle = Math.random() * Math.PI * 2;
      const dist  = 400 + Math.random() * 600;
      this._spawnEnemy(cx + Math.cos(angle) * dist, cy + Math.sin(angle) * dist);
    }

    // Camera — center immediately on player so first frame isn't blank
    this.cameras.main.setZoom(1.0);
    this.cameras.main.setBounds(0, 0, WW, WH);
    this.cameras.main.centerOn(cx, cy);
    this.cameras.main.startFollow(this.player.container, true, 0.08, 0.08);

    // Input
    this._setupInput();

    // Safe zone damage timer
    this.time.addEvent({
      delay: C.SAFE_DAMAGE_INTERVAL,
      loop: true,
      callback: this._applyZoneDamage,
      callbackScope: this,
    });

    // Launch HUD after everything is ready
    this.scene.launch('HUDScene');
    this._notifyHUD();
  }

  // ── update ────────────────────────────────────────────────
  update(time, delta) {
    if (this.gameOver) return;
    const dt = delta / 1000;

    this._updatePlayer(dt);
    this._updateEnemies(dt);
    this._updateBullets(dt);
    this._updateScraps(dt);
    this._updateSafeZone(dt);
    this._updateExplosions(dt);

    // Enemy spawn
    this._spawnTimer += delta;
    if (this._spawnTimer >= C.ENEMY_SPAWN_INTERVAL && this.enemies.length < C.ENEMY_MAX_COUNT) {
      this._spawnTimer = 0;
      const angle = Math.random() * Math.PI * 2;
      const dist  = 300 + Math.random() * 500;
      const px = this.player.container.x, py = this.player.container.y;
      this._spawnEnemy(px + Math.cos(angle) * dist, py + Math.sin(angle) * dist);
    }

    // Camera zoom toward target
    const targetZoom = C.GUNS[this.tierIndex].zoom;
    const curZoom    = this.cameras.main.zoom;
    this.cameras.main.setZoom(curZoom + (targetZoom - curZoom) * 0.04);
  }

  // ══════════════════════════════════════════════════════════
  //  BACKGROUND
  // ══════════════════════════════════════════════════════════
  _drawBackground() {
    const WW = C.WORLD_W, WH = C.WORLD_H;
    const bg = this.add.graphics().setDepth(0);
    // Sand fill
    bg.fillStyle(C.SAND_COLOR);
    bg.fillRect(0, 0, WW, WH);
    // Grid lines — lineBetween is the reliable one-call API
    bg.lineStyle(1, C.SAND_LINE, 0.35);
    const step = 80;
    for (let x = 0; x <= WW; x += step) bg.lineBetween(x, 0, x, WH);
    for (let y = 0; y <= WH; y += step) bg.lineBetween(0, y, WW, y);
    // Border
    bg.lineStyle(6, 0x000000, 1);
    bg.strokeRect(0, 0, WW, WH);
  }

  // ══════════════════════════════════════════════════════════
  //  OBSTACLES
  // ══════════════════════════════════════════════════════════
  _spawnObstacles() {
    // Seeded random using simple LCG
    let seed = 42;
    const rand = () => { seed = (seed * 1664525 + 1013904223) & 0xffffffff; return (seed >>> 0) / 0x100000000; };
    const cx = C.WORLD_W / 2, cy = C.WORLD_H / 2;

    const place = (type, count, minD, maxD) => {
      for (let i = 0; i < count; i++) {
        const a = rand() * Math.PI * 2;
        const d = minD + rand() * (maxD - minD);
        this._makeObstacle(type, cx + Math.cos(a) * d, cy + Math.sin(a) * d, rand);
      }
    };
    place('can',    18, 200, 1200);
    place('block',  24, 100, 1300);
    place('pencil', 12, 150, 1100);
  }

  _makeObstacle(type, x, y, rand) {
    const gfx = this.add.graphics().setDepth(3);
    let w, h, angle = 0;

    if (type === 'can') {
      w = 28; h = 50;
      gfx.fillStyle(0xCC3333); gfx.fillRoundedRect(-w/2, -h/2, w, h, 5);
      gfx.fillStyle(0x888888); gfx.fillRect(-w/2, -h/2, w, 8);
      gfx.fillRect(-w/2, h/2-8, w, 8);
      gfx.fillStyle(0xFFFFFF, 0.7); gfx.fillRect(-w/2+3, -4, w-6, 8);
      gfx.lineStyle(2, 0x000000, 0.5); gfx.strokeRoundedRect(-w/2, -h/2, w, h, 5);
    } else if (type === 'block') {
      w = 40 + rand() * 60; h = 30 + rand() * 50;
      gfx.fillStyle(0x5B9BD5); gfx.fillRect(-w/2, -h/2, w, h);
      gfx.fillStyle(0x7BB5E5, 0.5); gfx.fillRect(-w/2+2, -h/2+2, w-4, 8);
      gfx.lineStyle(2, 0x2A5A9A); gfx.strokeRect(-w/2, -h/2, w, h);
    } else {
      w = 120; h = 10;
      angle = rand() * Math.PI * 2;
      gfx.fillStyle(0xFFDE3A); gfx.fillRect(-w/2, -h/2, w, h);
      gfx.fillStyle(0x8B4513); gfx.fillRect(w/2-14, -h/2, 14, h);
      gfx.fillStyle(0xFF69B4); gfx.fillRect(-w/2, -h/2, 10, h);
      gfx.lineStyle(1, 0x000000, 0.4); gfx.strokeRect(-w/2, -h/2, w, h);
    }

    gfx.x = x; gfx.y = y; gfx.rotation = angle;

    // AABB for manual collision — account for pencil rotation
    const ow = type === 'pencil' ? Math.abs(Math.cos(angle)) * w + Math.abs(Math.sin(angle)) * h + 10 : w;
    const oh = type === 'pencil' ? Math.abs(Math.sin(angle)) * w + Math.abs(Math.cos(angle)) * h + 10 : h;
    this.obstacles.push({ gfx, x, y, w: ow, h: oh });
  }

  // ══════════════════════════════════════════════════════════
  //  PLAYER
  // ══════════════════════════════════════════════════════════
  _createPlayer(x, y) {
    this.player = {
      x, y, hp: C.PLAYER_MAX_HP, maxHp: C.PLAYER_MAX_HP,
      angle: 0, vx: 0, vy: 0, alive: true,
      container: this.add.container(x, y).setDepth(20),
    };

    this.player.body = this.add.graphics();
    this.player.healthBar = this.add.graphics();
    this.player.container.add([this.player.body, this.player.healthBar]);
    this._drawSoldier(this.player, true);

  }

  _drawSoldier(soldier, isPlayer) {
    const g  = soldier.body;
    const hg = soldier.healthBar;
    const r  = C.PLAYER_RADIUS;
    const gun = C.GUNS[this.tierIndex] || C.GUNS[0];
    const col = isPlayer ? C.PLAYER_COLOR : C.ENEMY_COLOR;
    const hi  = isPlayer ? C.PLAYER_HIGHLIGHT : C.ENEMY_HIGHLIGHT;

    g.clear();
    // Shadow
    g.fillStyle(0x000000, 0.3);
    g.fillCircle(3, 4, r);
    // Body
    g.fillStyle(col);
    g.fillCircle(0, 0, r);
    // Rim
    g.lineStyle(2, lerpColor(col, 0x000000, 0.3));
    g.strokeCircle(0, 0, r);
    // Highlight
    g.fillStyle(hi, 0.35);
    g.fillCircle(-r * 0.25, -r * 0.25, r * 0.55);

    // Barrel (drawn along local +x axis)
    const bw = isPlayer ? gun.barrelW : C.GUNS[soldier.tierIndex || 0].barrelW;
    const bh = isPlayer ? gun.barrelH : C.GUNS[soldier.tierIndex || 0].barrelH;
    const gc = isPlayer ? gun.color   : C.GUNS[soldier.tierIndex || 0].color;
    g.fillStyle(0x333333);
    g.fillRoundedRect(r - 2, -bh / 2, bw, bh, 2);
    g.fillStyle(gc);
    g.fillRoundedRect(r - 2, -bh / 2, bw - 4, bh, 2);

    // Health bar
    hg.clear();
    const pct = Math.max(0, soldier.hp / soldier.maxHp);
    const bColor = pct > 0.6 ? 0x66BB6A : pct > 0.3 ? 0xFFA726 : 0xEF5350;
    hg.fillStyle(0x222222, 0.7);
    hg.fillRect(-20, -r - 12, 40, 5);
    hg.fillStyle(bColor);
    hg.fillRect(-20, -r - 12, 40 * pct, 5);
  }

  // ══════════════════════════════════════════════════════════
  //  INPUT
  // ══════════════════════════════════════════════════════════
  _setupInput() {
    this.cursors = this.input.keyboard ? this.input.keyboard.createCursorKeys() : null;
    this.wasd    = this.input.keyboard ? this.input.keyboard.addKeys({ up: 'W', down: 'S', left: 'A', right: 'D' }) : null;
    if (this.input.mouse) this.input.mouse.disableContextMenu();

    // Virtual joysticks for touch
    this._leftJoy  = { active: false, id: -1, sx: 0, sy: 0, dx: 0, dy: 0 };
    this._rightJoy = { active: false, id: -1, sx: 0, sy: 0, dx: 0, dy: 0 };

    this.input.on('pointerdown', p => this._onPointerDown(p));
    this.input.on('pointermove', p => this._onPointerMove(p));
    this.input.on('pointerup',   p => this._onPointerUp(p));

    // Joystick graphics (HUD-layer, fixed camera)
    this.stickGfx = this.add.graphics().setScrollFactor(0).setDepth(100);
    this._drawJoysticks();
  }

  _drawJoysticks() {
    const g  = this.stickGfx;
    const W  = this.scale.width;
    const H  = this.scale.height;
    g.clear();

    const drawStick = (cx, cy, dx, dy, col) => {
      g.fillStyle(0xffffff, 0.15);
      g.fillCircle(cx, cy, 62);
      g.lineStyle(2, 0xffffff, 0.3);
      g.strokeCircle(cx, cy, 62);
      g.fillStyle(col, 0.7);
      g.fillCircle(cx + dx, cy + dy, 28);
    };

    const lj = this._leftJoy,  rj = this._rightJoy;
    const lx = 90,   ly = H - 90;
    const rx = W-90, ry = H - 90;
    drawStick(lx, ly, lj.active ? lj.dx : 0, lj.active ? lj.dy : 0, 0xffffff);
    drawStick(rx, ry, rj.active ? rj.dx : 0, rj.active ? rj.dy : 0, 0xff4444);
  }

  _onPointerDown(p) {
    const W = this.scale.width;
    if (p.x < W / 2) {
      this._leftJoy  = { active: true, id: p.id, sx: p.x, sy: p.y, dx: 0, dy: 0 };
    } else {
      this._rightJoy = { active: true, id: p.id, sx: p.x, sy: p.y, dx: 0, dy: 0 };
    }
    this._drawJoysticks();
  }

  _onPointerMove(p) {
    const clamp = (v, r) => Math.max(-r, Math.min(r, v));
    const MAX = 50;
    if (this._leftJoy.active && p.id === this._leftJoy.id) {
      this._leftJoy.dx = clamp(p.x - this._leftJoy.sx, MAX);
      this._leftJoy.dy = clamp(p.y - this._leftJoy.sy, MAX);
    }
    if (this._rightJoy.active && p.id === this._rightJoy.id) {
      this._rightJoy.dx = clamp(p.x - this._rightJoy.sx, MAX);
      this._rightJoy.dy = clamp(p.y - this._rightJoy.sy, MAX);
    }
    this._drawJoysticks();
  }

  _onPointerUp(p) {
    if (this._leftJoy.id === p.id)  this._leftJoy  = { active: false, id: -1, sx: 0, sy: 0, dx: 0, dy: 0 };
    if (this._rightJoy.id === p.id) this._rightJoy = { active: false, id: -1, sx: 0, sy: 0, dx: 0, dy: 0 };
    this._drawJoysticks();
  }

  // ══════════════════════════════════════════════════════════
  //  PLAYER UPDATE
  // ══════════════════════════════════════════════════════════
  _updatePlayer(dt) {
    const p = this.player;
    if (!p.alive) return;

    // ── Movement ──
    let mx = 0, my = 0;

    // Keyboard
    if (this.cursors && (this.cursors.left.isDown  || this.wasd.left.isDown))  mx -= 1;
    if (this.cursors && (this.cursors.right.isDown || this.wasd.right.isDown)) mx += 1;
    if (this.cursors && (this.cursors.up.isDown    || this.wasd.up.isDown))    my -= 1;
    if (this.cursors && (this.cursors.down.isDown  || this.wasd.down.isDown))  my += 1;

    // Left joystick
    if (this._leftJoy.active) {
      const mag = Math.hypot(this._leftJoy.dx, this._leftJoy.dy);
      if (mag > 8) { mx += this._leftJoy.dx / mag; my += this._leftJoy.dy / mag; }
    }

    // Normalize diagonal
    const mag = Math.hypot(mx, my);
    if (mag > 0) { mx /= mag; my /= mag; }

    // Recoil decay
    this._recoilVx *= Math.pow(1 / C.RECOIL_FRICTION, dt);
    this._recoilVy *= Math.pow(1 / C.RECOIL_FRICTION, dt);

    // Position
    const spd = C.PLAYER_SPEED;
    p.x += (mx * spd + this._recoilVx) * dt;
    p.y += (my * spd + this._recoilVy) * dt;
    p.x  = Phaser.Math.Clamp(p.x, C.PLAYER_RADIUS, C.WORLD_W - C.PLAYER_RADIUS);
    p.y  = Phaser.Math.Clamp(p.y, C.PLAYER_RADIUS, C.WORLD_H - C.PLAYER_RADIUS);

    // Obstacle collision (simple circle-rect push)
    this._resolveObstacleCollisions(p, C.PLAYER_RADIUS);

    // ── Aim & Shoot ──
    let shooting = false;

    // Mouse aim
    const cam    = this.cameras.main;
    const worldMx = (this.input.mousePointer.x - cam.x) / cam.zoom + cam.scrollX;
    const worldMy = (this.input.mousePointer.y - cam.y) / cam.zoom + cam.scrollY;
    let aimX = worldMx - p.x, aimY = worldMy - p.y;

    // Right joystick overrides
    if (this._rightJoy.active) {
      const rmag = Math.hypot(this._rightJoy.dx, this._rightJoy.dy);
      if (rmag > 8) {
        aimX = this._rightJoy.dx; aimY = this._rightJoy.dy;
        shooting = true;
      }
    } else if (this.input.mousePointer.isDown) {
      shooting = true;
    }

    const aimMag = Math.hypot(aimX, aimY);
    if (aimMag > 0) {
      p.angle = Math.atan2(aimY, aimX);
      this._aimAngle = p.angle;
    } else if (mag > 0) {
      p.angle = Math.atan2(my, mx);
    }

    // Redraw soldier
    p.container.x = p.x;
    p.container.y = p.y;
    p.container.rotation = p.angle;
    this._redrawHealthBar(p);

    // Fire
    this._fireTimer += dt * 1000;
    const gun = C.GUNS[this.tierIndex];
    if (shooting && this._fireTimer >= gun.fireRate) {
      this._fireTimer = 0;
      this._spawnBullet(p.x, p.y, p.angle, gun, true);
      this._recoilVx -= Math.cos(p.angle) * C.RECOIL_IMPULSE;
      this._recoilVy -= Math.sin(p.angle) * C.RECOIL_IMPULSE;
    }

  }

  _redrawHealthBar(soldier) {
    const hg  = soldier.healthBar;
    const pct = Math.max(0, soldier.hp / soldier.maxHp);
    const col = pct > 0.6 ? 0x66BB6A : pct > 0.3 ? 0xFFA726 : 0xEF5350;
    hg.clear();
    hg.fillStyle(0x222222, 0.7);
    hg.fillRect(-20, -C.PLAYER_RADIUS - 12, 40, 5);
    hg.fillStyle(col);
    hg.fillRect(-20, -C.PLAYER_RADIUS - 12, 40 * pct, 5);
  }

  // ══════════════════════════════════════════════════════════
  //  BULLET
  // ══════════════════════════════════════════════════════════
  _spawnBullet(x, y, angle, gun, fromPlayer) {
    const r  = C.PLAYER_RADIUS;
    const bx = x + Math.cos(angle) * (r + gun.barrelW);
    const by = y + Math.sin(angle) * (r + gun.barrelW);
    const vx = Math.cos(angle) * gun.speed;
    const vy = Math.sin(angle) * gun.speed;

    const gfx = this.add.graphics().setDepth(18);
    this._drawBullet(gfx, gun.bRadius, gun.color);

    const bullet = { gfx, x: bx, y: by, vx, vy, fromPlayer, gun, born: this.time.now, spent: false };
    this.bullets.push(bullet);
    gfx.x = bx; gfx.y = by;
  }

  _drawBullet(gfx, br, color) {
    gfx.clear();
    gfx.fillStyle(color, 0.5);
    gfx.fillCircle(0, 0, br * 2.5);
    gfx.fillStyle(color);
    gfx.fillCircle(0, 0, br);
    gfx.fillStyle(0xffffff, 0.6);
    gfx.fillCircle(-br * 0.3, -br * 0.3, br * 0.4);
  }

  _updateBullets(dt) {
    const toRemove = [];
    for (const b of this.bullets) {
      if (b.spent) { toRemove.push(b); continue; }
      if (this.time.now - b.born > C.BULLET_LIFETIME) { b.spent = true; toRemove.push(b); continue; }

      b.x += b.vx * dt;
      b.y += b.vy * dt;
      b.gfx.x = b.x; b.gfx.y = b.y;

      // World bounds
      if (b.x < 0 || b.x > C.WORLD_W || b.y < 0 || b.y > C.WORLD_H) {
        b.spent = true; toRemove.push(b); continue;
      }

      // Obstacle hit
      if (this._bulletHitsObstacle(b)) { b.spent = true; toRemove.push(b); continue; }

      // Hit check
      if (b.fromPlayer) {
        // Check against enemies
        for (const e of this.enemies) {
          if (!e.alive) continue;
          const dx = b.x - e.x, dy = b.y - e.y;
          if (dx*dx + dy*dy < (C.ENEMY_RADIUS + b.gun.bRadius) ** 2) {
            b.spent = true;
            if (b.gun.explosive) { this._doExplosion(b.x, b.y, b.gun); }
            else { this._damageEnemy(e, b.gun.damage); }
            toRemove.push(b); break;
          }
        }
      } else {
        // Check against player
        const p = this.player;
        if (p.alive) {
          const dx = b.x - p.x, dy = b.y - p.y;
          if (dx*dx + dy*dy < (C.PLAYER_RADIUS + b.gun.bRadius) ** 2) {
            b.spent = true;
            if (b.gun.explosive) { this._doExplosion(b.x, b.y, b.gun); }
            else { this._damagePlayer(b.gun.damage); }
            toRemove.push(b);
          }
        }
      }
    }
    for (const b of toRemove) {
      const idx = this.bullets.indexOf(b);
      if (idx >= 0) this.bullets.splice(idx, 1);
      if (b.gfx) b.gfx.destroy();
    }
  }

  _bulletHitsObstacle(b) {
    for (const obs of this.obstacles) {
      const dx = Math.abs(b.x - obs.x), dy = Math.abs(b.y - obs.y);
      if (dx < obs.w / 2 + b.gun.bRadius && dy < obs.h / 2 + b.gun.bRadius) return true;
    }
    return false;
  }

  // ══════════════════════════════════════════════════════════
  //  EXPLOSION
  // ══════════════════════════════════════════════════════════
  _doExplosion(x, y, gun) {
    // Damage in radius
    const p = this.player;
    [{ isPlayer: true, obj: p }, ...this.enemies.map(e => ({ isPlayer: false, obj: e }))]
      .forEach(({ isPlayer, obj }) => {
        if (!obj.alive) return;
        const dx = obj.x - x, dy = obj.y - y;
        const d  = Math.hypot(dx, dy);
        if (d < C.EXPLOSION_RADIUS) {
          const dmg = gun.damage * (1 - d / C.EXPLOSION_RADIUS);
          if (isPlayer) this._damagePlayer(dmg);
          else          this._damageEnemy(obj, dmg);
        }
      });

    // Drop bonus scraps
    for (let i = 0; i < 4; i++) this._spawnScrap(x, y, 0, 50, 1);

    // Visual ring
    const gfx = this.add.graphics().setDepth(19);
    const exp = { gfx, x, y, t: 0, dur: C.EXPLOSION_DURATION / 1000 };
    this.explosions.push(exp);
  }

  _updateExplosions(dt) {
    const done = [];
    for (const exp of this.explosions) {
      exp.t += dt / exp.dur;
      if (exp.t >= 1) { done.push(exp); exp.gfx.destroy(); continue; }
      const r = C.EXPLOSION_RADIUS * exp.t;
      const col = lerpColor(0xFF8C00, exp.t < 0.5 ? 0xFFFF00 : 0xFF1744, Math.min(1, exp.t * 2));
      exp.gfx.clear();
      exp.gfx.lineStyle(4 * (1 - exp.t), col, 1 - exp.t);
      exp.gfx.strokeCircle(exp.x, exp.y, r);
      exp.gfx.fillStyle(col, 0.15 * (1 - exp.t));
      exp.gfx.fillCircle(exp.x, exp.y, r);
    }
    for (const e of done) this.explosions.splice(this.explosions.indexOf(e), 1);
  }

  // ══════════════════════════════════════════════════════════
  //  ENEMIES
  // ══════════════════════════════════════════════════════════
  _spawnEnemy(x, y) {
    x = Phaser.Math.Clamp(x, 50, C.WORLD_W - 50);
    y = Phaser.Math.Clamp(y, 50, C.WORLD_H - 50);
    const body   = this.add.graphics().setDepth(20);
    const hpBar  = this.add.graphics().setDepth(21);
    const enemy  = {
      x, y, hp: C.ENEMY_MAX_HP, maxHp: C.ENEMY_MAX_HP,
      angle: 0, alive: true,
      state: 'wander',
      targetX: x + (Math.random() - 0.5) * 400,
      targetY: y + (Math.random() - 0.5) * 400,
      wanderTimer: 3 + Math.random() * 4,
      strafeTimer: 0,
      strafeDir: 1,
      fireTimer: 0,
      tierIndex: 0,
      scraps: Math.floor(Math.random() * 16),
      body, healthBar: hpBar,
      container: { x, y },  // dummy for compatibility
    };
    this._drawEnemySoldier(enemy);
    this.enemies.push(enemy);
  }

  _drawEnemySoldier(e) {
    const g  = e.body;
    const hg = e.healthBar;
    const r  = C.ENEMY_RADIUS;
    const gun = C.GUNS[e.tierIndex] || C.GUNS[0];

    g.clear();
    g.fillStyle(0x000000, 0.3); g.fillCircle(3, 4, r);
    g.fillStyle(C.ENEMY_COLOR); g.fillCircle(0, 0, r);
    g.lineStyle(2, 0x7A5A30); g.strokeCircle(0, 0, r);
    g.fillStyle(C.ENEMY_HIGHLIGHT, 0.35); g.fillCircle(-r*0.25, -r*0.25, r*0.55);
    g.fillStyle(0x333333);
    g.fillRoundedRect(r-2, -gun.barrelH/2, gun.barrelW, gun.barrelH, 2);
    g.fillStyle(gun.color);
    g.fillRoundedRect(r-2, -gun.barrelH/2, gun.barrelW-4, gun.barrelH, 2);

    this._redrawEnemyHPBar(e);
    g.x = e.x; g.y = e.y; g.rotation = e.angle;
    hg.x = e.x; hg.y = e.y; hg.rotation = 0;
  }

  _redrawEnemyHPBar(e) {
    const hg  = e.healthBar;
    const pct = Math.max(0, e.hp / e.maxHp);
    const col = pct > 0.6 ? 0x66BB6A : pct > 0.3 ? 0xFFA726 : 0xEF5350;
    hg.clear();
    hg.fillStyle(0x222222, 0.7); hg.fillRect(-20, -C.ENEMY_RADIUS-12, 40, 5);
    hg.fillStyle(col);           hg.fillRect(-20, -C.ENEMY_RADIUS-12, 40*pct, 5);
  }

  _updateEnemies(dt) {
    const p = this.player;
    for (const e of this.enemies) {
      if (!e.alive) continue;

      const dx = p.x - e.x, dy = p.y - e.y;
      const distToPlayer = Math.hypot(dx, dy);
      if (distToPlayer < 0.1) continue; // avoid division by zero

      // ── FSM ──
      switch (e.state) {
        case 'wander': {
          e.wanderTimer -= dt;
          const tdx = e.targetX - e.x, tdy = e.targetY - e.y;
          const td = Math.hypot(tdx, tdy);
          if (td < 30 || e.wanderTimer <= 0) {
            e.wanderTimer = 3 + Math.random() * 4;
            e.targetX = e.x + (Math.random()-0.5)*600;
            e.targetY = e.y + (Math.random()-0.5)*600;
          }
          if (td > 0) {
            e.x += (tdx/td) * C.ENEMY_SPEED * 0.55 * dt;
            e.y += (tdy/td) * C.ENEMY_SPEED * 0.55 * dt;
            e.angle = Math.atan2(tdy, tdx);
          }
          if (distToPlayer < C.ENEMY_DETECT_RANGE) e.state = 'chase';
          break;
        }
        case 'chase': {
          const nx = dx/distToPlayer, ny = dy/distToPlayer;
          e.x += nx * C.ENEMY_SPEED * dt;
          e.y += ny * C.ENEMY_SPEED * dt;
          e.angle = Math.atan2(dy, dx);
          if (distToPlayer < C.ENEMY_ATTACK_RANGE) e.state = 'attack';
          if (distToPlayer > C.ENEMY_DETECT_RANGE * 1.2) e.state = 'wander';
          if (e.hp / e.maxHp < 0.25) e.state = 'flee';
          break;
        }
        case 'attack': {
          e.angle = Math.atan2(dy, dx);
          // Strafe
          e.strafeTimer -= dt;
          if (e.strafeTimer <= 0) { e.strafeTimer = 0.6; e.strafeDir *= -1; }
          const perp = e.angle + Math.PI/2;
          e.x += Math.cos(perp) * C.ENEMY_SPEED * 0.4 * e.strafeDir * dt;
          e.y += Math.sin(perp) * C.ENEMY_SPEED * 0.4 * e.strafeDir * dt;

          // Fire
          e.fireTimer += dt * 1000;
          const gun = C.GUNS[e.tierIndex];
          if (e.fireTimer >= gun.fireRate) {
            e.fireTimer = 0;
            if (p.alive) this._spawnBullet(e.x, e.y, e.angle, gun, false);
          }

          if (distToPlayer > C.ENEMY_ATTACK_RANGE * 1.1) e.state = 'chase';
          if (e.hp / e.maxHp < 0.25) e.state = 'flee';
          break;
        }
        case 'flee': {
          const fx = -dx/distToPlayer, fy = -dy/distToPlayer;
          e.x += fx * C.ENEMY_SPEED * 1.25 * dt;
          e.y += fy * C.ENEMY_SPEED * 1.25 * dt;
          e.angle = Math.atan2(fy, fx);
          if (e.hp / e.maxHp > 0.4) e.state = 'wander';
          break;
        }
      }

      // Obstacle collision
      this._resolveObstacleCollisions(e, C.ENEMY_RADIUS);
      // World clamp
      e.x = Phaser.Math.Clamp(e.x, C.ENEMY_RADIUS, C.WORLD_W - C.ENEMY_RADIUS);
      e.y = Phaser.Math.Clamp(e.y, C.ENEMY_RADIUS, C.WORLD_H - C.ENEMY_RADIUS);

      // Sync graphics
      e.body.x = e.x; e.body.y = e.y; e.body.rotation = e.angle;
      e.healthBar.x = e.x; e.healthBar.y = e.y;
      this._redrawEnemyHPBar(e);
    }

    // Remove dead
    this.enemies = this.enemies.filter(e => e.alive);
  }

  _damageEnemy(e, dmg) {
    e.hp -= dmg;
    if (e.hp <= 0) this._killEnemy(e);
  }

  _killEnemy(e) {
    e.alive = false;
    e.body.destroy();
    e.healthBar.destroy();
    this.kills++;
    // Drop scraps
    const count = 1 + Math.floor(Math.max(0, e.scraps) / 4);
    for (let i = 0; i < Math.min(count, 8); i++) {
      this._spawnScrap(e.x, e.y, 0, 45, 2);
    }
    this._notifyHUD();
  }

  // ══════════════════════════════════════════════════════════
  //  SCRAPS
  // ══════════════════════════════════════════════════════════
  _spawnScrap(cx, cy, minD, maxD, value) {
    const angle = Math.random() * Math.PI * 2;
    const dist  = minD + Math.random() * (maxD - minD);
    const x = cx + Math.cos(angle) * dist;
    const y = cy + Math.sin(angle) * dist;
    const gfx = this.add.graphics().setDepth(8);
    const scrap = { gfx, x, y, value, bobTimer: Math.random() * Math.PI * 2 };
    this._drawScrap(gfx, value);
    gfx.x = x; gfx.y = y;
    this.scrapsGroup.push(scrap);
  }

  _drawScrap(gfx, value) {
    gfx.clear();
    const s = 7;
    gfx.fillStyle(0x000000, 0.2); gfx.fillCircle(2, 2, s);
    gfx.fillStyle(C.SCRAP_COLOR);
    gfx.fillTriangle(0, -s, s, 0, 0, s);
    gfx.fillTriangle(0, -s, -s, 0, 0, s);
    gfx.lineStyle(1, 0xFFAA00); gfx.strokeTriangle(0, -s, s, 0, 0, s);
    if (value > 1) {
      // Tiny label drawn via bitmap
    }
  }

  _updateScraps(dt) {
    const p = this.player;
    const toRemove = [];
    for (const sc of this.scrapsGroup) {
      sc.bobTimer += dt * 3;
      const bobs = Math.sin(sc.bobTimer) * 2;
      const dx = p.x - sc.x, dy = p.y - sc.y;
      const d  = Math.hypot(dx, dy);

      if (d < C.SCRAP_MAGNET_RANGE && d > 0.1) {
        sc.x += (dx/d) * C.SCRAP_MAGNET_SPEED * dt;
        sc.y += (dy/d) * C.SCRAP_MAGNET_SPEED * dt;
      }

      sc.gfx.x = sc.x;
      sc.gfx.y = sc.y + bobs;

      // Collect
      if (d < C.PLAYER_RADIUS + C.SCRAP_RADIUS) {
        toRemove.push(sc);
        this.scraps += sc.value;
        this._checkTierUp();
        this._notifyHUD();
      }
    }
    for (const sc of toRemove) {
      const i = this.scrapsGroup.indexOf(sc);
      if (i >= 0) this.scrapsGroup.splice(i, 1);
      sc.gfx.destroy();
    }
  }

  _checkTierUp() {
    for (let t = C.GUNS.length - 1; t >= 0; t--) {
      if (this.scraps >= C.GUNS[t].scraps) {
        if (t !== this.tierIndex) {
          this.tierIndex = t;
          // Redraw player barrel
          this._drawSoldier(this.player, true);
        }
        break;
      }
    }
  }

  // ══════════════════════════════════════════════════════════
  //  SAFE ZONE
  // ══════════════════════════════════════════════════════════
  _updateSafeZone(dt) {
    this.safeRadius = Math.max(30, this.safeRadius - C.SAFE_SHRINK_RATE * dt);

    // Pulsing ring so the border is always visible
    const pulse = 0.7 + 0.3 * Math.sin(this.time.now / 300);
    this.safeGfx.clear();
    this.safeGfx.lineStyle(4, C.SAFE_RING_COLOR, pulse);
    this.safeGfx.strokeCircle(this.safeCx, this.safeCy, this.safeRadius);
    // Thin danger-red fill just outside the ring as a visual cue
    this.safeGfx.lineStyle(30, C.DANGER_COLOR, 0.25);
    this.safeGfx.strokeCircle(this.safeCx, this.safeCy, this.safeRadius + 15);
  }

  _applyZoneDamage() {
    if (this.gameOver) return;
    const p = this.player;
    if (p.alive) {
      const d = Math.hypot(p.x - this.safeCx, p.y - this.safeCy);
      if (d > this.safeRadius) this._damagePlayer(C.SAFE_DAMAGE * C.SAFE_DAMAGE_INTERVAL / 1000);
    }
    for (const e of this.enemies) {
      if (!e.alive) continue;
      const d = Math.hypot(e.x - this.safeCx, e.y - this.safeCy);
      if (d > this.safeRadius) this._damageEnemy(e, C.SAFE_DAMAGE * C.SAFE_DAMAGE_INTERVAL / 1000);
    }
  }

  // ══════════════════════════════════════════════════════════
  //  DAMAGE & DEATH
  // ══════════════════════════════════════════════════════════
  _damagePlayer(dmg) {
    const p = this.player;
    if (!p.alive) return;
    p.hp = Math.max(0, p.hp - dmg);
    this._notifyHUD();
    if (p.hp <= 0) this._playerDied();
  }

  _playerDied() {
    const p = this.player;
    p.alive = false;
    p.container.destroy();
    this.gameOver = true;
    // stop HUD first, then scene.start auto-queues stop(GameScene) + start(GameOverScene)
    this.scene.stop('HUDScene');
    this.scene.start('GameOverScene', {
      kills: this.kills,
      scraps: this.scraps,
      weapon: C.GUNS[this.tierIndex].name,
    });
  }

  // ══════════════════════════════════════════════════════════
  //  OBSTACLE COLLISION (circle vs AABB)
  // ══════════════════════════════════════════════════════════
  _resolveObstacleCollisions(entity, radius) {
    for (const obs of this.obstacles) {
      const hw = obs.w / 2 + radius, hh = obs.h / 2 + radius;
      const dx = entity.x - obs.x, dy = entity.y - obs.y;
      const ox = hw - Math.abs(dx), oy = hh - Math.abs(dy);
      if (ox > 0 && oy > 0) {
        if (ox < oy) entity.x += dx > 0 ? ox : -ox;
        else          entity.y += dy > 0 ? oy : -oy;
      }
    }
  }

  // ══════════════════════════════════════════════════════════
  //  HUD BRIDGE
  // ══════════════════════════════════════════════════════════
  _notifyHUD() {
    const hud = this.scene.get('HUDScene');
    if (hud && hud.updateState) {
      hud.updateState({
        hp: this.player.hp, maxHp: this.player.maxHp,
        scraps: this.scraps,
        kills: this.kills,
        tierIndex: this.tierIndex,
        safeRadius: this.safeRadius,
        playerX: this.player.x, playerY: this.player.y,
        enemies: this.enemies,
        safeCx: this.safeCx, safeCy: this.safeCy,
      });
    }
  }
}
