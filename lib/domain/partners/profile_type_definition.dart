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

  factory ProfileTypeDefinition.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    final label = json['label']?.toString() ?? type;
    final capabilities =
        ProfileTypeCapabilities.fromJson(json['capabilities'] as Map<String, dynamic>?);
    return ProfileTypeDefinition(
      type: type,
      label: label,
      capabilities: capabilities,
      raw: json,
    );
  }
}
