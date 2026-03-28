import 'package:belluga_now/domain/share/value_objects/share_required_text_value.dart';

class SharePayload {
  SharePayload({
    required Object message,
    required Object subject,
  })  : messageValue = _parseRequiredText(message),
        subjectValue = _parseRequiredText(subject);

  final ShareRequiredTextValue messageValue;
  final ShareRequiredTextValue subjectValue;

  String get message => messageValue.value;
  String get subject => subjectValue.value;

  static ShareRequiredTextValue _parseRequiredText(Object raw) {
    if (raw is ShareRequiredTextValue) {
      return raw;
    }
    final value = ShareRequiredTextValue();
    value.parse(raw.toString());
    return value;
  }
}
