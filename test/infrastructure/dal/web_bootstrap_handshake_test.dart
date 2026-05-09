import 'dart:async';

import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/web_bootstrap_handshake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns the initial resolved value without waiting for event bootstrap',
      () async {
    var waitCalled = false;
    final handshake = WebBootstrapHandshake<String>(
      initialValue: 'ready',
      initialErrorMessage: null,
      hasInitialRawPayload: true,
      timeout: const Duration(milliseconds: 20),
      waitForEventValue: () async {
        waitCalled = true;
        return 'late';
      },
    );

    final value = await handshake.resolve();

    expect(value, 'ready');
    expect(waitCalled, isFalse);
  });

  test('waits for delayed success when no initial bootstrap value exists',
      () async {
    final handshake = WebBootstrapHandshake<String>(
      initialValue: null,
      initialErrorMessage: null,
      hasInitialRawPayload: false,
      timeout: const Duration(milliseconds: 40),
      waitForEventValue: () async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return 'delayed-ready';
      },
    );

    final value = await handshake.resolve();

    expect(value, 'delayed-ready');
  });

  test('fails immediately when the host page already knows bootstrap failed',
      () async {
    var waitCalled = false;
    final handshake = WebBootstrapHandshake<String>(
      initialValue: null,
      initialErrorMessage: 'Environment bootstrap failed [503]',
      hasInitialRawPayload: false,
      timeout: const Duration(milliseconds: 20),
      waitForEventValue: () async {
        waitCalled = true;
        return 'unexpected';
      },
    );

    await expectLater(
      handshake.resolve(),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Environment bootstrap failed [503]'),
        ),
      ),
    );
    expect(waitCalled, isFalse);
  });

  test(
      'fails immediately when a raw bootstrap payload exists but cannot decode',
      () async {
    var waitCalled = false;
    final handshake = WebBootstrapHandshake<String>(
      initialValue: null,
      initialErrorMessage: null,
      hasInitialRawPayload: true,
      timeout: const Duration(milliseconds: 20),
      waitForEventValue: () async {
        waitCalled = true;
        return 'unexpected';
      },
    );

    await expectLater(
      handshake.resolve(),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains(
              'Branding payload malformed during bootstrap pre-resolution.'),
        ),
      ),
    );
    expect(waitCalled, isFalse);
  });

  test('times out when bootstrap never resolves', () async {
    final handshake = WebBootstrapHandshake<String>(
      initialValue: null,
      initialErrorMessage: null,
      hasInitialRawPayload: false,
      timeout: const Duration(milliseconds: 5),
      waitForEventValue: () => Completer<String>().future,
    );

    await expectLater(
      handshake.resolve(),
      throwsA(
        isA<TimeoutException>().having(
          (error) => error.message,
          'message',
          contains('Web branding bootstrap did not resolve in time.'),
        ),
      ),
    );
  });
}
