import 'package:belluga_now/domain/partners/account_profile.dart';
import 'package:belluga_now/domain/partners/account_profile_complete.dart';
import 'package:belluga_now/domain/partners/account_profile_summary.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_public_detail_path_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_text_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

void main() {
  group('AccountProfile.publicDetailUrl', () {
    for (final factory in <String, AccountProfile Function(bool, String)>{
      'summary': _summary,
      'complete': _complete,
    }.entries) {
      test('${factory.key} returns the trimmed producer path when enabled', () {
        final profile = factory.value(true, '  /parceiro/casa-um  ');

        expect(profile.publicDetailUrl, '/parceiro/casa-um');
      });

      test('${factory.key} fails closed when capability is false', () {
        final profile = factory.value(false, '/parceiro/casa-um');

        expect(profile.publicDetailUrl, isNull);
      });

      test('${factory.key} fails closed when path is blank', () {
        final profile = factory.value(true, '   ');

        expect(profile.publicDetailUrl, isNull);
      });
    }

    test('complete copyWith preserves the inherited navigation pair', () {
      final profile = _complete(true, '/parceiro/casa-um');

      final updated = profile.copyWith(
        nameValue: AccountProfileNameValue()..parse('Casa Dois'),
      );

      expect(updated.canOpenPublicDetail, isTrue);
      expect(updated.publicDetailPath, '/parceiro/casa-um');
      expect(updated.publicDetailUrl, '/parceiro/casa-um');
    });

    test('profile type trims and rejects blank content', () {
      expect(
        () => AccountProfileTypeValue('   '),
        throwsA(isA<TooShortValueException<dynamic>>()),
      );
    });
  });
}

AccountProfileSummary _summary(bool enabled, String path) {
  return AccountProfileSummary(
    idValue: AccountProfileTextValue('profile-1'),
    nameValue: AccountProfileNameValue()..parse('Casa Um'),
    profileTypeValue: AccountProfileTypeValue('venue'),
    canOpenPublicDetailValue: _boolean(enabled),
    publicDetailPathValue: AccountProfilePublicDetailPathValue(path),
  );
}

AccountProfileComplete _complete(bool enabled, String path) {
  return AccountProfileComplete(
    idValue: MongoIDValue()..parse('507f1f77bcf86cd799439011'),
    nameValue: AccountProfileNameValue()..parse('Casa Um'),
    slugValue: SlugValue()..parse('casa-um'),
    profileTypeValue: AccountProfileTypeValue('venue'),
    canOpenPublicDetailValue: _boolean(enabled),
    publicDetailPathValue: AccountProfilePublicDetailPathValue(path),
  );
}

DomainBooleanValue _boolean(bool value) {
  return DomainBooleanValue(defaultValue: false, isRequired: false)
    ..parse(value.toString());
}
