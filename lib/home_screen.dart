import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();

    _homeDataFuture = ApiService.fetchHomeData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _homeDataFuture = ApiService.fetchHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'VTV Go',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: Colors.redAccent,
        backgroundColor: Colors.grey[900],
        onRefresh: _refreshData,
        child: FutureBuilder<List<ChannelCategory>>(
          future: _homeDataFuture,
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.redAccent),
              );
            }

            // 2. Error State
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi tải dữ liệu:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: _refreshData,
                      child: const Text(
                        'Thử Lại',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            // 3. Empty State
            final categories = snapshot.data ?? [];
            if (categories.isEmpty) {
              return const Center(
                child: Text(
                  'Không có dữ liệu kênh.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            // 4. Success State! Build the Netflix-style lists
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 30),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryRow(category);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryRow(ChannelCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Title
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 12.0),
          child: Text(
            category.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Horizontal Scrolling Row of Channels
        SizedBox(
          height: 140, // Height of the channel cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: category.channels.length,
            itemBuilder: (context, index) {
              final channel = category.channels[index];
              return _buildChannelCard(channel);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChannelCard(Channel channel) {
    return GestureDetector(
      onTap: () {
        // 🔥 Navigate to your completed StreamScreen when tapped!
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StreamScreen(channel: channel),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Channel Logo (Using a safe fallback if the image fails to load)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.network(
                  channel.logo,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.tv, color: Colors.grey, size: 40);
                  },
                ),
              ),
            ),
            // Current Program Title Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
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
    );
  }
}
