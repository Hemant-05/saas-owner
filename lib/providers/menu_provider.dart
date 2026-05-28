import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class MenuProvider extends ChangeNotifier {
  List<MenuItem> _items = [];
  Map<String, List<MenuItem>> _grouped = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<MenuItem> get items => _items;
  Map<String, List<MenuItem>> get grouped => _grouped;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _buildGrouped() {
    _grouped = {};
    for (final item in _items) {
      _grouped.putIfAbsent(item.category, () => []).add(item);
    }
  }

  Future<void> fetchMenuItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiService.get(ApiConfig.menuAll, auth: true);
      _items = (response['data']['items'] as List)
          .map((i) => MenuItem.fromJson(i))
          .toList();
      _buildGrouped();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load menu';
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
    try {
      final fields = <String, String>{};
      if (name != null) fields['name'] = name;
      if (description != null) fields['description'] = description;
      if (price != null) fields['price'] = price.toString();
      if (category != null) fields['category'] = category;
      if (isVeg != null) fields['isVeg'] = isVeg.toString();
      if (isAvailable != null) fields['isAvailable'] = isAvailable.toString();

      final response = await ApiService.putMultipart(
        ApiConfig.menuItemById(itemId),
        fields: fields,
        fileBytes: imageBytes,
        fileName: imageName,
        fileField: 'image',
        auth: true,
      );
      final updated = MenuItem.fromJson(response['data']['item']);
      final idx = _items.indexWhere((i) => i.id == itemId);
      if (idx != -1) _items[idx] = updated;
      _buildGrouped();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await ApiService.delete(ApiConfig.menuItemById(itemId), auth: true);
      _items.removeWhere((i) => i.id == itemId);
      _buildGrouped();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Quick toggle availability without full reload
  Future<void> toggleAvailability(String itemId, bool isAvailable) async {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isAvailable: isAvailable);
      _buildGrouped();
      notifyListeners();
    }
    await updateItem(itemId, isAvailable: isAvailable);
  }
}
