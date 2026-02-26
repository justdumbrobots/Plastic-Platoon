class MainMenu extends Phaser.Scene {
  constructor() { super('MainMenu'); }

  create() {
    const W = this.scale.width;
    const H = this.scale.height;

    // Background
    const bg = this.add.graphics();
    bg.fillStyle(0x1A2A1A);
    bg.fillRect(0, 0, W, H);

    // Grid pattern
    const grid = this.add.graphics();
    grid.lineStyle(1, 0x2A3A2A, 0.6);
    for (let x = 0; x < W; x += 40) { grid.moveTo(x, 0); grid.lineTo(x, H); }
    for (let y = 0; y < H; y += 40) { grid.moveTo(0, y); grid.lineTo(W, y); }
    grid.strokePath();

    // Title
    this.add.text(W / 2, H * 0.28, 'PLASTIC PLATOON', {
      fontSize: '52px',
      fontFamily: 'monospace',
      fontStyle: 'bold',
      fill: '#52A852',
      stroke: '#1A3A1A',
      strokeThickness: 6,
      shadow: { offsetX: 3, offsetY: 3, color: '#000', blur: 8, fill: true }
    }).setOrigin(0.5);

    // Tagline
    this.add.text(W / 2, H * 0.40, 'COLLECT  ·  UPGRADE  ·  DOMINATE', {
      fontSize: '16px',
      fontFamily: 'monospace',
      fill: '#FFD54F',
      letterSpacing: 3,
    }).setOrigin(0.5);

    // Deploy button
    const btnBg = this.add.graphics();
    const btnX = W / 2 - 100;
    const btnY = H * 0.55;
    const btnW = 200;
    const btnH = 52;

    btnBg.fillStyle(0x2A6A2A);
    btnBg.fillRoundedRect(btnX, btnY, btnW, btnH, 10);
    btnBg.lineStyle(2, 0x52A852);
    btnBg.strokeRoundedRect(btnX, btnY, btnW, btnH, 10);

    const btnText = this.add.text(W / 2, btnY + btnH / 2, '▶  DEPLOY', {
      fontSize: '22px',
      fontFamily: 'monospace',
      fontStyle: 'bold',
      fill: '#AAFFAA',
    }).setOrigin(0.5);

    // Pulsing animation on button
    this.tweens.add({
      targets: [btnBg, btnText],
      scaleX: 1.06,
      scaleY: 1.06,
      duration: 800,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut',
    });

    // Clickable area
    const hitZone = this.add.zone(W / 2, btnY + btnH / 2, btnW + 20, btnH + 20)
      .setInteractive({ useHandCursor: true });
    hitZone.on('pointerdown', () => this.startGame());

    // Controls info
    const controls = [
      'WASD / Arrow Keys — Move',
      'Mouse — Aim & Auto-fire',
      'Touch — Left stick move, Right stick aim',
    ];
    controls.forEach((line, i) => {
      this.add.text(W / 2, H * 0.73 + i * 22, line, {
        fontSize: '13px',
        fontFamily: 'monospace',
        fill: '#889988',
      }).setOrigin(0.5);
    });

    // Also start on space/enter
    this.input.keyboard.once('keydown-SPACE', () => this.startGame());
    this.input.keyboard.once('keydown-ENTER', () => this.startGame());
  }

  startGame() {
    this.scene.start('GameScene');
    this.scene.start('HUDScene');
    this.scene.stop('MainMenu');
  }
}
