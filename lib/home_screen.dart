import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'providers/home_provider.dart';
import 'search_screen.dart';
import 'widgets/home/category_row.dart';
import 'widgets/home/favorite_circle_card.dart';
import 'widgets/home/hero_spotlight_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeProvider(),
      child: const HomeScreenView(),
    );
  }
}

class HomeScreenView extends StatelessWidget {
  const HomeScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: RefreshIndicator(
        color: AppColors.accentColor,
        backgroundColor: Colors.grey[900],
        onRefresh: provider.refreshData,
        child: Builder(
          builder: (context) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accentColor),
              );
            }

            if (provider.errorMessage != null) {
              return _buildErrorState(context, provider.errorMessage!);
            }

            final categories = provider.categories;
            if (categories.isEmpty) {
              return const Center(
                child: Text(
                  'Không có dữ liệu kênh.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final allChannels = provider.allChannels;
            final favoriteChannels = provider.favoriteChannels;

            return CustomScrollView(
              slivers: [
                // 1. Sticky Frosted Header
                SliverAppBar(
                  backgroundColor: AppColors.pureBlack.withValues(alpha: 0.9),
                  elevation: 0,
                  pinned: true,
                  floating: true,
                  title: Image.asset('assets/VTVgo_logo.jpg', height: 32),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                if (allChannels.isNotEmpty)
                  SliverToBoxAdapter(
                    child: HeroSpotlightCard(channel: allChannels.first),
                  ),

                // 2. Local Favorites Quick-Lane
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
                          color: AppColors.favoriteAmber,
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
                          return FavoriteCircleCard(channel: channel);
                        },
                      ),
                    ),
                  ),
                ],

                // 3. Dynamic Category Swimlanes
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return CategoryRow(
                      category: categories[index],
                      favoriteIds: provider.favoriteIds,
                      onFavoriteToggled: provider.toggleFavorite,
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

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
            ),
            onPressed: context.read<HomeProvider>().refreshData,
            child: const Text('Thử Lại', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
