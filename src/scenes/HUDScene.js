class HUDScene extends Phaser.Scene {
  constructor() { super({ key: 'HUDScene', active: false }); }

  create() {
    const W = this.scale.width;
    const H = this.scale.height;

    // State
    this._state = {
      hp: 100, maxHp: 100, scraps: 0, kills: 0,
      tierIndex: 0, safeRadius: C.SAFE_INITIAL_RADIUS,
      playerX: C.WORLD_W/2, playerY: C.WORLD_H/2,
      enemies: [], safeCx: C.WORLD_W/2, safeCy: C.WORLD_H/2,
    };

    // ── Health bar ──
    this.hpBg   = this.add.graphics();
    this.hpFill = this.add.graphics();
    this.hpText = this.add.text(14, 12, 'HP', {
      fontSize: '11px', fontFamily: 'monospace', fill: '#aaaaaa'
    });

    // ── Gun badge ──
    this.gunBadge = this.add.text(W/2, 10, 'PISTOL', {
      fontSize: '17px', fontFamily: 'monospace', fontStyle: 'bold',
      fill: '#FFD54F', stroke: '#333', strokeThickness: 3,
    }).setOrigin(0.5, 0);

    // ── Kills ──
    this.killText = this.add.text(W - 10, 10, '☠ 0', {
      fontSize: '15px', fontFamily: 'monospace', fill: '#EF5350',
    }).setOrigin(1, 0);

    // ── Scrap progress ──
    this.scrapBg   = this.add.graphics();
    this.scrapFill = this.add.graphics();
    this.scrapText = this.add.text(W/2, H - 10, '0 / 10 scraps', {
      fontSize: '12px', fontFamily: 'monospace', fill: '#FFD700',
    }).setOrigin(0.5, 1);

    // ── Minimap ──
    const MM = 120, MPAD = 12;
    this.mmX = W - MM - MPAD;
    this.mmY = H - MM - MPAD;
    this.mmSize = MM;
    this.minimapGfx = this.add.graphics();

    this._drawAll();
  }

  // Runs every frame — pulls live data from GameScene for minimap + safe zone
  update() {
    const gs = this.scene.get('GameScene');
    if (gs && gs.player && !gs.gameOver) {
      this._state.playerX    = gs.player.x;
      this._state.playerY    = gs.player.y;
      this._state.safeRadius = gs.safeRadius;
      this._state.enemies    = gs.enemies;
      this._state.safeCx     = gs.safeCx;
      this._state.safeCy     = gs.safeCy;
    }
    this._drawAll();
  }

  updateState(s) {
    Object.assign(this._state, s);
  }

  _drawAll() {
    const s  = this._state;
    const W  = this.scale.width;
    const H  = this.scale.height;
    const gun = C.GUNS[s.tierIndex];

    // ── Health ──
    const pct = Math.max(0, s.hp / s.maxHp);
    const hcol = pct > 0.6 ? 0x66BB6A : pct > 0.3 ? 0xFFA726 : 0xEF5350;
    this.hpBg.clear();
    this.hpBg.fillStyle(0x111111, 0.7);
    this.hpBg.fillRoundedRect(10, 10, 160, 16, 4);
    this.hpFill.clear();
    this.hpFill.fillStyle(hcol);
    this.hpFill.fillRoundedRect(10, 10, 160 * pct, 16, 4);
    this.hpText.setText(`HP  ${Math.ceil(s.hp)}/${s.maxHp}`);

    // ── Gun badge ──
    this.gunBadge.setText(gun.name);

    // ── Kills ──
    this.killText.setText(`☠ ${s.kills}`);

    // ── Scrap progress ──
    const nextTier  = s.tierIndex < C.GUNS.length - 1 ? C.GUNS[s.tierIndex + 1] : null;
    const SB_W = 220, SB_H = 12;
    const sbX  = W/2 - SB_W/2, sbY = H - 28;
    this.scrapBg.clear();
    this.scrapFill.clear();

    if (nextTier) {
      const base = gun.scraps;
      const goal = nextTier.scraps;
      const prog = Math.min(1, (s.scraps - base) / (goal - base));
      this.scrapBg.fillStyle(0x111111, 0.7);
      this.scrapBg.fillRoundedRect(sbX, sbY, SB_W, SB_H, 4);
      this.scrapFill.fillStyle(C.SCRAP_COLOR);
      this.scrapFill.fillRoundedRect(sbX, sbY, SB_W * prog, SB_H, 4);
      this.scrapText.setText(`${s.scraps} / ${goal} scraps`);
    } else {
      this.scrapText.setText('MAX TIER');
    }
    this.scrapText.setY(sbY - 2);

    // ── Minimap ──
    this._drawMinimap(s);
  }

  _drawMinimap(s) {
    const g   = this.minimapGfx;
    const MM  = this.mmSize;
    const mx  = this.mmX, my = this.mmY;
    const scl = MM / C.WORLD_W;
    g.clear();

    // BG
    g.fillStyle(0x000000, 0.55);
    g.fillRect(mx, my, MM, MM);
    g.lineStyle(1, 0x444444, 0.8);
    g.strokeRect(mx, my, MM, MM);

    // Safe zone ring
    const sRad = s.safeRadius * scl;
    const sCx  = mx + s.safeCx * scl;
    const sCy  = my + s.safeCy * scl;
    g.lineStyle(1.5, C.SAFE_RING_COLOR, 0.5);
    g.strokeCircle(sCx, sCy, sRad);

    // Enemies
    g.fillStyle(C.ENEMY_COLOR, 0.9);
    for (const e of s.enemies) {
      if (!e.alive) continue;
      const ex = mx + e.x * scl;
      const ey = my + e.y * scl;
      if (ex > mx && ex < mx+MM && ey > my && ey < my+MM) {
        g.fillCircle(ex, ey, 2.5);
      }
    }

    // Player
    g.fillStyle(C.PLAYER_COLOR, 1);
    g.fillCircle(mx + s.playerX * scl, my + s.playerY * scl, 3.5);
  }
}
