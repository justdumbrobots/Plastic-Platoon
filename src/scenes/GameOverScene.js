class GameOverScene extends Phaser.Scene {
  constructor() { super('GameOverScene'); }

  init(data) {
    this.data_kills  = data.kills  || 0;
    this.data_scraps = data.scraps || 0;
    this.data_weapon = data.weapon || 'PISTOL';
  }

  create() {
    const W = this.scale.width;
    const H = this.scale.height;

    // Dim overlay
    const dim = this.add.graphics();
    dim.fillStyle(0x000000, 0.65);
    dim.fillRect(0, 0, W, H);

    // Panel
    const pw = 380, ph = 280;
    const px = (W - pw) / 2, py = (H - ph) / 2;
    const panel = this.add.graphics();
    panel.fillStyle(0x1A1A1A, 0.95);
    panel.fillRoundedRect(px, py, pw, ph, 12);
    panel.lineStyle(2, 0xEF5350, 0.8);
    panel.strokeRoundedRect(px, py, pw, ph, 12);

    // Title
    this.add.text(W/2, py + 32, 'SOLDIER DOWN', {
      fontSize: '32px', fontFamily: 'monospace', fontStyle: 'bold',
      fill: '#EF5350', stroke: '#000', strokeThickness: 4,
    }).setOrigin(0.5);

    // Stats
    const stats = [
      { label: 'Enemies Eliminated', value: this.data_kills,  color: '#ffffff' },
      { label: 'Scraps Collected',   value: this.data_scraps, color: '#FFD700' },
      { label: 'Weapon Reached',     value: this.data_weapon, color: '#66BB6A' },
    ];
    stats.forEach((st, i) => {
      this.add.text(W/2 - 80, py + 90 + i * 34, st.label + ':', {
        fontSize: '14px', fontFamily: 'monospace', fill: '#888888',
      }).setOrigin(0, 0.5);
      this.add.text(W/2 + 80, py + 90 + i * 34, String(st.value), {
        fontSize: '16px', fontFamily: 'monospace', fontStyle: 'bold', fill: st.color,
      }).setOrigin(1, 0.5);
    });

    // REDEPLOY button
    this._makeButton(W/2 - 90, py + ph - 54, 160, 38, 0x2A6A2A, 0x52A852, '▶ REDEPLOY', '#AAFFAA', () => {
      this.scene.stop('GameOverScene');
      this.scene.stop('HUDScene');
      this.scene.start('GameScene');   // restarts GameScene fresh
      this.scene.launch('HUDScene');   // launches HUDScene in parallel
    });

    // RETREAT button
    this._makeButton(W/2 + 90, py + ph - 54, 140, 38, 0x3A3A3A, 0x666666, '✕ RETREAT', '#AAAAAA', () => {
      this.scene.stop('GameOverScene');
      this.scene.stop('HUDScene');
      this.scene.stop('GameScene');
      this.scene.start('MainMenu');
    });
  }

  _makeButton(cx, cy, bw, bh, fillCol, strokeCol, label, textCol, cb) {
    const bg = this.add.graphics();
    bg.fillStyle(fillCol);
    bg.fillRoundedRect(cx - bw/2, cy - bh/2, bw, bh, 8);
    bg.lineStyle(2, strokeCol);
    bg.strokeRoundedRect(cx - bw/2, cy - bh/2, bw, bh, 8);

    const txt = this.add.text(cx, cy, label, {
      fontSize: '15px', fontFamily: 'monospace', fontStyle: 'bold', fill: textCol,
    }).setOrigin(0.5);

    const zone = this.add.zone(cx, cy, bw, bh).setInteractive({ useHandCursor: true });
    zone.on('pointerover',  () => { bg.setAlpha(0.8); txt.setAlpha(0.8); });
    zone.on('pointerout',   () => { bg.setAlpha(1.0); txt.setAlpha(1.0); });
    zone.on('pointerdown',  cb);
  }
}
