import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:vtv_go/search_result.dart';

import '../channel_data.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://staging-api-vtvgo.vtvdigital.vn';

  // Centralized default parameters for all VTV API calls
  static final Map<String, String> _defaultParams = {
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
    if (jsonResponse != null &&
        (jsonResponse['status'] == 0 || jsonResponse['message'] == 'Success')) {
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
    final token = AuthService.currentAccessToken;
    if (token == null) {
      log("Access Token is missing!");
      return null;
    }

    final queryParams = {..._defaultParams, ...?extraQueryParameters};
    final url = Uri.parse(
      '$baseUrl$endpoint',
    ).replace(queryParameters: queryParams);

    try {
      log('\n OUTBOUND API REQUEST');
      log('GET: $url');

      final response = await http.get(
        url,
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );

      log('\n INBOUND API RESPONSE');
      log('ENDPOINT: $endpoint');
      log('STATUS: ${response.statusCode}');

      try {
        final decoded = json.decode(response.body);
        log(
          'BODY (JSON):\n${const JsonEncoder.withIndent('  ').convert(decoded)}',
        );
      } catch (_) {
        log('BODY (RAW):\n${response.body}');
      }

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final decodedJson = json.decode(response.body);
          log('API call success: $endpoint');
          return decodedJson;
        } else {
          log('API call success but empty body: $endpoint');
          return null;
        }
      } else if (response.statusCode == 401) {
        log("Token expired, attempting refresh...");
        if (await AuthService.refreshExpiredToken()) {
          return await _get(
            endpoint,
            extraQueryParameters: extraQueryParameters,
          );
        }
      } else {
        log("API error: ${response.statusCode} for $endpoint");
        log(
          "Response body: ${response.body}",
        ); // Prints the raw HTML or empty string
      }
    } catch (e) {
      log("API Exception: $e");
    }
    return null;
  }

  static Future<List<ChannelCategory>> fetchHomeData() async {
    return await _request<List<ChannelCategory>>(
          '/live-channel/api/v1/channels/byCatalog',
          fromJson: (data) {
            final List<dynamic> favs = data['favoriteChannels'] ?? [];
            final List<dynamic> normal = data['channels'] ?? [];

            final allCategories = [
              ...favs.whereType<Map<String, dynamic>>().map(
                ChannelCategory.fromJson,
              ),
              ...normal.whereType<Map<String, dynamic>>().map(
                ChannelCategory.fromJson,
              ),
            ];

            return allCategories
                .where((cat) => cat.channels.isNotEmpty)
                .toList();
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
    //Grab the local date
    final localDate = targetDate ?? DateTime.now();

    //Construct the exact local midnight bounds (00:00:00 to 23:59:59)
    final localStart = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      0,
      0,
      0,
    );
    final localEnd = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      23,
      59,
      59,
    );

    //Convert those specific bounds to UTC for the API request
    final startIsoDate = localStart.toUtc().toIso8601String();
    final endIsoDate = localEnd.toUtc().toIso8601String();

    return await _request<List<Program>>(
          '/live-channel/api/v1/channels/$channelId/programs',
          params: {'startIsoDate': startIsoDate, 'endIsoDate': endIsoDate},
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
        final sourceModes = data['sourceModes'] as List?;
        if (sourceModes != null && sourceModes.isNotEmpty) {
          final sources = sourceModes[0]['sources'] as List?;
          if (sources != null && sources.isNotEmpty) {
            return sources[0]['url']?.toString();
          }
        }
        return null;
      },
    );
  }

  static Future<List<SearchResult>> searchContent(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) return [];

    return await _request<List<SearchResult>>(
          '/search-app/api/v1/search/metadata',
          params: {
            'limit': limit.toString(),
            'page': page.toString(),
            'textSearch': query,
          },
          fromJson: (data) {
            if (data is! List) return [];
            return data
                .whereType<Map<String, dynamic>>()
                .map((item) {
                  try {
                    return SearchResult.fromJson(item);
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<SearchResult>()
                .toList();
          },
        ) ??
        [];
  }
}
