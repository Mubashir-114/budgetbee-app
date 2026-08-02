import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/services/cache_service.dart';
import '../core/services/token_service.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _repository.login(
        email: email,
        password: password,
      );

      await TokenService.saveToken(
        response.data.token,
      );

      _currentUser = response.data.user;

      notifyListeners();

      return true;
    } on DioException catch (e) {
      _errorMessage =
          e.response?.data["message"] ?? e.message ?? "Login failed";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _repository.register(
        name: name,
        email: email,
        password: password,
      );

      await TokenService.saveToken(
        response.data.token,
      );

      _currentUser = response.data.user;

      notifyListeners();

      return true;
    } on DioException catch (e) {
      _errorMessage =
          e.response?.data["message"] ?? e.message ?? "Registration failed";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await TokenService.removeToken();
    await CacheService.clearAll();

    _currentUser = null;
    _isLoading = false;
    _errorMessage = null;

    notifyListeners();
  }

  Future<bool> loadCurrentUser() async {
    try {
      final token = await TokenService.getToken();

      if (token == null) {
        return false;
      }

      final response = await _repository.getProfile();

      _currentUser = response.data.user;

      notifyListeners();

      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Simulate network latency since API route doesn't exist
      await Future.delayed(const Duration(seconds: 1));

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(name: name, email: email);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Simulate network latency since API route doesn't exist
      await Future.delayed(const Duration(seconds: 1));

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}