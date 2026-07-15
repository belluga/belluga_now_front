import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_gallery_group_draft.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
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
    required this.contactMode,
    this.contactChannelDrafts = const <BellugaContactChannelDraft>[],
    this.expandedContactCtaDraftKey,
    this.contactBubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
    this.contactSourceAccountProfileId,
    this.galleryGroups = const <TenantAdminAccountProfileGalleryGroupDraft>[],
    this.nestedProfileGroups = const <TenantAdminNestedProfileGroup>[],
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
        contactMode: BellugaContactSourceMode.own,
        contactChannelDrafts: <BellugaContactChannelDraft>[],
        expandedContactCtaDraftKey: null,
        contactBubbleSelection: BellugaContactBubbleSelectionMutation.omit(),
        contactSourceAccountProfileId: null,
        galleryGroups: <TenantAdminAccountProfileGalleryGroupDraft>[],
        nestedProfileGroups: <TenantAdminNestedProfileGroup>[],
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
  final BellugaContactSourceMode contactMode;
  final List<BellugaContactChannelDraft> contactChannelDrafts;
  final String? expandedContactCtaDraftKey;
  final BellugaContactBubbleSelectionMutation contactBubbleSelection;
  final String? contactSourceAccountProfileId;
  final List<TenantAdminAccountProfileGalleryGroupDraft> galleryGroups;
  final List<TenantAdminNestedProfileGroup> nestedProfileGroups;

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
    BellugaContactSourceMode? contactMode,
    List<BellugaContactChannelDraft>? contactChannelDrafts,
    Object? expandedContactCtaDraftKey = _unset,
    BellugaContactBubbleSelectionMutation? contactBubbleSelection,
    Object? contactSourceAccountProfileId = _unset,
    List<TenantAdminAccountProfileGalleryGroupDraft>? galleryGroups,
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
      galleryGroups: galleryGroups ?? this.galleryGroups,
      nestedProfileGroups: nestedProfileGroups ?? this.nestedProfileGroups,
    );
  }

  TenantAdminAccountProfileEditDraft syncRemoteState(
    TenantAdminAccountProfile updated,
  ) {
    final avatarUrl = updated.avatarUrl;
    final coverUrl = updated.coverUrl;
    final contactChannelDrafts = updated.contactChannels
        .map(BellugaContactChannelDraft.fromChannel)
        .toList(growable: false);
    return copyWith(
      avatarRemoteUrl: avatarUrl,
      coverRemoteUrl: coverUrl,
      avatarRemoteReady: false,
      coverRemoteReady: false,
      avatarRemoteError: false,
      coverRemoteError: false,
      avatarPreloadUrl: null,
      coverPreloadUrl: null,
      contactMode: updated.contactMode,
      contactSourceAccountProfileId: updated.contactSourceAccountProfileId,
      contactChannelDrafts: contactChannelDrafts,
      expandedContactCtaDraftKey: _expandedCtaDraftKeyFor(contactChannelDrafts),
      contactBubbleSelection: updated.contactBubbleChannelId == null
          ? const BellugaContactBubbleSelectionMutation.clear()
          : BellugaContactBubbleSelectionMutation.setPersisted(
              updated.contactBubbleChannelId!,
            ),
      galleryGroups: updated.galleryGroups
          .map(TenantAdminAccountProfileGalleryGroupDraft.fromRead)
          .toList(growable: false),
      nestedProfileGroups: updated.nestedProfileGroups,
    );
  }

  String? _expandedCtaDraftKeyFor(
    List<BellugaContactChannelDraft> contactChannelDrafts,
  ) {
    final currentKey = expandedContactCtaDraftKey;
    if (currentKey != null &&
        contactChannelDrafts.any((draft) => draft.draftKey == currentKey)) {
      return currentKey;
    }

    for (final draft in contactChannelDrafts) {
      if (draft.definition.capabilities.messagePresets &&
          draft.initialMessages.isNotEmpty) {
        return draft.draftKey;
      }
    }
    return null;
  }
}
