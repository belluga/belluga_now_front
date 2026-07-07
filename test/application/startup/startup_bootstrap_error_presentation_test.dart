import 'package:belluga_now/application/startup/startup_bootstrap_error_presentation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'connection errors resolve to prominent no-internet copy without raw details',
    () {
      final presentation = StartupBootstrapErrorPresentation.fromError(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/api/v1/environment'),
          reason: "Failed host lookup: 'belluga-offline.invalid'",
        ),
      );

      expect(presentation.kind, StartupBootstrapErrorKind.connectivity);
      expect(presentation.isProminent, isTrue);
      expect(presentation.shouldReportToSentry, isFalse);
      expect(presentation.title, 'Sem conexão com a internet');

      final visibleCopy = '${presentation.title}\n${presentation.message}';
      expect(visibleCopy, isNot(contains('Failed host lookup')));
      expect(visibleCopy, isNot(contains('belluga-offline.invalid')));
    },
  );

  test('wrapped host lookup failures still resolve to no-internet copy', () {
    final presentation = StartupBootstrapErrorPresentation.fromError(
      Exception(
        'Failed to load environment data [status=unknown] '
        '(https://belluga-offline.invalid/api/v1/environment): '
        "Failed host lookup: 'belluga-offline.invalid'",
      ),
    );

    expect(presentation.kind, StartupBootstrapErrorKind.connectivity);
    expect(presentation.isProminent, isTrue);

    final visibleCopy = '${presentation.title}\n${presentation.message}';
    expect(visibleCopy, isNot(contains('Failed to load environment data')));
    expect(visibleCopy, isNot(contains('belluga-offline.invalid')));
  });

  test('internal failures resolve to generic copy and Sentry reporting', () {
    final presentation = StartupBootstrapErrorPresentation.fromError(
      StateError('InitializationModule has already registered inside GetIt'),
    );

    expect(presentation.kind, StartupBootstrapErrorKind.internal);
    expect(presentation.isProminent, isFalse);
    expect(presentation.shouldReportToSentry, isTrue);
    expect(presentation.title, 'Não foi possível iniciar o app');

    final visibleCopy = '${presentation.title}\n${presentation.message}';
    expect(visibleCopy, isNot(contains('InitializationModule')));
    expect(visibleCopy, isNot(contains('GetIt')));
    expect(visibleCopy, isNot(contains('already registered')));
  });

  test('backend HTTP failures do not masquerade as no-internet', () {
    final presentation = StartupBootstrapErrorPresentation.fromError(
      DioException.badResponse(
        requestOptions: RequestOptions(path: '/api/v1/environment'),
        response: Response<void>(
          requestOptions: RequestOptions(path: '/api/v1/environment'),
          statusCode: 500,
        ),
        statusCode: 500,
      ),
    );

    expect(presentation.kind, StartupBootstrapErrorKind.internal);
    expect(presentation.shouldReportToSentry, isTrue);
  });
}
