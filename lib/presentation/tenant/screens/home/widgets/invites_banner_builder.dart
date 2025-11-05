import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant/screens/home/controller/invites_banner_builder_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/main.dart';

class InvitesBannerBuilder extends StatefulWidget {
  final EdgeInsets? margin;

  const InvitesBannerBuilder({super.key, required this.onPressed, this.margin});

  final VoidCallback onPressed;

  @override
  State<InvitesBannerBuilder> createState() => _InvitesBannerBuilderState();
}

class _InvitesBannerBuilderState extends State<InvitesBannerBuilder> {
  final _controller = InvitesBannerBuilderController();

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return StreamValueBuilder<List<InviteModel>>(
      streamValue: _controller.pendingInvitesStreamValue,
      onNullWidget: SizedBox.shrink(),
      builder: (context, invites) {

        if(invites.isEmpty) {
          return const SizedBox.shrink();
        } 

        return Container(
          margin: widget.margin,
          child: Card(
            elevation: 0,
            color: theme.colorScheme.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Você tem ${invites.length} convites pendentes',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chame sua galera ou descubra quem ja confirmou.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondary.withValues(
                              alpha: 0.85,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onPressed,
                    style: TextButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      shape: const StadiumBorder(),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.rocket_launch_outlined,
                          size: 16,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Bora?',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
