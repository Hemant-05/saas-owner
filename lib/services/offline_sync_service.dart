import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class OfflineSyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingActions;
  final DateTime? lastSyncedAt;

  const OfflineSyncState({
    this.isOnline = true,
    this.isSyncing = false,
    this.pendingActions = 0,
    this.lastSyncedAt,
  });

  OfflineSyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingActions,
    DateTime? lastSyncedAt,
  }) {
    return OfflineSyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingActions: pendingActions ?? this.pendingActions,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class QueuedRequest {
  final String id;
  final String method;
  final String url;
  final Map<String, dynamic> body;
  final bool auth;
  final String label;
  final DateTime createdAt;

  QueuedRequest({
    required this.id,
    required this.method,
    required this.url,
    required this.body,
    required this.auth,
    required this.label,
    required this.createdAt,
  });

  String get dedupeKey => '$method::$url';

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'url': url,
        'body': body,
        'auth': auth,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) {
    return QueuedRequest(
      id: json['id'] ?? '',
      method: json['method'] ?? 'PUT',
      url: json['url'] ?? '',
      body: Map<String, dynamic>.from(json['body'] ?? const {}),
      auth: json['auth'] ?? true,
      label: json['label'] ?? 'Saved action',
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
    );
  }
}

class OfflineSyncService {
  OfflineSyncService._();

  static const String _queueKey = 'offline_sync_queue';

  static final ValueNotifier<OfflineSyncState> notifier =
      ValueNotifier<OfflineSyncState>(const OfflineSyncState());

  static Timer? _timer;
  static bool _isFlushing = false;

  static Future<void> initialize() async {
    await _refreshPendingCount();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      flushQueuedRequests();
    });
    flushQueuedRequests();
  }

  static void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> markOffline() async {
    if (!notifier.value.isOnline) return;
    notifier.value = notifier.value.copyWith(isOnline: false);
  }

  static Future<void> markOnline({bool sync = true}) async {
    notifier.value = notifier.value.copyWith(isOnline: true);
    if (sync) await flushQueuedRequests();
  }

  static Future<void> enqueuePut({
    required String url,
    required Map<String, dynamic> body,
    required String label,
    bool auth = true,
  }) {
    return enqueue(
      QueuedRequest(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        method: 'PUT',
        url: url,
        body: body,
        auth: auth,
        label: label,
        createdAt: DateTime.now(),
      ),
    );
  }

  static Future<void> enqueue(QueuedRequest request) async {
    final queue = await _loadQueue();
    queue.removeWhere((item) => item.dedupeKey == request.dedupeKey);
    queue.add(request);
    await _saveQueue(queue);
    await _refreshPendingCount();
    await markOffline();
  }

  static Future<int> flushQueuedRequests() async {
    if (_isFlushing) return 0;

    final queue = await _loadQueue();
    if (queue.isEmpty) {
      notifier.value = notifier.value.copyWith(
        isSyncing: false,
        pendingActions: 0,
      );
      return 0;
    }

    _isFlushing = true;
    notifier.value = notifier.value.copyWith(
      isSyncing: true,
      pendingActions: queue.length,
    );

    final remaining = <QueuedRequest>[];
    var synced = 0;
    var hitNetworkProblem = false;

    for (final request in queue) {
      try {
        await _send(request);
        synced++;
      } on ApiException catch (error) {
        if (error.isNetworkError) {
          hitNetworkProblem = true;
          remaining.add(request);
        } else {
          debugPrint(
            '[OfflineSync] Dropped "${request.label}" after server rejection: ${error.message}',
          );
        }
      } catch (error) {
        hitNetworkProblem = true;
        remaining.add(request);
      }
    }

    await _saveQueue(remaining);
    final pendingCount = remaining.length;
    notifier.value = notifier.value.copyWith(
      isOnline: !hitNetworkProblem,
      isSyncing: false,
      pendingActions: pendingCount,
      lastSyncedAt: synced > 0 ? DateTime.now() : notifier.value.lastSyncedAt,
    );
    _isFlushing = false;
    return synced;
  }

  static Future<void> _send(QueuedRequest request) async {
    switch (request.method.toUpperCase()) {
      case 'PUT':
        await ApiService.put(request.url, request.body, auth: request.auth);
        return;
      case 'POST':
        await ApiService.post(request.url, request.body, auth: request.auth);
        return;
      case 'DELETE':
        await ApiService.delete(request.url, auth: request.auth);
        return;
      default:
        throw ApiException('Unsupported offline action', 400);
    }
  }

  static Future<List<QueuedRequest>> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
              (item) => QueuedRequest.fromJson(Map<String, dynamic>.from(item)))
          .where((request) => request.url.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveQueue(List<QueuedRequest> queue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _queueKey,
      jsonEncode(queue.map((request) => request.toJson()).toList()),
    );
  }

  static Future<void> _refreshPendingCount() async {
    final queue = await _loadQueue();
    notifier.value = notifier.value.copyWith(pendingActions: queue.length);
  }
}
