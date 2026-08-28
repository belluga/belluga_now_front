import 'package:belluga_now/presentation/tenant_admin/shared/models/tenant_admin_group_label_mutation_state.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminGroupLabelActionButton extends StatelessWidget {
  const TenantAdminGroupLabelActionButton({
    super.key,
    required this.stateStreamValue,
    required this.onPressed,
  });

  final StreamValue<TenantAdminGroupLabelMutationState> stateStreamValue;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) => StreamValueBuilder(
    streamValue: stateStreamValue,
    builder: (context, state) => IconButton(
      tooltip: state.hasError ? state.errorText : 'Salvar nome da aba',
      onPressed: state.isLoading ? null : () => onPressed(),
      icon: state.isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(state.hasError ? Icons.error_outline : Icons.check),
    ),
  );
}
