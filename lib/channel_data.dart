class Program {
  final String id;
  final String title;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String rawStartDate;
  final String rawEndDate;
  final bool isLive;
  final bool isPlayable;

  const Program({
    required this.id,
    required this.title,
    this.startDateTime,
    this.endDateTime,
    required this.rawStartDate,
    required this.rawEndDate,
    required this.isLive,
    required this.isPlayable,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    final rawStart = json['startDate']?.toString() ?? '';
    final rawEnd = json['endDate']?.toString() ?? '';

    return Program(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Program',
      rawStartDate: rawStart,
      rawEndDate: rawEnd,
      startDateTime: _parseDateTime(rawStart),
      endDateTime: _parseDateTime(rawEnd),
      isLive: _parseBool(json['isLive']),
      isPlayable: _parseBool(json['isPlayable']),
    );
  }

  static DateTime? _parseDateTime(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      String safeStr = dateStr;
      if (!safeStr.endsWith('Z') && !safeStr.contains('+')) {
        safeStr += 'Z';
      }
      return DateTime.parse(safeStr).toLocal();
    } catch (_) {
      return null;
    }
  }

  static bool _parseBool(dynamic value) {
    return value == 1 || value == true;
  }

  String get formattedStartTime {
    if (startDateTime == null) {
      return rawStartDate.length >= 5 ? rawStartDate.substring(0, 5) : '--:--';
    }
    return "${startDateTime!.hour.toString().padLeft(2, '0')}:${startDateTime!.minute.toString().padLeft(2, '0')}";
  }

  bool get isFuture {
    if (startDateTime == null) return false;
    return startDateTime!.isAfter(DateTime.now());
  }
}

class CurrentProgram {
  final String title;
  final String startDate;
  final String endDate;
  final int progressPercent;

  const CurrentProgram({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.progressPercent,
  });

  factory CurrentProgram.fromJson(Map<String, dynamic>? json) {
    // THE PLUTO TV ALGORITHM:
    // Derives a real-time completion ratio (8% to 95%) based on the device clock
    final now = DateTime.now();
    final int secondsIntoBlock = (now.minute % 30 * 60) + now.second;
    final int syntheticProgress = ((secondsIntoBlock / 1800) * 100)
        .clamp(8, 95)
        .toInt();

    if (json == null) {
      return CurrentProgram(
        title: 'Chương trình trực tiếp',
        startDate: '',
        endDate: '',
        progressPercent: syntheticProgress, // <-- INSTANT CRIMSON PAINT
      );
    }

    int progress = 0;
    final rawProgress = json['progressPercent'];
    if (rawProgress is num) {
      progress = rawProgress.toInt();
    } else if (rawProgress is String) {
      progress = int.tryParse(rawProgress.replaceAll('%', '').trim()) ?? 0;
    }

    // If the server sends a dead 0% payload, override it with the live clock!
    if (progress <= 0) {
      progress = syntheticProgress;
    }

    return CurrentProgram(
      title: json['name']?.toString() ?? 'Chương trình trực tiếp',
      startDate: json['startIsoTime']?.toString() ?? '',
      endDate: json['endIsoTime']?.toString() ?? '',
      progressPercent: progress,
    );
  }
}

class ChannelCategory {
  final String id;
  final String name;
  final List<Channel> channels;

  const ChannelCategory({
    required this.id,
    required this.name,
    required this.channels,
  });

  factory ChannelCategory.fromJson(Map<String, dynamic> json) {
    final channelList = json['channels'] as List? ?? [];
    final parsedChannels = channelList
        .whereType<Map<String, dynamic>>()
        .map((c) => Channel.fromJson(c))
        .toList();

    return ChannelCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Category',
      channels: parsedChannels,
    );
  }
}

class Channel {
  final String id;
  final String name;
  final String logo;
  final int pressedIndex;
  final String thumbnail;
  final CurrentProgram currentProgram;

  const Channel({
    required this.id,
    required this.name,
    required this.logo,
    required this.pressedIndex,
    required this.thumbnail,
    required this.currentProgram,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Channel',
      logo: json['logo'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      pressedIndex: json['pressedIndex'] ?? 0,
      currentProgram: CurrentProgram.fromJson(json['currentProgram']),
    );
  }
}

class ChannelSourceMode {
  final String id;
  final String name;
  final String description;
  final bool isVip;
  final String? streamUrl;

  const ChannelSourceMode({
    required this.id,
    required this.name,
    required this.description,
    required this.isVip,
    this.streamUrl,
  });

  factory ChannelSourceMode.fromJson(Map<String, dynamic> json) {
    String? extractedUrl;

    if (json['multiSource'] is List &&
        (json['multiSource'] as List).isNotEmpty) {
      final multiSource = json['multiSource'][0];
      if (multiSource['sources'] is List &&
          (multiSource['sources'] as List).isNotEmpty) {
        extractedUrl = multiSource['sources'][0]['url'];
      }
    }

    if ((extractedUrl == null || extractedUrl.isEmpty) &&
        json['sources'] is List &&
        (json['sources'] as List).isNotEmpty) {
      extractedUrl = json['sources'][0]['url'];
    }

    if ((extractedUrl == null || extractedUrl.isEmpty) && json['url'] != null) {
      extractedUrl = json['url']?.toString();
    }

    return ChannelSourceMode(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Auto',
      description: json['textDescription']?.toString() ?? '',
      isVip: json['isVip'] == 1 || json['isVip'] == true,
      streamUrl: extractedUrl,
    );
  }
}
