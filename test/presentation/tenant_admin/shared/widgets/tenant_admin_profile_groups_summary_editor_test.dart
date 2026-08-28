import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/models/tenant_admin_group_label_mutation_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_profile_groups_summary_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  testWidgets('delegates inline label edit, draft, save, and field error', (
    tester,
  ) async {
    final state = StreamValue<TenantAdminGroupLabelMutationState>(
      defaultValue: const TenantAdminGroupLabelMutationState(draft: 'Artists'),
    );
    var begins = 0;
    var changed = '';
    var saves = 0;
    final group = TenantAdminNestedProfileGroup(
      idValue: TenantAdminNestedProfileGroupTextValue('artists'),
      labelValue: TenantAdminNestedProfileGroupTextValue('Artists'),
      orderValue: TenantAdminNestedProfileGroupOrderValue(0),
      memberCountValue: TenantAdminCountValue(0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantAdminProfileGroupsSummaryEditor(
            keyPrefix: 'test',
            groups: <TenantAdminNestedProfileGroup>[group],
            addButtonKey: const Key('add'),
            onAddGroup: () async {},
            groupLabelState: (_) => state,
            onBeginGroupLabelEdit: (_) {
              begins += 1;
              state.addValue(
                const TenantAdminGroupLabelMutationState(
                  draft: 'Artists',
                  isEditing: true,
                ),
              );
            },
            onChangeGroupLabelDraft: (_, label) {
              changed = label;
              state.addValue(
                TenantAdminGroupLabelMutationState(
                  draft: label,
                  isEditing: true,
                ),
              );
            },
            onSaveGroupLabel: (_) async {
              saves += 1;
              state.addValue(
                const TenantAdminGroupLabelMutationState(draft: 'Server label'),
              );
            },
            onMoveGroup: (_, _) {},
            onRemoveGroup: (_) async {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('testProfileGroupLabel_artists')));
    await tester.pump();
    expect(begins, 1);
    final input = find.byType(TextFormField);
    expect(input, findsOneWidget);
    await tester.enterText(input, 'Draft label');
    await tester.pump();
    expect(changed, 'Draft label');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    expect(saves, 1);
    expect(find.byType(TextFormField), findsNothing);

    state.addValue(
      const TenantAdminGroupLabelMutationState(
        draft: 'Draft label',
        isEditing: true,
        errorText: 'Invalid label',
      ),
    );
    await tester.pump();
    expect(find.text('Invalid label'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    state.dispose();
  });

  testWidgets(
    'blur saves once, loading disables input, and failure can reedit',
    (tester) async {
      final state = StreamValue<TenantAdminGroupLabelMutationState>(
        defaultValue: const TenantAdminGroupLabelMutationState(
          draft: 'Artists',
          isEditing: true,
        ),
      );
      var saves = 0;
      final group = TenantAdminNestedProfileGroup(
        idValue: TenantAdminNestedProfileGroupTextValue('artists'),
        labelValue: TenantAdminNestedProfileGroupTextValue('Artists'),
        orderValue: TenantAdminNestedProfileGroupOrderValue(0),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TenantAdminProfileGroupsSummaryEditor(
                  keyPrefix: 'test',
                  groups: [group],
                  addButtonKey: const Key('add'),
                  onAddGroup: () async {},
                  groupLabelState: (_) => state,
                  onBeginGroupLabelEdit: (_) {},
                  onChangeGroupLabelDraft: (_, label) => state.addValue(
                    TenantAdminGroupLabelMutationState(
                      draft: label,
                      isEditing: true,
                    ),
                  ),
                  onSaveGroupLabel: (_) async => saves += 1,
                  onMoveGroup: (_, _) {},
                  onRemoveGroup: (_) async {},
                ),
                const Text('outside'),
              ],
            ),
          ),
        ),
      );
      final input = find.byKey(const Key('testProfileGroupLabelInput_artists'));
      await tester.enterText(input, 'Draft');
      await tester.tap(find.text('outside'));
      await tester.pump();
      expect(saves, 1);

      state.addValue(
        const TenantAdminGroupLabelMutationState(
          draft: 'Draft',
          isEditing: true,
          isLoading: true,
        ),
      );
      await tester.pump();
      expect(tester.widget<TextFormField>(input).enabled, isFalse);
      state.addValue(
        const TenantAdminGroupLabelMutationState(
          draft: 'Draft',
          isEditing: true,
          errorText: 'Invalid label',
        ),
      );
      await tester.pump();
      expect(find.text('Invalid label'), findsOneWidget);
      await tester.enterText(input, 'Recovered');
      await tester.pump();
      expect(tester.widget<TextFormField>(input).enabled, isTrue);
      state.dispose();
    },
  );
}
