import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://staging-api-vtvgo.vtvdigital.vn';
  static const String secret = r'n5rBv+7W3juD4aC_#?E3tms$@x8n?DtY%';
  static const String versionCode = '20260504';
  static const String platform = '3';
  static const String dtId = '6';
  static const String spId = '1';
  static const String deviceId = 'flutter-test-device-001';
  static const String deviceName = 'Flutter Simulator';
  static const String clientId = 'flutter-client-001';

  static String? currentAccessToken;
  static String? currentRefreshToken;

  static const String _accessTokenKey = 'vtv_access_token';
  static const String _refreshTokenKey = 'vtv_refresh_token';

  static Future<bool> loginAsGuest({bool forceNetwork = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceNetwork) {
      final savedToken = prefs.getString(_accessTokenKey);
      final savedRefreshToken = prefs.getString(_refreshTokenKey);

      if (savedToken != null && savedRefreshToken != null) {
        currentAccessToken = savedToken;
        currentRefreshToken = savedRefreshToken;
        log('Auth: Tokens found in storage');
        return true;
      }
    }

    log('Auth: Attempting network login...');

    final rawSignatureString =
        '$deviceId&&$deviceName&&$versionCode&&$platform&&$secret';
    final signature = md5.convert(utf8.encode(rawSignatureString)).toString();

    final bodyMap = {
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
      final url = Uri.parse(
        '$baseUrl/user/nt/api/v1/auth/enter-guest',
      ).replace(queryParameters: bodyMap);

      log('AUTH URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: bodyMap,
      );

      log('AUTH STATUS: ${response.statusCode}');
      log('AUTH BODY: ${response.body}');
      log('========================================');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 0) {
          currentAccessToken = jsonResponse['data']['accessToken'];
          currentRefreshToken = jsonResponse['data']['refreshToken'];

          if (currentAccessToken != null && currentRefreshToken != null) {
            await prefs.setString(_accessTokenKey, currentAccessToken!);
            await prefs.setString(_refreshTokenKey, currentRefreshToken!);
            log('Auth: New tokens saved');
          }
          return true;
        }
      }
    } catch (e) {
      log('Auth: Network Exception: $e');
    }
    return false;
  }

  static Future<bool> refreshExpiredToken() async {
    final refreshToken = currentRefreshToken;
    if (refreshToken == null) {
      return await loginAsGuest(forceNetwork: true);
    }

    log('Auth: Refreshing expired token...');

    final rawSignatureString =
        '$deviceId&&$deviceName&&$versionCode&&$platform&&$refreshToken&&$secret';
    final signature = md5.convert(utf8.encode(rawSignatureString)).toString();

    final bodyMap = {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'deviceType': '3',
      'dtId': dtId,
      'spId': spId,
      'token': refreshToken,
      'signature': signature,
      'clientId': clientId,
    };

    try {
      final url = Uri.parse('$baseUrl/user/nt/api/v1/auth/refresh-token');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: bodyMap,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 0) {
          currentAccessToken = jsonResponse['data']['accessToken'];

          if (jsonResponse['data']['refreshToken'] != null) {
            currentRefreshToken = jsonResponse['data']['refreshToken'];
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_accessTokenKey, currentAccessToken!);
          await prefs.setString(_refreshTokenKey, currentRefreshToken!);

          log('Auth: Token successfully refreshed');
          return true;
        }
      }
      log('Auth: Refresh token rejected, forcing hard login');
      return await loginAsGuest(forceNetwork: true);
    } catch (e) {
      log('Auth: Refresh Network Exception: $e');
    }
    return false;
  }
}
