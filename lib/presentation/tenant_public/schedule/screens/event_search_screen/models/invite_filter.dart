export 'time_filter.dart';

enum InviteFilter { none, pendingOnly, confirmedOnly }

extension InviteFilterCycle on InviteFilter {
  InviteFilter get next {
    switch (this) {
      case InviteFilter.none:
        return InviteFilter.pendingOnly;
      case InviteFilter.pendingOnly:
        return InviteFilter.confirmedOnly;
      case InviteFilter.confirmedOnly:
        return InviteFilter.none;
    }
  }

  bool get isStatusExtended => this != InviteFilter.none;
}
