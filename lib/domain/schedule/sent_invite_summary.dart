import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/sent_invite_summary_count_value.dart';

class SentInviteSummary {
  SentInviteSummary({
    required this.pendingValue,
    required this.acceptedValue,
    required this.declinedValue,
    required this.terminalHiddenValue,
    required this.totalVisibleValue,
    required this.totalSentValue,
    List<SentInviteStatus> preview = const <SentInviteStatus>[],
  }) : preview = List<SentInviteStatus>.unmodifiable(preview);

  factory SentInviteSummary.empty() {
    return SentInviteSummary(
      pendingValue: SentInviteSummaryCountValue(),
      acceptedValue: SentInviteSummaryCountValue(),
      declinedValue: SentInviteSummaryCountValue(),
      terminalHiddenValue: SentInviteSummaryCountValue(),
      totalVisibleValue: SentInviteSummaryCountValue(),
      totalSentValue: SentInviteSummaryCountValue(),
    );
  }

  final SentInviteSummaryCountValue pendingValue;
  final SentInviteSummaryCountValue acceptedValue;
  final SentInviteSummaryCountValue declinedValue;
  final SentInviteSummaryCountValue terminalHiddenValue;
  final SentInviteSummaryCountValue totalVisibleValue;
  final SentInviteSummaryCountValue totalSentValue;
  final List<SentInviteStatus> preview;

  int get pending => pendingValue.value;
  int get accepted => acceptedValue.value;
  int get declined => declinedValue.value;
  int get terminalHidden => terminalHiddenValue.value;
  int get totalVisible => totalVisibleValue.value;
  int get totalSent => totalSentValue.value;
  bool get hasVisibleInvites => totalVisible > 0;
}
