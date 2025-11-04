import 'package:belluga_now/domain/invites/invite_friend_model.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class InviteShareScreen extends StatefulWidget {
  const InviteShareScreen({
    super.key,
    required this.invite,
    required this.friends,
  });

  final InviteModel invite;
  final List<InviteFriendModel> friends;

  @override
  State<InviteShareScreen> createState() => _InviteShareScreenState();
}

class _InviteShareScreenState extends State<InviteShareScreen> {
  late final Set<String> _selectedFriendIds =
      widget.friends.take(3).map((friend) => friend.id).toSet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('EEE, d MMM - HH:mm');
    final formattedDate =
        dateFormatter.format(widget.invite.eventDateTime.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convidar Amigos'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _EventSummary(
              invite: widget.invite,
              formattedDate: formattedDate,
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                itemBuilder: (context, index) {
                  final friend = widget.friends[index];
                  final isSelected = _selectedFriendIds.contains(friend.id);
                  return ListTile(
                    onTap: () => _toggle(friend.id),
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(friend.avatarUrl),
                    ),
                    title: Text(friend.name),
                    subtitle: Text(friend.matchLabel),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggle(friend.id),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const Divider(),
                itemCount: widget.friends.length,
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
                onPressed: _onSendInternalInvites,
                icon: const Icon(Icons.people_alt_outlined),
                label: Text(
                  _selectedFriendIds.isEmpty
                      ? 'Enviar convites internos'
                      : 'Enviar convites internos (${_selectedFriendIds.length})',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _shareExternally,
                icon: const Icon(Icons.ios_share),
                label: const Text('Compartilhar convite'),
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

  void _toggle(String friendId) {
    setState(() {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
      } else {
        _selectedFriendIds.add(friendId);
      }
    });
  }

  void _onSendInternalInvites() {
    final count = _selectedFriendIds.length;
    final message = count == 0
        ? 'Selecione pelo menos um amigo para enviar o convite.'
        : 'Convite marcado para $count contato(s) dentro do app.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _shareExternally() async {
    final invite = widget.invite;
    final date =
        DateFormat('d MMM, HH:mm').format(invite.eventDateTime.toLocal());
    final shareMessage =
        'Bora? ${invite.eventName} em ${invite.location} no dia $date.\n'
        'Detalhes: https://belluga.now/invite/${invite.id}';

    await Share.share(
      shareMessage,
      subject: 'Convite Belluga Now',
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

class _EventSummary extends StatelessWidget {
  const _EventSummary({
    required this.invite,
    required this.formattedDate,
  });

  final InviteModel invite;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  invite.eventImageUrl,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.eventName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            invite.location,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: invite.tags
                .map(
                  (tag) => Chip(
                    label: Text('#$tag'),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
