import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/api/api_client.dart';
import 'package:frontend/repositories/auth_repository.dart';

class _FailingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

class _UnauthorizedAdapter implements HttpClientAdapter {
  _UnauthorizedAdapter({this.beforeResponse});

  final void Function()? beforeResponse;

  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    beforeResponse?.call();
    return ResponseBody.fromString(
      '{"success":false,"message":"Unauthorized","data":{}}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ProfileAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      '{"success":true,"message":"Profile loaded","data":{"user":{"id":41,"name":"Test User","email":"test@example.test"}}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RetryingAdapter implements HttpClientAdapter {
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    if (requestCount == 1) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'sends the stored bearer token and does not retry transaction writes',
    () async {
      final adapter = _FailingAdapter();
      final client = ApiClient.createDio(
        tokenProvider: () async => 'test-token',
      )..httpClientAdapter = adapter;

      await expectLater(
        client.post<void>('transactions', data: const {'amount': 12.5}),
        throwsA(isA<DioException>()),
      );

      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer test-token',
      );
      expect(
        adapter.requests.single.headers['Authorization'],
        isNot('******'),
      );
      client.close(force: true);
    },
  );

  test(
    'public login and registration omit authorization and preserve session',
    () async {
      final adapter = _UnauthorizedAdapter();
      var storedToken = 'test-token';
      var removalCount = 0;
      var unauthorizedCount = 0;
      final previousHandler = ApiClient.onUnauthorized;
      ApiClient.onUnauthorized = () => unauthorizedCount++;
      final client = ApiClient.createDio(
        tokenProvider: () async => storedToken,
        tokenRemover: () async {
          removalCount++;
          storedToken = '';
        },
      )..httpClientAdapter = adapter;
      final repository = AuthRepository(dio: client);

      try {
        await expectLater(
          repository.login(
            email: 'synthetic@example.test',
            password: 'test-password',
          ),
          throwsA(isA<DioException>()),
        );
        await expectLater(
          repository.register(
            name: 'Test User',
            email: 'synthetic@example.test',
            password: 'test-password',
          ),
          throwsA(isA<DioException>()),
        );

        expect(adapter.requests, hasLength(2));
        expect(
          adapter.requests.every(
            (request) => request.headers['Authorization'] == null,
          ),
          isTrue,
        );
        expect(storedToken, 'test-token');
        expect(removalCount, 0);
        expect(unauthorizedCount, 0);

        await expectLater(
          client.get<void>('protected'),
          throwsA(isA<DioException>()),
        );

        expect(adapter.requests, hasLength(3));
        expect(
          adapter.requests.last.headers['Authorization'],
          'Bearer test-token',
        );
        expect(storedToken, isEmpty);
        expect(removalCount, 1);
        expect(unauthorizedCount, 1);
      } finally {
        ApiClient.onUnauthorized = previousHandler;
        client.close(force: true);
      }
    },
  );

  test('parses the profile response without a replacement token', () async {
    final adapter = _ProfileAdapter();
    final client = ApiClient.createDio(
      tokenProvider: () async => 'stored-test-token',
    )..httpClientAdapter = adapter;
    final repository = AuthRepository(dio: client);

    final response = await repository.getProfile();

    expect(response.data.user.id, 41);
    expect(response.data.user.name, 'Test User');
    expect(
      adapter.request?.headers['Authorization'],
      'Bearer stored-test-token',
    );
    client.close(force: true);
  });

  test('a 401 for an old token preserves a newer session', () async {
    var storedToken = 'old-test-token';
    var removalCount = 0;
    var unauthorizedCount = 0;
    final previousHandler = ApiClient.onUnauthorized;
    ApiClient.onUnauthorized = () => unauthorizedCount++;
    final adapter = _UnauthorizedAdapter(
      beforeResponse: () => storedToken = 'new-test-token',
    );
    final client = ApiClient.createDio(
      tokenProvider: () async => storedToken,
      tokenRemover: () async {
        removalCount++;
        storedToken = '';
      },
    )..httpClientAdapter = adapter;

    try {
      await expectLater(
        client.get<void>('protected'),
        throwsA(isA<DioException>()),
      );

      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer old-test-token',
      );
      expect(storedToken, 'new-test-token');
      expect(removalCount, 0);
      expect(unauthorizedCount, 0);
    } finally {
      ApiClient.onUnauthorized = previousHandler;
      client.close(force: true);
    }
  });

  test(
    'debug HTTP logging does not expose credentials or private payloads',
    () async {
      final adapter = _FailingAdapter();
      final previousDebugPrint = debugPrint;
      final debugMessages = <String>[];
      debugPrint = (message, {wrapWidth}) {
        if (message != null) debugMessages.add(message);
      };
      final client = ApiClient.createDio(
        tokenProvider: () async => 'jwt-test-credential',
      )..httpClientAdapter = adapter;
      final repository = AuthRepository(dio: client);

      try {
        await expectLater(
          repository.login(
            email: 'synthetic@example.test',
            password: 'private-test-password',
          ),
          throwsA(isA<DioException>()),
        );
        await expectLater(
          client.post<void>(
            'transactions?search=private-test-query',
            data: const {'amount': 91.25, 'note': 'private-financial-payload'},
          ),
          throwsA(isA<DioException>()),
        );
        await expectLater(
          client.post<void>(
            'transactions/import-sms',
            data: const [
              {
                'message': 'private-sms-content',
                'sms_hash': 'private-sms-hash',
              },
            ],
          ),
          throwsA(isA<DioException>()),
        );

        final output = debugMessages.join('\n');
        for (final privateValue in [
          'jwt-test-credential',
          'private-test-password',
          'private-test-query',
          'private-financial-payload',
          'private-sms-content',
          'private-sms-hash',
        ]) {
          expect(output, isNot(contains(privateValue)));
        }
      } finally {
        debugPrint = previousDebugPrint;
        client.close(force: true);
      }
    },
  );

  test('retries transient safe-method requests', () async {
    final adapter = _RetryingAdapter();
    final client = ApiClient.createDio(tokenProvider: () async => null)
      ..httpClientAdapter = adapter;

    await client.get<void>('health');

    expect(adapter.requestCount, 2);
    client.close(force: true);
  });
}
