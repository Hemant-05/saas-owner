import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/offline_cache_service.dart';
import '../services/offline_sync_service.dart';
import '../config/api_config.dart';
import '../models/models.dart';

enum DashboardState { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  static const String _statsCacheKey = 'owner_dashboard_stats';
  static const String _historyCacheKey = 'owner_order_history';

  DashboardState _state = DashboardState.initial;
  String? _errorMessage;
  bool _isOfflineMode = false;
  DateTime? _lastUpdatedAt;
  Timer? _refreshTimer;

  // All-time stats
  double _totalEarnings = 0.0;
  int _totalOrders = 0;
  double _avgOrderValue = 0.0;

  // Today stats
  double _todayEarnings = 0.0;
  int _todayOrders = 0;
  double _todayAvgOrderValue = 0.0;

  List<dynamic> _popularItems = [];

  List<Order> _orderHistory = [];
  bool _isLoadingHistory = false;
  int _currentPage = 1;
  int _totalPages = 1;

  DashboardState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isOfflineMode => _isOfflineMode;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  // All-time
  double get totalEarnings => _totalEarnings;
  int get totalOrders => _totalOrders;
  double get avgOrderValue => _avgOrderValue;

  // Today
  double get todayEarnings => _todayEarnings;
  int get todayOrders => _todayOrders;
  double get todayAvgOrderValue => _todayAvgOrderValue;

  List<dynamic> get popularItems => _popularItems;
  List<Order> get orderHistory => _orderHistory;
  bool get isLoadingHistory => _isLoadingHistory;

  DashboardProvider() {
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_state == DashboardState.loaded) {
        fetchDashboardStats(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchDashboardStats({bool silent = false}) async {
    if (_state == DashboardState.initial || _state == DashboardState.error) {
      final restored = await _restoreStatsFromCache();
      if (restored && !silent) notifyListeners();
    }

    final hasSavedData = _state == DashboardState.loaded ||
        _totalOrders > 0 ||
        _todayOrders > 0 ||
        _popularItems.isNotEmpty;

    if (!silent && !hasSavedData) {
      _state = DashboardState.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response =
          await ApiService.get(ApiConfig.dashboardStats, auth: true);
      final data = response['data'];
      _applyStatsData(Map<String, dynamic>.from(data));
      _state = DashboardState.loaded;
      _isOfflineMode = false;
      _lastUpdatedAt = DateTime.now();
      await OfflineCacheService.writeJson(_statsCacheKey, data);
      await OfflineSyncService.markOnline();
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        _isOfflineMode = true;
        await OfflineSyncService.markOffline();
        _errorMessage =
            hasSavedData ? null : 'Offline. No saved dashboard yet.';
        _state = hasSavedData ? DashboardState.loaded : DashboardState.error;
      } else {
        _errorMessage = e.message;
        _state = DashboardState.error;
      }
    } catch (e) {
      _isOfflineMode = true;
      await OfflineSyncService.markOffline();
      _errorMessage = hasSavedData ? null : 'Offline. No saved dashboard yet.';
      _state = hasSavedData ? DashboardState.loaded : DashboardState.error;
    }

    // Always fetch order history separately to ensure it updates even if stats fail
    try {
      await fetchOrderHistory(refresh: true);
    } catch (e) {
      debugPrint('Error fetching order history in fetchDashboardStats: $e');
    }

    notifyListeners();
  }

  Future<void> fetchOrderHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      if (_orderHistory.isEmpty) {
        final restored = await _restoreOrderHistoryFromCache();
        if (restored) notifyListeners();
      }
    } else {
      if (_currentPage >= _totalPages) return;
      _currentPage++;
    }

    _isLoadingHistory = _orderHistory.isEmpty;
    notifyListeners();

    try {
      final url = '${ApiConfig.orderHistory}?page=$_currentPage&limit=20';
      final response = await ApiService.get(url, auth: true);
      final data = response['data'];

      final List<dynamic> ordersJson = data['orders'];
      final newOrders = ordersJson.map((json) => Order.fromJson(json)).toList();

      if (refresh) {
        _orderHistory = newOrders;
      } else {
        _orderHistory.addAll(newOrders);
      }

      _totalPages = data['pagination']['pages'] ?? 1;
      _isOfflineMode = false;
      _lastUpdatedAt = DateTime.now();
      await _cacheOrderHistory();
      await OfflineSyncService.markOnline();
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        _isOfflineMode = true;
        await OfflineSyncService.markOffline();
      } else {
        debugPrint('Error fetching order history: ${e.message}');
      }
    } catch (e) {
      debugPrint('Error fetching order history: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  void _applyStatsData(Map<String, dynamic> data) {
    final stats = data['stats'] ?? {};
    final allTime = stats['allTime'] ?? {};
    final today = stats['today'] ?? {};

    _totalEarnings = (allTime['totalEarnings'] as num?)?.toDouble() ?? 0.0;
    _totalOrders = (allTime['totalOrders'] as num?)?.toInt() ?? 0;
    _avgOrderValue = (allTime['avgOrderValue'] as num?)?.toDouble() ?? 0.0;

    _todayEarnings = (today['totalEarnings'] as num?)?.toDouble() ?? 0.0;
    _todayOrders = (today['totalOrders'] as num?)?.toInt() ?? 0;
    _todayAvgOrderValue = (today['avgOrderValue'] as num?)?.toDouble() ?? 0.0;

    _popularItems = data['popularItems'] ?? [];
  }

  Future<bool> _restoreStatsFromCache() async {
    final cached = await OfflineCacheService.readJsonMap(_statsCacheKey);
    if (cached == null) return false;
    _applyStatsData(cached);
    _state = DashboardState.loaded;
    _lastUpdatedAt = await OfflineCacheService.savedAt(_statsCacheKey);
    return true;
  }

  Future<void> _cacheOrderHistory() {
    return OfflineCacheService.writeJson(_historyCacheKey, {
      'orders': _orderHistory.map((order) => order.toJson()).toList(),
      'totalPages': _totalPages,
    });
  }

  Future<bool> _restoreOrderHistoryFromCache() async {
    final cached = await OfflineCacheService.readJsonMap(_historyCacheKey);
    if (cached == null) return false;
    final orders = cached['orders'];
    if (orders is! List) return false;

    _orderHistory = orders
        .whereType<Map>()
        .map((item) => Order.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    _totalPages = (cached['totalPages'] as num?)?.toInt() ?? 1;
    return _orderHistory.isNotEmpty;
  }
}
