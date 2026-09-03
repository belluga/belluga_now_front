import 'package:belluga_now/application/icons/account_profile_external_link_icon_registry.dart';
import 'package:belluga_now/domain/partners/account_profile_external_link.dart';
import 'package:flutter/material.dart';

class AccountProfileExternalLinkStrip extends StatelessWidget {
  const AccountProfileExternalLinkStrip({
    super.key,
    required this.links,
    required this.onOpen,
  });

  final List<AccountProfileExternalLink> links;
  final ValueChanged<AccountProfileExternalLink> onOpen;

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      key: const Key('accountProfileExternalLinkStrip'),
      color: colorScheme.surface,
      child: SizedBox(
        height: 64,
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < links.length; index++) ...[
                  if (index > 0) const SizedBox(width: 12),
                  _ExternalLinkButton(
                    link: links[index],
                    onPressed: () => onOpen(links[index]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExternalLinkButton extends StatelessWidget {
  const _ExternalLinkButton({required this.link, required this.onPressed});

  final AccountProfileExternalLink link;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Abrir ${link.label}',
      child: IconButton.filledTonal(
        key: ValueKey('accountProfileExternalLink-${link.id}'),
        tooltip: link.label,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSecondaryContainer,
          backgroundColor: colorScheme.secondaryContainer,
        ),
        onPressed: onPressed,
        icon: Icon(
          AccountProfileExternalLinkIconRegistry.iconFor(link.type),
          size: 22,
        ),
      ),
    );
  }
}
