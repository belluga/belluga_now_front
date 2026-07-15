import 'dart:convert';
import 'dart:io';

import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'executes every package-local v1 contact-channel capability and URI vector',
      () {
    final fixtureFile = File(
        'packages/belluga_contact_channels/fixtures/contact_channels.v1.json');
    final resolvedFixture = fixtureFile.existsSync()
        ? fixtureFile
        : File('fixtures/contact_channels.v1.json');
    final fixture =
        jsonDecode(resolvedFixture.readAsStringSync()) as Map<String, dynamic>;

    expect(fixture['version'], 1);
    final channels = fixture['channels'] as Map<String, dynamic>;
    for (final entry in channels.entries) {
      final type = BellugaContactChannelType.fromRaw(entry.key);
      expect(type, isNotNull, reason: 'fixture type ${entry.key} must exist');
      final definition = BellugaContactChannelRegistry.canonical.require(type!);
      final channelFixture = entry.value as Map<String, dynamic>;
      final capabilities =
          channelFixture['capabilities'] as Map<String, dynamic>;

      expect(definition.capabilities.publicCard, capabilities['public_card']);
      expect(
          definition.capabilities.directLaunch, capabilities['direct_launch']);
      expect(definition.capabilities.bubble, capabilities['bubble']);
      expect(
        definition.capabilities.messagePresets,
        capabilities['message_presets'],
      );
      expect(definition.capabilities.repeatable, capabilities['repeatable']);
      expect(
        definition.capabilities.maxInitialMessages,
        capabilities['max_initial_messages'],
      );
      expect(
        definition.capabilities.maxInitialMessageCtaLength,
        capabilities['max_initial_message_cta_length'],
      );
      expect(
        definition.capabilities.maxInitialMessageLength,
        capabilities['max_initial_message_length'],
      );

      for (final rawVector in channelFixture['vectors'] as List<dynamic>) {
        final vector = rawVector as Map<String, dynamic>;
        final rawValue = vector['raw_value'] as String;
        expect(
          definition.normalizeValue(rawValue),
          vector['normalized_value'],
          reason: '${entry.key} normalization vector for $rawValue',
        );
        expect(
          definition.resolveLaunch(rawValue)?.uri.toString(),
          vector['launch_uri'],
          reason: '${entry.key} launch vector for $rawValue',
        );
        if (vector.containsKey('launch_uri_with_message')) {
          expect(
            definition
                .resolveLaunch(rawValue, prefilledMessage: 'Hello there')
                ?.uri
                .toString(),
            vector['launch_uri_with_message'],
            reason: '${entry.key} message launch vector for $rawValue',
          );
        }
      }
    }
  });
}
