class FormApiFailure implements Exception {
  FormApiFailure({
    required this.statusCode,
    required this.message,
    this.errorCode,
    List<String> hints = const <String>[],
    this.requestId,
    this.retryAfterSeconds,
    this.correlationId,
    this.cfRayId,
  }) : hints = List<String>.unmodifiable(
          hints.map((entry) => entry.trim()).where((entry) => entry.isNotEmpty),
        );

  final int statusCode;
  final String message;
  final String? errorCode;
  final List<String> hints;
  final String? requestId;
  final int? retryAfterSeconds;
  final String? correlationId;
  final String? cfRayId;

  @override
  String toString() {
    final segments = <String>[
      'status=$statusCode',
      'message=$message',
    ];
    if (errorCode != null) {
      segments.add('code=$errorCode');
    }
    if (retryAfterSeconds != null) {
      segments.add('retryAfterSeconds=$retryAfterSeconds');
    }
    if (correlationId != null) {
      segments.add('correlationId=$correlationId');
    }
    if (cfRayId != null) {
      segments.add('cfRayId=$cfRayId');
    }
    if (requestId != null) {
      segments.add('requestId=$requestId');
    }
    if (hints.isNotEmpty) {
      segments.add('hints=${hints.join('|')}');
    }
    return 'FormApiFailure(${segments.join(', ')})';
  }
}
