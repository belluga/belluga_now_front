import 'belluga_contact_channel_definition.dart';
import 'belluga_contact_channel_definitions.dart';
import 'belluga_contact_channel_type.dart';

/// The single behaviour-resolution point for all supported contact channels.
final class BellugaContactChannelRegistry {
  BellugaContactChannelRegistry(
      Iterable<BellugaContactChannelDefinition> definitions)
      : _definitions = Map<BellugaContactChannelType,
            BellugaContactChannelDefinition>.unmodifiable(
          <BellugaContactChannelType, BellugaContactChannelDefinition>{
            for (final definition in definitions) definition.type: definition,
          },
        );

  factory BellugaContactChannelRegistry.standard() =>
      BellugaContactChannelRegistry(
        const <BellugaContactChannelDefinition>[
          BellugaEmailContactChannelDefinition(),
          BellugaWhatsAppContactChannelDefinition(),
        ],
      );

  static final BellugaContactChannelRegistry canonical =
      BellugaContactChannelRegistry.standard();

  final Map<BellugaContactChannelType, BellugaContactChannelDefinition>
      _definitions;

  BellugaContactChannelDefinition require(BellugaContactChannelType type) {
    final definition = _definitions[type];
    if (definition == null) {
      throw StateError(
          'Unsupported Belluga contact channel type: ${type.rawValue}.');
    }
    return definition;
  }

  BellugaContactChannelDefinition? find(BellugaContactChannelType? type) =>
      type == null ? null : _definitions[type];

  List<BellugaContactChannelDefinition> get definitions =>
      List<BellugaContactChannelDefinition>.unmodifiable(_definitions.values);
}
