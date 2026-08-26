import 'package:belluga_now/presentation/tenant_admin/shared/models/tenant_admin_group_label_mutation_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_group_label_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  testWidgets('renders loading and error states from StreamValue', (
    tester,
  ) async {
    final state = StreamValue<TenantAdminGroupLabelMutationState>(
      defaultValue: const TenantAdminGroupLabelMutationState(
        draft: 'Partners',
        isEditing: true,
      ),
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantAdminGroupLabelActionButton(
            stateStreamValue: state,
            onPressed: () async {},
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
    state.addValue(
      const TenantAdminGroupLabelMutationState(
        draft: 'Partners',
        isEditing: true,
        isLoading: true,
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    state.addValue(
      const TenantAdminGroupLabelMutationState(
        draft: 'Partners',
        isEditing: true,
        errorText: 'Required',
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
