import 'package:flutter/material.dart';

class LiveProgressBar extends StatelessWidget {
  final double? progress;

  const LiveProgressBar({super.key, this.progress});

  @override
  Widget build(BuildContext context) {
    // Converts the 0-1 decimal into a safe width factor
    final safeValue = (progress ?? 0.0).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: safeValue,
        minHeight: 3.5, // Razor-thin OTT look
        backgroundColor: Colors.white.withAlpha(38),
        valueColor: const AlwaysStoppedAnimation<Color>(
          Color(0xFFE50914),
        ), // OTT Crimson
      ),
    );
  }
}
