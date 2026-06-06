import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/offline_cache_service.dart';
import '../services/offline_sync_service.dart';
import '../config/api_config.dart';

class TableProvider extends ChangeNotifier {
  static const String _tablesCacheKey = 'owner_tables';

  List<TableModel> _tables = [];
  bool _isLoading = false;
  bool _isOfflineMode = false;
  String? _errorMessage;
  DateTime? _lastUpdatedAt;
  Timer? _refreshTimer;

  List<TableModel> get tables => _tables;
  bool get isLoading => _isLoading;
  bool get isOfflineMode => _isOfflineMode;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  TableProvider() {
    // Auto-refresh every 15 seconds to keep occupancy up to date
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchTables(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchTables({bool silent = false}) async {
    if (_tables.isEmpty) {
      final restored = await _restoreFromCache();
      if (restored && !silent) notifyListeners();
    }

    final hasSavedData = _tables.isNotEmpty;
    if (!silent) {
      _isLoading = !hasSavedData;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      final response = await ApiService.get(ApiConfig.tables, auth: true);
      _tables = (response['data']['tables'] as List)
          .map((t) => TableModel.fromJson(t))
          .toList();
      _isOfflineMode = false;
      _lastUpdatedAt = DateTime.now();
      await _cacheTables();
      await OfflineSyncService.markOnline();
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        _isOfflineMode = true;
        await OfflineSyncService.markOffline();
        _errorMessage = hasSavedData ? null : 'Offline. No saved tables yet.';
      } else {
        _errorMessage = e.message;
      }
    } catch (e) {
      _isOfflineMode = true;
      await OfflineSyncService.markOffline();
      _errorMessage = hasSavedData ? null : 'Offline. No saved tables yet.';
    }
    if (!silent) {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<TableModel?> addTable(int tableNumber, String tableName, int capacity) async {
    try {
      final response = await ApiService.post(
        ApiConfig.tables,
        {'tableNumber': tableNumber, 'tableName': tableName, 'capacity': capacity},
        auth: true,
      );
      final table = TableModel.fromJson(response['data']['table']);
      _tables.add(table);
      _tables.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
      await _cacheTables();
      await OfflineSyncService.markOnline();
      notifyListeners();
      return table;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateTable(String tableId, String tableName) async {
    final idx = _tables.indexWhere((t) => t.id == tableId);
    final previous = idx == -1 ? null : _tables[idx];
    if (previous != null) {
      _tables[idx] = previous.copyWith(tableName: tableName);
      await _cacheTables();
      notifyListeners();
    }

    try {
      final response = await ApiService.put(
        ApiConfig.tableById(tableId),
        {'tableName': tableName},
        auth: true,
      );
      final updated = TableModel.fromJson(response['data']['table']);
      final updatedIdx = _tables.indexWhere((t) => t.id == tableId);
      if (updatedIdx != -1) _tables[updatedIdx] = updated;
      _isOfflineMode = false;
      _lastUpdatedAt = DateTime.now();
      await _cacheTables();
      await OfflineSyncService.markOnline();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        _isOfflineMode = true;
        _errorMessage = null;
        await OfflineSyncService.enqueuePut(
          url: ApiConfig.tableById(tableId),
          body: {'tableName': tableName},
          label: 'Table update',
        );
        notifyListeners();
        return previous != null;
      }
      if (previous != null) {
        _tables[idx] = previous;
        await _cacheTables();
      }
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleServiceable(String tableId, bool isServiceable) async {
    final idx = _tables.indexWhere((t) => t.id == tableId);
    final previous = idx == -1 ? null : _tables[idx];
    if (previous != null) {
      _tables[idx] = previous.copyWith(isServiceable: isServiceable);
      await _cacheTables();
      notifyListeners();
    }

    try {
      final response = await ApiService.put(
        ApiConfig.tableById(tableId),
        {'isServiceable': isServiceable},
        auth: true,
      );
      final updatedRaw = response['data']['table'];
      final updatedIdx = _tables.indexWhere((t) => t.id == tableId);
      if (updatedIdx != -1) {
        final currentTable = _tables[updatedIdx];
        updatedRaw['isOccupied'] = currentTable.isOccupied;
        _tables[updatedIdx] = TableModel.fromJson(updatedRaw);
        _isOfflineMode = false;
        _lastUpdatedAt = DateTime.now();
        await _cacheTables();
        await OfflineSyncService.markOnline();
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        _isOfflineMode = true;
        _errorMessage = null;
        await OfflineSyncService.enqueuePut(
          url: ApiConfig.tableById(tableId),
          body: {'isServiceable': isServiceable},
          label: 'Table service update',
        );
        notifyListeners();
        return previous != null;
      }
      if (previous != null) {
        _tables[idx] = previous;
        await _cacheTables();
      }
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTable(String tableId) async {
    try {
      await ApiService.delete(ApiConfig.tableById(tableId), auth: true);
      _tables.removeWhere((t) => t.id == tableId);
      await _cacheTables();
      await OfflineSyncService.markOnline();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        final removed = _tables.where((t) => t.id == tableId).toList();
        _tables.removeWhere((t) => t.id == tableId);
        await _cacheTables();
        await OfflineSyncService.enqueue(
          QueuedRequest(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            method: 'DELETE',
            url: ApiConfig.tableById(tableId),
            body: const {},
            auth: true,
            label: 'Table delete',
            createdAt: DateTime.now(),
          ),
        );
        _errorMessage = null;
        _isOfflineMode = true;
        notifyListeners();
        return removed.isNotEmpty;
      }
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _restoreFromCache() async {
    final cached = await OfflineCacheService.readJsonList(_tablesCacheKey);
    if (cached == null) return false;
    _tables = cached
        .whereType<Map>()
        .map((item) => TableModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    _lastUpdatedAt = await OfflineCacheService.savedAt(_tablesCacheKey);
    return _tables.isNotEmpty;
  }

  Future<void> _cacheTables() {
    return OfflineCacheService.writeJson(
      _tablesCacheKey,
      _tables.map((table) => table.toJson()).toList(),
    );
  }
}
