import 'package:belluga_now/application/sharing/account_profile_public_share_payload.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds authenticated share copy using content before bio', () {
    final profile = buildAccountProfileModelFromPrimitives(
      id: '507f1f77bcf86cd799439099',
      name: 'Casa Marracini',
      slug: 'casa-marracini',
      type: 'restaurant',
      bio: 'Bio fallback',
      content: '<p>Conteúdo principal do perfil.</p>',
    );

    final payload = AccountProfilePublicSharePayloadBuilder.build(
      publicUri: Uri.parse('https://tenant.test/parceiro/casa-marracini'),
      fallbackName: 'Fallback',
      profile: profile,
      actorDisplayName: 'Ananda',
      fallbackDescription: 'Descrição fallback',
    );

    expect(payload.subject, 'Casa Marracini');
    expect(
      payload.message,
      contains('Ananda está te convidando para conhecer Casa Marracini.'),
    );
    expect(payload.message, contains('Conteúdo principal do perfil.'));
    expect(payload.message, contains('https://tenant.test/parceiro/casa-marracini'));
    expect(payload.message, isNot(contains('Descrição fallback')));
  });

  test('builds anonymous share copy with fallback description when needed', () {
    final payload = AccountProfilePublicSharePayloadBuilder.build(
      publicUri: Uri.parse('https://tenant.test/parceiro/casa-marracini'),
      fallbackName: 'Casa Marracini',
      actorDisplayName: null,
      fallbackDescription: '<p>Descrição factual do profile.</p>',
    );

    expect(payload.subject, 'Casa Marracini');
    expect(
      payload.message,
      contains('Ei, vi isso e achei que você gostaria: Casa Marracini.'),
    );
    expect(payload.message, contains('Descrição factual do profile.'));
    expect(payload.message, contains('https://tenant.test/parceiro/casa-marracini'));
  });
}
