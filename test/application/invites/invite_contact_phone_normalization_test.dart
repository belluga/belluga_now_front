import 'package:belluga_now/application/invites/invite_contact_phone_normalization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preferredWhatsAppTarget derives country code from explicit region', () {
    expect(
      InviteContactPhoneNormalization.preferredWhatsAppTarget(
        '(27) 98888-7777',
        regionCode: 'BR',
      ),
      '5527988887777',
    );
    expect(
      InviteContactPhoneNormalization.preferredWhatsAppTarget(
        '(27) 98888-7777',
        regionCode: 'US',
      ),
      isNull,
    );
  });

  test('hashInputs does not assume Brazil for non-Brazilian regions', () {
    final brInputs = InviteContactPhoneNormalization.hashInputs(
      '(27) 99999-9999',
      regionCode: 'BR',
    );
    final usInputs = InviteContactPhoneNormalization.hashInputs(
      '(27) 99999-9999',
      regionCode: 'US',
    );

    expect(brInputs, contains('5527999999999'));
    expect(usInputs, isNot(contains('5527999999999')));
    expect(usInputs, contains('27999999999'));
  });
}
