import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/invites/invite_contact_phone_normalization.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume_with_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_external_contact_share_target.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_external_contact_card.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_app_bar_title.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_event_hero.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_footer.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_friend_card.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_relation_filter_chips.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_summary.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:url_launcher/url_launcher.dart';

typedef InviteExternalUrlLauncher = Future<bool> Function(Uri uri,
    {required LaunchMode mode});
typedef InviteSystemShareLauncher = Future<void> Function(ShareParams params);

class InviteShareScreen extends StatefulWidget {
  const InviteShareScreen({
    super.key,
    required this.invite,
    this.externalUrlLauncher,
    this.systemShareLauncher,
  });

  final InviteModel invite;
  final InviteExternalUrlLauncher? externalUrlLauncher;
  final InviteSystemShareLauncher? systemShareLauncher;

  @override
  State<InviteShareScreen> createState() => _InviteShareScreenState();
}

class _InviteShareScreenState extends State<InviteShareScreen> {
  late final InviteShareScreenController _controller =
      GetIt.I.get<InviteShareScreenController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _controller.setContactRegionCodeIfAbsent(_currentCountryCode());
      unawaited(_controller.init(widget.invite));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InviteShareAppBarTitle(invite: widget.invite),
        actions: [
          IconButton(
            tooltip: 'Gerenciar grupos',
            onPressed: _openGroupManagement,
            icon: const Icon(Icons.group),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamValueBuilder<String?>(
          streamValue: _controller.selectedInviteableReasonStreamValue,
          builder: (context, selectedReason) {
            return StreamValueBuilder<List<SentInviteStatus>>(
              streamValue: _controller.sentInvitesStreamValue,
              builder: (context, sentInvites) {
                return StreamValueBuilder<InviteSharePane>(
                  streamValue: _controller.selectedPaneStreamValue,
                  builder: (context, selectedPane) {
                    return StreamValueBuilder<bool>(
                      streamValue:
                          _controller.isPhoneContactsRefreshingStreamValue,
                      builder: (context, isRefreshing) {
                        return StreamValueBuilder<bool>(
                          streamValue:
                              _controller.phoneContactsRefreshFailedStreamValue,
                          builder: (context, hasRefreshFailed) {
                            if (selectedPane == InviteSharePane.app) {
                              return StreamValueBuilder<
                                  List<InviteFriendResumeWithStatus>?>(
                                streamValue:
                                    _controller.friendsSuggestionsStreamValue,
                                onNullWidget: _buildScreenBody(
                                  selectedPane: selectedPane,
                                  phoneContactCount:
                                      _cachedExternalTargets().length,
                                  isRefreshing: isRefreshing,
                                  hasRefreshFailed: hasRefreshFailed,
                                  availableReasons: const <String>[],
                                  selectedReason: selectedReason,
                                  filteredFriends:
                                      const <InviteFriendResumeWithStatus>[],
                                  externalTargets: _cachedExternalTargets(),
                                  isPaneLoading: true,
                                ),
                                builder: (context, friendsWithStatus) {
                                  final resolvedFriendsWithStatus =
                                      friendsWithStatus ??
                                          const <InviteFriendResumeWithStatus>[];
                                  return _buildScreenBody(
                                    selectedPane: selectedPane,
                                    phoneContactCount:
                                        _cachedExternalTargets().length,
                                    isRefreshing: isRefreshing,
                                    hasRefreshFailed: hasRefreshFailed,
                                    availableReasons: _availableReasons(
                                      resolvedFriendsWithStatus,
                                    ),
                                    selectedReason: selectedReason,
                                    filteredFriends: _filterFriends(
                                      resolvedFriendsWithStatus,
                                      selectedReason,
                                    ),
                                    externalTargets: _cachedExternalTargets(),
                                    isPaneLoading: false,
                                  );
                                },
                              );
                            }

                            return StreamValueBuilder<
                                List<InviteExternalContactShareTarget>?>(
                              streamValue:
                                  _controller.externalContactShareTargetsStreamValue,
                              onNullWidget: _buildScreenBody(
                                selectedPane: selectedPane,
                                phoneContactCount: 0,
                                isRefreshing: isRefreshing,
                                hasRefreshFailed: hasRefreshFailed,
                                availableReasons: _availableReasons(
                                  _cachedFriendsWithStatus(),
                                ),
                                selectedReason: selectedReason,
                                filteredFriends: _filterFriends(
                                  _cachedFriendsWithStatus(),
                                  selectedReason,
                                ),
                                externalTargets:
                                    const <InviteExternalContactShareTarget>[],
                                isPaneLoading: true,
                              ),
                              builder: (context, externalTargets) {
                                final resolvedExternalTargets = externalTargets ??
                                    const <InviteExternalContactShareTarget>[];
                                return _buildScreenBody(
                                  selectedPane: selectedPane,
                                  phoneContactCount:
                                      resolvedExternalTargets.length,
                                  isRefreshing: isRefreshing,
                                  hasRefreshFailed: hasRefreshFailed,
                                  availableReasons: _availableReasons(
                                    _cachedFriendsWithStatus(),
                                  ),
                                  selectedReason: selectedReason,
                                  filteredFriends: _filterFriends(
                                    _cachedFriendsWithStatus(),
                                    selectedReason,
                                  ),
                                  externalTargets: resolvedExternalTargets,
                                  isPaneLoading: false,
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildScreenBody({
    required InviteSharePane selectedPane,
    required int phoneContactCount,
    required bool isRefreshing,
    required bool hasRefreshFailed,
    required List<String> availableReasons,
    required String? selectedReason,
    required List<InviteFriendResumeWithStatus> filteredFriends,
    required List<InviteExternalContactShareTarget> externalTargets,
    required bool isPaneLoading,
  }) {
    return Column(
      children: [
        Expanded(
          child: _buildScrollableContent(
            selectedPane: selectedPane,
            phoneContactCount: phoneContactCount,
            isRefreshing: isRefreshing,
            hasRefreshFailed: hasRefreshFailed,
            availableReasons: availableReasons,
            selectedReason: selectedReason,
            filteredFriends: filteredFriends,
            externalTargets: externalTargets,
            isPaneLoading: isPaneLoading,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: StreamValueBuilder<bool>(
            streamValue: _controller.isShareCodeLoadingStreamValue,
            builder: (context, isGeneratingShareCode) {
              return StreamValueBuilder<InviteShareCodeResult?>(
                streamValue: _controller.shareCodeStreamValue,
                builder: (context, shareCode) {
                  return InviteShareFooter(
                    invite: widget.invite,
                    shareUri: _controller.buildShareUri(shareCode),
                    isGeneratingShareCode: isGeneratingShareCode,
                    onRetryShareCode: _controller.reloadShareCode,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<InviteFriendResumeWithStatus> _cachedFriendsWithStatus() =>
      _controller.friendsSuggestionsStreamValue.value ??
      const <InviteFriendResumeWithStatus>[];

  List<InviteExternalContactShareTarget> _cachedExternalTargets() =>
      _controller.externalContactShareTargetsStreamValue.value ??
      const <InviteExternalContactShareTarget>[];

  Widget _buildScrollableContent({
    required InviteSharePane selectedPane,
    required int phoneContactCount,
    required bool isRefreshing,
    required bool hasRefreshFailed,
    required List<String> availableReasons,
    required String? selectedReason,
    required List<InviteFriendResumeWithStatus> filteredFriends,
    required List<InviteExternalContactShareTarget> externalTargets,
    required bool isPaneLoading,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _contentItemCount(
        selectedPane: selectedPane,
        availableReasons: availableReasons,
        filteredFriends: filteredFriends,
        externalTargets: externalTargets,
        isPaneLoading: isPaneLoading,
      ),
      itemBuilder: (context, index) {
        return _buildContentItem(
          context: context,
          index: index,
          selectedPane: selectedPane,
          phoneContactCount: phoneContactCount,
          isRefreshing: isRefreshing,
          hasRefreshFailed: hasRefreshFailed,
          availableReasons: availableReasons,
          selectedReason: selectedReason,
          filteredFriends: filteredFriends,
          externalTargets: externalTargets,
          isPaneLoading: isPaneLoading,
        );
      },
    );
  }

  int _contentItemCount({
    required InviteSharePane selectedPane,
    required List<String> availableReasons,
    required List<InviteFriendResumeWithStatus> filteredFriends,
    required List<InviteExternalContactShareTarget> externalTargets,
    required bool isPaneLoading,
  }) {
    if (isPaneLoading) {
      return 7;
    }
    final paneCount = selectedPane == InviteSharePane.app
        ? _appPaneItemCount(
            availableReasons: availableReasons,
            filteredFriends: filteredFriends,
          )
        : _phonePaneItemCount(externalTargets);
    return 6 + paneCount;
  }

  Widget _buildContentItem({
    required BuildContext context,
    required int index,
    required InviteSharePane selectedPane,
    required int phoneContactCount,
    required bool isRefreshing,
    required bool hasRefreshFailed,
    required List<String> availableReasons,
    required String? selectedReason,
    required List<InviteFriendResumeWithStatus> filteredFriends,
    required List<InviteExternalContactShareTarget> externalTargets,
    required bool isPaneLoading,
  }) {
    switch (index) {
      case 0:
        return InviteEventHero(invite: widget.invite);
      case 1:
      case 3:
      case 5:
        return const SizedBox(height: 16);
      case 2:
        return StreamValueBuilder<List<SentInviteStatus>>(
          streamValue: _controller.sentInvitesStreamValue,
          builder: (context, invites) => InviteShareSummary(invites: invites),
        );
      case 4:
        return _buildControls(
          selectedPane: selectedPane,
          phoneContactCount: phoneContactCount,
          isRefreshing: isRefreshing,
          hasRefreshFailed: hasRefreshFailed,
        );
      default:
        final paneIndex = index - 6;
        if (selectedPane == InviteSharePane.app) {
          return _buildAppPaneItem(
            context: context,
            index: paneIndex,
            availableReasons: availableReasons,
            selectedReason: selectedReason,
            filteredFriends: filteredFriends,
            isLoading: isPaneLoading,
          );
        }
        return _buildPhonePaneItem(
          context: context,
          index: paneIndex,
          externalTargets: externalTargets,
          isLoading: isPaneLoading,
        );
    }
  }

  Widget _buildControls({
    required InviteSharePane selectedPane,
    required int phoneContactCount,
    required bool isRefreshing,
    required bool hasRefreshFailed,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<InviteSharePane>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment<InviteSharePane>(
              value: InviteSharePane.app,
              icon: Icon(Icons.people_alt_outlined),
              label: Text(_controller.appPaneLabel),
            ),
            ButtonSegment<InviteSharePane>(
              value: InviteSharePane.phone,
              icon: Icon(Icons.contact_phone_outlined),
              label: Text('Agenda'),
            ),
          ],
          selected: {selectedPane},
          onSelectionChanged: (selection) {
            unawaited(_controller.selectPane(selection.single));
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            if (selectedPane == InviteSharePane.phone)
              TextButton.icon(
                onPressed:
                    isRefreshing ? null : _controller.refreshPhoneContacts,
                icon: isRefreshing
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  isRefreshing ? 'Atualizando...' : 'Atualizar agenda',
                ),
              ),
          ],
        ),
        if (selectedPane == InviteSharePane.phone && hasRefreshFailed)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Não foi possível atualizar agora',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
          ),
        if (selectedPane == InviteSharePane.phone && phoneContactCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                phoneContactCount == 1
                    ? '1 contato'
                    : '$phoneContactCount contatos',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  int _appPaneItemCount({
    required List<String> availableReasons,
    required List<InviteFriendResumeWithStatus> filteredFriends,
  }) {
    return (availableReasons.isNotEmpty ? 1 : 0) +
        (filteredFriends.isEmpty ? 1 : filteredFriends.length);
  }

  Widget _buildAppPaneItem({
    required BuildContext context,
    required int index,
    required List<String> availableReasons,
    required String? selectedReason,
    required List<InviteFriendResumeWithStatus> filteredFriends,
    required bool isLoading,
  }) {
    if (isLoading) {
      return _buildLoadingState(
        context: context,
        icon: Icons.people_alt_outlined,
        text: 'Carregando pessoas do app...',
      );
    }

    var itemIndex = index;
    if (availableReasons.isNotEmpty) {
      if (itemIndex == 0) {
        return InviteShareRelationFilterChips(
          selectedReason: selectedReason,
          availableReasons: availableReasons,
          onSelectReason: _controller.selectInviteableReason,
        );
      }
      itemIndex -= 1;
    }

    if (filteredFriends.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.person_search_outlined,
        text: 'Nenhum contato convidável para este filtro.',
      );
    }

    final item = filteredFriends[itemIndex];
    return InviteShareFriendCard(
      key: ValueKey(_inviteableCardKey(item.friend)),
      friend: item.friend,
      status: item.inviteStatus,
      onInvite: () => _controller.sendInviteToFriend(item.friend),
      isPlaceholder: false,
    );
  }

  int _phonePaneItemCount(List<InviteExternalContactShareTarget> targets) {
    return targets.isEmpty ? 1 : targets.length;
  }

  Widget _buildPhonePaneItem({
    required BuildContext context,
    required int index,
    required List<InviteExternalContactShareTarget> externalTargets,
    required bool isLoading,
  }) {
    return StreamValueBuilder<InviteShareCodeResult?>(
      streamValue: _controller.shareCodeStreamValue,
      builder: (context, shareCode) {
        final shareUri = _controller.buildShareUri(shareCode);
        if (isLoading) {
          return _buildLoadingState(
            context: context,
            icon: Icons.contact_phone_outlined,
            text: 'Carregando agenda...',
          );
        }
        if (externalTargets.isEmpty) {
          return _buildEmptyState(
            context: context,
            icon: Icons.contact_phone_outlined,
            text: 'Nenhum contato do telefone disponível.',
          );
        }

        final target = externalTargets[index];
        return InviteExternalContactCard(
          key: ValueKey('external-contact:${target.id}'),
          target: target,
          onShare: shareUri == null
              ? null
              : () => unawaited(_shareWithExternalContact(target, shareUri)),
        );
      },
    );
  }

  String _inviteableCardKey(InviteFriendResume friend) {
    final accountProfileId = friend.accountProfileId.trim();
    if (accountProfileId.isNotEmpty) {
      return 'inviteable-account-profile:$accountProfileId';
    }
    return 'inviteable-user:${friend.id}';
  }

  Widget _buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Icon(icon, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  List<InviteFriendResumeWithStatus> _filterFriends(
    List<InviteFriendResumeWithStatus> friends,
    String? selectedReason,
  ) {
    final reason = selectedReason?.trim();
    if (reason == null || reason.isEmpty) {
      return friends;
    }
    return friends
        .where((item) => item.friend.inviteableReasons.contains(reason))
        .toList(growable: false);
  }

  List<String> _availableReasons(List<InviteFriendResumeWithStatus> friends) {
    const order = <String>[
      'contact_match',
      'favorite_by_you',
      'favorited_you',
      'friend',
    ];
    final available = <String>{
      for (final item in friends) ...item.friend.inviteableReasons,
    };
    return order.where(available.contains).toList(growable: false);
  }

  void _openGroupManagement() {
    context.router.push(const ContactGroupManagementRoute());
  }

  Future<void> _shareWithExternalContact(
    InviteExternalContactShareTarget target,
    Uri shareUri,
  ) async {
    final text = _buildShareText(shareUri);
    final whatsappUri = _buildWhatsappUri(target, text);

    if (whatsappUri != null &&
        await _launchExternalUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        )) {
      return;
    }

    await _shareSystem(ShareParams(text: text, subject: 'Convite Belluga Now'));
  }

  Uri? _buildWhatsappUri(InviteExternalContactShareTarget target, String text) {
    final phone = target.primaryPhone == null
        ? null
        : InviteContactPhoneNormalization.preferredWhatsAppTarget(
            target.primaryPhone!,
            regionCode:
                _controller.debugContactRegionCodeValue ?? _currentCountryCode(),
          );
    if (phone == null || phone.isEmpty) {
      return null;
    }
    return Uri.https('wa.me', '/$phone', {'text': text});
  }

  String? _currentCountryCode() {
    final countryCode = Localizations.maybeLocaleOf(context)?.countryCode ??
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    if (countryCode == null || countryCode.trim().isEmpty) {
      return null;
    }
    return countryCode.trim().toUpperCase();
  }

  Future<bool> _launchExternalUrl(Uri uri, {required LaunchMode mode}) =>
      widget.externalUrlLauncher?.call(uri, mode: mode) ??
      launchUrl(uri, mode: mode);

  Future<void> _shareSystem(ShareParams params) async {
    final launcher = widget.systemShareLauncher;
    if (launcher != null) {
      await launcher(params);
      return;
    }

    await SharePlus.instance.share(params);
  }

  String _buildShareText(Uri shareUri) {
    final localEventDate = TimezoneConverter.utcToLocal(
      widget.invite.eventDateTime,
    );
    return 'Bora? ${widget.invite.eventName} em ${widget.invite.location} no dia $localEventDate.'
        '\nDetalhes: $shareUri';
  }
}
