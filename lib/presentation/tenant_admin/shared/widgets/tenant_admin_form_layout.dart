import 'package:flutter/material.dart';

class TenantAdminFormScaffold extends StatelessWidget {
  const TenantAdminFormScaffold({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.maxContentWidth = 760,
  });

  final String title;
  final Widget child;
  final Widget? leading;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: leading,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class TenantAdminFormSectionCard extends StatelessWidget {
  const TenantAdminFormSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class TenantAdminPrimaryFormAction extends StatelessWidget {
  const TenantAdminPrimaryFormAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.buttonKey,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: icon == null
          ? FilledButton(
              key: buttonKey,
              onPressed: onPressed,
              child: Text(label),
            )
          : FilledButton.icon(
              key: buttonKey,
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}
