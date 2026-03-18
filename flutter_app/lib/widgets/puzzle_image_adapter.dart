import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

Uint8List? decodePuzzleDataUriBytes(String source) {
  final trimmed = source.trim();
  const marker = ';base64,';
  final markerIndex = trimmed.indexOf(marker);
  if (!trimmed.startsWith('data:image/') || markerIndex <= 0) {
    return null;
  }
  try {
    final encoded = trimmed.substring(markerIndex + marker.length);
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}

ImageProvider<Object>? puzzleImageProviderFromSource(String source) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();

  if (lower.startsWith('data:image/')) {
    final bytes = decodePuzzleDataUriBytes(trimmed);
    if (bytes == null || bytes.isEmpty) return null;
    return MemoryImage(bytes);
  }
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return NetworkImage(trimmed);
  }
  if (trimmed.startsWith('assets/')) {
    return AssetImage(trimmed);
  }
  final file = File(trimmed);
  if (file.existsSync()) {
    return FileImage(file);
  }
  return null;
}

Future<void> evictPuzzleImageSource(String source) async {
  final provider = puzzleImageProviderFromSource(source);
  if (provider == null) return;
  await provider.evict();
}

class PuzzleImageAdapter extends StatelessWidget {
  const PuzzleImageAdapter({
    super.key,
    required this.imageSource,
    required this.size,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  final String imageSource;
  final double size;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final provider = puzzleImageProviderFromSource(imageSource);
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: provider == null
            ? const ColoredBox(
                color: Color(0xFFE8ECF7),
                child: Icon(Icons.broken_image_outlined),
              )
            : Image(
                image: provider,
                fit: fit,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFFE8ECF7),
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}
