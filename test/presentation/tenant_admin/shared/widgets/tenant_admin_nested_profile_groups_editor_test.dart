import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_nested_profile_groups_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  testWidgets(
    'opens the canonical nested picker with legacy keys and live selection callbacks',
    (tester) async {
      final candidatesStreamValue =
          StreamValue<List<TenantAdminAccountProfile>>(
            defaultValue: [
              tenantAdminAccountProfileFromRaw(
                id: 'profile-1',
                accountId: 'account-1',
                profileType: 'venue',
                displayName: 'Venue Alpha',
              ),
              tenantAdminAccountProfileFromRaw(
                id: 'profile-2',
                accountId: 'account-2',
                profileType: 'artist',
                displayName: 'Artist Beta',
              ),
            ],
          );
      final searchLoadingStreamValue = StreamValue<bool>(defaultValue: false);
      final searchPageLoadingStreamValue =
          StreamValue<bool>(defaultValue: false);
      final searchHasMoreStreamValue = StreamValue<bool>(defaultValue: false);

      String? latestSearchQuery;
      String? latestProfileTypeFilter;
      ({String groupId, String profileId, bool selected})? lastSelection;

      addTearDown(() {
        candidatesStreamValue.dispose();
        searchLoadingStreamValue.dispose();
        searchPageLoadingStreamValue.dispose();
        searchHasMoreStreamValue.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            body: TenantAdminNestedProfileGroupsEditor(
              keyPrefix: 'test',
              groups: [_group('group-1', 'Grupo 1')],
              candidatesStreamValue: candidatesStreamValue,
              profileTypes: [
                _profileType('artist', 'Artist'),
                _profileType('venue', 'Venue'),
              ],
              addButtonKey: const Key('testAddNestedGroupButton'),
              onAddGroup: () {},
              onRenameGroup: (_, _) {},
              onMoveGroup: (_, _) {},
              onRemoveGroup: (_) {},
              onSelectionChanged: (groupId, profileId, selected) {
                lastSelection = (
                  groupId: groupId,
                  profileId: profileId,
                  selected: selected,
                );
              },
              onSearchChanged: (query) => latestSearchQuery = query,
              onProfileTypeChanged: (profileType) {
                latestProfileTypeFilter = profileType;
              },
              onLoadMore: () async {},
              searchLoadingStreamValue: searchLoadingStreamValue,
              searchPageLoadingStreamValue: searchPageLoadingStreamValue,
              searchHasMoreStreamValue: searchHasMoreStreamValue,
              emptySelectionText: 'Selecionar perfis',
              selectedCountLabel: 'perfil(is) selecionado(s)',
              searchLabelText: 'Buscar perfil',
              emptySearchText: 'Nenhum perfil encontrado.',
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const Key('testNestedAccountSelector_group-1')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('testNestedAccountSearch_group-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('testNestedAccountTypeFilter_group-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('testNestedAccountCandidate_group-1_profile-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('testNestedAccountCandidate_group-1_profile-2')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('testNestedAccountSearch_group-1')),
        'Artist',
      );
      await tester.pumpAndSettle();
      expect(latestSearchQuery, 'Artist');

      await tester.tap(
        find.byKey(const Key('testNestedAccountTypeFilter_group-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Artist').last);
      await tester.pumpAndSettle();
      expect(latestProfileTypeFilter, 'artist');

      await tester.tap(
        find.byKey(const Key('testNestedAccountCandidate_group-1_profile-2')),
      );
      await tester.pumpAndSettle();

      expect(
        lastSelection,
        (
          groupId: 'group-1',
          profileId: 'profile-2',
          selected: true,
        ),
      );

      final checkbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('testNestedAccountCandidate_group-1_profile-2')),
      );
      expect(checkbox.value, isTrue);
    },
  );
}

TenantAdminNestedProfileGroup _group(String id, String label) {
  return TenantAdminNestedProfileGroup(
    idValue: TenantAdminNestedProfileGroupTextValue(id),
    labelValue: TenantAdminNestedProfileGroupTextValue(label),
    orderValue: TenantAdminNestedProfileGroupOrderValue(0),
    accountProfileIdValues: const [],
  );
}

TenantAdminProfileTypeDefinition _profileType(String type, String label) {
  return tenantAdminProfileTypeDefinitionFromRaw(
    type: type,
    label: label,
    allowedTaxonomies: const [],
    capabilities: TenantAdminProfileTypeCapabilities(
      isFavoritable: TenantAdminFlagValue(true),
      isPoiEnabled: TenantAdminFlagValue(false),
      hasBio: TenantAdminFlagValue(false),
      hasContent: TenantAdminFlagValue(false),
      hasTaxonomies: TenantAdminFlagValue(false),
      hasAvatar: TenantAdminFlagValue(false),
      hasCover: TenantAdminFlagValue(false),
      hasEvents: TenantAdminFlagValue(false),
      hasNestedProfileGroups: TenantAdminFlagValue(true),
    ),
  );
}
