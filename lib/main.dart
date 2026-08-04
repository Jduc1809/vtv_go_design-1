import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'main_wrapper.dart';

void main() async {
  if (kDebugMode) {
    HttpOverrides.global = DevHttpOverrides();
  }
  WidgetsFlutterBinding.ensureInitialized();

  bool loggedIn = await AuthService.loginAsGuest();

  if (loggedIn) {
    log('Current access token : ${AuthService.currentAccessToken}');
  } else {
    log('Failed to authenticate as guest. Exiting app.');
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VTVGo',
      theme: ThemeData.dark(), //Dark mode
      home: const MainWrapper(),
    );
  }
}

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
