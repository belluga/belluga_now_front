enum DiscoveryFilterSelectionMode {
  single,
  multiple;
}

extension DiscoveryFilterSelectionModeX on DiscoveryFilterSelectionMode {
  static DiscoveryFilterSelectionMode fromWire(
    String? value, {
    required DiscoveryFilterSelectionMode fallback,
  }) {
    return switch (value?.trim().toLowerCase()) {
      'single' => DiscoveryFilterSelectionMode.single,
      'multiple' || 'multi' => DiscoveryFilterSelectionMode.multiple,
      _ => fallback,
    };
  }

  String get wireName => switch (this) {
        DiscoveryFilterSelectionMode.single => 'single',
        DiscoveryFilterSelectionMode.multiple => 'multiple',
      };
}

enum DiscoveryFilterLayoutMode {
  row,
  wrap;
}

extension DiscoveryFilterLayoutModeX on DiscoveryFilterLayoutMode {
  static DiscoveryFilterLayoutMode fromWire(
    String? value, {
    required DiscoveryFilterLayoutMode fallback,
  }) {
    return switch (value?.trim().toLowerCase()) {
      'row' => DiscoveryFilterLayoutMode.row,
      'wrap' => DiscoveryFilterLayoutMode.wrap,
      _ => fallback,
    };
  }

  String get wireName => switch (this) {
        DiscoveryFilterLayoutMode.row => 'row',
        DiscoveryFilterLayoutMode.wrap => 'wrap',
      };
}

class DiscoveryFilterPolicy {
  const DiscoveryFilterPolicy({
    this.primarySelectionMode = DiscoveryFilterSelectionMode.single,
    this.taxonomySelectionMode = DiscoveryFilterSelectionMode.multiple,
    this.primaryLayoutMode = DiscoveryFilterLayoutMode.row,
    this.taxonomyLayoutMode = DiscoveryFilterLayoutMode.wrap,
  });

  factory DiscoveryFilterPolicy.fromJson(Map<String, Object?> json) {
    return DiscoveryFilterPolicy(
      primarySelectionMode: DiscoveryFilterSelectionModeX.fromWire(
        json['primary_selection_mode'] as String?,
        fallback: DiscoveryFilterSelectionMode.single,
      ),
      taxonomySelectionMode: DiscoveryFilterSelectionModeX.fromWire(
        json['taxonomy_selection_mode'] as String?,
        fallback: DiscoveryFilterSelectionMode.multiple,
      ),
      primaryLayoutMode: DiscoveryFilterLayoutModeX.fromWire(
        json['primary_layout_mode'] as String?,
        fallback: DiscoveryFilterLayoutMode.row,
      ),
      taxonomyLayoutMode: DiscoveryFilterLayoutModeX.fromWire(
        json['taxonomy_layout_mode'] as String?,
        fallback: DiscoveryFilterLayoutMode.wrap,
      ),
    );
  }

  final DiscoveryFilterSelectionMode primarySelectionMode;
  final DiscoveryFilterSelectionMode taxonomySelectionMode;
  final DiscoveryFilterLayoutMode primaryLayoutMode;
  final DiscoveryFilterLayoutMode taxonomyLayoutMode;

  Map<String, Object?> toJson() => <String, Object?>{
        'primary_selection_mode': primarySelectionMode.wireName,
        'taxonomy_selection_mode': taxonomySelectionMode.wireName,
        'primary_layout_mode': primaryLayoutMode.wireName,
        'taxonomy_layout_mode': taxonomyLayoutMode.wireName,
      };
}
