import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
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

        allowMuting: true,
        allowPlaybackSpeedChanging: false,

        overlay: _buildDoubleTapSeekOverlay(),
        additionalOptions: (context) {
          if (_availableModes.isEmpty) return [];

          return [
            OptionItem(
              onTap: (BuildContext menuContext) {
                Navigator.pop(menuContext);

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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return "$day/$month/$year";
  }

  String _extractTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return '--:--';

    try {
      String safeStr = dateTimeStr;
      if (!safeStr.endsWith('Z') && !safeStr.contains('+')) {
        safeStr += 'Z';
      }

      final DateTime parsedTime = DateTime.parse(safeStr).toLocal();

      final String hour = parsedTime.hour.toString().padLeft(2, '0');
      final String minute = parsedTime.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    } catch (e) {
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
    return Stack(
      children: [
        Positioned.fill(
          child: Row(
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
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color pureBlack = Colors.black;
    const Color sheetColor = Color(0xFF1C1C1E);
    const Color cardColor = Color(0xFF2C2C2E);

    return Scaffold(
      backgroundColor: pureBlack,
      appBar: AppBar(
        backgroundColor: pureBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.channel.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () {
              final String shareText =
                  'Xem ${widget.channel.name} trên VTV Go!';

              final size = MediaQuery.of(context).size;

              SharePlus.instance.share(
                ShareParams(
                  text: shareText,
                  sharePositionOrigin: Rect.fromLTWH(
                    0,
                    0,
                    size.width,
                    size.height / 2,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. VIDEO PLAYER AREA
          Container(
            width: double.infinity,
            color: pureBlack,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: _errorMessage != null
                ? AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                : _chewieController != null &&
                      _chewieController!
                          .videoPlayerController
                          .value
                          .isInitialized
                ? Center(
                    child: AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: Chewie(controller: _chewieController!),
                    ),
                  )
                : const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
          ),

          // 2. SCHEDULE & BOTTOM SHEET AREA
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: sheetColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Lịch Phát Sóng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Date Selector
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableDates.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final date = _availableDates[index];
                        final isSelected =
                            date.day == _selectedDate.day &&
                            date.month == _selectedDate.month;
                        final labelText = _formatDate(date);

                        return GestureDetector(
                          onTap: () {
                            if (!isSelected) _fetchScheduleForDate(date);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(
                              right: 12,
                              top: 4,
                              bottom: 8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: isSelected ? null : cardColor,
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: Colors.grey[700]!,
                                      width: 1,
                                    ),
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        Colors.orange[400]!,
                                        Colors.deepOrange[500]!,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.deepOrange.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                labelText,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Program Schedule List
                  const SizedBox(height: 8),
                  Expanded(
                    child: FutureBuilder<List<Program>>(
                      future: _futureSchedule,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Lỗi: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'Không có chương trình khả dụng',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        final schedule = snapshot.data!;

                        int liveIndex = schedule.indexWhere(
                          (program) => program.isLive,
                        );

                        int targetIndex = 0;
                        if (liveIndex > 0) {
                          targetIndex = liveIndex - 1;
                        }

                        return ScrollablePositionedList.builder(
                          initialScrollIndex: targetIndex,
                          padding: const EdgeInsets.only(bottom: 24, top: 8),
                          itemCount: schedule.length,
                          itemBuilder: (context, index) {
                            final program = schedule[index];
                            final String displayStartTime = _extractTime(
                              program.startDate,
                            );

                            return GestureDetector(
                              onTap: () {
                                if (!program.isLive) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Chức năng xem lại sẽ sớm được cập nhật!',
                                      ),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: program.isLive
                                      ? Border.all(
                                          color: Colors.red.withValues(
                                            alpha: 0.5,
                                          ),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayStartTime,
                                            style: TextStyle(
                                              color: program.isLive
                                                  ? Colors.redAccent
                                                  : Colors.grey[400],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            program.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.2,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            program.isLive
                                                ? Icons.play_arrow
                                                : Icons.play_arrow_rounded,
                                            color: pureBlack,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          program.isLive
                                              ? 'Trực Tiếp'
                                              : 'Xem Lại',
                                          style: TextStyle(
                                            color: program.isLive
                                                ? Colors.redAccent
                                                : Colors.grey[400],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
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
