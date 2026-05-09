import 'dart:async';

typedef WaitForBootstrapEventValue<T> = Future<T> Function();

final class WebBootstrapHandshake<T> {
  const WebBootstrapHandshake({
    required this.initialValue,
    required this.initialErrorMessage,
    required this.hasInitialRawPayload,
    required this.timeout,
    required this.waitForEventValue,
    this.malformedInitialPayloadMessage =
        'Branding payload malformed during bootstrap pre-resolution.',
  });

  final T? initialValue;
  final String? initialErrorMessage;
  final bool hasInitialRawPayload;
  final Duration timeout;
  final WaitForBootstrapEventValue<T> waitForEventValue;
  final String malformedInitialPayloadMessage;

  Future<T> resolve() async {
    final initialValue = this.initialValue;
    if (initialValue != null) {
      return initialValue;
    }

    final initialErrorMessage = this.initialErrorMessage?.trim();
    if (initialErrorMessage != null && initialErrorMessage.isNotEmpty) {
      throw Exception(initialErrorMessage);
    }

    if (hasInitialRawPayload) {
      throw Exception(malformedInitialPayloadMessage);
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
