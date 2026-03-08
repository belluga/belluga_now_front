class FormValidationState {
  const FormValidationState({
    required this.fieldErrors,
    required this.groupErrors,
    required this.globalErrors,
    required this.firstInvalidTargetId,
  });

  const FormValidationState.empty()
      : fieldErrors = const <String, List<String>>{},
        groupErrors = const <String, List<String>>{},
        globalErrors = const <String, List<String>>{},
        firstInvalidTargetId = null;

  final Map<String, List<String>> fieldErrors;
  final Map<String, List<String>> groupErrors;
  final Map<String, List<String>> globalErrors;
  final String? firstInvalidTargetId;

  bool get hasErrors =>
      fieldErrors.isNotEmpty ||
      groupErrors.isNotEmpty ||
      globalErrors.isNotEmpty;

  String? errorForField(String fieldId) {
    final messages = fieldErrors[fieldId];
    if (messages == null || messages.isEmpty) {
      return null;
    }
    return messages.first;
  }

  List<String> errorsForGroup(String groupId) {
    return groupErrors[groupId] ?? const <String>[];
  }

  List<String> errorsForGlobal([String targetId = 'global']) {
    return globalErrors[targetId] ?? const <String>[];
  }
}
