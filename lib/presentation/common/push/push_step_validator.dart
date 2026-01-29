import 'package:push_handler/push_handler.dart';

class PushStepValidator {
  String? validate(StepData step, String? value) {
    final validatorSpec = step.config?.validator;
    if (validatorSpec == null) return null;
    final name = _resolveName(validatorSpec);
    switch (name) {
      case 'required_text':
        return _requiredText(value);
      default:
        return null;
    }
  }

  String? _resolveName(dynamic validatorSpec) {
    if (validatorSpec is String) {
      return validatorSpec;
    }
    if (validatorSpec is Map<String, dynamic>) {
      return validatorSpec['name']?.toString();
    }
    return null;
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }
}
