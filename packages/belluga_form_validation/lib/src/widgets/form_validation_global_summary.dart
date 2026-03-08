import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';

import '../state/form_validation_state.dart';
import 'form_validation_global_errors_builder.dart';
import 'form_validation_message_panel.dart';

class FormValidationGlobalSummary extends StatelessWidget {
  const FormValidationGlobalSummary({
    super.key,
    required this.validationStreamValue,
    this.targetId = 'global',
    this.summarySuffixBuilder,
    this.expandLabel = 'Show all',
    this.collapseLabel = 'Hide',
  });

  final StreamValue<FormValidationState> validationStreamValue;
  final String targetId;
  final String Function(int remainingCount)? summarySuffixBuilder;
  final String expandLabel;
  final String collapseLabel;

  @override
  Widget build(BuildContext context) {
    return FormValidationGlobalErrorsBuilder(
      validationStreamValue: validationStreamValue,
      targetId: targetId,
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
