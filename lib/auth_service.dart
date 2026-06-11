import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://staging-api-vtvgo.vtvdigital.vn';
  static const String SECRET = r'n5rBv+7W3juD4aC_#?E3tms$@x8n?DtY%';
  static const String versionCode = '20260504';
  static const String platform = '3';
  static const String dtId = '6';
  static const String spId = '1';
  static const String deviceId = 'flutter-test-device-001';
  static const String deviceName = 'Flutter Simulator';
  static const String clientId = 'flutter-client-001';

  static String? currentAccessToken;
  static String? currentRefreshToken;

  //Initial Guest Login

  static Future<bool> loginAsGuest({bool forceNetwork = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!forceNetwork) {
      final String? savedToken = prefs.getString('vtv_access_token');
      final String? savedRefreshToken = prefs.getString('vtv_refresh_token');

      if (savedToken != null && savedRefreshToken != null) {
        currentAccessToken = savedToken;
        currentRefreshToken = savedRefreshToken;
        print('Reading from device: Found tokens');
        return true;
      }
    }

    print('login to network');

    final String rawSignatureString =
        '$deviceId&&$deviceName&&$versionCode&&$platform&&$SECRET';
    final String signature = md5
        .convert(utf8.encode(rawSignatureString))
        .toString();

    final Map<String, String> bodyMap = {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'versionCode': versionCode,
      'platform': platform,
      'mac': '00:00:00:00:00:00',
      'dtId': dtId,
      'spId': spId,
      'signature': signature,
      'deviceInfo': '{}',
      'clientId': clientId,
      'versionName': '12.5.26',
      'packageName': 'vn.vtv.vtvgotv',
      'deviceType': '3',
      'osVersion': '29',
      'appVersion': '12.5.26',
    };

    try {
      final Uri url = Uri.parse(
        '$baseUrl/user/nt/api/v1/auth/enter-guest',
      ).replace(queryParameters: bodyMap);

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: bodyMap,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 0) {
          currentAccessToken = jsonResponse['data']['accessToken'];
          currentRefreshToken =
              jsonResponse['data']['refreshToken']; // 🔥 Save it!

          if (currentAccessToken != null && currentRefreshToken != null) {
            await prefs.setString('vtv_access_token', currentAccessToken!);
            await prefs.setString('vtv_refresh_token', currentRefreshToken!);
            print('Saved new tokens ');
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Auth Network Exception: $e');
      return false;
    }
  }

  static Future<bool> refreshExpiredToken() async {
    if (currentRefreshToken == null) {
      // If we don't have a refresh token, force a complete fresh login
      return await loginAsGuest(forceNetwork: true);
    }

    print('Auth: refreshing expired token');

    final String rawSignatureString =
        '$deviceId&&$deviceName&&$versionCode&&$platform&&$currentRefreshToken&&$SECRET';
    final String signature = md5
        .convert(utf8.encode(rawSignatureString))
        .toString();

    final Map<String, String> bodyMap = {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'deviceType': '3',
      'dtId': dtId,
      'spId': spId,
      'token': currentRefreshToken!,
      'signature': signature,
      'clientId': clientId,
    };

    try {
      final Uri url = Uri.parse('$baseUrl/user/nt/api/v1/auth/refresh-token');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: bodyMap,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 0) {
          currentAccessToken = jsonResponse['data']['accessToken'];

          if (jsonResponse['data']['refreshToken'] != null) {
            currentRefreshToken = jsonResponse['data']['refreshToken'];
          }

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('vtv_access_token', currentAccessToken!);
          await prefs.setString('vtv_refresh_token', currentRefreshToken!);

          print('Token refreshed');
          return true;
        }
      }

      print('Refresh token rejected. Forcing hard login...');
      return await loginAsGuest(forceNetwork: true);
    } catch (e) {
      print('Refresh Network Exception: $e');
      return false;
    }
  }
}
