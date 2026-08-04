import 'dart:async';

import 'package:flutter/material.dart';

import '/api_service.dart';
import '/search_result.dart';

class SearchProvider extends ChangeNotifier {
  List<SearchResult> _results = [];
  List<SearchResult> get results => _results;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Timer? _debounce;

  void onSearchChanged(String query) {
    // Cancel the previous timer if the user is still typing
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Wait 500ms after the user stops typing to fire the API call
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query);
      } else {
        _results = [];
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> _performSearch(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _results = await ApiService.searchContent(query);
      if (_results.isEmpty) {
        _errorMessage = 'Không tìm thấy kết quả nào.';
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi khi tìm kiếm.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
