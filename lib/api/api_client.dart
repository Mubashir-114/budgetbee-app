import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/services/token_service.dart';

class ApiClient {
  ApiClient._();

  static void Function()? onUnauthorized;

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        "Content-Type": "application/json",
      },
    ),
  )
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenService.getToken();

          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }

          handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Global 401 Unauthorized check
          if (error.response?.statusCode == 401) {
            await TokenService.removeToken();
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
          }

          // Progressive retry logic for Network Timeout or Render Cold Start
          final isTimeout = error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout;
          
          final isConnectionError = error.type == DioExceptionType.connectionError;

          if (isTimeout || isConnectionError) {
            final requestOptions = error.requestOptions;
            int retries = requestOptions.extra['retries'] ?? 0;

            if (retries < 3) {
              requestOptions.extra['retries'] = retries + 1;
              
              // Exponential backoff: 2s, 4s, 6s
              final delaySeconds = (retries + 1) * 2;
              await Future.delayed(Duration(seconds: delaySeconds));

              try {
                final response = await dio.request(
                  requestOptions.path,
                  data: requestOptions.data,
                  queryParameters: requestOptions.queryParameters,
                  options: Options(
                    method: requestOptions.method,
                    headers: requestOptions.headers,
                    contentType: requestOptions.contentType,
                    responseType: requestOptions.responseType,
                    extra: requestOptions.extra,
                  ),
                );
                return handler.resolve(response);
              } catch (retryError) {
                if (retryError is DioException) {
                  error = retryError;
                }
              }
            }
          }

          handler.next(error);
        },
      ),
    )
    ..interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
}