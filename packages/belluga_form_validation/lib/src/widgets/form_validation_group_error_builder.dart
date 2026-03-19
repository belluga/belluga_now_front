import 'package:flutter/widgets.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

import '../state/form_validation_state.dart';

class FormValidationGroupErrorBuilder extends StatelessWidget {
  const FormValidationGroupErrorBuilder({
    super.key,
    required this.validationStreamValue,
    required this.groupId,
    required this.builder,
  });

  final StreamValue<FormValidationState> validationStreamValue;
  final String groupId;
  final Widget Function(BuildContext context, List<String> messages) builder;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<FormValidationState>(
      streamValue: validationStreamValue,
      builder: (context, state) {
        return builder(context, state.errorsForGroup(groupId));
      },
    );
  }
}
