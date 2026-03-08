import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';

import '../state/form_validation_state.dart';
import 'form_validation_group_error_builder.dart';
import 'form_validation_message_panel.dart';

class FormValidationGroupError extends StatelessWidget {
  const FormValidationGroupError({
    super.key,
    required this.validationStreamValue,
    required this.groupId,
    this.summarySuffixBuilder,
    this.expandLabel = 'Show all',
    this.collapseLabel = 'Hide',
  });

  final StreamValue<FormValidationState> validationStreamValue;
  final String groupId;
  final String Function(int remainingCount)? summarySuffixBuilder;
  final String expandLabel;
  final String collapseLabel;

  @override
  Widget build(BuildContext context) {
    return FormValidationGroupErrorBuilder(
      validationStreamValue: validationStreamValue,
      groupId: groupId,
      builder: (context, messages) {
        if (messages.isEmpty) {
          return const SizedBox.shrink();
        }
        return FormValidationMessagePanel(
          messages: messages,
          summarySuffixBuilder: summarySuffixBuilder,
          expandLabel: expandLabel,
          collapseLabel: collapseLabel,
        );
      },
    );
  }
}
