import 'package:flutter/material.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF141415);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text(
          'Cổng Dịch Vụ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              child: const Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[800]),
            const SizedBox(height: 16),
            const Text(
              'Trang cổng dịch vụ đang được xây dựng...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
