import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/user/friend.dart';
import 'package:stream_value/core/stream_value.dart';

/// Repository contract for managing friends data
abstract class FriendsRepositoryContract {
  /// Cached friends list (app-wide)
  /// This stream holds the cached list of friends and can be subscribed to
  /// for reactive updates across the app
  StreamValue<List<InviteFriendResume>> get friendsStreamValue;

  /// Fetch friends from data source and cache them
  ///
  /// [forceRefresh] - If true, fetches from source even if cache exists
  /// If false and cache is populated, returns immediately without fetching
  Future<void> fetchAndCacheFriends({bool forceRefresh = false});

  /// Get raw Friend objects (for internal repository use)
  /// This is typically used by other repositories that need Friend domain objects
  Future<List<Friend>> fetchFriends();
}
