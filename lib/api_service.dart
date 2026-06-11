import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'channel_data.dart';

class ApiService {
  static const String baseUrl = 'https://staging-api-vtvgo.vtvdigital.vn';

  static Future<dynamic> _get(
    String endpoint, {
    Map<String, String>? extraQueryParameters,
  }) async {
    if (AuthService.currentAccessToken == null) {
      print("Access Token is missing!");
      return null;
    }

    final Map<String, String> defaultParams = {
      'platform': '3',
      'dtId': '6',
      'spId': '1',
      'versionCode': '20260504',
      'packageName': 'vn.vtv.vtvgotv',
      'deviceName': 'Flutter Simulator',
      'osVersion': '29',
      'appVersion': '12.5.26',
    };

    if (extraQueryParameters != null) {
      defaultParams.addAll(extraQueryParameters);
    }

    final Uri url = Uri.parse(
      '$baseUrl$endpoint',
    ).replace(queryParameters: defaultParams);

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

        print('API calls successfully (${response.statusCode})');
        log(const JsonEncoder.withIndent('  ').convert(decodedBody));
        print('----------------------------------------------------\n');

        return decodedBody;
      } else if (response.statusCode == 401) {
        print("Token expired");

        final bool refreshSuccess = await AuthService.refreshExpiredToken();

        if (refreshSuccess) {
          print("refresh success");
          return await _get(
            endpoint,
            extraQueryParameters: extraQueryParameters,
          );
        } else {
          print("can not refresh token");
          return null;
        }
      } else {
        print("API error : (${response.statusCode}})");
        return null;
      }
    } catch (e) {
      print("API Exception: $e");
      return null;
    }
  }

  static Future<List<ChannelCategory>> fetchHomeData() async {
    final jsonResponse = await _get(
      '/live-channel/api/v1/channels/byCatalog',
      extraQueryParameters: {
        'versionName': '12.5.26',
        'mac': '00:00:00:00:00:00',
        'appVersion': '12.5.26',
      },
    );

    if (jsonResponse != null && jsonResponse['status'] == 0) {
      final Map<String, dynamic> data = jsonResponse['data'] ?? {};
      List<ChannelCategory> categories = [];

      // Process Favorite Categories
      final List<dynamic> favoriteCatalogs = data['favoriteChannels'] ?? [];
      for (var catalog in favoriteCatalogs) {
        categories.add(ChannelCategory.fromJson(catalog));
      }

      // Process Standard Categories
      final List<dynamic> normalCatalogs = data['channels'] ?? [];
      for (var catalog in normalCatalogs) {
        categories.add(ChannelCategory.fromJson(catalog));
      }

      // Return only categories that actually have channels in them
      return categories.where((cat) => cat.channels.isNotEmpty).toList();
    }

    // If anything fails, return an empty list
    return [];
  }

  Future<String?> fetchStreamUrl(String channelId) async {
    final jsonResponse = await _get(
      'live-channel/api/v2/channels/$channelId/source',
    );

    if (jsonResponse != null && jsonResponse['data'] != 0) {
      final sourceMode = ChannelSourceMode.fromJson(jsonResponse['data']);

      return sourceMode.streamUrl;
    }
    return null;
  }

  static Future<List<Program>> fetchChannelSchedule(
    String channelId, {
    DateTime? targetDate,
  }) async {
    final baseDate = (targetDate ?? DateTime.now()).toUtc();
    final startIsoDate = DateTime.utc(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      0,
      0,
      0,
    ).toIso8601String();
    final endIsoDate = DateTime.utc(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      23,
      59,
      59,
    ).toIso8601String();

    // Pass the custom date parameters into the get methods
    final jsonResponse = await _get(
      '/live-channel/api/v1/channels/$channelId/programs',
      extraQueryParameters: {
        'startIsoDate': startIsoDate,
        'endIsoDate': endIsoDate,
      },
    );

    if (jsonResponse != null &&
        (jsonResponse['status'] == 0 || jsonResponse['message'] == 'Success')) {
      final rawData = jsonResponse['data'];
      if (rawData != null && rawData is List) {
        return rawData
            .whereType<Map<String, dynamic>>()
            .map((item) {
              try {
                return Program.fromJson(item);
              } catch (e) {
                return null;
              }
            })
            .whereType<Program>()
            .toList();
      }
    }
    return [];
  }

  static Future<Map<String, dynamic>?> fetchStreamData(String channelId) async {
    final jsonResponse = await _get(
      '/live-channel/api/v1/channels/$channelId/source',
    );

    if (jsonResponse != null && jsonResponse['status'] == 0) {
      return jsonResponse['data'];
    }
    return null;
  }

  static Future<String?> fetchProgramStreamUrl(
    String channelId,
    String programId,
  ) async {
    final jsonResponse = await _get(
      '/live-channel/api/v1/channels/$channelId/programs/$programId/source',
    );

    if (jsonResponse != null && jsonResponse['data'] != null) {
      final data = jsonResponse['data'];
      if (data['sourceModes'] != null && data['sourceModes'].isNotEmpty) {
        final sources = data['sourceModes'][0]['sources'];
        if (sources != null && sources.isNotEmpty) {
          return sources[0]['url'];
        }
      }
    }
    return null;
  }
}
