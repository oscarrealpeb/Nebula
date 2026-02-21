import 'package:flutter/material.dart';

class CosmicBackground extends StatelessWidget {
  const CosmicBackground({
    super.key,
    required this.child,
    this.topGlowColor = const Color(0xFF8FC6FF),
    this.bottomGlowColor = const Color(0xFFBBD8FF),
  });

  final Widget child;
  final Color topGlowColor;
  final Color bottomGlowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAFAFB),
            Color(0xFFF6F7F9),
            Color(0xFFF2F3F5),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            left: -24,
            child: _GlowBlob(
              color: topGlowColor.withValues(alpha: 0.20),
              size: 200,
            ),
          ),
          Positioned(
            top: 130,
            right: -42,
            child: _GlowBlob(
              color: const Color(0xFFFFD6E6).withValues(alpha: 0.20),
              size: 180,
            ),
          ),
          Positioned(
            bottom: -80,
            left: -30,
            child: _GlowBlob(
              color: const Color(0xFFCFF5D9).withValues(alpha: 0.24),
              size: 210,
            ),
          ),
          Positioned(
            bottom: 80,
            right: -46,
            child: _GlowBlob(
              color: bottomGlowColor.withValues(alpha: 0.18),
              size: 170,
            ),
          ),
          const _MiniStars(),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _MiniStars extends StatelessWidget {
  const _MiniStars();

  static const _positions = [
    (12.0, 40.0, 1.0),
    (48.0, 190.0, 1.6),
    (98.0, 310.0, 1.3),
    (136.0, 80.0, 1.4),
    (182.0, 240.0, 1.1),
    (230.0, 330.0, 1.8),
    (270.0, 110.0, 1.2),
    (320.0, 270.0, 1.0),
    (360.0, 50.0, 1.5),
    (420.0, 200.0, 1.2),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (_, constraints) {
          final maxW = constraints.maxWidth;
          return Stack(
            children: _positions.map((p) {
              final y = p.$1;
              final x = p.$2 % (maxW == 0 ? 360 : maxW);
              final scale = p.$3;
              return Positioned(
                top: y,
                left: x,
                child: Container(
                  width: 3.2 * scale,
                  height: 3.2 * scale,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4DBE7),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
