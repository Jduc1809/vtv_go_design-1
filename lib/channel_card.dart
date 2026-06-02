// lib/channel_card.dart
import 'package:flutter/material.dart';

import 'channel_data.dart';
import 'stream_screen.dart';

class ChannelCard extends StatelessWidget {
  final Channel channel;

  const ChannelCard({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StreamScreen(channel: channel),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (channel.logo.isNotEmpty)
              Hero(
                tag: channel.id,
                child: Image.asset(
                  channel.logo,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,

                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return const Icon(Icons.broken_image, size: 48);
                      },
                ),
              ),
            if (channel.logo.isEmpty)
              Text(
                channel.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
