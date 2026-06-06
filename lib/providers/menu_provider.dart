import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/offline_cache_service.dart';
import '../services/offline_sync_service.dart';
import '../config/api_config.dart';

class MenuProvider extends ChangeNotifier {
  static const String _menuCacheKey = 'owner_menu_items';

  List<MenuItem> _items = [];
  Map<String, List<MenuItem>> _grouped = {};
  bool _isLoading = false;
  bool _isOfflineMode = false;
  String? _errorMessage;
  DateTime? _lastUpdatedAt;

  List<MenuItem> get items => _items;
  Map<String, List<MenuItem>> get grouped => _grouped;
  bool get isLoading => _isLoading;
  bool get isOfflineMode => _isOfflineMode;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  void _buildGrouped() {
    _grouped = {};
    for (final item in _items) {
      _grouped.putIfAbsent(item.category, () => []).add(item);
    }
  }

  Future<void> fetchMenuItems() async {
    if (_items.isEmpty) {
      final restored = await _restoreFromCache();
      if (restored) notifyListeners();
    }

    final hasSavedData = _items.isNotEmpty;
    if (!hasSavedData) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await ApiService.get(ApiConfig.menuAll, auth: true);
      _items = (response['data']['items'] as List)
          .map((i) => MenuItem.fromJson(i))
          .toList();
      _buildGrouped();
      _isOfflineMode = false;
      _lastUpdatedAt = DateTime.now();
      await _cacheItems();
      await OfflineSyncService.markOnline();
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        _isOfflineMode = true;
        await OfflineSyncService.markOffline();
        _errorMessage = hasSavedData ? null : 'Offline. No saved menu yet.';
      } else {
        _errorMessage = e.message;
      }
    } catch (e) {
      _isOfflineMode = true;
      await OfflineSyncService.markOffline();
      _errorMessage = hasSavedData ? null : 'Offline. No saved menu yet.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<MenuItem?> addItem({
    required String name,
    required String description,
    required double price,
    required String category,
    required bool isVeg,
    bool isAvailable = true,
    List<int>? imageBytes,
    String? imageName,
  }) async {
    try {
      final response = await ApiService.postMultipart(
        ApiConfig.menu,
        fields: {
          'name': name,
          'description': description,
          'price': price.toString(),
          'category': category,
          'isVeg': isVeg.toString(),
          'isAvailable': isAvailable.toString(),
        },
        fileBytes: imageBytes,
        fileName: imageName,
        fileField: 'image',
        auth: true,
      );
      final item = MenuItem.fromJson(response['data']['item']);
      _items.add(item);
      _buildGrouped();
      await _cacheItems();
      await OfflineSyncService.markOnline();
      notifyListeners();
      return item;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateItem(
    String itemId, {
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isVeg,
    bool? isAvailable,
    List<int>? imageBytes,
    String? imageName,
  }) async {
    final idx = _items.indexWhere((i) => i.id == itemId);
    final previous = idx == -1 ? null : _items[idx];
    final canQueue = imageBytes == null && imageName == null;
    final fields = <String, String>{};
    if (name != null) fields['name'] = name;
    if (description != null) fields['description'] = description;
    if (price != null) fields['price'] = price.toString();
    if (category != null) fields['category'] = category;
    if (isVeg != null) fields['isVeg'] = isVeg.toString();
    if (isAvailable != null) fields['isAvailable'] = isAvailable.toString();

    if (previous != null && canQueue) {
      _items[idx] = previous.copyWith(
        name: name,
        description: description,
        price: price,
        category: category,
        isVeg: isVeg,
        isAvailable: isAvailable,
      );
      _buildGrouped();
      await _cacheItems();
      notifyListeners();
    }

    try {
      final response = await ApiService.putMultipart(
        ApiConfig.menuItemById(itemId),
        fields: fields,
        fileBytes: imageBytes,
        fileName: imageName,
        fileField: 'image',
        auth: true,
      );
      final updated = MenuItem.fromJson(response['data']['item']);
      final updatedIdx = _items.indexWhere((i) => i.id == itemId);
      if (updatedIdx != -1) _items[updatedIdx] = updated;
      _buildGrouped();
      _isOfflineMode = false;
      _lastUpdatedAt = DateTime.now();
      await _cacheItems();
      await OfflineSyncService.markOnline();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      if (e.isNetworkError && canQueue) {
        _isOfflineMode = true;
        _errorMessage = null;
        await OfflineSyncService.enqueuePut(
          url: ApiConfig.menuItemById(itemId),
          body: Map<String, dynamic>.from(fields),
          label: 'Menu update',
        );
        notifyListeners();
        return true;
      }
      if (previous != null && canQueue) {
        _items[idx] = previous;
        _buildGrouped();
        await _cacheItems();
      }
      _errorMessage =
          e.isNetworkError ? 'Connect to upload menu images.' : e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await ApiService.delete(ApiConfig.menuItemById(itemId), auth: true);
      _items.removeWhere((i) => i.id == itemId);
      _buildGrouped();
      await _cacheItems();
      await OfflineSyncService.markOnline();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        final removed = _items.where((i) => i.id == itemId).toList();
        _items.removeWhere((i) => i.id == itemId);
        _buildGrouped();
        await _cacheItems();
        await OfflineSyncService.enqueue(
          QueuedRequest(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            method: 'DELETE',
            url: ApiConfig.menuItemById(itemId),
            body: const {},
            auth: true,
            label: 'Menu item delete',
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

  /// Quick toggle availability without full reload
  Future<void> toggleAvailability(String itemId, bool isAvailable) async {
    await updateItem(itemId, isAvailable: isAvailable);
  }

  Future<bool> _restoreFromCache() async {
    final cached = await OfflineCacheService.readJsonList(_menuCacheKey);
    if (cached == null) return false;
    _items = cached
        .whereType<Map>()
        .map((item) => MenuItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    _buildGrouped();
    _lastUpdatedAt = await OfflineCacheService.savedAt(_menuCacheKey);
    return _items.isNotEmpty;
  }

  Future<void> _cacheItems() {
    return OfflineCacheService.writeJson(
      _menuCacheKey,
      _items.map((item) => item.toJson()).toList(),
    );
  }
}
