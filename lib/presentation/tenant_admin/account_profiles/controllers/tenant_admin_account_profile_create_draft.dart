import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
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
    required this.contactMode,
    this.contactChannelDrafts = const <BellugaContactChannelDraft>[],
    this.expandedContactCtaDraftKey,
    this.contactBubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
    this.contactSourceAccountProfileId,
    this.nestedProfileGroups = const <TenantAdminNestedProfileGroup>[],
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
        contactMode: BellugaContactSourceMode.own,
        contactChannelDrafts: <BellugaContactChannelDraft>[],
        expandedContactCtaDraftKey: null,
        contactBubbleSelection: BellugaContactBubbleSelectionMutation.omit(),
        contactSourceAccountProfileId: null,
        nestedProfileGroups: <TenantAdminNestedProfileGroup>[],
      );

  final String? selectedProfileType;
  final XFile? avatarFile;
  final XFile? coverFile;
  final String? avatarWebUrl;
  final String? coverWebUrl;
  final bool avatarBusy;
  final bool coverBusy;
  final BellugaContactSourceMode contactMode;
  final List<BellugaContactChannelDraft> contactChannelDrafts;
  final String? expandedContactCtaDraftKey;
  final BellugaContactBubbleSelectionMutation contactBubbleSelection;
  final String? contactSourceAccountProfileId;
  final List<TenantAdminNestedProfileGroup> nestedProfileGroups;

  TenantAdminAccountProfileCreateDraft copyWith({
    Object? selectedProfileType = _unset,
    Object? avatarFile = _unset,
    Object? coverFile = _unset,
    Object? avatarWebUrl = _unset,
    Object? coverWebUrl = _unset,
    bool? avatarBusy,
    bool? coverBusy,
    BellugaContactSourceMode? contactMode,
    List<BellugaContactChannelDraft>? contactChannelDrafts,
    Object? expandedContactCtaDraftKey = _unset,
    BellugaContactBubbleSelectionMutation? contactBubbleSelection,
    Object? contactSourceAccountProfileId = _unset,
    List<TenantAdminNestedProfileGroup>? nestedProfileGroups,
  }) {
    final nextSelectedProfileType = selectedProfileType == _unset
        ? this.selectedProfileType
        : selectedProfileType as String?;
    final nextAvatarFile = avatarFile == _unset
        ? this.avatarFile
        : avatarFile as XFile?;
    final nextCoverFile = coverFile == _unset
        ? this.coverFile
        : coverFile as XFile?;
    final nextAvatarWebUrl = avatarWebUrl == _unset
        ? this.avatarWebUrl
        : avatarWebUrl as String?;
    final nextCoverWebUrl = coverWebUrl == _unset
        ? this.coverWebUrl
        : coverWebUrl as String?;

    return TenantAdminAccountProfileCreateDraft(
      selectedProfileType: nextSelectedProfileType,
      avatarFile: nextAvatarFile,
      coverFile: nextCoverFile,
      avatarWebUrl: nextAvatarWebUrl,
      coverWebUrl: nextCoverWebUrl,
      avatarBusy: avatarBusy ?? this.avatarBusy,
      coverBusy: coverBusy ?? this.coverBusy,
      contactMode: contactMode ?? this.contactMode,
      contactChannelDrafts: contactChannelDrafts ?? this.contactChannelDrafts,
      expandedContactCtaDraftKey: expandedContactCtaDraftKey == _unset
          ? this.expandedContactCtaDraftKey
          : expandedContactCtaDraftKey as String?,
      contactBubbleSelection:
          contactBubbleSelection ?? this.contactBubbleSelection,
      contactSourceAccountProfileId: contactSourceAccountProfileId == _unset
          ? this.contactSourceAccountProfileId
          : contactSourceAccountProfileId as String?,
      nestedProfileGroups: nestedProfileGroups ?? this.nestedProfileGroups,
    );
  }
}
