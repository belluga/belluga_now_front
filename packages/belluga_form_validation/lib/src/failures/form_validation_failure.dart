class FormValidationFailure implements Exception {
  FormValidationFailure({
    required this.statusCode,
    required this.message,
    required Map<String, List<String>> fieldErrors,
    this.errorCode,
    List<String> hints = const <String>[],
    this.requestId,
  })  : fieldErrors = _freeze(fieldErrors),
        hints = List<String>.unmodifiable(
          hints.where((entry) => entry.trim().isNotEmpty),
        );

  final int statusCode;
  final String message;
  final String? errorCode;
  final List<String> hints;
  final String? requestId;
  final Map<String, List<String>> fieldErrors;

  @override
  String toString() {
    final segments = <String>[
      'statusCode: $statusCode',
      'message: $message',
    ];
    if (errorCode != null && errorCode!.trim().isNotEmpty) {
      segments.add('errorCode: $errorCode');
    }
    if (requestId != null && requestId!.trim().isNotEmpty) {
      segments.add('requestId: $requestId');
    }
    if (hints.isNotEmpty) {
      segments.add('hints: ${hints.join('|')}');
    }
    if (fieldErrors.isNotEmpty) {
      final renderedFieldErrors = fieldErrors.entries
          .map((entry) => '${entry.key}: ${entry.value.join('|')}')
          .join('; ');
      segments.add('fieldErrors: $renderedFieldErrors');
    }
    return 'FormValidationFailure(${segments.join(', ')})';
  }

  static Map<String, List<String>> _freeze(
    Map<String, List<String>> source,
  ) {
    final result = <String, List<String>>{};
    for (final entry in source.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) {
        continue;
      }
      final messages = entry.value
          .map((message) => message.trim())
          .where((message) => message.isNotEmpty)
          .toList(growable: false);
      if (messages.isEmpty) {
        continue;
      }
      result[key] = List<String>.unmodifiable(messages);
    }
    return Map<String, List<String>>.unmodifiable(result);
  }
}
