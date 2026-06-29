import 'dart:async';

import 'package:flutter/material.dart';

import 'epg_service.dart';

class LiveProgressBar extends StatefulWidget {
  final String startTime;
  final String endTime;

  const LiveProgressBar({
    super.key,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<LiveProgressBar> createState() => _LiveProgressBarState();
}

class _LiveProgressBarState extends State<LiveProgressBar> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateProgress();
    // Wake up every 30 seconds to nudge the red line forward
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateProgress();
    });
  }

  void _updateProgress() {
    if (!mounted) return;
    setState(() {
      _progress = EpgService.calculateProgress(
        widget.startTime,
        widget.endTime,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Kill the timer if user scrolls card off-screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: _progress,
        minHeight: 3.5, // Razor-thin cinema look
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        valueColor: const AlwaysStoppedAnimation<Color>(
          Color(0xFFE50914),
        ), // OTT Crimson
      ),
    );
  }
}
