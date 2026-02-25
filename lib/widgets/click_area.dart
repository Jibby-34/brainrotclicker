import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

// ── Data classes ──────────────────────────────────────────────────────────────

class _FloatingLabel {
  final String text;
  final double x;
  double y;
  double opacity;
  _FloatingLabel({required this.text, required this.x, required this.y})
      : opacity = 1.0;
}

class _Particle {
  double x, y;
  final double vx;
  double vy;
  double opacity;
  final double size;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  }) : opacity = 1.0;
}

// ── Widget ────────────────────────────────────────────────────────────────────

class ClickArea extends StatefulWidget {
  const ClickArea({super.key});

  @override
  State<ClickArea> createState() => _ClickAreaState();
}

class _ClickAreaState extends State<ClickArea> with TickerProviderStateMixin {
  // Tap squish
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  // Expanding ring on tap
  late AnimationController _pulseController;
  late Animation<double> _pulseSize;
  late Animation<double> _pulseOpacity;

  // Idle breathing
  late AnimationController _breathController;
  late Animation<double> _breathAnim;

  // Gentle left-right sway
  late AnimationController _wobbleController;
  late Animation<double> _wobbleAnim;

  // Orbiting sparkles
  late AnimationController _orbitController;

  // Particles & labels
  final List<_FloatingLabel> _labels = [];
  final List<_Particle> _particles = [];
  bool _particleLoopRunning = false;

  final _rng = Random();

  static const _particleColors = [
    Color(0xFFFFD700),
    Color(0xFFFF6B9D),
    Color(0xFF4ECDC4),
    Colors.white,
    Color(0xFFFF6B6B),
    Color(0xFFB06EFF),
  ];

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.82)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.82, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_scaleController);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _pulseSize = Tween(begin: 0.65, end: 1.75).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween(begin: 0.75, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _breathAnim = Tween(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _wobbleAnim = Tween(begin: -0.07, end: 0.07).animate(
      CurvedAnimation(parent: _wobbleController, curve: Curves.easeInOut),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _breathController.dispose();
    _wobbleController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  // ── Particle loop ─────────────────────────────────────────────────────────

  void _startParticleLoop() {
    if (_particleLoopRunning) return;
    _particleLoopRunning = true;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) {
        _particleLoopRunning = false;
        return false;
      }
      setState(() {
        for (final p in _particles) {
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.2; // gravity
          p.opacity -= 0.025;
        }
        _particles.removeWhere((p) => p.opacity <= 0);
      });
      if (_particles.isEmpty) {
        _particleLoopRunning = false;
        return false;
      }
      return true;
    });
  }

  // ── Tap handler ───────────────────────────────────────────────────────────

  void _onTap(BuildContext context, TapUpDetails details) {
    final gs = context.read<GameState>();
    gs.tap();
    _scaleController.forward(from: 0);
    _pulseController.forward(from: 0);

    final renderBox = context.findRenderObject() as RenderBox;
    final local = renderBox.globalToLocal(details.globalPosition);

    // Floating +N label
    final label = _FloatingLabel(
      text: '+${gs.formatNumber(gs.clickPower)}',
      x: local.dx,
      y: local.dy,
    );
    setState(() => _labels.add(label));
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) return false;
      setState(() {
        label.y -= 2.8;
        label.opacity -= 0.028;
      });
      if (label.opacity <= 0) {
        setState(() => _labels.remove(label));
        return false;
      }
      return true;
    });

    // Burst particles from tap position
    for (int i = 0; i < 9; i++) {
      final angle = (i / 9) * 2 * pi + (_rng.nextDouble() - 0.5) * 0.7;
      final speed = 2.8 + _rng.nextDouble() * 3.8;
      _particles.add(_Particle(
        x: local.dx,
        y: local.dy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 1.2,
        size: 5.0 + _rng.nextDouble() * 6.5,
        color: _particleColors[_rng.nextInt(_particleColors.length)],
      ));
    }
    _startParticleLoop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final character = gs.activeCharacter;

    return GestureDetector(
      onTapUp: (d) => _onTap(context, d),
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ── Orbiting sparkle dots ──────────────────────────────────────
            AnimatedBuilder(
              animation: _orbitController,
              builder: (_, __) {
                const orbitR = 112.0;
                const cx = 120.0;
                const cy = 120.0;
                return Stack(
                  children: List.generate(4, (i) {
                    final angle =
                        _orbitController.value * 2 * pi + (i * pi / 2);
                    // Alternate dot sizes and give them a slight pulse via sin
                    final dotSize =
                        (i.isEven ? 10.0 : 7.0) + sin(angle * 2) * 1.5;
                    return Positioned(
                      left: cx + cos(angle) * orbitR - dotSize / 2,
                      top: cy + sin(angle) * orbitR - dotSize / 2,
                      child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: character.color,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

            // ── Expanding pulse ring ───────────────────────────────────────
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Opacity(
                opacity: _pulseOpacity.value,
                child: Transform.scale(
                  scale: _pulseSize.value,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: character.color,
                        width: 4.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Outer ambient glow ─────────────────────────────────────────
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: character.color.withValues(alpha: 0.55),
                    blurRadius: 55,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),

            // ── Character: wobble + breath + squish ────────────────────────
            AnimatedBuilder(
              animation: Listenable.merge([
                _breathController,
                _scaleController,
                _wobbleController,
              ]),
              builder: (_, child) => Transform.rotate(
                angle: _wobbleAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value * _breathAnim.value,
                  child: child,
                ),
              ),
              child: Container(
                width: 215,
                height: 215,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      character.color.withValues(alpha: 0.22),
                      character.color.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    character.assetPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // ── Floating +N labels ─────────────────────────────────────────
            for (final lbl in _labels)
              Positioned(
                left: lbl.x - 32,
                top: lbl.y - 20,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: lbl.opacity.clamp(0.0, 1.0),
                    child: Stack(
                      children: [
                        Text(
                          lbl.text,
                          style: TextStyle(
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 4.5
                              ..strokeJoin = StrokeJoin.round
                              ..color = Colors.black.withValues(alpha: 0.85),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          lbl.text,
                          style: TextStyle(
                            color: character.color,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Burst particles ────────────────────────────────────────────
            for (final p in _particles)
              Positioned(
                left: p.x - p.size / 2,
                top: p.y - p.size / 2,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: p.opacity.clamp(0.0, 1.0),
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.color,
                        boxShadow: [
                          BoxShadow(
                            color: p.color.withValues(alpha: 0.7),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
