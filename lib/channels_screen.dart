import 'package:flutter/material.dart';

import 'api_service.dart';
import 'channel_data.dart';
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
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
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
            appBar: _buildAppBar(categories),
            body: TabBarView(
              children: categories.map((category) => _buildCategoryGrid(category)).toList(),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(List<ChannelCategory> categories) {
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              tabs: categories.map((c) => Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(c.name)))).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(ChannelCategory category) {
    final screenWidth = MediaQuery.of(context).size.width;
    int columns = 2;
    if (screenWidth >= 900) columns = 4;
    else if (screenWidth >= 600) columns = 3;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 16 / 9,
      ),
      itemCount: category.channels.length,
      itemBuilder: (context, index) => _buildChannelCard(category.channels[index]),
    );
  }

  Widget _buildChannelCard(Channel channel) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StreamScreen(channel: channel)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Display only one image: Thumbnail is prioritized, falling back to Logo
            Image.network(
              channel.thumbnail.isNotEmpty ? channel.thumbnail : channel.logo,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[800],
                child: const Icon(Icons.tv, color: Colors.white54, size: 40),
              ),
            ),
            // Gradient Overlay for UI consistency
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
