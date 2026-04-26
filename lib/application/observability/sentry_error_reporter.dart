import 'package:sentry_flutter/sentry_flutter.dart';

typedef SentryExceptionCapture = Future<SentryId> Function(
  dynamic throwable, {
  dynamic stackTrace,
  Hint? hint,
  SentryMessage? message,
  ScopeCallback? withScope,
});

final class SentryErrorReporter {
  SentryErrorReporter._();

  static SentryExceptionCapture _captureException = Sentry.captureException;

  static Future<SentryId> captureRecoverable({
    required String origin,
    required Object error,
    StackTrace? stackTrace,
  }) {
    return _capture(
      classification: 'recoverable_reported',
      origin: origin,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static Future<SentryId> captureFatal({
    required String origin,
    required Object error,
    StackTrace? stackTrace,
  }) {
    return _capture(
      classification: 'fatal_reported',
      origin: origin,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static Future<SentryId> _capture({
    required String classification,
    required String origin,
    required Object error,
    StackTrace? stackTrace,
  }) {
    return _captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) async {
        await scope.setTag('belluga.error_classification', classification);
        await scope.setTag('belluga.error_origin', origin);
      },
    );
  }

  static void overrideCaptureExceptionForTesting(
    SentryExceptionCapture captureException,
  ) {
    _captureException = captureException;
  }

  static void resetForTesting() {
    _captureException = Sentry.captureException;
  }
}
