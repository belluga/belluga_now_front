import 'package:belluga_now/domain/partners/account_profile_summary.dart';

class EventRelatedProfileGroupSummary {
  EventRelatedProfileGroupSummary({
    required String label,
    required List<AccountProfileSummary> profiles,
  }) : label = label.trim(),
       profiles = List<AccountProfileSummary>.unmodifiable(profiles);

  final String label;
  final List<AccountProfileSummary> profiles;

  List<String> get profileNames => List<String>.unmodifiable(
    profiles
        .map((profile) => profile.displayName.trim())
        .where((name) => name.isNotEmpty),
  );
}
