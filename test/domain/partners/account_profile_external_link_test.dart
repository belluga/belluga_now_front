import 'package:belluga_now/domain/partners/account_profile_external_link.dart';
import 'package:belluga_now/infrastructure/dal/decoders/account_profile_external_link_decoder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';

void main() {
  group('AccountProfileExternalLinkRegistry', () {
    test('owns the closed first-delivery type order and semantic labels', () {
      expect(
        AccountProfileExternalLinkType.values.map((value) => value.wireValue),
        ['instagram', 'facebook', 'youtube', 'tiktok', 'spotify', 'website'],
      );
      expect(
        AccountProfileExternalLinkType.values.map(
          (value) => value.semanticLabel,
        ),
        ['Instagram', 'Facebook', 'YouTube', 'TikTok', 'Spotify', 'Website'],
      );
    });

    test('accepts exact provider hosts and a non-root path', () {
      final accepted = <AccountProfileExternalLinkType, String>{
        AccountProfileExternalLinkType.instagram:
            'https://www.instagram.com/belluga.now/',
        AccountProfileExternalLinkType.facebook:
            'https://m.facebook.com/belluga',
        AccountProfileExternalLinkType.youtube: 'https://youtu.be/dQw4w9WgXcQ',
        AccountProfileExternalLinkType.tiktok:
            'https://www.tiktok.com/@belluga',
        AccountProfileExternalLinkType.spotify:
            'https://open.spotify.com/artist/abc',
      };

      for (final entry in accepted.entries) {
        final link = _parseExternalLink(
          id: 'id-${entry.key.wireValue}',
          type: entry.key,
          url: entry.value,
        );
        expect(link.url.toString(), entry.value);
        expect(link.label, entry.key.semanticLabel);
      }
    });

    test(
      'rejects insecure, credentialed, lookalike, and root provider URLs',
      () {
        for (final url in [
          'http://instagram.com/belluga',
          'https://user@instagram.com/belluga',
          'https://instagram.com.evil.test/belluga',
          'https://instagram.com/',
        ]) {
          expect(
            () => _parseExternalLink(
              id: 'id',
              type: AccountProfileExternalLinkType.instagram,
              url: url,
            ),
            throwsA(
              anyOf(
                isA<AccountProfileExternalLinkValidationException>(),
                isA<InvalidValueException>(),
              ),
            ),
          );
        }
      },
    );

    test(
      'requires a bounded website label and omits branded authored labels',
      () {
        final website = _parseExternalLink(
          id: 'website-id',
          type: AccountProfileExternalLinkType.website,
          url: '  https://example.org/path  ',
          label: '  Official site  ',
        );
        expect(website.url.toString(), 'https://example.org/path');
        expect(website.label, 'Official site');

        expect(
          () => _parseExternalLink(
            id: 'instagram-id',
            type: AccountProfileExternalLinkType.instagram,
            url: 'https://instagram.com/belluga',
            label: 'Authored brand label',
          ),
          throwsA(
            isA<AccountProfileExternalLinkValidationException>().having(
              (error) => error.field,
              'field',
              AccountProfileExternalLinkValidationField.label,
            ),
          ),
        );
      },
    );

    test('decodes valid links in registry order and fails closed per item', () {
      final links = AccountProfileExternalLinkDecoder.decodeList([
        {
          'id': 'website',
          'type': 'website',
          'url': 'https://example.org',
          'label': 'Official',
        },
        {
          'id': 'instagram',
          'type': 'instagram',
          'url': 'https://instagram.com/belluga',
        },
        {'id': 'invalid', 'type': 'facebook', 'url': 'javascript:alert(1)'},
      ]);

      expect(links.map((link) => link.type), [
        AccountProfileExternalLinkType.instagram,
        AccountProfileExternalLinkType.website,
      ]);
    });

    test('omits every ambiguous duplicate type and identity', () {
      final links = AccountProfileExternalLinkDecoder.decodeList([
        {
          'id': 'duplicate-type-a',
          'type': 'instagram',
          'url': 'https://instagram.com/first',
        },
        {
          'id': 'duplicate-type-b',
          'type': 'instagram',
          'url': 'https://instagram.com/second',
        },
        {
          'id': 'website',
          'type': 'website',
          'url': 'https://example.org',
          'label': 'Only valid item',
        },
      ]);

      expect(links, hasLength(1));
      expect(links.single.id, 'website');
    });

    test('fails closed when branded links carry any authored label field', () {
      final links = AccountProfileExternalLinkDecoder.decodeList([
        {
          'id': 'instagram-null-label',
          'type': 'instagram',
          'url': 'https://instagram.com/belluga',
          'label': null,
        },
        {
          'id': 'facebook-non-string-label',
          'type': 'facebook',
          'url': 'https://facebook.com/belluga',
          'label': 42,
        },
        {
          'id': 'website-valid-label',
          'type': 'website',
          'url': 'https://example.org',
          'label': 'Official site',
        },
      ]);

      expect(links, hasLength(1));
      expect(links.single.type, AccountProfileExternalLinkType.website);
    });

    test('fails closed for missing, null, malformed, and overlong values', () {
      for (final raw in <Object?>[
        null,
        const {},
        const {'id': '', 'type': 'website', 'url': 'https://example.org'},
        {
          'id': 'long',
          'type': 'website',
          'url': 'https://${List.filled(2049, 'x').join()}',
          'label': 'Long',
        },
      ]) {
        expect(AccountProfileExternalLinkDecoder.decodeList([raw]), isEmpty);
      }
    });

    test(
      'uses only the supplied resolved capacity and never a client limit',
      () {
        final payload = [
          {
            'id': 'website',
            'type': 'website',
            'url': 'https://example.org',
            'label': 'Site',
          },
          {
            'id': 'instagram',
            'type': 'instagram',
            'url': 'https://instagram.com/belluga',
          },
          {
            'id': 'facebook',
            'type': 'facebook',
            'url': 'https://facebook.com/belluga',
          },
          {
            'id': 'youtube',
            'type': 'youtube',
            'url': 'https://youtu.be/dQw4w9WgXcQ',
          },
        ];

        expect(
          AccountProfileExternalLinkDecoder.decodeList(payload, limit: 3),
          isEmpty,
        );
        expect(
          AccountProfileExternalLinkDecoder.decodeList(payload, limit: 4),
          hasLength(4),
        );
        expect(
          AccountProfileExternalLinkDecoder.decodeList(payload),
          hasLength(4),
        );
      },
    );

    test('rejects transport collections above the closed registry shape', () {
      final links = AccountProfileExternalLinkDecoder.decodeList([
        for (var index = 0; index < 7; index++)
          {
            'id': 'link-$index',
            'type': 'website',
            'url': 'https://example-$index.org',
            'label': 'Site $index',
          },
      ]);

      expect(links, isEmpty);
    });
  });
}

AccountProfileExternalLink _parseExternalLink({
  required String id,
  required AccountProfileExternalLinkType type,
  required String url,
  String? label,
}) => AccountProfileExternalLinkRegistry.validateMutation(
  id: AccountProfileExternalLinkIdValue(id),
  type: type,
  url: AccountProfileExternalLinkUrlValue(url),
  label: label == null ? null : AccountProfileExternalLinkLabelValue(label),
);
