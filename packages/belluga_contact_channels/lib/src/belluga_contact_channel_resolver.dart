import 'belluga_contact_channel.dart';
import 'belluga_contact_channel_registry.dart';
import 'belluga_contact_channel_type.dart';
import 'belluga_contact_resolution.dart';

final class BellugaContactChannelResolver {
  BellugaContactChannelResolver._();

  static BellugaContactResolution? resolveChannel(
    BellugaContactChannel channel, {
    String? prefilledMessage,
  }) {
    return resolveRaw(
      type: channel.type,
      rawValue: channel.value,
      prefilledMessage: prefilledMessage,
    );
  }

  static BellugaContactResolution? resolveRaw({
    required BellugaContactChannelType type,
    required String rawValue,
    String? prefilledMessage,
  }) {
    return BellugaContactChannelRegistry.canonical
        .require(type)
        .resolveLaunch(rawValue, prefilledMessage: prefilledMessage);
  }

  static bool isResolvable({
    required BellugaContactChannelType type,
    required String rawValue,
  }) {
    return resolveRaw(type: type, rawValue: rawValue) != null;
  }
}
