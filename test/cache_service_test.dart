import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/services/cache_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CacheService.setUserId(null);
    await CacheService.initialize();
  });

  test('keeps cached responses isolated by authenticated user', () async {
    CacheService.setUserId(41);
    await CacheService.save('dashboard_cache', const {'balance': 250});

    CacheService.setUserId(42);
    expect(await CacheService.get('dashboard_cache'), isNull);

    CacheService.setUserId(41);
    expect(
      await CacheService.get('dashboard_cache'),
      {'balance': 250},
    );
  });

  test('removes corrupted entries without clearing unrelated preferences', () async {
    final preferences = await SharedPreferences.getInstance();
    CacheService.setUserId(41);
    await preferences.setString('fintrack_cache_41_corrupt', '{');
    await preferences.setString('user_currency_code', 'EUR');

    expect(await CacheService.get('corrupt'), isNull);
    expect(
      preferences.containsKey('fintrack_cache_41_corrupt'),
      isFalse,
    );

    await CacheService.clearAll();

    expect(preferences.getString('user_currency_code'), 'EUR');
  });
}
