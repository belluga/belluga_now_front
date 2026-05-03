import 'dart:convert';

import 'package:belluga_now/application/invites/invite_contact_phone_normalization.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:crypto/crypto.dart';

class InviteContactImportHashes {
  const InviteContactImportHashes._();

  static Set<String> contactHashes(
    ContactModel contact, {
    String? regionCode,
  }) {
    final hashes = <String>{};

    for (final email in contact.emails) {
      final normalized = email.value.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      hashes.add(sha256.convert(utf8.encode(normalized)).toString());
    }

    for (final phone in contact.phones) {
      for (final normalized in InviteContactPhoneNormalization.hashInputs(
        phone.value,
        regionCode: regionCode,
      )) {
        hashes.add(sha256.convert(utf8.encode(normalized)).toString());
      }
    }

    return hashes;
  }
}
