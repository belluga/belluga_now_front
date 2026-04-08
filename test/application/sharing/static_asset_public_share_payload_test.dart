import 'package:belluga_now/application/sharing/static_asset_public_share_payload.dart';
import 'package:belluga_now/domain/static_assets/value_objects/public_static_asset_fields.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds authenticated static asset share copy using content before bio',
      () {
    final asset = PublicStaticAssetModel(
      idValue: PublicStaticAssetIdValue(defaultValue: 'asset-1'),
      profileTypeValue: PublicStaticAssetTypeValue(defaultValue: 'beach'),
      displayNameValue:
          PublicStaticAssetNameValue(defaultValue: 'Praia das Virtudes'),
      slugValue: SlugValue()..parse('praia-das-virtudes'),
      bioValue: PublicStaticAssetDescriptionValue(
        defaultValue: 'Bio fallback',
        isRequired: false,
      ),
      contentValue: PublicStaticAssetDescriptionValue(
        defaultValue: '<p>Uma praia charmosa para curtir o pôr do sol.</p>',
        isRequired: false,
      ),
    );

    final payload = StaticAssetPublicSharePayloadBuilder.build(
      publicUri: Uri.parse('https://tenant.test/static/praia-das-virtudes'),
      fallbackName: 'Fallback',
      asset: asset,
      actorDisplayName: 'Ananda',
      fallbackDescription: 'Descrição fallback',
    );

    expect(payload.subject, 'Praia das Virtudes');
    expect(
      payload.message,
      contains('Ananda está te convidando para conhecer Praia das Virtudes.'),
    );
    expect(
      payload.message,
      contains('Uma praia charmosa para curtir o pôr do sol.'),
    );
    expect(
      payload.message,
      contains('https://tenant.test/static/praia-das-virtudes'),
    );
    expect(payload.message, isNot(contains('Descrição fallback')));
  });

  test('builds anonymous static asset share copy with fallback description',
      () {
    final payload = StaticAssetPublicSharePayloadBuilder.build(
      publicUri: Uri.parse('https://tenant.test/static/praia-das-virtudes'),
      fallbackName: 'Praia das Virtudes',
      actorDisplayName: null,
      fallbackDescription: '<p>Vista para o mar e acesso fácil.</p>',
    );

    expect(payload.subject, 'Praia das Virtudes');
    expect(
      payload.message,
      contains('Ei, vi isso e achei que você gostaria: Praia das Virtudes.'),
    );
    expect(payload.message, contains('Vista para o mar e acesso fácil.'));
    expect(
      payload.message,
      contains('https://tenant.test/static/praia-das-virtudes'),
    );
  });
}
