import 'package:belluga_now/presentation/common/push/push_step_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_handler/push_handler.dart';

void main() {
  test('required_text returns error when empty and null when valid', () {
    final step = StepData.fromMap({
      'slug': 'about',
      'type': 'question',
      'title': 'About you',
      'body': '',
      'config': {
        'question_type': 'text',
        'validator': 'required_text',
      },
      'buttons': [],
    });

    final validator = PushStepValidator();

    expect(validator.validate(step, ''), isNotNull);
    expect(validator.validate(step, 'Hello'), isNull);
  });
}
