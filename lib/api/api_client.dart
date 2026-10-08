import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/services/token_service.dart';

class ApiClient {
  ApiClient._();

  static void Function()? onUnauthorized;

  static final Dio dio = createDio();

  static Dio createDio({
    Future<String?> Function()? tokenProvider,
    Future<void> Function()? tokenRemover,
  }) {
    final client = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuth'] == true) {
            options.headers.remove('Authorization');
            handler.next(options);
            return;
          }

          final token = await (tokenProvider ?? TokenService.getToken)();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final authorization = error.requestOptions.headers['Authorization'];
          final currentToken =
              error.response?.statusCode == 401 && authorization != null
              ? await (tokenProvider ?? TokenService.getToken)()
              : null;
          if (error.response?.statusCode == 401 &&
              currentToken != null &&
              currentToken.isNotEmpty &&
              authorization == 'Bearer $currentToken') {
            await (tokenRemover ?? TokenService.removeToken)();
            onUnauthorized?.call();
          }

          final requestOptions = error.requestOptions;
          final retryCount = requestOptions.extra['retries'] is int
              ? requestOptions.extra['retries'] as int
              : 0;
          final isTransientFailure =
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.connectionError;
          final isSafeMethod = const {
            'GET',
            'HEAD',
            'OPTIONS',
          }.contains(requestOptions.method.toUpperCase());

          if (isTransientFailure &&
              isSafeMethod &&
              retryCount < 3 &&
              requestOptions.cancelToken?.isCancelled != true) {
            requestOptions.extra['retries'] = retryCount + 1;
            await Future<void>.delayed(Duration(seconds: 1 << retryCount));

            if (requestOptions.cancelToken?.isCancelled == true) {
              handler.next(requestOptions.cancelToken!.cancelError ?? error);
              return;
            }

            try {
              final response = await client.fetch<dynamic>(requestOptions);
              handler.resolve(response);
              return;
            } on DioException catch (retryError) {
              error = retryError;
            }
          }

          handler.next(error);
        },
      ),
    );

    return client;
  }
}
