import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../config/api_config.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _activeOrders = [];
  List<Order> _allOrders = [];
  bool _isLoading = false;
  String? _errorMessage;
  IO.Socket? _socket;
  Timer? _refreshTimer;

  List<Order> get activeOrders => _activeOrders;
  List<Order> get allOrders => _allOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      body: 'Table ${order.tableNumber} — ₹${order.totalAmount.toStringAsFixed(2)}',
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
      debugPrint('[Socket.io] Connected — joining room: restaurant:$restaurantId');
      _socket!.emit('join_restaurant', restaurantId);
      // Start polling as a fallback for missed socket events
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        fetchActiveOrders();
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
        _updateOrderInList(updatedOrder);
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

  Future<void> fetchActiveOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiService.get(ApiConfig.activeOrders, auth: true);
      _activeOrders = (response['data']['orders'] as List)
          .map((o) => Order.fromJson(o))
          .toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load orders';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllOrders({String? status, String? date}) async {
    _isLoading = true;
    notifyListeners();
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
    } on ApiException catch (e) {
      _errorMessage = e.message;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Order?> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await ApiService.put(
        ApiConfig.orderStatus(orderId),
        {'orderStatus': status},
        auth: true,
      );
      final updated = Order.fromJson(response['data']['order']);
      _updateOrderInList(updated);
      notifyListeners();
      return updated;
    } on ApiException catch (e) {
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
    try {
      final body = <String, dynamic>{'paymentStatus': paymentStatus};
      if (paymentMethod != null) body['paymentMethod'] = paymentMethod;

      final response = await ApiService.put(
        ApiConfig.orderPayment(orderId),
        body,
        auth: true,
      );
      final updated = Order.fromJson(response['data']['order']);
      _updateOrderInList(updated);
      notifyListeners();
      return updated;
    } on ApiException catch (e) {
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

  void _updateOrderInList(Order updated) {
    // Update in active orders
    final activeIdx = _activeOrders.indexWhere((o) => o.id == updated.id);
    if (activeIdx != -1) {
      if (['placed', 'preparing', 'ready'].contains(updated.orderStatus)) {
        _activeOrders[activeIdx] = updated;
      } else {
        // Move to all orders if delivered/cancelled
        _activeOrders.removeAt(activeIdx);
      }
    }
    // Update in all orders
    final allIdx = _allOrders.indexWhere((o) => o.id == updated.id);
    if (allIdx != -1) {
      _allOrders[allIdx] = updated;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    disconnectSocket();
    super.dispose();
  }
}
