import 'package:flutter/material.dart';
import '../core/data/universe_data.dart';
import '../services/narration_service.dart';

class UniverseGameScreen extends StatefulWidget {
  final UniverseItem item;

  const UniverseGameScreen({super.key, required this.item});

  @override
  State<UniverseGameScreen> createState() => _UniverseGameScreenState();
}

class _UniverseGameScreenState extends State<UniverseGameScreen>
    with SingleTickerProviderStateMixin {
  final narration = NarrationService.instance;

  String? currentAudio;
  bool isPlaying = false;

  late AnimationController _controller;

  // ── Paleta ──────────────────────────────────────────────────────────────────
  static const _bgDeep    = Color(0xFF060B1A);
  static const _bgCard    = Color(0xFF0D1530);
  static const _accent    = Color(0xFF38EFC3);
  static const _accentDim = Color(0xFF1A7A63);
  static const _textHigh  = Color(0xFFE8F0FF);
  static const _textLow   = Color(0xFF7A8BAD);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.95,
      upperBound: 1.05,
    );

    playAudio();
  }

  Future<void> playAudio() async {
    if (isPlaying) return;

    setState(() => isPlaying = true);

    _controller.repeat(reverse: true);

    final audio =
        await narration.playRandomFromList(widget.item.audios);

    if (!mounted) return;

    setState(() {
      currentAudio = audio;
      isPlaying = false;
    });

    _controller.stop();
  }

  @override
  void dispose() {
    narration.stop();
    _controller.dispose();
    super.dispose();
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textHigh, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          widget.item.title.toUpperCase(),
          style: const TextStyle(
            color: _textHigh,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.5,
          ),
        ),
      ),

      // ── Body ────────────────────────────────────────────────────────────────
      body: SafeArea(
        child: Column(
          children: [
            // Línea decorativa bajo el AppBar
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  _accent.withValues(alpha: 0.4),
                  Colors.transparent,
                ]),
              ),
            ),

            const Spacer(),

            // ── Imagen animada ─────────────────────────────────────────────
            AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                return Transform.scale(
                  scale: isPlaying ? _controller.value : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: isPlaying
                          ? [
                              BoxShadow(
                                color: _accent.withValues(alpha: 0.35),
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: _accent.withValues(alpha: 0.12),
                                blurRadius: 120,
                                spreadRadius: 30,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: _accentDim.withValues(alpha: 0.2),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                    ),
                    child: child,
                  ),
                );
              },
              child: Image.asset(
  widget.item.image,
  width: 240,
  errorBuilder: (context, error, stackTrace) {
    print("❌ Error cargando imagen: ${widget.item.image}");
    return const Icon(
      Icons.error,
      color: Colors.red,
      size: 50,
    );
  },
),
            ),

            const Spacer(),

            // ── Panel inferior ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _accent.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Estado del audio
                  _AudioStatus(
                    isPlaying: isPlaying,
                    currentAudio: currentAudio,
                  ),

                  const SizedBox(height: 24),

                  // Botón
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isPlaying ? null : playAudio,
                      icon: const Icon(Icons.shuffle_rounded, size: 18),
                      label: const Text(
                        "Otro audio",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isPlaying ? const Color(0xFF1A2340) : _accent,
                        foregroundColor:
                            isPlaying ? _textLow : const Color(0xFF060B1A),
                        disabledBackgroundColor: const Color(0xFF1A2340),
                        disabledForegroundColor: _textLow,
                        elevation: isPlaying ? 0 : 6,
                        shadowColor: _accent.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: isPlaying
                              ? BorderSide(
                                  color: _textLow.withValues(alpha: 0.2))
                              : BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget auxiliar: estado del audio ─────────────────────────────────────────
class _AudioStatus extends StatelessWidget {
  final bool isPlaying;
  final String? currentAudio;

  static const _accent   = Color(0xFF38EFC3);
  static const _textLow  = Color(0xFF7A8BAD);
  static const _textHigh = Color(0xFFE8F0FF);

  const _AudioStatus({required this.isPlaying, required this.currentAudio});

  @override
  Widget build(BuildContext context) {
    if (isPlaying) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _accent,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "Reproduciendo...",
            style: TextStyle(color: _textLow, fontSize: 13),
          ),
        ],
      );
    }

    if (currentAudio != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.graphic_eq_rounded, color: _accent, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              currentAudio!.split('/').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _textHigh, fontSize: 13),
            ),
          ),
        ],
      );
    }

    // Estado inicial antes de cualquier reproducción
    return const Text(
      "Preparando audio...",
      style: TextStyle(color: _textLow, fontSize: 13),
    );
  }
}