import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../widgets/click_area.dart';
import '../widgets/shop_panel.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3D0E87),
                  Color(0xFF1E0B55),
                  Color(0xFF0D1A5C),
                ],
              ),
            ),
          ),
          // Floating decorative bubbles
          const _BackgroundBubbles(),
          // Main content
          SafeArea(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(flex: 5, child: _ClickSection()),
                const Expanded(flex: 5, child: ShopPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated background bubbles ───────────────────────────────────────────────

class _BackgroundBubbles extends StatefulWidget {
  const _BackgroundBubbles();

  @override
  State<_BackgroundBubbles> createState() => _BackgroundBubblesState();
}

class _BackgroundBubblesState extends State<_BackgroundBubbles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value * 2 * pi;
        return Stack(
          children: [
            _FloatBubble(
              top: -50,
              right: -30,
              size: 160,
              color: const Color(0xFFFF6B9D),
              dy: sin(t * 0.7) * 18,
            ),
            _FloatBubble(
              top: 160,
              left: -50,
              size: 110,
              color: const Color(0xFF4ECDC4),
              dy: sin(t * 1.1 + 1.0) * 14,
            ),
            _FloatBubble(
              top: 320,
              right: -20,
              size: 75,
              color: const Color(0xFFFFE66D),
              dy: sin(t * 0.9 + 2.0) * 11,
            ),
            _FloatBubble(
              bottom: 240,
              left: -40,
              size: 130,
              color: const Color(0xFFB06EFF),
              dy: sin(t * 0.6 + 0.5) * 20,
            ),
            _FloatBubble(
              bottom: 60,
              right: -30,
              size: 100,
              color: const Color(0xFFFF6B6B),
              dy: sin(t * 1.0 + 1.5) * 15,
            ),
          ],
        );
      },
    );
  }
}

class _FloatBubble extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;
  final double dy;

  const _FloatBubble({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
    required this.dy,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.13),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.07),
                blurRadius: 28,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          OutlinedText(
            'BRAINROT CLICKER',
            style: GoogleFonts.bangers(
              fontSize: 22,
              color: const Color(0xFFFFE66D),
              letterSpacing: 3,
            ),
            strokeColor: Colors.black,
            strokeWidth: 3.5,
          ),
          const SizedBox(height: 6),
          _BrainCountPill(gs: gs),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatPill(
                label: '${gs.formatNumber(gs.cps)}/sec',
                color: const Color(0xFF4ECDC4),
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: '${gs.formatNumber(gs.clickPower)}/tap',
                color: const Color(0xFFFF6B9D),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pulsing brain count pill ──────────────────────────────────────────────────

class _BrainCountPill extends StatefulWidget {
  final GameState gs;
  const _BrainCountPill({required this.gs});

  @override
  State<_BrainCountPill> createState() => _BrainCountPillState();
}

class _BrainCountPillState extends State<_BrainCountPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9F43), Color(0xFFFFD700)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xAAFF9F43),
              blurRadius: 0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧠', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            OutlinedText(
              widget.gs.formatNumber(widget.gs.totalClicks),
              style: GoogleFonts.bangers(
                fontSize: 30,
                color: Colors.white,
                letterSpacing: 1,
              ),
              strokeColor: const Color(0xFFB25900),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ── Click section ─────────────────────────────────────────────────────────────

class _ClickSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final character = context.watch<GameState>().activeCharacter;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Character name badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: [
                character.color,
                character.color.withValues(alpha: 0.65),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: character.color.withValues(alpha: 0.55),
                blurRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: OutlinedText(
            character.name.toUpperCase(),
            style: GoogleFonts.bangers(
              fontSize: 16,
              color: Colors.white,
              letterSpacing: 2.5,
            ),
            strokeColor: Colors.black.withValues(alpha: 0.65),
            strokeWidth: 3,
          ),
        ),
        const ClickArea(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👆', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              'TAP TO COLLECT BRAINS',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white30,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Reusable outlined text ─────────────────────────────────────────────────────

class OutlinedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color strokeColor;
  final double strokeWidth;

  const OutlinedText(
    this.text, {
    super.key,
    required this.style,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
          ),
        ),
        Text(text, style: style),
      ],
    );
  }
}
