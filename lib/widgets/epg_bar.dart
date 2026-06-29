import 'package:flutter/material.dart';

class EpgBar extends StatelessWidget {
  final double progress; // Expects 0.0 to 1.0

  const EpgBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    // Sanitize the input, but NEVER shrink to 0 width
    final safeValue = (progress.isNaN || progress.isInfinite)
        ? 0.0
        : progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: safeValue, // Even at 0.0, the background track will render!
        minHeight: 3.5,
        backgroundColor: Colors.white.withAlpha(
          45,
        ), // Made slightly brighter (18% opacity) so it's easy to see
        valueColor: const AlwaysStoppedAnimation<Color>(
          Color(0xFFE50914),
        ), // OTT Crimson
      ),
    );
  }
}
