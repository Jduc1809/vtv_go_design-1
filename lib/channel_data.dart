class Program {
  final String id;
  final String title;
  final String startDate;
  final String endDate;
  final bool isLive;
  final bool isPlayable;

  Program({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.isLive,
    required this.isPlayable,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Program',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',

      isLive: json['isLive'] == 1 || json['isLive'] == true,
      isPlayable: json['isPlayable'] == 1 || json['isPlayable'] == true,
    );
  }
}

class CurrentProgram {
  final String title;
  final String startDate;
  final String endDate;

  CurrentProgram({
    required this.title,
    required this.startDate,
    required this.endDate,
  });

  factory CurrentProgram.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CurrentProgram(title: 'Đang Chiếu', startDate: '', endDate: '');
    }
    return CurrentProgram(
      title: json['title'] ?? 'Live Broadcast',
      startDate: json['startTime'] ?? '',
      endDate: json['endTime'] ?? '',
    );
  }
}

class ChannelCategory {
  final String id;
  final String name;
  final List<Channel> channels;

  ChannelCategory({
    required this.id,
    required this.name,
    required this.channels,
  });

  factory ChannelCategory.fromJson(Map<String, dynamic> json) {
    var channelList = json['channels'] as List? ?? [];
    List<Channel> parsedChannels = channelList
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

  Channel({
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

  ChannelSourceMode({
    required this.id,
    required this.name,
    required this.description,
    required this.isVip,
    this.streamUrl,
  });

  factory ChannelSourceMode.fromJson(Map<String, dynamic> json) {
    String? extractedUrl;

    if (json['multiSource'] != null &&
        json['multiSource'] is List &&
        json['multiSource'].isNotEmpty) {
      final multiSource = json['multiSource'][0];
      if (multiSource['sources'] != null &&
          multiSource['sources'] is List &&
          multiSource['sources'].isNotEmpty) {
        extractedUrl = multiSource['sources'][0]['url'];
      }
    }

    return ChannelSourceMode(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['textDescription'] ?? '',
      isVip: json['isVip'] == 1,
      streamUrl: extractedUrl,
    );
  }
}
