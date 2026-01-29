import 'dart:collection';

import 'package:flutter/foundation.dart';

class TenantAdminStore extends ChangeNotifier {
  final List<TenantAdminAccount> _accounts = [];
  final List<TenantAdminOrganization> _organizations = [];
  final Map<String, List<TenantAdminAccountProfile>> _profilesByAccount = {};

  UnmodifiableListView<TenantAdminAccount> get accounts =>
      UnmodifiableListView(_accounts);

  UnmodifiableListView<TenantAdminOrganization> get organizations =>
      UnmodifiableListView(_organizations);

  List<TenantAdminAccountProfile> profilesForAccount(String accountSlug) {
    return List.unmodifiable(_profilesByAccount[accountSlug] ?? const []);
  }

  TenantAdminAccount addAccount({
    required String name,
    required String documentType,
    required String documentNumber,
    OwnershipState ownership = OwnershipState.tenantOwned,
  }) {
    final slug = _slugify(name);
    final account = TenantAdminAccount(
      slug: slug,
      name: name,
      documentType: documentType,
      documentNumber: documentNumber,
      ownership: ownership,
    );
    _accounts.add(account);
    notifyListeners();
    return account;
  }

  TenantAdminAccountProfile addAccountProfile({
    required String accountSlug,
    required String profileType,
    required String displayName,
    String? location,
  }) {
    final profile = TenantAdminAccountProfile(
      id: _slugify(displayName.isEmpty ? profileType : displayName),
      accountSlug: accountSlug,
      type: profileType,
      displayName: displayName,
      location: location,
    );
    final list = _profilesByAccount.putIfAbsent(accountSlug, () => []);
    list.add(profile);
    notifyListeners();
    return profile;
  }

  TenantAdminOrganization addOrganization({
    required String name,
    String? slug,
  }) {
    final org = TenantAdminOrganization(
      id: slug?.isNotEmpty == true ? slug! : _slugify(name),
      name: name,
    );
    _organizations.add(org);
    notifyListeners();
    return org;
  }

  String _slugify(String input) {
    final normalized = input.trim().toLowerCase();
    final replaced = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return replaced.replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  }
}

enum OwnershipState {
  tenantOwned('Do tenant', 'tenant_owned'),
  unmanaged('Nao gerenciadas', 'unmanaged'),
  userOwned('Do usuario', 'user_owned');

  const OwnershipState(this.label, this.subtitle);

  final String label;
  final String subtitle;
}

class TenantAdminAccount {
  TenantAdminAccount({
    required this.slug,
    required this.name,
    required this.documentType,
    required this.documentNumber,
    required this.ownership,
  });

  final String slug;
  final String name;
  final String documentType;
  final String documentNumber;
  final OwnershipState ownership;
}

class TenantAdminAccountProfile {
  TenantAdminAccountProfile({
    required this.id,
    required this.accountSlug,
    required this.type,
    required this.displayName,
    this.location,
  });

  final String id;
  final String accountSlug;
  final String type;
  final String displayName;
  final String? location;
}

class TenantAdminOrganization {
  TenantAdminOrganization({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
