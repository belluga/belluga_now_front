import 'belluga_contact_channel_capabilities.dart';
import 'belluga_contact_channel_type.dart';
import 'belluga_contact_icon_token.dart';
import 'belluga_contact_initial_message.dart';
import 'belluga_contact_resolution.dart';

/// Closed, typed behaviour for one persisted [BellugaContactChannelType].
///
/// Account-profile code stores only the type discriminator and data. UI and
/// codecs resolve this definition instead of branching on wire type strings.
abstract interface class BellugaContactChannelDefinition {
  BellugaContactChannelType get type;
  String get canonicalLabel;
  BellugaContactIconToken get iconToken;
  BellugaContactChannelCapabilities get capabilities;

  String? normalizeValue(String rawValue);

  BellugaContactResolution? resolveLaunch(
    String rawValue, {
    String? prefilledMessage,
  });

  List<BellugaContactInitialMessage> decodeInitialMessages(Object? rawMetadata);

  Map<String, dynamic> encodeMetadata(
    List<BellugaContactInitialMessage> initialMessages,
  );
}
