import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';

class TenantAdminAccountDTO {
  const TenantAdminAccountDTO({
    required this.id,
    required this.name,
    required this.slug,
    required this.documentType,
    required this.documentNumber,
    this.organizationId,
    this.ownershipState,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String slug;
  final String documentType;
  final String documentNumber;
  final String? organizationId;
  final String? ownershipState;
  final String? avatarUrl;

  factory TenantAdminAccountDTO.fromJson(Map<String, dynamic> json) {
    final document = json['document'];
    String? documentType;
    String? documentNumber;
    if (document is Map<String, dynamic>) {
      documentType = document['type']?.toString();
      documentNumber = document['number']?.toString();
    }
    return TenantAdminAccountDTO(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      documentType: documentType ?? '',
      documentNumber: documentNumber ?? '',
      organizationId: json['organization_id']?.toString(),
      ownershipState: json['ownership_state']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  TenantAdminAccount toDomain() {
    final ownershipStateRaw = ownershipState?.trim();
    final resolvedOwnershipState =
        (ownershipStateRaw == null || ownershipStateRaw.isEmpty)
            ? TenantAdminOwnershipState.unmanaged
            : TenantAdminOwnershipState.fromApiValue(ownershipStateRaw);
    return TenantAdminAccount(
      id: id,
      name: name,
      slug: slug,
      document: TenantAdminDocument(
        type: documentType,
        number: documentNumber,
      ),
      organizationId: organizationId,
      ownershipState: resolvedOwnershipState,
      avatarUrl: avatarUrl,
    );
  }
}
