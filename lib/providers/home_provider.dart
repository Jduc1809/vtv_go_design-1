import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data_handler/channel_data.dart';
import '../services/api_service.dart';

class HomeProvider extends ChangeNotifier {
  List<ChannelCategory> _categories = [];
  List<ChannelCategory> get categories => _categories;

  List<String> _favoriteIds = [];
  List<String> get favoriteIds => _favoriteIds;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  HomeProvider() {
    init();
  }

  Future<void> init() async {
    await loadFavorites();
    await fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await ApiService.fetchHomeData();
    } catch (e) {
      _errorMessage = _mapError(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await loadFavorites();
    await fetchHomeData();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteIds = prefs.getStringList('favorite_channels') ?? [];
    notifyListeners();
  }

  Future<void> toggleFavorite(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favoriteIds.contains(channelId)) {
      _favoriteIds.remove(channelId);
    } else {
      _favoriteIds.add(channelId);
    }
    await prefs.setStringList('favorite_channels', _favoriteIds);
    notifyListeners();
  }

  String _mapError(String error) {
    if (error.contains("SocketException")) {
      return "Không có kết nối mạng. Vui lòng kiểm tra lại.";
    }
    return "Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.";
  }

  List<Channel> get allChannels {
    return _categories.expand((cat) => cat.channels).toList();
  }

  List<Channel> get favoriteChannels {
    return allChannels
        .where((channel) => _favoriteIds.contains(channel.id))
        .fold<List<Channel>>([], (list, channel) {
          if (!list.any((c) => c.id == channel.id)) list.add(channel);
          return list;
        });
  }
}
