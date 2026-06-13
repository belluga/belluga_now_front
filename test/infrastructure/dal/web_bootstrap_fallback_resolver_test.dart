import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/web_bootstrap_fallback_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns bootstrap value when bootstrap succeeds', () async {
    var fallbackCalls = 0;
    final resolver = WebBootstrapFallbackResolver<String>(
      bootstrapResolver: () async => 'bootstrap',
      fallbackResolver: () async {
        fallbackCalls += 1;
        return 'fallback';
      },
    );

    final value = await resolver.resolve();

    expect(value, 'bootstrap');
    expect(fallbackCalls, 0);
  });

  test('falls back to direct fetch when bootstrap fails', () async {
    final resolver = WebBootstrapFallbackResolver<String>(
      bootstrapResolver: () async => throw Exception('bootstrap timeout'),
      fallbackResolver: () async => 'fallback',
    );

    final value = await resolver.resolve();

    expect(value, 'fallback');
  });

  test('surfaces combined failure when bootstrap and fallback both fail',
      () async {
    final resolver = WebBootstrapFallbackResolver<String>(
      bootstrapResolver: () async => throw Exception('bootstrap timeout'),
      fallbackResolver: () async => throw Exception('direct fetch failed'),
    );

    await expectLater(
      resolver.resolve(),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('bootstrap timeout'),
            contains('direct fetch failed'),
          ),
        ),
      ),
    );
  });
}
