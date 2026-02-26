import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_screen.dart';

/// Main menu with title, tagline, and a "DEPLOY" button.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    // Force landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2A1A), // dark olive
      body: Stack(
        children: [
          // ── Decorative background pattern ─────────────────────────────────
          const _BackgroundPattern(),

          // ── Content ───────────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / Title
                const Text(
                  'PLASTIC',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const Text(
                  'PLATOON',
                  style: TextStyle(
                    color: Color(0xFF81C784),
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 16,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'COLLECT  ·  UPGRADE  ·  DOMINATE',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 11,
                    letterSpacing: 3,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 50),

                // Deploy button
                ScaleTransition(
                  scale: _pulseAnim,
                  child: _MenuButton(
                    label: '▶  DEPLOY',
                    color: const Color(0xFF3B7A3B),
                    onTap: _startGame,
                  ),
                ),
                const SizedBox(height: 20),

                // How-to blurb
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Column(
                    children: [
                      Text('LEFT stick → move   RIGHT stick → aim & fire',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontFamily: 'monospace')),
                      SizedBox(height: 4),
                      Text(
                          'Collect ◆ scraps to upgrade your weapon (5 tiers)',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontFamily: 'monospace')),
                      SizedBox(height: 4),
                      Text('Stay inside the safe zone — it shrinks!',
                          style: TextStyle(
                              color: Color(0xFFEF5350),
                              fontSize: 11,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }
}

// ---------------------------------------------------------------------------
// Decorative tiled background (static Army-Men silhouettes via CustomPaint)
// ---------------------------------------------------------------------------
class _BackgroundPattern extends StatelessWidget {
  const _BackgroundPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PatternPainter(),
      size: Size.infinite,
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E4A2E).withOpacity(0.4)
      ..strokeWidth = 1;

    // Simple grid dots
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Reusable menu button
// ---------------------------------------------------------------------------
class _MenuButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
