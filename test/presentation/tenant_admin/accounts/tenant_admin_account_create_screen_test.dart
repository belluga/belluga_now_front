import 'dart:io';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class _FakeAccountsRepository implements TenantAdminAccountsRepositoryContract {
  @override
  Future<TenantAdminAccount> createAccount({
    required String name,
    required TenantAdminDocument document,
    String? organizationId,
  }) async {
    return TenantAdminAccount(
      id: 'acc-1',
      name: name,
      slug: 'acc-1',
      document: document,
      ownershipState: TenantAdminOwnershipState.tenantOwned,
      organizationId: organizationId,
    );
  }

  @override
  Future<void> deleteAccount(String accountSlug) async {}

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug) async {
    return TenantAdminAccount(
      id: 'acc-1',
      name: 'Conta',
      slug: accountSlug,
      document: const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async {
    return const [];
  }

  @override
  Future<void> forceDeleteAccount(String accountSlug) async {}

  @override
  Future<TenantAdminAccount> restoreAccount(String accountSlug) async {
    return TenantAdminAccount(
      id: 'acc-1',
      name: 'Conta',
      slug: accountSlug,
      document: const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    TenantAdminDocument? document,
  }) async {
    return TenantAdminAccount(
      id: 'acc-1',
      name: name ?? 'Conta',
      slug: accountSlug,
      document:
          document ?? const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }
}

class _FakeAccountProfilesRepository
    implements TenantAdminAccountProfilesRepositoryContract {
  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return const [
      TenantAdminProfileTypeDefinition(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: true,
          hasBio: false,
          hasTaxonomies: false,
          hasAvatar: false,
          hasCover: false,
          hasEvents: false,
        ),
      ),
    ];
  }

  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    return TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: accountId,
      profileType: profileType,
      displayName: displayName,
      location: location,
      taxonomyTerms: taxonomyTerms,
    );
  }

  @override
  Future<void> deleteAccountProfile(String accountProfileId) async {}

  @override
  Future<void> forceDeleteAccountProfile(String accountProfileId) async {}

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
      String accountProfileId) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  }) async {
    return const [];
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    return TenantAdminProfileTypeDefinition(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<void> deleteProfileType(String type) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
      String accountProfileId) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    return TenantAdminProfileTypeDefinition(
      type: type,
      label: label ?? 'Venue',
      allowedTaxonomies: allowedTaxonomies ?? const [],
      capabilities: capabilities ??
          const TenantAdminProfileTypeCapabilities(
            isFavoritable: true,
            isPoiEnabled: true,
            hasBio: false,
            hasTaxonomies: false,
            hasAvatar: false,
            hasCover: false,
            hasEvents: false,
          ),
    );
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required String accountProfileId,
    String? profileType,
    String? displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    return TenantAdminAccountProfile(
      id: accountProfileId,
      accountId: 'acc-1',
      profileType: profileType ?? 'venue',
      displayName: displayName ?? 'Perfil',
      location: location,
      taxonomyTerms: taxonomyTerms ?? const [],
    );
  }
}

void main() {
  final originalImagePicker = ImagePickerPlatform.instance;

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<TenantAdminAccountsRepositoryContract>(
      _FakeAccountsRepository(),
    );
    GetIt.I.registerSingleton<TenantAdminAccountProfilesRepositoryContract>(
      _FakeAccountProfilesRepository(),
    );
    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();
    GetIt.I.registerSingleton<TenantAdminLocationSelectionContract>(
      locationSelectionService,
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(
      TenantAdminAccountsController(
        locationSelectionService: locationSelectionService,
      ),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
    ImagePickerPlatform.instance = originalImagePicker;
  });

  testWidgets(
      'requires location and shows map pick for POI-enabled profile type',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantAdminAccountCreateScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Conta Teste',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'cpf',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Perfil Teste',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      '000',
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Venue').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tenant_admin_account_create_map_pick')),
      findsOneWidget,
    );

    final saveButton =
        find.byKey(const ValueKey('tenant_admin_account_create_save'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.text('Localização é obrigatória para este perfil.'),
      findsOneWidget,
    );
  });

  testWidgets('shows selected avatar and allows clear', (tester) async {
    final avatarFile = _createTempImageFile('avatar.png');
    final coverFile = _createTempImageFile('cover.png');
    ImagePickerPlatform.instance = _FakeImagePickerPlatform([
      avatarFile,
      coverFile,
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantAdminAccountCreateScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Remover'), findsNothing);

    final avatarPick =
        find.byKey(const ValueKey('tenant_admin_account_create_avatar_pick'));
    await tester.ensureVisible(avatarPick);
    await tester.tap(avatarPick);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_outline), findsNothing);
    expect(find.text('Remover'), findsOneWidget);

    final avatarRemove = find.byKey(
      const ValueKey('tenant_admin_account_create_avatar_remove'),
    );
    await tester.tap(avatarRemove);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Remover'), findsNothing);

    final coverPick =
        find.byKey(const ValueKey('tenant_admin_account_create_cover_pick'));
    await tester.ensureVisible(coverPick);
    await tester.tap(coverPick);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image_outlined), findsNothing);
    expect(find.text('Remover'), findsOneWidget);
  });
}

XFile _createTempImageFile(String name) {
  final dir = Directory.systemTemp.createTempSync('belluga_test_');
  final file = File('${dir.path}/$name');
  file.writeAsBytesSync([0, 1, 2, 3, 4]);
  return XFile(file.path, name: name, mimeType: 'image/png');
}

class _FakeImagePickerPlatform extends ImagePickerPlatform {
  _FakeImagePickerPlatform(this._queue);

  final List<XFile> _queue;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }
}
