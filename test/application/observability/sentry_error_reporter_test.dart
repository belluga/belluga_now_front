import 'package:belluga_now/application/observability/sentry_error_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  tearDown(SentryErrorReporter.resetForTesting);

  test('captureRecoverable tags classification and origin', () async {
    final captures = <_SentryCapture>[];
    final stackTrace = StackTrace.current;
    final error = StateError('recoverable');

    SentryErrorReporter.overrideCaptureExceptionForTesting(
      (throwable, {stackTrace, hint, message, withScope}) async {
        captures.add(
          _SentryCapture(
            throwable: throwable,
            stackTrace: stackTrace,
            withScope: withScope,
          ),
        );
        return SentryId.empty();
      },
    );

    await SentryErrorReporter.captureRecoverable(
      origin: 'test.origin',
      error: error,
      stackTrace: stackTrace,
    );

    expect(captures, hasLength(1));
    expect(captures.single.throwable, same(error));
    expect(captures.single.stackTrace, same(stackTrace));

    final scope = Scope(SentryOptions());
    await captures.single.withScope?.call(scope);
    expect(scope.tags['belluga.error_classification'], 'recoverable_reported');
    expect(scope.tags['belluga.error_origin'], 'test.origin');
  });
}

class _SentryCapture {
  _SentryCapture({
    required this.throwable,
    required this.stackTrace,
    required this.withScope,
  });

  final dynamic throwable;
  final dynamic stackTrace;
  final ScopeCallback? withScope;
}
