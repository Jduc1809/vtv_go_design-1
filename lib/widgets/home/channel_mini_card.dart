import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../channel_data.dart';
import '../../core/constants/app_colors.dart';
import '../../stream_screen.dart';

class ChannelMiniCard extends StatelessWidget {
  final Channel channel;
  final bool isFavorited;
  final VoidCallback onFavoriteToggled;

  const ChannelMiniCard({
    super.key,
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
              color: AppColors.darkGrey,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[900]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CachedNetworkImage(
                      imageUrl: channel.logo,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentColor,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.tv, color: Colors.grey, size: 40),
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
