import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/widgets/contact_selection_list.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/widgets/friend_selection_list.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/widgets/invite_event_summary.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stream_value/main.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteShareScreen extends StatefulWidget {
  const InviteShareScreen({
    super.key,
    required this.invite,
  });

  final InviteModel invite;

  @override
  State<InviteShareScreen> createState() => _InviteShareScreenState();
}

class _InviteShareScreenState extends State<InviteShareScreen>
    with SingleTickerProviderStateMixin {
  final _controller = GetIt.I.get<InviteShareScreenController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.init(widget.invite.eventId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEE, d MMM - HH:mm');
    final formattedDate =
        dateFormatter.format(widget.invite.eventDateTime.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convidar Amigos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Amigos Belluga'),
            Tab(text: 'Contatos'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.refreshFriends,
            tooltip: 'Atualizar lista',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            InviteEventSummary(
              invite: widget.invite,
              formattedDate: formattedDate,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  FriendSelectionList(),
                  ContactSelectionList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _tabController.index == 0
                    ? _onSendInternalInvites
                    : _onSendSMSInvites,
                icon: Icon(_tabController.index == 0
                    ? Icons.people_alt_outlined
                    : Icons.sms_outlined),
                label: _tabController.index == 0
                    ? StreamValueBuilder<List<InviteFriendResume>>(
                        streamValue:
                            _controller.selectedFriendsSuggestionsStreamValue,
                        builder: (context, selectedFriends) {
                          return Text(
                            selectedFriends.isEmpty
                                ? 'Convidar amigos'
                                : 'Convidar (${selectedFriends.length}) amigos!',
                          );
                        })
                    : StreamValueBuilder<List<ContactModel>>(
                        streamValue: _controller.selectedContactsStreamValue,
                        builder: (context, selectedContacts) {
                          return Text(
                            selectedContacts.isEmpty
                                ? 'Convidar contatos'
                                : 'Convidar (${selectedContacts.length}) via SMS',
                          );
                        }),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _shareExternally,
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Convidar amigos'),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _copyLink(context),
                icon: const Icon(Icons.copy),
                label: const Text('Copiar link'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSendInternalInvites() async {
    final count =
        _controller.selectedFriendsSuggestionsStreamValue.value.length;

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um amigo para enviar o convite.'),
        ),
      );
      return;
    }

    try {
      await _controller.sendInvites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Convite enviado para $count amigo(s)!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar convites. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onSendSMSInvites() async {
    final selectedContacts = _controller.selectedContactsStreamValue.value;
    if (selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um contato.'),
        ),
      );
      return;
    }

    final invite = widget.invite;
    final date =
        DateFormat('d MMM, HH:mm').format(invite.eventDateTime.toLocal());
    final message =
        'Bora? ${invite.eventName} em ${invite.location} no dia $date.\n'
        'Detalhes: https://belluga.now/invite/${invite.id}';

    final phones = selectedContacts
        .expand((c) => c.phones)
        .map((p) => p.replaceAll(RegExp(r'[^\d+]'), ''))
        .join(',');

    final uri = Uri.parse('sms:$phones?body=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await SharePlus.instance.share(
        ShareParams(text: message, subject: 'Convite Belluga Now'),
      );
    }
  }

  Future<void> _shareExternally() async {
    final invite = widget.invite;
    final date =
        DateFormat('d MMM, HH:mm').format(invite.eventDateTime.toLocal());
    final shareMessage =
        'Bora? ${invite.eventName} em ${invite.location} no dia $date.\n'
        'Detalhes: https://belluga.now/invite/${invite.id}';

    await SharePlus.instance.share(
      ShareParams(text: shareMessage, subject: 'Convite Belluga Now'),
    );
  }

  void _copyLink(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado para a area de transferencia.'),
      ),
    );
  }
}
