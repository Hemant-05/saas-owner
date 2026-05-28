import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class TableProvider extends ChangeNotifier {
  List<TableModel> _tables = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  List<TableModel> get tables => _tables;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      final response = await ApiService.get(ApiConfig.tables, auth: true);
      _tables = (response['data']['tables'] as List)
          .map((t) => TableModel.fromJson(t))
          .toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load tables';
    }
    if (!silent) {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<TableModel?> addTable(int tableNumber, String tableName) async {
    try {
      final response = await ApiService.post(
        ApiConfig.tables,
        {'tableNumber': tableNumber, 'tableName': tableName},
        auth: true,
      );
      final table = TableModel.fromJson(response['data']['table']);
      _tables.add(table);
      _tables.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
      notifyListeners();
      return table;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateTable(String tableId, String tableName) async {
    try {
      final response = await ApiService.put(
        ApiConfig.tableById(tableId),
        {'tableName': tableName},
        auth: true,
      );
      final updated = TableModel.fromJson(response['data']['table']);
      final idx = _tables.indexWhere((t) => t.id == tableId);
      if (idx != -1) _tables[idx] = updated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleServiceable(String tableId, bool isServiceable) async {
    try {
      final response = await ApiService.put(
        ApiConfig.tableById(tableId),
        {'isServiceable': isServiceable},
        auth: true,
      );
      final updatedRaw = response['data']['table'];
      final idx = _tables.indexWhere((t) => t.id == tableId);
      if (idx != -1) {
        final currentTable = _tables[idx];
        updatedRaw['isOccupied'] = currentTable.isOccupied;
        _tables[idx] = TableModel.fromJson(updatedRaw);
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTable(String tableId) async {
    try {
      await ApiService.delete(ApiConfig.tableById(tableId), auth: true);
      _tables.removeWhere((t) => t.id == tableId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
