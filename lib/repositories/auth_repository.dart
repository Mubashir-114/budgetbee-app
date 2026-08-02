import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/auth_response.dart';

class AuthRepository {
  final Dio _dio = ApiClient.dio;

  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      "auth/login",
      data: {
        "email": email,
        "password": password,
      },
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => AuthResponse.fromJson(json),
    );
  }

  Future<ApiResponse<AuthResponse>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      "auth/register",
      data: {
        "name": name,
        "email": email,
        "password": password,
      },
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => AuthResponse.fromJson(json),
    );
  }

  Future<ApiResponse<AuthResponse>> getProfile() async {
    final response = await _dio.get("auth/me");

    return ApiResponse.fromJson(
      response.data,
      (json) => AuthResponse.fromJson(json),
    );
  }
}