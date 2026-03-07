import 'package:flutter/widgets.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

import '../state/form_validation_state.dart';

class FormValidationFieldErrorBuilder extends StatelessWidget {
  const FormValidationFieldErrorBuilder({
    super.key,
    required this.validationStreamValue,
    required this.fieldId,
    required this.builder,
  });

  final StreamValue<FormValidationState> validationStreamValue;
  final String fieldId;
  final Widget Function(BuildContext context, String? errorText) builder;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<FormValidationState>(
      streamValue: validationStreamValue,
      builder: (context, state) {
        return builder(context, state.errorForField(fieldId));
      },
    );
  }
}
