import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_item_request.dart';

class InviteContactImportRequest {
  const InviteContactImportRequest({
    required this.contacts,
  });

  final List<InviteContactImportItemRequest> contacts;

  Map<String, dynamic> toJson() {
    return {
      'contacts': contacts.map((item) => item.toJson()).toList(growable: false),
    };
  }
}
