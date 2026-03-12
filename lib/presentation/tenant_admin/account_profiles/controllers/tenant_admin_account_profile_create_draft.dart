import 'package:image_picker/image_picker.dart';

class TenantAdminAccountProfileCreateDraft {
  static const _unset = Object();

  const TenantAdminAccountProfileCreateDraft({
    required this.selectedProfileType,
    required this.avatarFile,
    required this.coverFile,
    required this.avatarWebUrl,
    required this.coverWebUrl,
    required this.avatarBusy,
    required this.coverBusy,
  });

  factory TenantAdminAccountProfileCreateDraft.initial() =>
      const TenantAdminAccountProfileCreateDraft(
        selectedProfileType: null,
        avatarFile: null,
        coverFile: null,
        avatarWebUrl: null,
        coverWebUrl: null,
        avatarBusy: false,
        coverBusy: false,
      );

  final String? selectedProfileType;
  final XFile? avatarFile;
  final XFile? coverFile;
  final String? avatarWebUrl;
  final String? coverWebUrl;
  final bool avatarBusy;
  final bool coverBusy;

  TenantAdminAccountProfileCreateDraft copyWith({
    Object? selectedProfileType = _unset,
    Object? avatarFile = _unset,
    Object? coverFile = _unset,
    Object? avatarWebUrl = _unset,
    Object? coverWebUrl = _unset,
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
    final nextAvatarWebUrl =
        avatarWebUrl == _unset ? this.avatarWebUrl : avatarWebUrl as String?;
    final nextCoverWebUrl =
        coverWebUrl == _unset ? this.coverWebUrl : coverWebUrl as String?;

    return TenantAdminAccountProfileCreateDraft(
      selectedProfileType: nextSelectedProfileType,
      avatarFile: nextAvatarFile,
      coverFile: nextCoverFile,
      avatarWebUrl: nextAvatarWebUrl,
      coverWebUrl: nextCoverWebUrl,
      avatarBusy: avatarBusy ?? this.avatarBusy,
      coverBusy: coverBusy ?? this.coverBusy,
    );
  }
}
