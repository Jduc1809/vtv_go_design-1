import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'channel_data.dart';
import 'search_screen.dart';
import 'stream_screen.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  late Future<List<ChannelCategory>> _futureCategories;
  static const Color bgColor = Color(0xFF141415);

  @override
  void initState() {
    super.initState();
    _futureCategories = ApiService.fetchHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChannelCategory>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: bgColor,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: Text(
                'Không thể tải danh sách kênh.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final categories = snapshot.data!;
        return DefaultTabController(
          length: categories.length,
          child: Scaffold(
            backgroundColor: bgColor,
            appBar: _ChannelsAppBar(categories: categories),
            body: TabBarView(
              children: categories
                  .map((category) => _CategoryGrid(category: category))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

class _ChannelsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<ChannelCategory> categories;

  const _ChannelsAppBar({required this.categories});

  @override
  Size get preferredSize => const Size.fromHeight(108); // 48 (title) + 60 (bottom)

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF141415);

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyActions: false,
      titleSpacing: 16.0,
      title: Image.asset(
        'assets/VTVgo_logo.jpg',
        height: 28,
        fit: BoxFit.contain,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(32),
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x662196F3), // Colors.blue with 0.4 opacity
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              tabs: categories
                  .map(
                    (c) => Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(c.name),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final ChannelCategory category;

  const _CategoryGrid({required this.category});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    int columns = 2;
    if (screenWidth >= 900) {
      columns = 4;
    } else if (screenWidth >= 600) {
      columns = 3;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 16 / 9,
      ),
      itemCount: category.channels.length,
      itemBuilder: (context, index) {
        return _ChannelGridCard(channel: category.channels[index]);
      },
    );
  }
}

class _ChannelGridCard extends StatelessWidget {
  final Channel channel;

  const _ChannelGridCard({required this.channel});

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: channel.thumbnail.isNotEmpty
                  ? channel.thumbnail
                  : channel.logo,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[800],
                child: const Icon(Icons.tv, color: Colors.white54, size: 40),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xB3000000), // Colors.black with 0.7 opacity
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                channel.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
