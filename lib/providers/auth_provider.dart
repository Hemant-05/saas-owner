import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/offline_cache_service.dart';
import '../services/offline_sync_service.dart';
import '../config/api_config.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  static const String _restaurantCacheKey = 'owner_restaurant_profile';

  AuthState _state = AuthState.initial;
  Restaurant? _restaurant;
  String? _errorMessage;

  AuthState get state => _state;
  Restaurant? get restaurant => _restaurant;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;

  /// Called on app start — restores session from stored token
  Future<void> loadFromStorage() async {
    final token = await ApiService.getToken();
    if (token == null) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final response = await ApiService.get(ApiConfig.me, auth: true);
      _restaurant = Restaurant.fromJson(response['data']['restaurant']);
      await _cacheRestaurant(_restaurant!);
      _state = AuthState.authenticated;
      await OfflineSyncService.markOnline();
      // Non-blocking: register FCM token on every app start
      NotificationService()
          .registerTokenForRestaurant(token)
          .catchError((_) {});
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        final cached =
            await OfflineCacheService.readJsonMap(_restaurantCacheKey);
        if (cached != null) {
          _restaurant = Restaurant.fromJson(cached);
          _state = AuthState.authenticated;
          await OfflineSyncService.markOffline();
        } else {
          _state = AuthState.unauthenticated;
        }
      } else {
        await ApiService.clearToken();
        _state = AuthState.unauthenticated;
      }
    } catch (_) {
      final cached = await OfflineCacheService.readJsonMap(_restaurantCacheKey);
      if (cached != null) {
        _restaurant = Restaurant.fromJson(cached);
        _state = AuthState.authenticated;
        await OfflineSyncService.markOffline();
      } else {
        await ApiService.clearToken();
        _state = AuthState.unauthenticated;
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiService.post(ApiConfig.login, {
        'email': email,
        'password': password,
      });
      final data = response['data'];
      final token = data['token'] as String;
      await ApiService.saveToken(token);
      _restaurant = Restaurant.fromJson(data['restaurant']);
      await _cacheRestaurant(_restaurant!);
      _state = AuthState.authenticated;
      await OfflineSyncService.markOnline();
      // Non-blocking: register FCM token after login
      NotificationService()
          .registerTokenForRestaurant(token)
          .catchError((_) {});
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _state = AuthState.error;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? gstNumber,
    String? address,
    List<int>? logoBytes,
    String? logoName,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      Map<String, dynamic> response;
      if (logoBytes != null && logoName != null) {
        response = await ApiService.postMultipart(
          ApiConfig.register,
          fields: {
            'name': name,
            'email': email,
            'password': password,
            'phone': phone,
            if (gstNumber != null) 'gstNumber': gstNumber,
            if (address != null) 'address': address,
          },
          fileBytes: logoBytes,
          fileName: logoName,
          fileField: 'logo',
        );
      } else {
        response = await ApiService.post(ApiConfig.register, {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          if (gstNumber != null) 'gstNumber': gstNumber,
          if (address != null) 'address': address,
        });
      }
      final data = response['data'];
      await ApiService.saveToken(data['token']);
      _restaurant = Restaurant.fromJson(data['restaurant']);
      await _cacheRestaurant(_restaurant!);
      _state = AuthState.authenticated;
      await OfflineSyncService.markOnline();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? address,
    List<int>? logoBytes,
    String? logoName,
  }) async {
    try {
      final response = await ApiService.putMultipart(
        ApiConfig.updateProfile,
        fields: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
        },
        fileBytes: logoBytes,
        fileName: logoName,
        fileField: 'logo',
        auth: true,
      );
      _restaurant = Restaurant.fromJson(response['data']['restaurant']);
      await _cacheRestaurant(_restaurant!);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    await OfflineCacheService.remove(_restaurantCacheKey);
    _restaurant = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<bool> forgotPassword(String email) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      // Mocking the forgot password logic since no backend endpoint exists
      await Future.delayed(const Duration(seconds: 1));
      _state = AuthState.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to process request';
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> _cacheRestaurant(Restaurant restaurant) {
    return OfflineCacheService.writeJson(
      _restaurantCacheKey,
      restaurant.toJson(),
    );
  }
}
