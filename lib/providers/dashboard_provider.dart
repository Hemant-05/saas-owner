import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/models.dart';

enum DashboardState { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  DashboardState _state = DashboardState.initial;
  String? _errorMessage;
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
    if (!silent) {
      _state = DashboardState.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response =
          await ApiService.get(ApiConfig.dashboardStats, auth: true);
      final data = response['data'];
      final stats = data['stats'];
      final allTime = stats['allTime'];
      final today = stats['today'];

      _totalEarnings = (allTime['totalEarnings'] ?? 0).toDouble();
      _totalOrders = allTime['totalOrders'] ?? 0;
      _avgOrderValue = (allTime['avgOrderValue'] ?? 0).toDouble();

      _todayEarnings = (today['totalEarnings'] ?? 0).toDouble();
      _todayOrders = today['totalOrders'] ?? 0;
      _todayAvgOrderValue = (today['avgOrderValue'] ?? 0).toDouble();

      _popularItems = data['popularItems'] ?? [];

      _state = DashboardState.loaded;
      
      // Auto-fetch the first page of order history to keep recent orders list updated
      if (!silent) {
        fetchOrderHistory(refresh: true).catchError((_) {});
      } else {
        // If silent, also fetch silently without triggering global loading
        fetchOrderHistory(refresh: true).catchError((_) {});
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = DashboardState.error;
    } catch (e) {
      _errorMessage = 'Failed to load dashboard stats';
      _state = DashboardState.error;
    }
    notifyListeners();
  }

  Future<void> fetchOrderHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _orderHistory = [];
    } else {
      if (_currentPage >= _totalPages) return;
      _currentPage++;
    }

    _isLoadingHistory = true;
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
    } catch (e) {
      debugPrint('Error fetching order history: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }
}
