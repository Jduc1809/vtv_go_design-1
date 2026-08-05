import 'package:flutter/material.dart';

import '../../data_handler/channel_data.dart';
import 'channel_mini_card.dart';

class CategoryRow extends StatelessWidget {
  final ChannelCategory category;
  final List<String> favoriteIds;
  final Function(String) onFavoriteToggled;

  const CategoryRow({
    super.key,
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
              return ChannelMiniCard(
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
