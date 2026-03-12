import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:image_picker/image_picker.dart';

class TenantAdminAccountProfileEditDraft {
  static const _unset = Object();

  const TenantAdminAccountProfileEditDraft({
    required this.selectedProfileType,
    required this.avatarFile,
    required this.coverFile,
    required this.avatarRemoteUrl,
    required this.coverRemoteUrl,
    required this.avatarRemoteReady,
    required this.coverRemoteReady,
    required this.avatarRemoteError,
    required this.coverRemoteError,
    required this.avatarPreloadUrl,
    required this.coverPreloadUrl,
    required this.avatarBusy,
    required this.coverBusy,
  });

  factory TenantAdminAccountProfileEditDraft.initial() =>
      const TenantAdminAccountProfileEditDraft(
        selectedProfileType: null,
        avatarFile: null,
        coverFile: null,
        avatarRemoteUrl: null,
        coverRemoteUrl: null,
        avatarRemoteReady: false,
        coverRemoteReady: false,
        avatarRemoteError: false,
        coverRemoteError: false,
        avatarPreloadUrl: null,
        coverPreloadUrl: null,
        avatarBusy: false,
        coverBusy: false,
      );

  final String? selectedProfileType;
  final XFile? avatarFile;
  final XFile? coverFile;
  final String? avatarRemoteUrl;
  final String? coverRemoteUrl;
  final bool avatarRemoteReady;
  final bool coverRemoteReady;
  final bool avatarRemoteError;
  final bool coverRemoteError;
  final String? avatarPreloadUrl;
  final String? coverPreloadUrl;
  final bool avatarBusy;
  final bool coverBusy;

  TenantAdminAccountProfileEditDraft copyWith({
    Object? selectedProfileType = _unset,
    Object? avatarFile = _unset,
    Object? coverFile = _unset,
    Object? avatarRemoteUrl = _unset,
    Object? coverRemoteUrl = _unset,
    bool? avatarRemoteReady,
    bool? coverRemoteReady,
    bool? avatarRemoteError,
    bool? coverRemoteError,
    Object? avatarPreloadUrl = _unset,
    Object? coverPreloadUrl = _unset,
    bool? avatarBusy,
    bool? coverBusy,
  }) {
    final nextSelectedProfileType = selectedProfileType == _unset
        ? this.selectedProfileType
        : selectedProfileType as String?;
    final nextAvatarFile =
        avatarFile == _unset ? this.avatarFile : avatarFile as XFile?;
    final nextCoverFile =
        coverFile == _unset ? this.coverFile : coverFile as XFile?;
    final nextAvatarRemoteUrl = avatarRemoteUrl == _unset
        ? this.avatarRemoteUrl
        : avatarRemoteUrl as String?;
    final nextCoverRemoteUrl = coverRemoteUrl == _unset
        ? this.coverRemoteUrl
        : coverRemoteUrl as String?;
    final nextAvatarPreloadUrl = avatarPreloadUrl == _unset
        ? this.avatarPreloadUrl
        : avatarPreloadUrl as String?;
    final nextCoverPreloadUrl = coverPreloadUrl == _unset
        ? this.coverPreloadUrl
        : coverPreloadUrl as String?;

    return TenantAdminAccountProfileEditDraft(
      selectedProfileType: nextSelectedProfileType,
      avatarFile: nextAvatarFile,
      coverFile: nextCoverFile,
      avatarRemoteUrl: nextAvatarRemoteUrl,
      coverRemoteUrl: nextCoverRemoteUrl,
      avatarRemoteReady: avatarRemoteReady ?? this.avatarRemoteReady,
      coverRemoteReady: coverRemoteReady ?? this.coverRemoteReady,
      avatarRemoteError: avatarRemoteError ?? this.avatarRemoteError,
      coverRemoteError: coverRemoteError ?? this.coverRemoteError,
      avatarPreloadUrl: nextAvatarPreloadUrl,
      coverPreloadUrl: nextCoverPreloadUrl,
      avatarBusy: avatarBusy ?? this.avatarBusy,
      coverBusy: coverBusy ?? this.coverBusy,
    );
  }

  TenantAdminAccountProfileEditDraft syncRemoteState(
    TenantAdminAccountProfile updated,
  ) {
    final avatarUrl = updated.avatarUrl;
    final coverUrl = updated.coverUrl;
    return copyWith(
      avatarRemoteUrl: avatarUrl,
      coverRemoteUrl: coverUrl,
      avatarRemoteReady: false,
      coverRemoteReady: false,
      avatarRemoteError: false,
      coverRemoteError: false,
      avatarPreloadUrl: null,
      coverPreloadUrl: null,
    );
  }
}
