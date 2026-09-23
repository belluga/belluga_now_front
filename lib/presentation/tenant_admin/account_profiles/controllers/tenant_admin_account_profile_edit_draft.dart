import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'dart:typed_data';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_gallery_group_draft.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_capabilities.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:image_picker/image_picker.dart';

class TenantAdminAccountProfileEditDraft {
  static const _unset = Object();

  const TenantAdminAccountProfileEditDraft({
    required this.selectedProfileType,
    required this.avatarFile,
    required this.coverFile,
    required this.avatarRemoteBytes,
    required this.coverRemoteBytes,
    required this.avatarRemoteLoadFailed,
    required this.coverRemoteLoadFailed,
    required this.avatarBusy,
    required this.coverBusy,
    required this.contactMode,
    this.contactChannelDrafts = const <BellugaContactChannelDraft>[],
    this.expandedContactCtaDraftKey,
    this.contactBubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
    this.contactSourceAccountProfileId,
    this.galleryGroups = const <TenantAdminAccountProfileGalleryGroupDraft>[],
    required this.galleryCapabilities,
    this.nestedProfileGroups = const <TenantAdminNestedProfileGroup>[],
  });

  factory TenantAdminAccountProfileEditDraft.initial() =>
      TenantAdminAccountProfileEditDraft(
        selectedProfileType: null,
        avatarFile: null,
        coverFile: null,
        avatarRemoteBytes: null,
        coverRemoteBytes: null,
        avatarRemoteLoadFailed: false,
        coverRemoteLoadFailed: false,
        avatarBusy: false,
        coverBusy: false,
        contactMode: BellugaContactSourceMode.own,
        contactChannelDrafts: <BellugaContactChannelDraft>[],
        expandedContactCtaDraftKey: null,
        contactBubbleSelection: BellugaContactBubbleSelectionMutation.omit(),
        contactSourceAccountProfileId: null,
        galleryGroups: <TenantAdminAccountProfileGalleryGroupDraft>[],
        galleryCapabilities:
            TenantAdminAccountProfileGalleryCapabilities.empty(),
        nestedProfileGroups: <TenantAdminNestedProfileGroup>[],
      );

  final String? selectedProfileType;
  final XFile? avatarFile;
  final XFile? coverFile;
  final Uint8List? avatarRemoteBytes;
  final Uint8List? coverRemoteBytes;
  final bool avatarRemoteLoadFailed;
  final bool coverRemoteLoadFailed;
  final bool avatarBusy;
  final bool coverBusy;
  final BellugaContactSourceMode contactMode;
  final List<BellugaContactChannelDraft> contactChannelDrafts;
  final String? expandedContactCtaDraftKey;
  final BellugaContactBubbleSelectionMutation contactBubbleSelection;
  final String? contactSourceAccountProfileId;
  final List<TenantAdminAccountProfileGalleryGroupDraft> galleryGroups;
  final TenantAdminAccountProfileGalleryCapabilities galleryCapabilities;
  final List<TenantAdminNestedProfileGroup> nestedProfileGroups;

  TenantAdminAccountProfileEditDraft copyWith({
    Object? selectedProfileType = _unset,
    Object? avatarFile = _unset,
    Object? coverFile = _unset,
    Object? avatarRemoteBytes = _unset,
    Object? coverRemoteBytes = _unset,
    bool? avatarRemoteLoadFailed,
    bool? coverRemoteLoadFailed,
    bool? avatarBusy,
    bool? coverBusy,
    BellugaContactSourceMode? contactMode,
    List<BellugaContactChannelDraft>? contactChannelDrafts,
    Object? expandedContactCtaDraftKey = _unset,
    BellugaContactBubbleSelectionMutation? contactBubbleSelection,
    Object? contactSourceAccountProfileId = _unset,
    List<TenantAdminAccountProfileGalleryGroupDraft>? galleryGroups,
    TenantAdminAccountProfileGalleryCapabilities? galleryCapabilities,
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
    final nextAvatarRemoteBytes = avatarRemoteBytes == _unset
        ? this.avatarRemoteBytes
        : avatarRemoteBytes as Uint8List?;
    final nextCoverRemoteBytes = coverRemoteBytes == _unset
        ? this.coverRemoteBytes
        : coverRemoteBytes as Uint8List?;

    return TenantAdminAccountProfileEditDraft(
      selectedProfileType: nextSelectedProfileType,
      avatarFile: nextAvatarFile,
      coverFile: nextCoverFile,
      avatarRemoteBytes: nextAvatarRemoteBytes,
      coverRemoteBytes: nextCoverRemoteBytes,
      avatarRemoteLoadFailed:
          avatarRemoteLoadFailed ?? this.avatarRemoteLoadFailed,
      coverRemoteLoadFailed:
          coverRemoteLoadFailed ?? this.coverRemoteLoadFailed,
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
      galleryCapabilities: galleryCapabilities ?? this.galleryCapabilities,
      nestedProfileGroups: nestedProfileGroups ?? this.nestedProfileGroups,
    );
  }

  TenantAdminAccountProfileEditDraft syncRemoteState(
    TenantAdminAccountProfile updated,
  ) {
    final contactChannelDrafts = updated.contactChannels
        .map(BellugaContactChannelDraft.fromChannel)
        .toList(growable: false);
    return copyWith(
      avatarRemoteBytes: null,
      coverRemoteBytes: null,
      avatarRemoteLoadFailed: false,
      coverRemoteLoadFailed: false,
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
      galleryCapabilities: updated.galleryCapabilities,
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
