import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class ImageCropEditorScreen extends StatefulWidget {
  const ImageCropEditorScreen({
    super.key,
    required this.imageBytes,
  });

  final Uint8List imageBytes;

  @override
  State<ImageCropEditorScreen> createState() => _ImageCropEditorScreenState();
}

class _ImageCropEditorScreenState extends State<ImageCropEditorScreen> {
  final CropController _cropController = CropController();
  bool _cropping = false;
  double? _aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text('Ajustar imagen'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cropping ? null : () => Navigator.of(context).pop(),
          tooltip: 'Cancelar',
        ),
        actions: [
          IconButton(
            icon: _cropping
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _cropping
                ? null
                : () {
                    setState(() => _cropping = true);
                    _cropController.crop();
                  },
            tooltip: 'Usar recorte',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Crop(
                      image: widget.imageBytes,
                      controller: _cropController,
                      interactive: true,
                      baseColor: const Color(0xFF020617),
                      maskColor: Colors.black.withValues(alpha: 0.45),
                      radius: 18,
                      clipBehavior: Clip.none,
                      aspectRatio: _aspectRatio,
                      initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                        size: 0.82,
                        aspectRatio: _aspectRatio,
                      ),
                      onCropped: (result) {
                        if (!mounted) return;
                        switch (result) {
                          case CropSuccess(:final croppedImage):
                            Navigator.of(context).pop(croppedImage);
                          case CropFailure():
                            setState(() => _cropping = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No pudimos recortar la imagen. Intenta de nuevo.',
                                ),
                              ),
                            );
                        }
                      },
                      cornerDotBuilder: (size, _) => Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFF0F172A),
                            width: 1.6,
                          ),
                        ),
                      ),
                      overlayBuilder: (context, rect) => const IgnorePointer(
                        child: CustomPaint(painter: _GridPainter()),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'Arrastra las esquinas para ajustar el \u00e1rea. Tambi\u00e9n puedes mover la imagen.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _AspectChip(
                    label: 'Libre',
                    selected: _aspectRatio == null,
                    onTap: () {
                      setState(() => _aspectRatio = null);
                      _cropController.aspectRatio = null;
                    },
                  ),
                  _AspectChip(
                    label: 'Cuadrado',
                    selected: _aspectRatio == 1,
                    onTap: () {
                      setState(() => _aspectRatio = 1);
                      _cropController.aspectRatio = 1;
                    },
                  ),
                  _AspectChip(
                    label: '4:3',
                    selected: _aspectRatio == (4 / 3),
                    onTap: () {
                      setState(() => _aspectRatio = 4 / 3);
                      _cropController.aspectRatio = 4 / 3;
                    },
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

class _AspectChip extends StatelessWidget {
  const _AspectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white70,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFF111827),
      side: BorderSide(
        color: selected ? Colors.transparent : Colors.white24,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    final dx = size.width / 3;
    final dy = size.height / 3;

    for (var i = 1; i < 3; i++) {
      final x = dx * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var i = 1; i < 3; i++) {
      final y = dy * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return false;
  }
}
