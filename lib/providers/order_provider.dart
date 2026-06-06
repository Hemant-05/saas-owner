import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/offline_cache_service.dart';
import '../services/offline_sync_service.dart';
import '../config/api_config.dart';

class OrderProvider extends ChangeNotifier {
  static const String _activeOrdersCacheKey = 'owner_active_orders';

  List<Order> _activeOrders = [];
  List<Order> _allOrders = [];
  bool _isLoading = false;
  bool _isOfflineMode = false;
  String? _errorMessage;
  DateTime? _lastUpdatedAt;
  IO.Socket? _socket;
  Timer? _refreshTimer;

  List<Order> get activeOrders => _activeOrders;
  List<Order> get allOrders => _allOrders;
  bool get isLoading => _isLoading;
  bool get isOfflineMode => _isOfflineMode;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  // Kanban columns
  List<Order> get newOrders =>
      _activeOrders.where((o) => o.orderStatus == 'placed').toList();
  List<Order> get preparingOrders =>
      _activeOrders.where((o) => o.orderStatus == 'preparing').toList();
  List<Order> get readyOrders =>
      _activeOrders.where((o) => o.orderStatus == 'ready').toList();
  List<Order> get deliveredOrders =>
      _allOrders.where((o) => o.orderStatus == 'delivered').toList();

  // ─── Notifications Setup ────────────────────────────────────────────────────

  /// Initialize is now a no-op — NotificationService in main.dart handles
  /// the FlutterLocalNotificationsPlugin initialization globally.
  Future<void> initNotifications() async {
    // No-op: NotificationService.initialize() in main.dart handles this.
  }

  Future<void> _showNewOrderNotification(Order order) async {
    // Delegate to the NotificationService singleton which owns the plugin
    await NotificationService().storeNotification(AppNotification(
      id: '${order.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: 'new_order',
      title: '🔔 New Order!',
      body:
          'Table ${order.tableNumber} — ₹${order.totalAmount.toStringAsFixed(2)}',
      data: {
        'type': 'new_order',
        'orderId': order.id,
        'tableNumber': order.tableNumber.toString(),
        'orderNumber': order.orderNumber,
      },
      receivedAt: DateTime.now(),
    ));
  }

  // ─── Socket.io ─────────────────────────────────────────────────────────────

  void connectSocket(String restaurantId, {VoidCallback? onOrderEvent}) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      ApiConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint(
          '[Socket.io] Connected — joining room: restaurant:$restaurantId');
      _socket!.emit('join_restaurant', restaurantId);
      // Start polling as a fallback for missed socket events
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        fetchActiveOrders(silent: true);
      });
    });

    _socket!.on('new_order', (data) {
      debugPrint('[Socket.io] new_order received');
      try {
        final orderData = data['order'] as Map<String, dynamic>;
        final newOrder = Order.fromJson(orderData);
        // Insert at top of active orders if not already present
        if (!_activeOrders.any((o) => o.id == newOrder.id)) {
          _activeOrders.insert(0, newOrder);
          unawaited(_cacheActiveOrders());
          notifyListeners();
          _showNewOrderNotification(newOrder);
          onOrderEvent?.call();
        }
      } catch (e) {
        debugPrint('[Socket.io] Failed to parse new_order: $e');
      }
    });

    _socket!.on('order_updated', (data) {
      debugPrint('[Socket.io] order_updated received');
      try {
        final orderData = data['order'] as Map<String, dynamic>;
        final updatedOrder = Order.fromJson(orderData);
        _applyOrderLocally(updatedOrder);
        unawaited(_cacheActiveOrders());
        unawaited(_cacheAllOrders());
        notifyListeners();
        onOrderEvent?.call();
      } catch (e) {
        debugPrint('[Socket.io] Failed to parse order_updated: $e');
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket.io] Disconnected');
    });

    _socket!.onError((err) {
      debugPrint('[Socket.io] Error: $err');
    });
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
  }

  // ─── Data Fetching ──────────────────────────────────────────────────────────

  Future<void> fetchActiveOrders({bool silent = false}) async {
    if (_activeOrders.isEmpty) {
      final restored = await _restoreActiveOrdersFromCache();
      if (restored && !silent) notifyListeners();
    }

    final hasSavedData = _activeOrders.isNotEmpty;
    if (!silent && !hasSavedData) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await ApiService.get(ApiConfig.activeOrders, auth: true);
      _activeOrders = (response['data']['orders'] as List)
          .map((o) => Order.fromJson(o))
          .toList();
      _isOfflineMode = false;
      _lastUpdatedAt = DateTime.now();
      await _cacheActiveOrders();
      await OfflineSyncService.markOnline();
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        _isOfflineMode = true;
        await OfflineSyncService.markOffline();
        _errorMessage = hasSavedData
            ? null
            : 'Offline. Saved orders will appear here after the first sync.';
      } else {
        _errorMessage = e.message;
      }
    } catch (e) {
      _isOfflineMode = true;
      await OfflineSyncService.markOffline();
      _errorMessage = hasSavedData
          ? null
          : 'Offline. Saved orders will appear here after the first sync.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllOrders({String? status, String? date}) async {
    final cacheKey = _allOrdersCacheKey(status: status, date: date);
    if (_allOrders.isEmpty) {
      final restored = await _restoreAllOrdersFromCache(cacheKey);
      if (restored) notifyListeners();
    }

    final hasSavedData = _allOrders.isNotEmpty;
    if (!hasSavedData) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      var url = ApiConfig.restaurantOrders;
      final params = <String>[];
      if (status != null) params.add('status=$status');
      if (date != null) params.add('date=$date');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await ApiService.get(url, auth: true);
      _allOrders = (response['data']['orders'] as List)
          .map((o) => Order.fromJson(o))
          .toList();
      _isOfflineMode = false;
      _lastUpdatedAt = DateTime.now();
      await _cacheAllOrders(cacheKey: cacheKey);
      await OfflineSyncService.markOnline();
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        _isOfflineMode = true;
        await OfflineSyncService.markOffline();
        _errorMessage = hasSavedData ? null : 'Offline. No saved orders yet.';
      } else {
        _errorMessage = e.message;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Order?> updateOrderStatus(String orderId, String status) async {
    final previous = _findOrder(orderId);
    Order? optimistic;
    if (previous != null) {
      optimistic = previous.copyWith(
        orderStatus: status,
        paymentStatus: status == 'delivered' &&
                previous.paymentMethod == 'cash' &&
                previous.paymentStatus == 'pending'
            ? 'paid'
            : previous.paymentStatus,
        paidAt: status == 'delivered' &&
                previous.paymentMethod == 'cash' &&
                previous.paymentStatus == 'pending'
            ? DateTime.now().toIso8601String()
            : previous.paidAt,
      );
      _applyOrderLocally(optimistic);
      await _cacheActiveOrders();
      await _cacheAllOrders();
      notifyListeners();
    }

    try {
      final response = await ApiService.put(
        ApiConfig.orderStatus(orderId),
        {'orderStatus': status},
        auth: true,
      );
      final updated = Order.fromJson(response['data']['order']);
      _applyOrderLocally(updated);
      _isOfflineMode = false;
      _lastUpdatedAt = DateTime.now();
      await _cacheActiveOrders();
      await _cacheAllOrders();
      await OfflineSyncService.markOnline();
      notifyListeners();
      return updated;
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        _isOfflineMode = true;
        _errorMessage = null;
        await OfflineSyncService.enqueuePut(
          url: ApiConfig.orderStatus(orderId),
          body: {'orderStatus': status},
          label: 'Order status update',
        );
        notifyListeners();
        return optimistic;
      }
      if (previous != null) {
        _applyOrderLocally(previous);
        await _cacheActiveOrders();
        await _cacheAllOrders();
      }
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<Order?> updatePaymentStatus(
    String orderId,
    String paymentStatus, {
    String? paymentMethod,
  }) async {
    final previous = _findOrder(orderId);
    Order? optimistic;
    if (previous != null) {
      optimistic = previous.copyWith(
        paymentStatus: paymentStatus,
        paymentMethod: paymentMethod ?? previous.paymentMethod,
        paidAt: paymentStatus == 'paid'
            ? DateTime.now().toIso8601String()
            : previous.paidAt,
      );
      _applyOrderLocally(optimistic);
      await _cacheActiveOrders();
      await _cacheAllOrders();
      notifyListeners();
    }

    try {
      final body = <String, dynamic>{'paymentStatus': paymentStatus};
      if (paymentMethod != null) body['paymentMethod'] = paymentMethod;

      final response = await ApiService.put(
        ApiConfig.orderPayment(orderId),
        body,
        auth: true,
      );
      final updated = Order.fromJson(response['data']['order']);
      _applyOrderLocally(updated);
      _isOfflineMode = false;
      _lastUpdatedAt = DateTime.now();
      await _cacheActiveOrders();
      await _cacheAllOrders();
      await OfflineSyncService.markOnline();
      notifyListeners();
      return updated;
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        final body = <String, dynamic>{'paymentStatus': paymentStatus};
        if (paymentMethod != null) body['paymentMethod'] = paymentMethod;
        _isOfflineMode = true;
        _errorMessage = null;
        await OfflineSyncService.enqueuePut(
          url: ApiConfig.orderPayment(orderId),
          body: body,
          label: 'Payment update',
        );
        notifyListeners();
        return optimistic;
      }
      if (previous != null) {
        _applyOrderLocally(previous);
        await _cacheActiveOrders();
        await _cacheAllOrders();
      }
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<Bill?> fetchBill(String orderId) async {
    try {
      final response = await ApiService.get(ApiConfig.bill(orderId));
      return Bill.fromJson(response['data']['bill']);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    }
  }

  Order? _findOrder(String orderId) {
    for (final order in _activeOrders) {
      if (order.id == orderId) return order;
    }
    for (final order in _allOrders) {
      if (order.id == orderId) return order;
    }
    return null;
  }

  void _applyOrderLocally(Order updated) {
    final activeIdx = _activeOrders.indexWhere((o) => o.id == updated.id);
    final isActiveStatus =
        ['placed', 'preparing', 'ready'].contains(updated.orderStatus);

    if (isActiveStatus) {
      if (activeIdx == -1) {
        _activeOrders.insert(0, updated);
      } else {
        _activeOrders[activeIdx] = updated;
      }
    } else if (activeIdx != -1) {
      _activeOrders.removeAt(activeIdx);
    }

    final allIdx = _allOrders.indexWhere((o) => o.id == updated.id);
    if (allIdx != -1) {
      _allOrders[allIdx] = updated;
    } else if (!isActiveStatus) {
      _allOrders.insert(0, updated);
    }
  }

  Future<bool> _restoreActiveOrdersFromCache() async {
    final cached =
        await OfflineCacheService.readJsonList(_activeOrdersCacheKey);
    if (cached == null) return false;
    _activeOrders = cached
        .whereType<Map>()
        .map((item) => Order.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    _lastUpdatedAt = await OfflineCacheService.savedAt(_activeOrdersCacheKey);
    return _activeOrders.isNotEmpty;
  }

  Future<bool> _restoreAllOrdersFromCache(String cacheKey) async {
    final cached = await OfflineCacheService.readJsonList(cacheKey);
    if (cached == null) return false;
    _allOrders = cached
        .whereType<Map>()
        .map((item) => Order.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    _lastUpdatedAt = await OfflineCacheService.savedAt(cacheKey);
    return _allOrders.isNotEmpty;
  }

  Future<void> _cacheActiveOrders() {
    return OfflineCacheService.writeJson(
      _activeOrdersCacheKey,
      _activeOrders.map((order) => order.toJson()).toList(),
    );
  }

  Future<void> _cacheAllOrders({String? cacheKey}) {
    return OfflineCacheService.writeJson(
      cacheKey ?? _allOrdersCacheKey(),
      _allOrders.map((order) => order.toJson()).toList(),
    );
  }

  String _allOrdersCacheKey({String? status, String? date}) {
    final safeStatus = status ?? 'all';
    final safeDate = date ?? 'any';
    return 'owner_orders_${safeStatus}_$safeDate';
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    disconnectSocket();
    super.dispose();
  }
}
