import 'dart:async';

typedef WaitForBootstrapEventValue<T> = Future<T> Function();

final class WebBootstrapHandshake<T> {
  const WebBootstrapHandshake({
    required this.initialValue,
    required this.initialErrorMessage,
    required this.timeout,
    required this.waitForEventValue,
  });

  final T? initialValue;
  final String? initialErrorMessage;
  final Duration timeout;
  final WaitForBootstrapEventValue<T> waitForEventValue;

  Future<T> resolve() async {
    final initialValue = this.initialValue;
    if (initialValue != null) {
      return initialValue;
    }

    final initialErrorMessage = this.initialErrorMessage?.trim();
    if (initialErrorMessage != null && initialErrorMessage.isNotEmpty) {
      throw Exception(initialErrorMessage);
    }

    try {
      return await waitForEventValue().timeout(timeout);
    } on TimeoutException {
      throw TimeoutException(
        'Web branding bootstrap did not resolve in time.',
        timeout,
      );
    }
  }
}
