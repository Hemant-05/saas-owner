import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../config/api_config.dart';
import 'dart:io';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
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
      _state = AuthState.authenticated;
      // Non-blocking: register FCM token on every app start
      NotificationService().registerTokenForRestaurant(token).catchError((_) {});
    } catch (_) {
      await ApiService.clearToken();
      _state = AuthState.unauthenticated;
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
      _state = AuthState.authenticated;
      // Non-blocking: register FCM token after login
      NotificationService().registerTokenForRestaurant(token).catchError((_) {});
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
    String? address,
    File? logo,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      Map<String, dynamic> response;
      if (logo != null) {
        response = await ApiService.postMultipart(
          ApiConfig.register,
          fields: {
            'name': name,
            'email': email,
            'password': password,
            'phone': phone,
            if (address != null) 'address': address,
          },
          fileBytes: await logo.readAsBytes(),
          fileName: logo.path.split(Platform.pathSeparator).last,
          fileField: 'logo',
        );
      } else {
        response = await ApiService.post(ApiConfig.register, {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          if (address != null) 'address': address,
        });
      }
      final data = response['data'];
      await ApiService.saveToken(data['token']);
      _restaurant = Restaurant.fromJson(data['restaurant']);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? address,
    File? logo,
  }) async {
    try {
      final response = await ApiService.putMultipart(
        ApiConfig.updateProfile,
        fields: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
        },
        fileBytes: logo != null ? await logo.readAsBytes() : null,
        fileName: logo?.path.split(Platform.pathSeparator).last,
        fileField: 'logo',
        auth: true,
      );
      _restaurant = Restaurant.fromJson(response['data']['restaurant']);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _restaurant = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
