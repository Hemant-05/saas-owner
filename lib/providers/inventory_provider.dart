import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/inventory_models.dart';

enum InventoryState { idle, loading, loaded, error }

class InventoryProvider with ChangeNotifier {
  InventoryState _state = InventoryState.idle;
  List<InventoryItem> _items = [];
  List<InventoryItem> _lowStockItems = [];
  InventoryStats _stats = InventoryStats.empty();
  List<StockTransaction> _transactions = [];
  List<MenuItemIngredient> _menuLinks = [];
  String? _errorMessage;

  InventoryState get state => _state;
  List<InventoryItem> get items => _items;
  List<InventoryItem> get lowStockItems => _lowStockItems;
  InventoryStats get stats => _stats;
  List<StockTransaction> get transactions => _transactions;
  List<MenuItemIngredient> get menuLinks => _menuLinks;
  String? get errorMessage => _errorMessage;

  String? _token;

  Future<String?> _getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    return _token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_token ?? ''}',
      };

  // ─── Fetch All Items ──────────────────────────────────────────────────────
  Future<void> fetchItems() async {
    try {
      _state = InventoryState.loading;
      notifyListeners();

      final token = await _getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.inventoryItems),
        headers: {
          'Authorization': 'Bearer ${token ?? ''}',
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _items = (data['data']['items'] as List)
            .map((j) => InventoryItem.fromJson(j))
            .toList();
        if (data['data']['summary'] != null) {
          _stats = InventoryStats.fromJson(data['data']['summary']);
        }
        _state = InventoryState.loaded;
      } else {
        _errorMessage = data['message'] ?? 'Failed to load inventory';
        _state = InventoryState.error;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = InventoryState.error;
    }
    notifyListeners();
  }

  // ─── Fetch Low Stock Items (for dashboard alert) ──────────────────────────
  Future<void> fetchLowStockItems() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.inventoryLowStock),
        headers: {'Authorization': 'Bearer ${token ?? ''}'},
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _lowStockItems = (data['data']['items'] as List)
            .map((j) => InventoryItem.fromJson(j))
            .toList();
        notifyListeners();
      }
    } catch (_) {
      // Silently fail — low stock alerts are non-critical
    }
  }

  // ─── Create Item ──────────────────────────────────────────────────────────
  Future<String?> createItem({
    required String name,
    required String unit,
    required double currentStock,
    required double lowStockThreshold,
    double? costPerUnit,
    File? imageFile,
  }) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse(ApiConfig.inventoryItems);
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer ${token ?? ''}';
      request.fields['name'] = name;
      request.fields['unit'] = unit;
      request.fields['currentStock'] = currentStock.toString();
      request.fields['lowStockThreshold'] = lowStockThreshold.toString();
      if (costPerUnit != null) {
        request.fields['costPerUnit'] = costPerUnit.toString();
      }

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        await fetchItems();
        return null; // success
      }
      return data['message'] ?? 'Failed to create item';
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Update Item ──────────────────────────────────────────────────────────
  Future<String?> updateItem({
    required String itemId,
    String? name,
    String? unit,
    double? lowStockThreshold,
    double? costPerUnit,
    File? imageFile,
  }) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse(ApiConfig.inventoryItemById(itemId));
      final request = http.MultipartRequest('PUT', uri);

      request.headers['Authorization'] = 'Bearer ${token ?? ''}';
      if (name != null) request.fields['name'] = name;
      if (unit != null) request.fields['unit'] = unit;
      if (lowStockThreshold != null) {
        request.fields['lowStockThreshold'] = lowStockThreshold.toString();
      }
      if (costPerUnit != null) {
        request.fields['costPerUnit'] = costPerUnit.toString();
      }

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        await fetchItems();
        return null;
      }
      return data['message'] ?? 'Failed to update item';
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Delete Item ──────────────────────────────────────────────────────────
  Future<String?> deleteItem(String itemId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse(ApiConfig.inventoryItemById(itemId)),
        headers: {'Authorization': 'Bearer ${token ?? ''}'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _items.removeWhere((i) => i.id == itemId);
        notifyListeners();
        return null;
      }
      return data['message'] ?? 'Failed to delete item';
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Adjust Stock ─────────────────────────────────────────────────────────
  Future<String?> adjustStock({
    required String itemId,
    required double quantity,
    required String transactionType,
    String? note,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.inventoryAdjust(itemId)),
        headers: {
          'Authorization': 'Bearer ${token ?? ''}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'quantity': quantity,
          'transactionType': transactionType,
          'note': note ?? '',
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        // Update item in local list
        final updatedItem = InventoryItem.fromJson(data['data']['item']);
        final idx = _items.indexWhere((i) => i.id == itemId);
        if (idx != -1) {
          _items[idx] = updatedItem;
        }
        notifyListeners();
        return null;
      }
      return data['message'] ?? 'Failed to adjust stock';
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Fetch Transactions for one item ──────────────────────────────────────
  Future<void> fetchItemTransactions(String itemId, {int page = 1}) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.inventoryItemById(itemId)}/transactions?page=$page&limit=50'),
        headers: {'Authorization': 'Bearer ${token ?? ''}'},
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _transactions = (data['data']['transactions'] as List)
            .map((j) => StockTransaction.fromJson(j))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[InventoryProvider] fetchItemTransactions error: $e');
    }
  }

  // ─── Menu Links ───────────────────────────────────────────────────────────
  Future<void> fetchMenuLinks(String menuItemId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.inventoryMenuLinks(menuItemId)),
        headers: {'Authorization': 'Bearer ${token ?? ''}'},
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _menuLinks = (data['data']['links'] as List)
            .map((j) => MenuItemIngredient.fromJson(j))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[InventoryProvider] fetchMenuLinks error: $e');
    }
  }

  Future<String?> linkIngredient({
    required String menuItemId,
    required String inventoryItemId,
    required double quantityUsedPerServing,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.inventoryMenuLinksBase),
        headers: {
          'Authorization': 'Bearer ${token ?? ''}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'menuItemId': menuItemId,
          'inventoryItemId': inventoryItemId,
          'quantityUsedPerServing': quantityUsedPerServing,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        await fetchMenuLinks(menuItemId);
        return null;
      }
      return data['message'] ?? 'Failed to link ingredient';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> unlinkIngredient(String linkId, String menuItemId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse(ApiConfig.inventoryMenuLinkById(linkId)),
        headers: {'Authorization': 'Bearer ${token ?? ''}'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _menuLinks.removeWhere((l) => l.id == linkId);
        notifyListeners();
        return null;
      }
      return data['message'] ?? 'Failed to unlink ingredient';
    } catch (e) {
      return e.toString();
    }
  }

  void clearToken() {
    _token = null;
  }
}
