import 'package:flutter/material.dart';

class LiveProgressBar extends StatelessWidget {
  // If progress is null, default to 0.0
  final double? progress;

  const LiveProgressBar({super.key, this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        // Default to 0.0 if progress is null
        value: (progress ?? 0.0).clamp(0.0, 1.0),
        minHeight: 3.5,
        backgroundColor: Colors.white.withAlpha(38),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
      ),
    );
  }
}
