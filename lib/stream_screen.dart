import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:video_player/video_player.dart';

import 'api_service.dart';
import 'channel_data.dart';
import 'custom_video_player.dart';

class StreamScreen extends StatefulWidget {
  final Channel channel;
  const StreamScreen({super.key, required this.channel});

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  VideoPlayerController? _videoPlayerController;

  late Future<List<Program>> _futureSchedule;
  String? _errorMessage;

  late DateTime _selectedDate;
  late List<DateTime> _availableDates;

  List<ChannelSourceMode> _availableModes = [];
  ChannelSourceMode? _currentSelectedMode;

  Program? _currentlyPlayingProgram;

  // Simple cache for schedules
  final Map<String, List<Program>> _scheduleCache = {};

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _availableDates = List.generate(
      7,
      (index) => _selectedDate.subtract(Duration(days: 3 - index)),
    );

    _loadAndPlayBroadcast();
    _fetchScheduleForDate(_selectedDate);
  }

  void _fetchScheduleForDate(DateTime date) {
    final dateKey = _formatDateKey(date);
    setState(() {
      _selectedDate = date;
      if (_scheduleCache.containsKey(dateKey)) {
        _futureSchedule = Future.value(_scheduleCache[dateKey]);
      } else {
        _futureSchedule = ApiService.fetchChannelSchedule(
          widget.channel.id,
          targetDate: date,
        ).then((schedule) {
          _scheduleCache[dateKey] = schedule;
          return schedule;
        });
      }
    });
  }

  String _formatDateKey(DateTime date) => "${date.year}-${date.month}-${date.day}";

  Future<void> _disposeCurrentPlayer() async {
    if (_videoPlayerController != null) {
      final controller = _videoPlayerController!;
      _videoPlayerController = null; // Prevent further access
      await controller.pause();
      await controller.dispose();
    }
  }

  Future<void> _loadAndPlayBroadcast() async {
    setState(() {
      _errorMessage = null;
      _currentlyPlayingProgram = null;
    });

    await _disposeCurrentPlayer();

    try {
      final streamData = await ApiService.fetchStreamData(widget.channel.id);

      if (streamData == null) {
        if (mounted) setState(() => _errorMessage = "Kênh không khả dụng");
        return;
      }

      if (streamData['sourceModes'] is List) {
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
        if (mounted) setState(() => _errorMessage = "Không tìm thấy luồng phát sóng hợp lệ");
        return;
      }

      await _initializeAndPlay(targetUrl);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Không thể tải luồng video: $e");
    }
  }

  Future<void> _initializeAndPlay(String url, {Duration? seekTo}) async {
    final oldController = _videoPlayerController;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      
      if (seekTo != null && controller.value.duration > seekTo) {
        await controller.seekTo(seekTo);
      }
      
      if (mounted) {
        setState(() {
          _videoPlayerController = controller;
        });
        controller.play();
        
        // Dispose old controller after new one starts playing
        if (oldController != null) {
          oldController.pause();
          oldController.dispose();
        }
      } else {
        controller.dispose();
        oldController?.dispose();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = "Không thể phát video: $e");
      }
    }
  }

  void _showResolutionMenu() {
    if (_availableModes.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: _availableModes.map((mode) {
          final isSelected = mode.id == _currentSelectedMode?.id;
          return ListTile(
            leading: Icon(
              mode.isVip ? Icons.workspace_premium : Icons.hd,
              color: mode.isVip ? Colors.amber : (isSelected ? Colors.red : Colors.white54),
            ),
            title: Text(
              mode.name,
              style: TextStyle(
                color: isSelected ? Colors.red : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              mode.description,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.red)
                : null,
            onTap: () {
              Navigator.pop(context);
              _switchResolutionMode(mode);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _switchResolutionMode(ChannelSourceMode selectedMode) async {
    if (_currentSelectedMode?.id == selectedMode.id) return;

    if (selectedMode.isVip) {
      _showSnackBar('${selectedMode.name} yêu cầu tài khoản Premium VIP!', Colors.amber[800]);
      return;
    }

    final targetUrl = selectedMode.streamUrl;
    if (targetUrl == null || targetUrl.isEmpty) {
      _showSnackBar('Luồng phân giải này tạm thời không khả dụng');
      return;
    }

    final currentPosition = await _videoPlayerController?.position ?? Duration.zero;

    setState(() {
      _currentSelectedMode = selectedMode;
    });

    await _initializeAndPlay(targetUrl, seekTo: currentPosition);
  }

  void _showSnackBar(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Future<void> _playProgramVOD(Program program) async {
    if (_currentlyPlayingProgram?.id == program.id) return;

    if (program.isLive) {
      await _loadAndPlayBroadcast();
      return;
    }

    if (program.isFuture) {
      _showSnackBar('Chương trình ${program.title} chưa bắt đầu!', Colors.orange);
      return;
    }

    setState(() {
      _currentlyPlayingProgram = program;
      _errorMessage = null;
    });

    try {
      final targetUrl = await ApiService.fetchProgramStreamUrl(
        widget.channel.id,
        program.id,
      );

      if (targetUrl == null || targetUrl.isEmpty) {
        if (mounted) setState(() => _errorMessage = "Chương trình không thể xem lại");
        return;
      }

      await _initializeAndPlay(targetUrl);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Không thể tải luồng video: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color pureBlack = Colors.black;
    const Color sheetColor = Color(0xFF1C1C1E);

    return Scaffold(
      backgroundColor: pureBlack,
      appBar: AppBar(
        backgroundColor: pureBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.channel.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_currentlyPlayingProgram != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                icon: const Icon(Icons.emergency_recording, color: Colors.redAccent, size: 18),
                label: const Text('LIVE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onPressed: _loadAndPlayBroadcast,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _VideoSection(
            errorMessage: _errorMessage,
            controller: _videoPlayerController,
            isLive: _currentlyPlayingProgram == null,
            onSettingsTap: _showResolutionMenu,
            channelName: widget.channel.name,
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: sheetColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DragHandle(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Text(
                      'Lịch Phát Sóng',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _DateSelector(
                    availableDates: _availableDates,
                    selectedDate: _selectedDate,
                    onDateSelected: _fetchScheduleForDate,
                    formatDate: _formatDate,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _ScheduleList(
                      futureSchedule: _futureSchedule,
                      currentlyPlayingProgram: _currentlyPlayingProgram,
                      onProgramTap: _playProgramVOD,
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

class _VideoSection extends StatelessWidget {
  final String? errorMessage;
  final VideoPlayerController? controller;
  final bool isLive;
  final VoidCallback onSettingsTap;
  final String channelName;

  const _VideoSection({
    required this.errorMessage,
    required this.controller,
    required this.isLive,
    required this.onSettingsTap,
    required this.channelName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
      child: errorMessage != null
          ? AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red))),
            )
          : controller != null && controller!.value.isInitialized
              ? Center(
                  child: CustomVideoPlayer(
                    controller: controller!,
                    isLive: isLive,
                    onSettingsTap: onSettingsTap,
                    shareText: 'Xem $channelName trên VTV Go!',
                  ),
                )
              : const AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[600],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final List<DateTime> availableDates;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final String Function(DateTime) formatDate;

  const _DateSelector({
    required this.availableDates,
    required this.selectedDate,
    required this.onDateSelected,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF2C2C2E);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableDates.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final date = availableDates[index];
          final isSelected = date.day == selectedDate.day && date.month == selectedDate.month;
          return GestureDetector(
            onTap: () {
              if (!isSelected) onDateSelected(date);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12, top: 4, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isSelected ? null : cardColor,
                border: isSelected ? null : Border.all(color: Colors.grey[700]!, width: 1),
                gradient: isSelected
                    ? LinearGradient(
                        colors: [Colors.orange[400]!, Colors.deepOrange[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                boxShadow: isSelected
                    ? const [BoxShadow(color: Color(0x66FF5722), blurRadius: 8, offset: Offset(0, 4))]
                    : const [],
              ),
              child: Center(
                child: Text(
                  formatDate(date),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[400],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  final Future<List<Program>> futureSchedule;
  final Program? currentlyPlayingProgram;
  final Function(Program) onProgramTap;

  const _ScheduleList({
    required this.futureSchedule,
    required this.currentlyPlayingProgram,
    required this.onProgramTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Program>>(
      future: futureSchedule,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        final schedule = snapshot.data ?? [];
        if (schedule.isEmpty) {
          return const Center(child: Text('Không có chương trình khả dụng', style: TextStyle(color: Colors.grey)));
        }

        int liveIndex = schedule.indexWhere((p) => p.isLive);
        int targetIndex = liveIndex > 0 ? liveIndex - 1 : 0;

        return ScrollablePositionedList.builder(
          initialScrollIndex: targetIndex,
          padding: const EdgeInsets.only(bottom: 24, top: 8),
          itemCount: schedule.length,
          itemBuilder: (context, index) => _ProgramItem(
            program: schedule[index],
            isPlaying: (currentlyPlayingProgram == null && schedule[index].isLive) || (currentlyPlayingProgram?.id == schedule[index].id),
            onTap: () => onProgramTap(schedule[index]),
          ),
        );
      },
    );
  }
}

class _ProgramItem extends StatelessWidget {
  final Program program;
  final bool isPlaying;
  final VoidCallback onTap;

  const _ProgramItem({
    required this.program,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF2C2C2E);
    final bool isRedText = isPlaying || program.isLive;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isPlaying ? Border.all(color: const Color(0x80F44336), width: 1) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.formattedStartTime,
                    style: TextStyle(
                      color: isRedText ? Colors.redAccent : Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    program.title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 40, color: Colors.grey[700]),
            const SizedBox(width: 16),
            _PlayStatus(isPlaying: isPlaying, isLive: program.isLive, isRedText: isRedText),
          ],
        ),
      ),
    );
  }
}

class _PlayStatus extends StatelessWidget {
  final bool isPlaying;
  final bool isLive;
  final bool isRedText;

  const _PlayStatus({
    required this.isPlaying,
    required this.isLive,
    required this.isRedText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Icon(isPlaying ? Icons.play_arrow : Icons.play_arrow_rounded, color: Colors.black, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          isPlaying ? (isLive ? 'Trực Tiếp' : 'Đang Phát') : (isLive ? 'Trực Tiếp' : 'Xem Lại'),
          style: TextStyle(
            color: isRedText ? Colors.redAccent : Colors.grey[400],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
