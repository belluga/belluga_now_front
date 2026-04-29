import 'package:intl/intl.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class InviteContactPhoneNormalization {
  const InviteContactPhoneNormalization._();

  static List<String> hashInputs(
    String rawPhone, {
    String? regionCode,
  }) {
    final digits = _digitsOnly(rawPhone);
    if (digits.isEmpty) {
      return const <String>[];
    }

    final variants = <String>{digits};

    final withoutTrunkPrefix = digits.replaceFirst(RegExp(r'^0+'), '');
    if (withoutTrunkPrefix.isNotEmpty && withoutTrunkPrefix != digits) {
      variants.add(withoutTrunkPrefix);
    }

    final parsedPhone = _tryParsePhone(
      rawPhone,
      regionCode: regionCode ?? _defaultRegionCode(),
    );
    if (parsedPhone != null && parsedPhone.isValidLength()) {
      variants.add(_digitsOnly(parsedPhone.international));
      variants.add(parsedPhone.nsn);
    }

    return variants.toList(growable: false);
  }

  static String? preferredWhatsAppTarget(
    String rawPhone, {
    String? regionCode,
  }) {
    final digits = _digitsOnly(rawPhone);
    if (digits.isEmpty) {
      return null;
    }

    final parsedPhone = _tryParsePhone(
      rawPhone,
      regionCode: regionCode ?? _defaultRegionCode(),
    );
    if (parsedPhone != null && parsedPhone.isValid()) {
      return _digitsOnly(parsedPhone.international);
    }

    if (_looksExplicitlyInternational(rawPhone, digits)) {
      return digits;
    }

    return null;
  }

  static String _digitsOnly(String value) => value.replaceAll(
        RegExp(r'\D+'),
        '',
      );

  static PhoneNumber? _tryParsePhone(
    String rawPhone, {
    required String? regionCode,
  }) {
    final isoCode = _isoCodeFromRegion(regionCode);

    try {
      return PhoneNumber.parse(
        rawPhone,
        callerCountry: isoCode,
      );
    } catch (_) {
      return null;
    }
  }

  static IsoCode? _isoCodeFromRegion(String? regionCode) {
    final normalized = regionCode?.trim().toUpperCase();
    if (normalized == null || normalized.length != 2) {
      return null;
    }

    for (final isoCode in IsoCode.values) {
      if (isoCode.name == normalized) {
        return isoCode;
      }
    }

    return null;
  }

  static bool _looksExplicitlyInternational(String rawPhone, String digits) {
    if (digits.length < 8 || digits.length > 15) {
      return false;
    }

    final trimmed = rawPhone.trimLeft();
    return trimmed.startsWith('+') || digits.length >= 12;
  }

  static String? _defaultRegionCode() {
    final locale = Intl.defaultLocale ?? Intl.getCurrentLocale();
    final parts = locale.split(RegExp(r'[-_]'));

    for (final part in parts.reversed) {
      final normalized = part.trim().toUpperCase();
      if (RegExp(r'^[A-Z]{2}$').hasMatch(normalized)) {
        return normalized;
      }
    }

    return null;
  }
}
