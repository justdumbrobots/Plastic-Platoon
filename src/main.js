const config = {
  type: Phaser.AUTO,
  width: 960,
  height: 540,
  backgroundColor: '#1A2A1A',
  physics: {
    default: 'arcade',
    arcade: { gravity: { y: 0 }, debug: false }
  },
  scene: [MainMenu, GameScene, HUDScene, GameOverScene],
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
};

const game = new Phaser.Game(config);
