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
    _loadData();
  }

  void _loadData() {
    _homeDataFuture = ApiService.fetchHomeData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color pureBlack = Colors.black;
    const Color accentColor = Colors.redAccent;

    return Scaffold(
      backgroundColor: pureBlack,
      appBar: AppBar(
        backgroundColor: pureBlack,
        elevation: 0,
        title: const Text(
          'VTV Go',
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
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

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 30),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return _CategoryRow(category: categories[index]);
              },
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

  const _CategoryRow({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: category.channels.length,
            itemBuilder: (context, index) {
              return _ChannelMiniCard(channel: category.channels[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _ChannelMiniCard extends StatelessWidget {
  final Channel channel;

  const _ChannelMiniCard({required this.channel});

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF2C2C2E);
    final borderColor = Colors.grey[800]!;

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
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
