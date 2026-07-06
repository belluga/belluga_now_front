import 'dart:async';

import 'package:dio/dio.dart';

enum StartupBootstrapErrorKind { connectivity, internal, retrying }

final class StartupBootstrapErrorPresentation {
  const StartupBootstrapErrorPresentation._({
    required this.kind,
    required this.title,
    required this.message,
    required this.isProminent,
    required this.shouldReportToSentry,
  });

  static const retrying = StartupBootstrapErrorPresentation._(
    kind: StartupBootstrapErrorKind.retrying,
    title: 'Conectando...',
    message: 'Estamos tentando iniciar o app novamente.',
    isProminent: false,
    shouldReportToSentry: false,
  );

  static const _connectivity = StartupBootstrapErrorPresentation._(
    kind: StartupBootstrapErrorKind.connectivity,
    title: 'Sem conexão com a internet',
    message: 'Verifique o Wi-Fi ou os dados móveis e tente novamente.',
    isProminent: true,
    shouldReportToSentry: false,
  );

  static const _internal = StartupBootstrapErrorPresentation._(
    kind: StartupBootstrapErrorKind.internal,
    title: 'Não foi possível iniciar o app',
    message:
        'Tente novamente em instantes. '
        'Se o problema continuar, nossa equipe será notificada '
        'automaticamente.',
    isProminent: false,
    shouldReportToSentry: true,
  );

  final StartupBootstrapErrorKind kind;
  final String title;
  final String message;
  final bool isProminent;
  final bool shouldReportToSentry;

  static StartupBootstrapErrorPresentation fromError(Object error) {
    if (_isConnectivityFailure(error)) {
      return _connectivity;
    }

    return _internal;
  }

  static bool _isConnectivityFailure(Object error) {
    if (error is TimeoutException) {
      return _hasConnectivitySignature(error.message);
    }

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError) {
        return true;
      }

      return _hasConnectivitySignature(error.message) ||
          _hasConnectivitySignature(error.error) ||
          _hasConnectivitySignature(error);
    }

    return _hasConnectivitySignature(error);
  }

  static bool _hasConnectivitySignature(Object? value) {
    if (value == null) {
      return false;
    }

    final normalized = value.toString().toLowerCase();
    return _connectivityFragments.any(normalized.contains);
  }

  static const List<String> _connectivityFragments = <String>[
    'failed host lookup',
    'host lookup failed',
    'socketexception',
    'network is unreachable',
    'no address associated with hostname',
    'no route to host',
    'temporary failure in name resolution',
    'internet address lookup failed',
    'connection errored',
    'errno = 7',
    'errno = 101',
  ];
}
