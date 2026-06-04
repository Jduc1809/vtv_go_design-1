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

  @override
  void initState() {
    super.initState();
    _futureCategories = ApiService.fetchHomeData();
  }

  @override
  Widget build(BuildContext context) {
    //Dark background color for the entire app
    const Color bgColor = Color(0xFF141415);

    return FutureBuilder<List<ChannelCategory>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: bgColor,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return const Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: Text(
                'Failed to load channels.',
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

            // The bar at the top with the logo, search, avatar, and category tabs
            appBar: AppBar(
              backgroundColor: bgColor,
              elevation: 0,
              centerTitle: false,
              automaticallyImplyActions: false,
              titleSpacing: 16.0,

              // Logo
              title: Image.asset(
                'assets/VTVgo_logo.jpg',
                height: 28,
                fit: BoxFit.contain,
              ),

              //Tap Bar
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,

                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.blue[600]?.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.blue[600]!, width: 1),
                ),

                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,

                labelColor: Colors.blue[300],
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
                      (category) => Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(category.name),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            body: TabBarView(
              children: categories.map((category) {
                final screenWidth = MediaQuery.of(context).size.width;
                int repsonsiveColumns = 2; // Default for small screens
                if (screenWidth >= 600) {
                  repsonsiveColumns = 3; // Medium screens
                }
                if (screenWidth >= 900) {
                  repsonsiveColumns = 4; // Large screens
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: repsonsiveColumns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 16 / 9,
                  ),
                  itemCount: category.channels.length,
                  itemBuilder: (context, index) {
                    final channel = category.channels[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StreamScreen(channel: channel),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              channel.thumbnail.isNotEmpty
                                  ? channel.thumbnail
                                  : channel.logo,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: Colors.grey[800]),
                            ),

                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                            if (channel.logo.isEmpty) ...[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Image.network(
                                    channel.logo,
                                    height: 24,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.tv,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                  ),
                                ),
                              ),
                            ],
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Text(
                                channel.name,

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
