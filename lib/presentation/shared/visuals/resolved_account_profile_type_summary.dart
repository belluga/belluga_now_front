import 'package:belluga_now/domain/partners/profile_type_definition.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_profile_type_visual.dart';

class ResolvedAccountProfileTypeSummary {
  const ResolvedAccountProfileTypeSummary({
    required this.type,
    required this.label,
    this.definition,
    this.visual,
  });

  final String type;
  final String label;
  final ProfileTypeDefinition? definition;
  final ResolvedProfileTypeVisual? visual;
}
