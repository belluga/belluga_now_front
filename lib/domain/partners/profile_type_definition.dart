import 'package:belluga_now/domain/partners/profile_type_capabilities.dart';

class ProfileTypeDefinition {
  ProfileTypeDefinition({
    required this.type,
    required this.label,
    required this.capabilities,
    Map<String, dynamic>? raw,
  }) : raw = Map<String, dynamic>.unmodifiable(raw ?? const <String, dynamic>{});

  final String type;
  final String label;
  final ProfileTypeCapabilities capabilities;
  final Map<String, dynamic> raw;

  factory ProfileTypeDefinition.fromPrimitives({
    required String type,
    String? label,
    required ProfileTypeCapabilities capabilities,
    Map<String, dynamic>? raw,
  }) {
    return ProfileTypeDefinition(
      type: type,
      label: label ?? type,
      capabilities: capabilities,
      raw: raw,
    );
  }
}
