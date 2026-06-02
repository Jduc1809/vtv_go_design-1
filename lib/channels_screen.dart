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

              // Search and Avatar Actions
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.grey, size: 28),
                  onPressed: () {},
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey[800],
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],

              // The Swipeable Category Tabs
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
                dividerColor: Colors.transparent,
                tabs: categories
                    .map((category) => Tab(text: category.name))
                    .toList(),
              ),
            ),

            body: TabBarView(
              children: categories.map((category) {
                // Responsive Desktop/Tablet/Mobile Logic
                final screenWidth = MediaQuery.of(context).size.width;
                int responsiveColumns = 3; // Default to 3 columns for mobile
                if (screenWidth > 900) {
                  responsiveColumns = 6;
                } else if (screenWidth > 600) {
                  responsiveColumns = 4;
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: responsiveColumns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio:
                        0.85, // Makes the cards taller than they are wide
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

                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          // Subtle grey gradient for the card background
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.grey[800]!, Colors.black],
                          ),
                          // Optional: subtle border to make them pop
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. Centered Channel Logo
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.network(
                                  channel.logo,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.tv,
                                        color: Colors.grey,
                                        size: 40,
                                      ),
                                ),
                              ),
                            ),

                            // 2. Channel Name Text
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 12.0,
                                left: 4,
                                right: 4,
                              ),
                              child: Text(
                                channel.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
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
