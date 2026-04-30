import 'dart:async';

import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

class PostAuthIdentityHydrationCoordinator {
  PostAuthIdentityHydrationCoordinator({
    AuthRepositoryContract? authRepository,
    FavoriteRepositoryContract? favoriteRepository,
    AccountProfilesRepositoryContract? accountProfilesRepository,
    UserEventsRepositoryContract? userEventsRepository,
    InvitesRepositoryContract? invitesRepository,
  })  : _authRepository =
            authRepository ?? GetIt.I.get<AuthRepositoryContract>(),
        _favoriteRepository =
            favoriteRepository ?? _tryResolve<FavoriteRepositoryContract>(),
        _accountProfilesRepository = accountProfilesRepository ??
            _tryResolve<AccountProfilesRepositoryContract>(),
        _userEventsRepository =
            userEventsRepository ?? _tryResolve<UserEventsRepositoryContract>(),
        _invitesRepository =
            invitesRepository ?? _tryResolve<InvitesRepositoryContract>();

  final AuthRepositoryContract _authRepository;
  final FavoriteRepositoryContract? _favoriteRepository;
  final AccountProfilesRepositoryContract? _accountProfilesRepository;
  final UserEventsRepositoryContract? _userEventsRepository;
  final InvitesRepositoryContract? _invitesRepository;

  StreamSubscription<UserContract?>? _authSubscription;
  String? _lastHydratedUserId;
  Future<void>? _hydrationInFlight;

  void bind() {
    _authSubscription?.cancel();
    _authSubscription =
        _authRepository.userStreamValue.stream.listen(_handleAuthUser);
    final currentUser = _authRepository.userStreamValue.value;
    if (currentUser != null) {
      unawaited(_handleAuthUser(currentUser));
    }
  }

  Future<void> _handleAuthUser(UserContract? user) async {
    if (!_isRegisteredIdentity(user)) {
      _lastHydratedUserId = null;
      return;
    }

    final userId = user!.uuidValue.value.trim();
    if (userId.isEmpty || userId == _lastHydratedUserId) {
      return;
    }

    final inFlight = _hydrationInFlight;
    if (inFlight != null) {
      await inFlight;
      if (userId == _lastHydratedUserId) {
        return;
      }
    }

    _lastHydratedUserId = userId;
    final hydration = _hydrateIdentityOwnedState().whenComplete(() {
      _hydrationInFlight = null;
    });
    _hydrationInFlight = hydration;
    await hydration;
  }

  Future<void> _hydrateIdentityOwnedState() async {
    await Future.wait<void>([
      _runHydrationStep(
        label: 'favorite-resumes',
        action: () async {
          await _favoriteRepository?.refreshFavoriteResumes();
        },
      ),
      _runHydrationStep(
        label: 'account-profile-favorite-ids',
        action: () async {
          await _accountProfilesRepository?.refreshFavoriteAccountProfileIds();
        },
      ),
      _runHydrationStep(
        label: 'confirmed-occurrences',
        action: () async {
          await _userEventsRepository?.refreshConfirmedOccurrenceIds();
        },
      ),
      _runHydrationStep(
        label: 'pending-invites',
        action: () async {
          await _invitesRepository?.refreshPendingInvites();
        },
      ),
    ]);
  }

  Future<void> _runHydrationStep({
    required String label,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint(
        'PostAuthIdentityHydrationCoordinator.$label failed: '
        '$error\n$stackTrace',
      );
    }
  }

  bool _isRegisteredIdentity(UserContract? user) {
    if (user == null) {
      return false;
    }
    return !(user.customData?.isAnonymous ?? false);
  }

  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
  }

  static T? _tryResolve<T extends Object>() {
    if (!GetIt.I.isRegistered<T>()) {
      return null;
    }
    return GetIt.I.get<T>();
  }
}
