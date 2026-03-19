import 'package:stream_value/core/stream_value.dart';

import '../config/form_validation_config.dart';
import '../failures/form_validation_failure.dart';
import '../state/form_validation_state.dart';

class FormValidationControllerAdapter {
  FormValidationControllerAdapter({
    required this.config,
  }) : stateStreamValue = StreamValue<FormValidationState>(
          defaultValue: const FormValidationState.empty(),
        );

  final FormValidationConfig config;
  final StreamValue<FormValidationState> stateStreamValue;

  FormValidationState get state => stateStreamValue.value;

  bool get hasErrors => state.hasErrors;

  String? errorForField(String fieldId) => state.errorForField(fieldId);

  List<String> errorsForGroup(String groupId) => state.errorsForGroup(groupId);

  List<String> errorsForGlobal([String targetId = 'global']) =>
      state.errorsForGlobal(targetId);

  void applyFailure(FormValidationFailure failure) {
    stateStreamValue.addValue(config.resolveFailure(failure));
  }

  void replaceWithResolved({
    Map<String, List<String>> fieldErrors = const <String, List<String>>{},
    Map<String, List<String>> groupErrors = const <String, List<String>>{},
    Map<String, List<String>> globalErrors = const <String, List<String>>{},
  }) {
    stateStreamValue.addValue(
      config.buildResolvedState(
        fieldErrors: fieldErrors,
        groupErrors: groupErrors,
        globalErrors: globalErrors,
      ),
    );
  }

  void clearField(String fieldId) {
    _replaceWithout(
      fieldId: fieldId,
    );
  }

  void clearGroup(String groupId) {
    _replaceWithout(
      groupId: groupId,
    );
  }

  void clearGlobal([String targetId = 'global']) {
    _replaceWithout(
      globalId: targetId,
    );
  }

  void clearAll() {
    stateStreamValue.addValue(const FormValidationState.empty());
  }

  void dispose() {
    stateStreamValue.dispose();
  }

  void _replaceWithout({
    String? fieldId,
    String? groupId,
    String? globalId,
  }) {
    final nextFieldErrors = Map<String, List<String>>.from(state.fieldErrors);
    final nextGroupErrors = Map<String, List<String>>.from(state.groupErrors);
    final nextGlobalErrors = Map<String, List<String>>.from(state.globalErrors);
    if (fieldId != null) {
      nextFieldErrors.remove(fieldId);
    }
    if (groupId != null) {
      nextGroupErrors.remove(groupId);
    }
    if (globalId != null) {
      nextGlobalErrors.remove(globalId);
    }
    replaceWithResolved(
      fieldErrors: nextFieldErrors,
      groupErrors: nextGroupErrors,
      globalErrors: nextGlobalErrors,
    );
  }
}
