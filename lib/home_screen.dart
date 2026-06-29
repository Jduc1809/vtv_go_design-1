import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'channel_data.dart';
import 'stream_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<ChannelCategory>> _homeDataFuture;
  List<String> _favoriteIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadFavorites();
  }

  void _loadData() {
    _homeDataFuture = ApiService.fetchHomeData();
  }

  // Load saved favorite IDs from device storage
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteIds = prefs.getStringList('favorite_channels') ?? [];
    });
  }

  // Toggle favorite status and save to device
  Future<void> _toggleFavorite(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteIds.contains(channelId)) {
        _favoriteIds.remove(channelId);
      } else {
        _favoriteIds.add(channelId);
      }
    });
    await prefs.setStringList('favorite_channels', _favoriteIds);
  }

  Future<void> _refreshData() async {
    await _loadFavorites();
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color pureBlack = Color(0xFF0F1115); // Deep cinema black
    const Color accentColor = Colors.redAccent;

    return Scaffold(
      backgroundColor: pureBlack,
      body: RefreshIndicator(
        color: accentColor,
        backgroundColor: Colors.grey[900],
        onRefresh: _refreshData,
        child: FutureBuilder<List<ChannelCategory>>(
          future: _homeDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: accentColor),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final categories = snapshot.data ?? [];
            if (categories.isEmpty) {
              return const Center(
                child: Text(
                  'Không có dữ liệu kênh.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            // Extract all channels across categories to build the Favorites row
            final allChannels = categories
                .expand((cat) => cat.channels)
                .toList();
            final favoriteChannels = allChannels
                .where((channel) => _favoriteIds.contains(channel.id))
                // Prevent duplicates if a channel appears in multiple API categories
                .fold<List<Channel>>([], (list, channel) {
                  if (!list.any((c) => c.id == channel.id)) list.add(channel);
                  return list;
                });

            return CustomScrollView(
              slivers: [
                // 1. Sticky Frosted Header
                SliverAppBar(
                  backgroundColor: pureBlack.withValues(alpha: 0.9),
                  elevation: 0,
                  pinned: true,
                  floating: true,
                  title: const Text(
                    'VTV Go',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),

                if (allChannels.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _HeroSpotlightCard(channel: allChannels.first),
                  ),

                // 2. Local Favorites Quick-Lane (Only shows if favorites exist)
                if (favoriteChannels.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 16.0,
                        top: 16.0,
                        bottom: 8.0,
                      ),
                      child: Text(
                        'KÊNH YÊU THÍCH',
                        style: TextStyle(
                          color: Colors
                              .amber, // Accent color specifically for favorites
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: favoriteChannels.length,
                        itemBuilder: (context, index) {
                          final channel = favoriteChannels[index];
                          return _FavoriteCircleCard(channel: channel);
                        },
                      ),
                    ),
                  ),
                ],

                // 3. Dynamic Category Swimlanes
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _CategoryRow(
                      category: categories[index],
                      favoriteIds: _favoriteIds,
                      onFavoriteToggled: _toggleFavorite,
                    );
                  }, childCount: categories.length),
                ),

                // Bottom spacer
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Text(
            'Lỗi tải dữ liệu:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: _refreshData,
            child: const Text('Thử Lại', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final ChannelCategory category;
  final List<String> favoriteIds;
  final Function(String) onFavoriteToggled;

  const _CategoryRow({
    required this.category,
    required this.favoriteIds,
    required this.onFavoriteToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 12.0),
          child: Text(
            category.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: category.channels.length,
            itemBuilder: (context, index) {
              final channel = category.channels[index];
              final isFavorited = favoriteIds.contains(channel.id);
              return _ChannelMiniCard(
                channel: channel,
                isFavorited: isFavorited,
                onFavoriteToggled: () => onFavoriteToggled(channel.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChannelMiniCard extends StatelessWidget {
  final Channel channel;
  final bool isFavorited;
  final VoidCallback onFavoriteToggled;

  const _ChannelMiniCard({
    required this.channel,
    required this.isFavorited,
    required this.onFavoriteToggled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StreamScreen(channel: channel),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            width: 150,
            margin: const EdgeInsets.symmetric(horizontal: 6.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[900]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.network(
                      channel.logo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.tv,
                          color: Colors.grey,
                          size: 40,
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    channel.currentProgram.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          // Heart icon layer to pin/unpin favorites smoothly
          Positioned(
            top: 4,
            right: 10,
            child: GestureDetector(
              onTap: onFavoriteToggled,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.red : Colors.white70,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Compact circular layout for the dedicated top favorites tray
class _FavoriteCircleCard extends StatelessWidget {
  final Channel channel;

  const _FavoriteCircleCard({required this.channel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StreamScreen(channel: channel),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        key: ValueKey(channel.id),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.network(
                    channel.logo,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.tv, color: Colors.grey, size: 24);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 75,
              child: Text(
                channel.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Zone 2: Flagship Hero Spotlight Banner
class _HeroSpotlightCard extends StatelessWidget {
  final Channel channel;

  const _HeroSpotlightCard({required this.channel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StreamScreen(channel: channel),
          ),
        );
      },
      child: Container(
        height: 210,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[850]!, width: 1),
          // Fallback dark gradient if image takes a second to load
          gradient: const LinearGradient(
            colors: [Color(0xFF2C141A), Color(0xFF141518)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: Background Art (Using channel logo as fallback poster)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Image.network(
                  channel.logo,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                  color: Colors.white.withValues(
                    alpha: 0.15,
                  ), // Dimmed watermark effect
                  colorBlendMode: BlendMode.modulate,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),

              // Layer 2: Dark Vignette gradient for text readability
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),

              // Layer 3: UI Overlays (Live Badge + Titles + Play Button)
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Live Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCF0A2C), // Official VTV Red
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                color: Colors.white,
                                size: 10,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'TRỰC TIẾP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          channel.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Bottom Row: Show Title & Call to Action Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Đang phát sóng:',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                channel.currentProgram.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Frosted Play Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Xem Ngay',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
