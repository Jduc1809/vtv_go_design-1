import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'channel_data.dart';

class ApiService {
  static const String baseUrl = 'https://staging-api-vtvgo.vtvdigital.vn';

  // Centralized default parameters for all VTV API calls
  static Map<String, String> get _defaultParams => {
        'platform': '3',
        'dtId': '6',
        'spId': '1',
        'versionCode': '20260504',
        'packageName': 'vn.vtv.vtvgotv',
        'deviceName': 'Flutter Simulator',
        'osVersion': '29',
        'appVersion': '12.5.26',
        'versionName': '12.5.26',
        'mac': '00:00:00:00:00:00',
      };

  /// Generic request handler that manages the API "envelope" (status, message, data).
  static Future<T?> _request<T>(
    String endpoint, {
    Map<String, String>? params,
    T Function(dynamic json)? fromJson,
  }) async {
    final jsonResponse = await _get(endpoint, extraQueryParameters: params);

    // Standard VTV API success check
    if (jsonResponse != null && (jsonResponse['status'] == 0 || jsonResponse['message'] == 'Success')) {
      final data = jsonResponse['data'];
      if (data == null) return null;
      return fromJson != null ? fromJson(data) : data as T;
    }
    return null;
  }

  /// Base GET method handling authentication, headers, and token refresh logic.
  static Future<dynamic> _get(
    String endpoint, {
    Map<String, String>? extraQueryParameters,
  }) async {
    if (AuthService.currentAccessToken == null) {
      log("Access Token is missing!");
      return null;
    }

    final Map<String, String> queryParams = Map.from(_defaultParams);
    if (extraQueryParameters != null) {
      queryParams.addAll(extraQueryParameters);
    }

    final Uri url = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': AuthService.currentAccessToken!,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        log('API call success: $endpoint');
        return decodedBody;
      } else if (response.statusCode == 401) {
        log("Token expired, attempting refresh...");
        if (await AuthService.refreshExpiredToken()) {
          return await _get(endpoint, extraQueryParameters: extraQueryParameters);
        }
        return null;
      } else {
        log("API error: ${response.statusCode} for $endpoint");
        return null;
      }
    } catch (e) {
      log("API Exception: $e");
      return null;
    }
  }

  static Future<List<ChannelCategory>> fetchHomeData() async {
    return await _request<List<ChannelCategory>>(
          '/live-channel/api/v1/channels/byCatalog',
          fromJson: (data) {
            final List<ChannelCategory> categories = [];
            final List<dynamic> favs = data['favoriteChannels'] ?? [];
            final List<dynamic> normal = data['channels'] ?? [];

            for (var c in favs) {
              categories.add(ChannelCategory.fromJson(c));
            }
            for (var c in normal) {
              categories.add(ChannelCategory.fromJson(c));
            }

            return categories.where((cat) => cat.channels.isNotEmpty).toList();
          },
        ) ??
        [];
  }

  static Future<String?> fetchStreamUrl(String channelId) async {
    return await _request<String?>(
      '/live-channel/api/v2/channels/$channelId/source',
      fromJson: (data) => ChannelSourceMode.fromJson(data).streamUrl,
    );
  }

  static Future<List<Program>> fetchChannelSchedule(
    String channelId, {
    DateTime? targetDate,
  }) async {
    final baseDate = (targetDate ?? DateTime.now()).toUtc();
    final startIsoDate = DateTime.utc(baseDate.year, baseDate.month, baseDate.day, 0, 0, 0).toIso8601String();
    final endIsoDate = DateTime.utc(baseDate.year, baseDate.month, baseDate.day, 23, 59, 59).toIso8601String();

    return await _request<List<Program>>(
          '/live-channel/api/v1/channels/$channelId/programs',
          params: {
            'startIsoDate': startIsoDate,
            'endIsoDate': endIsoDate,
          },
          fromJson: (data) {
            if (data is! List) return [];
            return data
                .whereType<Map<String, dynamic>>()
                .map((item) {
                  try {
                    return Program.fromJson(item);
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<Program>()
                .toList();
          },
        ) ??
        [];
  }

  static Future<Map<String, dynamic>?> fetchStreamData(String channelId) async {
    return _request<Map<String, dynamic>>(
      '/live-channel/api/v1/channels/$channelId/source',
    );
  }

  static Future<String?> fetchProgramStreamUrl(
    String channelId,
    String programId,
  ) async {
    return await _request<String?>(
      '/live-channel/api/v1/channels/$channelId/programs/$programId/source',
      fromJson: (data) {
        if (data['sourceModes'] != null && data['sourceModes'].isNotEmpty) {
          final sources = data['sourceModes'][0]['sources'];
          if (sources != null && sources.isNotEmpty) {
            return sources[0]['url'];
          }
        }
        return null;
      },
    );
  }
}
