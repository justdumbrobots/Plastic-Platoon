import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/plastic_platoon_game.dart';

/// Wraps the Flame game in a Flutter widget with overlay definitions
/// (game-over screen, pause screen).
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late PlasticPlatoonGame _game;

  @override
  void initState() {
    super.initState();
    _game = PlasticPlatoonGame();
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: _game,
      overlayBuilderMap: {
        kGameOverOverlay: (context, game) =>
            _GameOverOverlay(game: game as PlasticPlatoonGame),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Game-over overlay
// ---------------------------------------------------------------------------
class _GameOverOverlay extends StatelessWidget {
  final PlasticPlatoonGame game;
  const _GameOverOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withOpacity(0.78),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                'SOLDIER DOWN',
                style: TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              // Stats
              Text(
                'Enemies eliminated: ${game.killCount}',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontFamily: 'monospace'),
              ),
              const SizedBox(height: 6),
              Text(
                'Scraps collected: ${game.player.scrapsCollected}',
                style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 16,
                    fontFamily: 'monospace'),
              ),
              const SizedBox(height: 6),
              Text(
                'Weapon reached: ${game.player.tier.name}',
                style: const TextStyle(
                    color: Color(0xFF66BB6A),
                    fontSize: 16,
                    fontFamily: 'monospace'),
              ),
              const SizedBox(height: 40),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _OverlayButton(
                    label: 'REDEPLOY',
                    color: const Color(0xFF3B7A3B),
                    onTap: () => game.restart(),
                  ),
                  const SizedBox(width: 24),
                  _OverlayButton(
                    label: 'RETREAT',
                    color: const Color(0xFF616161),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OverlayButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
