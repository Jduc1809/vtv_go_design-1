class EpgService {
  static double calculateProgress(String startTimeStr, String endTimeStr) {
    try {
      if (startTimeStr.isEmpty || endTimeStr.isEmpty) return 0.0;

      final now = DateTime.now();

      // Use Dart's built-in parsing which handles ISO strings
      final start =
          DateTime.tryParse(startTimeStr) ?? _parseLegacy(startTimeStr, now);
      var end = DateTime.tryParse(endTimeStr) ?? _parseLegacy(endTimeStr, now);

      // Midnight rollover logic
      if (end.isBefore(start)) {
        end = end.add(const Duration(days: 1));
      }

      final totalDuration = end.difference(start).inSeconds;
      final elapsed = now.difference(start).inSeconds;

      if (totalDuration <= 0) return 0.0;
      if (elapsed < 0) return 0.0;
      if (elapsed > totalDuration) return 1.0;

      return elapsed / totalDuration;
    } catch (e) {
      return 0.0;
    }
  }

  // Fallback for HH:mm strings
  static DateTime _parseLegacy(String timeStr, DateTime baseDate) {
    final parts = timeStr.split(':');
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
