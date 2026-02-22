import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nebula_button.dart';
import '../../widgets/nebula_snack.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late String _narratorId;
  late bool _soundEnabled;
  late double _hue;
  late double _intensity;
  Timer? _themeSyncTimer;

  final _narrators = const [
    ('narrator_1', 'Leo'),
    ('narrator_2', 'Mateo'),
    ('narrator_3', 'Bruno'),
    ('narrator_4', 'Sofia'),
    ('narrator_5', 'Valeria'),
    ('narrator_6', 'Emma'),
  ];

  final _hues = const [196.0, 212.0, 228.0, 172.0, 35.0, 330.0];

  @override
  void initState() {
    super.initState();
    final user = widget.controller.currentUser!;
    _narratorId = user.selectedNarratorId;
    _soundEnabled = user.soundEffectsEnabled;
    _hue = user.accentHue;
    _intensity = user.accentIntensity;
  }

  @override
  void dispose() {
    if (_themeSyncTimer?.isActive ?? false) {
      widget.controller.setThemeColor(
        hue: _hue,
        intensity: _intensity,
      );
    }
    _themeSyncTimer?.cancel();
    super.dispose();
  }

  Color _colorFromHue(double hue) {
    final value = _intensity.clamp(0.72, 1.0).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.78, value).toColor();
  }

  void _applyThemeRealtime() {
    _themeSyncTimer?.cancel();
    _themeSyncTimer = Timer(const Duration(milliseconds: 70), () {
      widget.controller.setThemeColor(
        hue: _hue,
        intensity: _intensity,
      );
    });
  }

  void _showSavedSnack() {
    widget.controller.setThemeColor(
      hue: _hue,
      intensity: _intensity,
    );
    NebulaSnack.show(
      context,
      message: 'Listo. Tus cambios ya se aplicaron al instante.',
      ok: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Preferencias'),
      ),
      body: CosmicBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sonidos felices',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Elige una voz amiga',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      itemCount: _narrators.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.8,
                      ),
                      itemBuilder: (_, index) {
                        final option = _narrators[index];
                        final selected = option.$1 == _narratorId;
                        return InkWell(
                          onTap: () {
                            setState(() => _narratorId = option.$1);
                            widget.controller.setNarrator(option.$1);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? primary
                                    : primary.withValues(alpha: 0.20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(option.$2),
                                IconButton(
                                  onPressed: () {
                                    NebulaSnack.show(
                                      context,
                                      message:
                                          'Hola, soy ${option.$2}. Vamos a jugar y aprender juntos.',
                                      ok: true,
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  tooltip: 'Escuchar',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activar efectos divertidos'),
                      value: _soundEnabled,
                      onChanged: (value) {
                        setState(() => _soundEnabled = value);
                        widget.controller.setSoundEffects(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color de la app',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Se actualiza en tiempo real mientras eliges.'),
                    const SizedBox(height: 10),
                    GridView.builder(
                      itemCount: _hues.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.2,
                      ),
                      itemBuilder: (_, index) {
                        final hue = _hues[index];
                        final selected = hue == _hue;
                        return InkWell(
                          onTap: () {
                            setState(() => _hue = hue);
                            _applyThemeRealtime();
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: _colorFromHue(hue),
                              border: Border.all(
                                color: selected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Intensidad del color',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Slider(
                      value: _intensity,
                      min: 0.72,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() => _intensity = value);
                        _applyThemeRealtime();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            NebulaPrimaryButton(text: 'Listo, me gusta asi', onPressed: _showSavedSnack),
          ],
        ),
      ),
    );
  }
}
