import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data_handler/channel_data.dart';
import '../../screens/stream_screen.dart';

class FavoriteCircleCard extends StatelessWidget {
  final Channel channel;

  const FavoriteCircleCard({super.key, required this.channel});

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
                color: AppColors.darkGrey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.favoriteAmber.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CachedNetworkImage(
                    imageUrl: channel.logo,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentColor,
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.tv,
                      color: Colors.grey,
                      size: 24,
                    ),
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
                style: const TextStyle(color: AppColors.textWhite, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
