class EpgService {
  static double calculateProgress(String startTimeStr, String endTimeStr) {
    try {
      final now = DateTime.now();
      final start = _parseTimeToday(startTimeStr, now);
      var end = _parseTimeToday(endTimeStr, now);

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

  // Parameter renamed to 'baseDate' to be 100% bulletproof
  static DateTime _parseTimeToday(String timeStr, DateTime baseDate) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }
}
