import 'package:belluga_now/domain/partners/account_profile_summary.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_text_value.dart';

class AccountProfileSummaryPage {
  const AccountProfileSummaryPage.empty()
    : items = const <AccountProfileSummary>[],
      nextCursorValue = null;

  AccountProfileSummaryPage({
    required List<AccountProfileSummary> items,
    required this.nextCursorValue,
  }) : items = List<AccountProfileSummary>.unmodifiable(items);

  final List<AccountProfileSummary> items;
  final AccountProfileTextValue? nextCursorValue;

  bool get hasMore => (nextCursorValue?.value.trim() ?? '').isNotEmpty;
}
