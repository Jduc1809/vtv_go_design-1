import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'api_service.dart';
import 'channel_data.dart';

class StreamScreen extends StatefulWidget {
  final Channel channel;
  const StreamScreen({super.key, required this.channel});

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  late Future<List<Program>> _futureSchedule;
  String? _errorMessage;

  late DateTime _selectedDate;
  late List<DateTime> _availableDates;

  List<ChannelSourceMode> _availableModes = [];
  ChannelSourceMode? _currentSelectedMode;

  @override
  void initState() {
    super.initState();

    _selectedDate = DateTime.now();
    _availableDates = List.generate(
      7,
      (index) => DateTime.now().subtract(Duration(days: 3 - index)),
    );

    _loadAndPlayBroadcast();
    _fetchScheduleForDate(_selectedDate);
  }

  void _fetchScheduleForDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _futureSchedule = ApiService.fetchChannelSchedule(
        widget.channel.id,
        targetDate: date,
      );
    });
  }

  Future<void> _loadAndPlayBroadcast() async {
    try {
      final streamData = await ApiService.fetchStreamData(widget.channel.id);

      if (streamData == null) {
        setState(() => _errorMessage = "Kênh không khả dụng");
        return;
      }

      if (streamData['sourceModes'] != null &&
          streamData['sourceModes'] is List) {
        final List rawModes = streamData['sourceModes'];
        _availableModes = rawModes
            .map((item) => ChannelSourceMode.fromJson(item))
            .toList();
      }

      if (_availableModes.isNotEmpty) {
        _currentSelectedMode = _availableModes.firstWhere(
          (mode) => mode.id == (streamData['sourceModeId'] ?? 'default'),
          orElse: () => _availableModes.first,
        );
      }

      final targetUrl = _currentSelectedMode?.streamUrl ?? '';
      if (targetUrl.isEmpty) {
        setState(() => _errorMessage = "Không tìm thấy luồng phát sóng hợp lệ");
        return;
      }

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(targetUrl),
      );
      await _videoPlayerController!.initialize();

      _initializeChewie();
    } catch (e) {
      setState(() => _errorMessage = "Không thể tải luồng video: $e");
    }
  }

  void _initializeChewie() {
    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        isLive: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        overlay: _buildDoubleTapSeekOverlay(),
        additionalOptions: (context) {
          if (_availableModes.isEmpty) return [];

          return [
            OptionItem(
              onTap: (BuildContext menuContext) {
                Navigator.pop(context);

                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.grey[900],
                  builder: (context) => ListView(
                    shrinkWrap: true,
                    children: _availableModes.map((mode) {
                      final isSelected = mode.id == _currentSelectedMode?.id;
                      return ListTile(
                        leading: Icon(
                          mode.isVip ? Icons.workspace_premium : Icons.hd,
                          color: mode.isVip ? Colors.amber : Colors.white54,
                        ),
                        title: Text(
                          mode.name,
                          style: TextStyle(
                            color: isSelected ? Colors.red : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          mode.description,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.red)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _switchResolutionMode(mode);
                        },
                      );
                    }).toList(),
                  ),
                );
              },
              iconData: Icons.settings_outlined,
              title: 'Chất lượng (${_currentSelectedMode?.name ?? "Mặc định"})',
            ),
          ];
        },
        errorBuilder: (context, errorMessage) => Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    });
  }

  Future<void> _switchResolutionMode(ChannelSourceMode selectedMode) async {
    if (_currentSelectedMode?.id == selectedMode.id) return;

    if (selectedMode.isVip) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedMode.name} yêu cầu tài khoản Premium VIP!'),
          backgroundColor: Colors.amber[800],
        ),
      );
      return;
    }

    if (selectedMode.streamUrl == null || selectedMode.streamUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Luồng phân giải này tạm thời không khả dụng'),
        ),
      );
      return;
    }

    final currentPosition =
        await _videoPlayerController?.position ?? Duration.zero;

    setState(() {
      _currentSelectedMode = selectedMode;
      _chewieController?.dispose();
      _chewieController = null;
    });

    final oldController = _videoPlayerController;

    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(selectedMode.streamUrl!),
    );
    await _videoPlayerController!.initialize();

    if (_videoPlayerController!.value.duration != Duration.zero) {
      await _videoPlayerController!.seekTo(currentPosition);
    }

    _initializeChewie();
    oldController?.dispose();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  String _extractDate(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return 'Unknown Date';
    if (dateTimeStr.contains('T')) return dateTimeStr.split('T')[0];
    if (dateTimeStr.contains(' ')) return dateTimeStr.split(' ')[0];
    return dateTimeStr;
  }

  String _extractTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return '--:--';
    String timePart = '';
    if (dateTimeStr.contains('T')) {
      timePart = dateTimeStr.split('T')[1];
    } else if (dateTimeStr.contains(' ')) {
      timePart = dateTimeStr.split(' ')[1];
    } else {
      return dateTimeStr;
    }
    return timePart.length >= 5 ? timePart.substring(0, 5) : timePart;
  }

  Future<void> _seekBackward() async {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      return;
    }
    final currentPosition = await _videoPlayerController!.position;
    if (currentPosition != null) {
      final newPosition = currentPosition - const Duration(seconds: 5);
      _videoPlayerController!.seekTo(
        newPosition < Duration.zero ? Duration.zero : newPosition,
      );
    }
  }

  Future<void> _seekForward() async {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      return;
    }
    final currentPosition = await _videoPlayerController!.position;
    if (currentPosition == null) return;
    final duration = _videoPlayerController!.value.duration;
    final newPosition = currentPosition + const Duration(seconds: 5);

    if (duration != Duration.zero && newPosition > duration) {
      _videoPlayerController!.seekTo(duration);
    } else {
      _videoPlayerController!.seekTo(newPosition);
    }
  }

  Widget _buildDoubleTapSeekOverlay() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: () {
              _seekBackward();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⏪ Lùi 5s'),
                  duration: Duration(milliseconds: 500),
                ),
              );
            },
            child: const SizedBox.expand(),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: () {
              _seekForward();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⏩ Tiến 5s'),
                  duration: Duration(milliseconds: 500),
                ),
              );
            },
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.channel.name,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.black,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _errorMessage != null
                ? AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.grey[900],
                      child: Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  )
                : _chewieController != null &&
                      _chewieController!
                          .videoPlayerController
                          .value
                          .isInitialized
                ? AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: Chewie(controller: _chewieController!),
                  )
                : const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    ),
                  ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Lịch Phát Sóng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableDates.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (context, index) {
                        final date = _availableDates[index];
                        final isSelected =
                            date.day == _selectedDate.day &&
                            date.month == _selectedDate.month;

                        final now = DateTime.now();
                        String labelText = '${date.day}/${date.month}';
                        if (date.day == now.day && date.month == now.month) {
                          labelText = 'Hôm nay';
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(
                              labelText,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.red,
                            backgroundColor: Colors.grey[900],
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (selected) {
                              if (selected && !isSelected) {
                                _fetchScheduleForDate(date);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Program>>(
                    future: _futureSchedule,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.red),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'Lỗi: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'Không có chương trình khả dụng',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      final schedule = snapshot.data!;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: schedule.length,
                        itemBuilder: (context, index) {
                          final program = schedule[index];

                          final String currentDate = _extractDate(
                            program.startDate,
                          );
                          final String previousDate = index > 0
                              ? _extractDate(schedule[index - 1].startDate)
                              : '';
                          final bool isNewDateSection =
                              currentDate != previousDate;

                          final String displayStartTime = _extractTime(
                            program.startDate,
                          );
                          final String displayEndTime = _extractTime(
                            program.endDate,
                          );

                          Widget programTile = Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              tileColor: program.isLive
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : Colors.grey[900],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: program.isLive
                                    ? const BorderSide(color: Colors.red)
                                    : BorderSide.none,
                              ),
                              onTap: () {
                                if (program.isLive) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Bạn đang xem trực tiếp chương trình này',
                                      ),
                                    ),
                                  );
                                } else if (program.isPlayable) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Chuyển sang: ${program.title}...',
                                      ),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Chương trình không thể xem lại',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                              leading: SizedBox(
                                width: 55,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      displayStartTime,
                                      style: TextStyle(
                                        color: program.isLive
                                            ? Colors.red
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      displayEndTime,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(
                                program.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: program.isLive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: program.isLive
                                  ? const Chip(
                                      label: Text(
                                        'LIVE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                      side: BorderSide.none,
                                    )
                                  : program.isPlayable
                                  ? const Icon(
                                      Icons.replay,
                                      color: Colors.blueAccent,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          );

                          if (isNewDateSection) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    top: 16,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    currentDate,
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                programTile,
                              ],
                            );
                          }

                          return programTile;
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
