import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/dynamic_footer.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class ImmersiveEventFooter extends StatelessWidget {
  const ImmersiveEventFooter({
    required this.isConfirmedStream,
    required this.activeTabStream,
    required this.onConfirmAttendance,
    required this.onInviteFriends,
    required this.onShowQrCode,
    required this.onFollowArtists,
    required this.onTraceRoute,
    super.key,
  });

  final StreamValue<bool> isConfirmedStream;
  final StreamValue<int> activeTabStream;
  final VoidCallback onConfirmAttendance;
  final VoidCallback onInviteFriends;
  final VoidCallback onShowQrCode;
  final VoidCallback onFollowArtists;
  final VoidCallback onTraceRoute;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: isConfirmedStream,
      builder: (context, isConfirmed) {
        return StreamValueBuilder<int>(
          streamValue: activeTabStream,
          builder: (context, activeTab) {
            // Determine footer mode based on state
            FooterMode mode;
            VoidCallback onPressed;

            if (!isConfirmed) {
              mode = FooterMode.buyTicket;
              onPressed = onConfirmAttendance;
            } else {
              // Confirmed user - change based on section
              switch (activeTab) {
                case 0: // Sua Galera
                  mode = FooterMode.bora;
                  onPressed = onInviteFriends;
                  break;
                case 1: // O Rolê
                  mode = FooterMode.viewQrCode;
                  onPressed = onShowQrCode;
                  break;
                case 2: // Line-up
                  mode = FooterMode.followArtists;
                  onPressed = onFollowArtists;
                  break;
                case 3: // O Local
                  mode = FooterMode.traceRoute;
                  onPressed = onTraceRoute;
                  break;
                default:
                  mode = FooterMode.bora;
                  onPressed = () {};
              }
            }

            return DynamicFooter(
              mode: mode,
              onActionPressed: onPressed,
            );
          },
        );
      },
    );
  }
}
