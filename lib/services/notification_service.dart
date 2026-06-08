import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

// ─── Background message handler (must be a top-level function) ────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this is called (Flutter guarantees it).
  debugPrint('[FCM Background] Received: ${message.messageId}');
  // Store locally so the notification history screen can show it
  await NotificationService().storeNotification(AppNotification(
    id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    type: message.data['type'] ?? '',
    title: message.notification?.title ?? '',
    body: message.notification?.body ?? '',
    data: Map<String, String>.from(message.data),
    receivedAt: DateTime.now(),
  ));
}

// ─── AppNotification model ─────────────────────────────────────────────────────

/// Represents a single received notification stored locally
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, String> data;
  final DateTime receivedAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'receivedAt': receivedAt.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] ?? '',
        type: json['type'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        data: Map<String, String>.from(json['data'] ?? {}),
        receivedAt:
            DateTime.tryParse(json['receivedAt'] ?? '') ?? DateTime.now(),
        isRead: json['isRead'] ?? false,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
/// NotificationService
///
/// Full Firebase Cloud Messaging integration for the Restaurant Owner App.
/// Handles foreground, background, and terminated message states.
/// Stores up to 50 notifications in SharedPreferences for the history screen.
/// ─────────────────────────────────────────────────────────────────────────────
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _notificationsKey = 'app_notifications';
  static const int _maxNotifications = 50;
  static const String _webPushVapidKey = String.fromEnvironment(
    'FCM_WEB_VAPID_KEY',
    defaultValue: '',
  );

  // Android notification channel for high-priority order alerts
  static const AndroidNotificationChannel _orderChannel =
      AndroidNotificationChannel(
    'qrcafe_orders',
    'QR Cafe Order Alerts',
    description: 'Notifications for new orders and order status changes',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _lastRestaurantAuthToken;
  bool _tokenRefreshListenerAttached = false;

  // Callback for navigation when notification is tapped
  Function(String type, Map<String, String> data)? onNotificationTap;

  // Unread count notifier — widgets can listen to this
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  // ─── Initialization ──────────────────────────────────────────────────────

  /// Initialize Firebase Messaging and local notifications.
  /// Must be called from main() after Firebase.initializeApp().
  Future<void> initialize() async {
    try {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux)) {
        debugPrint('[NotificationService] FCM not supported on Windows/Linux. Skipping init.');
        return;
      }

      // Register background handler BEFORE any other FCM calls
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request notification permissions (Android 13+ / iOS)
      await _requestPermissions();

      if (!kIsWeb) {
        await _initLocalNotifications();
      }

      // Set foreground notification presentation options (iOS)
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Register message handlers
      _setupMessageHandlers();

      // Refresh unread count
      await _refreshUnreadCount();

      debugPrint('[NotificationService] Fully initialized.');
    } catch (e) {
      debugPrint('[NotificationService] Initialization error (non-fatal): $e');
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
        '[NotificationService] Permission: ${settings.authorizationStatus}');

    // Android 13+ — local notifications also need permission
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _initLocalNotifications() async {
    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_orderChannel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // User tapped on the local notification while app was in foreground
        final payloadStr = response.payload;
        if (payloadStr != null && payloadStr.isNotEmpty) {
          try {
            final Map<String, dynamic> decoded = jsonDecode(payloadStr);
            final type = decoded['type'] as String? ?? '';
            final data = Map<String, String>.from(decoded);
            onNotificationTap?.call(type, data);
          } catch (_) {}
        }
      },
    );
  }

  void _setupMessageHandlers() {
    // Foreground messages — show local notification manually
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM Foreground] Received: ${message.notification?.title}');
      _handleIncomingMessage(message, showLocal: true);
    });

    // Background tap — app was in background, user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM Tap/Background] User tapped notification');
      _handleIncomingMessage(message, showLocal: false);
      // Navigate based on notification type
      final type = message.data['type'] ?? '';
      onNotificationTap?.call(type, Map<String, String>.from(message.data));
    });

    // Terminated state tap — app was killed, user tapped notification
    try {
      if (!kIsWeb) {
        FirebaseMessaging.instance.getInitialMessage().then((message) {
          if (message != null) {
            debugPrint('[FCM Terminated] App opened via notification tap');
            _handleIncomingMessage(message, showLocal: false);
            // Delay navigation until app is fully built
            Future.delayed(const Duration(milliseconds: 500), () {
              final type = message.data['type'] ?? '';
              onNotificationTap?.call(
                  type, Map<String, String>.from(message.data));
            });
          }
        });
      }
    } catch (e) {
      debugPrint('[NotificationService] getInitialMessage error: $e');
    }
  }

  Future<void> _handleIncomingMessage(RemoteMessage message,
      {required bool showLocal}) async {
    final notification = message.notification;
    final data = Map<String, String>.from(message.data);

    // Store in local history
    await storeNotification(AppNotification(
      id: message.messageId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: data['type'] ?? '',
      title: notification?.title ?? '',
      body: notification?.body ?? '',
      data: data,
      receivedAt: DateTime.now(),
    ));

    // Show local notification when app is foreground (FCM doesn't auto-show on Android)
    if (showLocal && notification != null) {
      await _showLocalNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        data: data,
      );
    }

    await _refreshUnreadCount();
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    if (kIsWeb) return;

    final androidDetails = AndroidNotificationDetails(
      _orderChannel.id,
      _orderChannel.name,
      channelDescription: _orderChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body),
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(data),
    );
  }

  // ─── Token Management ────────────────────────────────────────────────────

  /// Get the FCM token for this device and register it with the backend.
  /// Call this every time the app starts and the owner is logged in.
  Future<void> registerTokenForRestaurant(String authToken) async {
    try {
      _lastRestaurantAuthToken = authToken;
      _attachTokenRefreshListener();

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux)) {
        debugPrint('[NotificationService] Skipping token registration on Windows/Linux.');
        return;
      }
      final fcmToken = await _getFcmToken();
      if (fcmToken == null) {
        debugPrint('[NotificationService] FCM token is null — skipping registration.');
        return;
      }
      debugPrint('[NotificationService] FCM Token: $fcmToken');

      final response = await http.post(
        Uri.parse(ApiConfig.registerRestaurantToken),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
          'platform': _platformName,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[NotificationService] Restaurant FCM token registered successfully.');
      } else {
        debugPrint('[NotificationService] Token registration failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[NotificationService] registerTokenForRestaurant error: $e');
    }
  }

  // ─── Local Notification Storage ───────────────────────────────────────────

  Future<String?> _getFcmToken() {
    if (kIsWeb && _webPushVapidKey.isNotEmpty) {
      return FirebaseMessaging.instance.getToken(vapidKey: _webPushVapidKey);
    }
    return FirebaseMessaging.instance.getToken();
  }

  void _attachTokenRefreshListener() {
    if (_tokenRefreshListenerAttached) return;
    _tokenRefreshListenerAttached = true;
    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      final token = _lastRestaurantAuthToken;
      if (token == null || token.isEmpty) return;
      registerTokenForRestaurant(token);
    });
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }

  /// Store a notification in local SharedPreferences (max 50, FIFO).
  Future<void> storeNotification(AppNotification notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_notificationsKey);
      final List<dynamic> list = raw != null ? jsonDecode(raw) : [];

      // Add to front
      list.insert(0, notification.toJson());

      // Keep only last 50
      final trimmed = list.take(_maxNotifications).toList();
      await prefs.setString(_notificationsKey, jsonEncode(trimmed));
      await _refreshUnreadCount();
    } catch (e) {
      debugPrint('[NotificationService] storeNotification error: $e');
    }
  }

  /// Retrieve all stored notifications.
  Future<List<AppNotification>> getStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_notificationsKey);
      if (raw == null) return [];
      final List<dynamic> list = jsonDecode(raw);
      return list.map((j) => AppNotification.fromJson(j)).toList();
    } catch (e) {
      debugPrint('[NotificationService] getStoredNotifications error: $e');
      return [];
    }
  }

  /// Get count of unread notifications.
  Future<int> getUnreadCount() async {
    final notifications = await getStoredNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  Future<void> _refreshUnreadCount() async {
    unreadCount.value = await getUnreadCount();
  }

  /// Mark all notifications as read.
  Future<void> markAllRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_notificationsKey);
      if (raw == null) return;
      final List<dynamic> list = jsonDecode(raw);
      final updated = list.map((j) {
        final n = Map<String, dynamic>.from(j);
        n['isRead'] = true;
        return n;
      }).toList();
      await prefs.setString(_notificationsKey, jsonEncode(updated));
      unreadCount.value = 0;
    } catch (e) {
      debugPrint('[NotificationService] markAllRead error: $e');
    }
  }

  /// Mark a specific notification as read by its ID.
  Future<void> markRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_notificationsKey);
      if (raw == null) return;
      final List<dynamic> list = jsonDecode(raw);
      final updated = list.map((j) {
        final n = Map<String, dynamic>.from(j);
        if (n['id'] == notificationId) n['isRead'] = true;
        return n;
      }).toList();
      await prefs.setString(_notificationsKey, jsonEncode(updated));
      await _refreshUnreadCount();
    } catch (e) {
      debugPrint('[NotificationService] markRead error: $e');
    }
  }

  // ─── Navigation Handler ───────────────────────────────────────────────────

  /// Handle navigation based on notification type.
  void handleNotificationNavigation(
    BuildContext context,
    String type,
    Map<String, String> data, {
    required VoidCallback goToOrders,
    required VoidCallback goToInventory,
  }) {
    switch (type) {
      case 'new_order':
      case 'order_updated':
      case 'order_cancelled':
        goToOrders();
        break;
      case 'low_stock':
        goToInventory();
        break;
    }
  }
}
