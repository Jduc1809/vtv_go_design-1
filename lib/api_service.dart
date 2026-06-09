import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'channel_data.dart';

class ApiService {
  static const String baseUrl = 'https://staging-api-vtvgo.vtvdigital.vn';

  static Future<List<ChannelCategory>> fetchHomeData() async {
    if (AuthService.currentAccessToken == null) return [];

    final Uri url = Uri.parse('$baseUrl/live-channel/api/v1/channels/byCatalog')
        .replace(
          queryParameters: {
            'platform': '3',
            'dtId': '6',
            'spId': '1',
            'versionCode': '20260504',
            'versionName': '12.5.26',
            'packageName': 'vn.vtv.vtvgotv',
            'deviceName': 'Flutter Simulator',
            'mac': '00:00:00:00:00:00',
            'osVersion': '29',
            'appVersion': '12.5.26',
          },
        );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': AuthService.currentAccessToken!},
      );
      print('API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        log(const JsonEncoder.withIndent('  ').convert(jsonResponse));

        if (jsonResponse['status'] == 0) {
          final Map<String, dynamic> data = jsonResponse['data'] ?? {};
          List<ChannelCategory> categories = [];

          //Process Favorite Categories
          final List<dynamic> favoriteCatalogs = data['favoriteChannels'] ?? [];
          for (var catalog in favoriteCatalogs) {
            categories.add(ChannelCategory.fromJson(catalog));
          }

          //Process Standard Categories
          final List<dynamic> normalCatalogs = data['channels'] ?? [];
          for (var catalog in normalCatalogs) {
            categories.add(ChannelCategory.fromJson(catalog));
          }

          //Return only categories that actually have channels in them
          return categories.where((cat) => cat.channels.isNotEmpty).toList();
        }
      } else if (response.statusCode == 401) {
        print('Token expired, refreshing');

        final bool refreshSuccess = await AuthService.refreshExpiredToken();

        if (refreshSuccess) {
          print('refresh success');
          return fetchHomeData();
        } else {
          print('can not refresh token');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Catalog Network Exception: $e');
      return [];
    }
  }

  static Future<String?> fetchStreamUrl(String channelId) async {
    if (AuthService.currentAccessToken == null) return null;

    final Uri url =
        Uri.parse(
          '$baseUrl/live-channel/api/v2/channels/$channelId/source',
        ).replace(
          queryParameters: {
            'platform': '3',
            'dtId': '6',
            'spId': '1',
            'versionCode': '20260504',
            'packageName': 'vn.vtv.vtvgotv',
            'deviceName': 'Flutter Simulator',
            'osVersion': '29',
          },
        );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': AuthService.currentAccessToken!,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        print('API response for streams: $channelId');
        log(const JsonEncoder.withIndent('  ').convert(jsonResponse));

        final data = jsonResponse['data'];
        if (data != null && data is Map) {
          final sourceModes = data['sourceModes'];

          if (sourceModes != null &&
              sourceModes is List &&
              sourceModes.isNotEmpty) {
            final multiSource = sourceModes[0]['multiSource'];

            if (multiSource != null &&
                multiSource is List &&
                multiSource.isNotEmpty) {
              final sources = multiSource[0]['sources'];

              if (sources != null && sources is List && sources.isNotEmpty) {
                final String realStreamUrl =
                    sources[0]['url']?.toString() ?? '';

                if (realStreamUrl.isNotEmpty) {
                  return realStreamUrl;
                }
              }
            }
          }
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      print('Stream Fetch Exception: $e');
      return null;
    }
  }

  static Future<List<Program>> fetchChannelSchedule(
    String channelId, {
    DateTime? targetDate,
  }) async {
    if (AuthService.currentAccessToken == null) return [];

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

    final Uri url =
        Uri.parse(
          '$baseUrl/live-channel/api/v1/channels/$channelId/programs',
        ).replace(
          queryParameters: {
            'startIsoDate': startIsoDate,
            'endIsoDate': endIsoDate,
            'platform': '3',
            'dtId': '6',
            'spId': '1',
          },
        );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': AuthService.currentAccessToken!},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        print("Schedule API response");
        log(const JsonEncoder.withIndent('  ').convert(jsonResponse));

        if (jsonResponse['status'] == 0 ||
            jsonResponse['message'] == 'Success') {
          final rawData = jsonResponse['data'];

          if (rawData != null && rawData is List) {
            List<Program> parsedPrograms = [];

            for (var item in rawData) {
              // Ensure the item inside the list is actually an object/map
              if (item is Map<String, dynamic>) {
                try {
                  parsedPrograms.add(Program.fromJson(item));
                } catch (e) {
                  print('Skipped a broken program format: $e');
                }
              }
            }
            print(
              'SUCCESS: Safely schedule ${parsedPrograms.length} programs!',
            );
            return parsedPrograms;
          } else {
            print(
              'Server returned an empty or invalid format (Data was not a List).',
            );
          }
        }
      }
      return [];
    } catch (e) {
      print('EPG API Exception: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchStreamData(String channelId) async {
    if (AuthService.currentAccessToken == null) {
      print('Stream fetch failed: Access token is missing!');
      return null;
    }

    final Uri url = Uri.parse(
      '$baseUrl/live-channel/api/v2/channels/$channelId/source',
    ).replace(queryParameters: {'platform': '3', 'dtId': '6', 'spId': '1'});

    print('Fetching stream from : $url');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': AuthService.currentAccessToken!},
      );

      print('API status ${response.statusCode}');

      print('Stream API response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 0 && jsonResponse['data'] != null) {
          print('stream fetch successfully');
          return jsonResponse['data'];
        } else {
          print(
            'API returned 200 but invalid status: ${jsonResponse['message']}',
          );
        }
      }
      return null;
    } catch (e) {
      print('STREAM API EXCEPTION: $e');
      return null;
    }
  }

  static Future<String?> fetchProgramStreamUrl(
    String channelId,
    String programId,
  ) async {
    final String baseUrl =
        'https://staging-api-vtvgo.vtvdigital.vn/live-channel';
    final url = Uri.parse(
      '$baseUrl/api/v1/channels/$channelId/programs/$programId/source',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': AuthService.currentAccessToken!},
      );

      print("Schedule API response");
      print(response.statusCode);
      log(const JsonEncoder.withIndent('  ').convert(response.body));

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'];

        if (data != null &&
            data['sourceModes'] != null &&
            data['sourceModes'].isNotEmpty) {
          final sources = data['sourceModes'][0]['sources'];
          if (sources != null && sources.isNotEmpty) {
            return sources[0]['url'];
          }
        }
      }
    } catch (e) {
      print('Error fetching program stream URL: $e');
      return null;
    }
    return null;
  }
}
