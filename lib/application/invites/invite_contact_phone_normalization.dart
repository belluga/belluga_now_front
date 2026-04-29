class InviteContactPhoneNormalization {
  const InviteContactPhoneNormalization._();

  static List<String> hashInputs(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'\D+'), '');
    if (digits.isEmpty) {
      return const <String>[];
    }

    final variants = <String>{digits};

    final withoutTrunkPrefix = digits.replaceFirst(RegExp(r'^0+'), '');
    if (withoutTrunkPrefix.isNotEmpty && withoutTrunkPrefix != digits) {
      variants.add(withoutTrunkPrefix);
    }

    for (final candidate in List<String>.from(variants)) {
      if (candidate.length == 10 || candidate.length == 11) {
        variants.add('55$candidate');
      }
      if (candidate.startsWith('55') &&
          (candidate.length == 12 || candidate.length == 13)) {
        variants.add(candidate.substring(2));
      }
    }

    return variants.toList(growable: false);
  }

  static String? preferredWhatsAppTarget(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'\D+'), '');
    if (digits.isEmpty) {
      return null;
    }

    if (digits.startsWith('55') &&
        (digits.length == 12 || digits.length == 13)) {
      return digits;
    }

    for (final candidate in hashInputs(rawPhone)) {
      if (candidate.startsWith('55') &&
          (candidate.length == 12 || candidate.length == 13)) {
        return candidate;
      }
    }

    if (digits.length >= 12) {
      return digits;
    }

    return null;
  }
}
