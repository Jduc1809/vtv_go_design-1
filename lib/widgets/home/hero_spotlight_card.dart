import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../channel_data.dart';
import '../../core/constants/app_colors.dart';
import '../../screens/stream_screen.dart';
import '../epg_bar.dart';

class HeroSpotlightCard extends StatelessWidget {
  final Channel channel;

  const HeroSpotlightCard({super.key, required this.channel});

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
      child: Container(
        height: 210,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[850]!, width: 1),
          gradient: const LinearGradient(
            colors: [Color(0xFF2C141A), Color(0xFF141518)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: Background Art
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: CachedNetworkImage(
                  imageUrl: channel.logo,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                  color: Colors.white.withValues(alpha: 0.15),
                  colorBlendMode: BlendMode.modulate,
                  errorWidget: (context, url, error) => const SizedBox(),
                ),
              ),

              // Layer 2: Dark Vignette gradient
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),

              // Layer 3: UI Overlays (Text & Actions)
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Badges
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                color: Colors.white,
                                size: 10,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'TRỰC TIẾP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          channel.name,
                          style: const TextStyle(
                            color: AppColors.textWhite70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Bottom Row: Metadata & CTA Button
                    Padding(
                      // Add a tiny bottom padding so text doesn't touch the EPG line
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Đang phát sóng:',
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  channel.currentProgram.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Xem Ngay',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Layer 4: Edge-to-Edge OTT Progress Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: EpgBar(
                  progress: channel.currentProgram.progressPercent / 100.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
