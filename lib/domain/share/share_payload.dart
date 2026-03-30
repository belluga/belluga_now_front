import 'package:belluga_now/domain/share/value_objects/share_required_text_value.dart';

class SharePayload {
  SharePayload({
    required this.messageValue,
    required this.subjectValue,
  });

  final ShareRequiredTextValue messageValue;
  final ShareRequiredTextValue subjectValue;

  String get message => messageValue.value;
  String get subject => subjectValue.value;
}
