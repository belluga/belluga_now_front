import 'package:flutter/material.dart';

enum FooterMode {
  buyTicket,
  bora,
  viewQrCode,
  followArtists,
  traceRoute,
}

class DynamicFooter extends StatelessWidget {
  const DynamicFooter({
    required this.mode,
    required this.onActionPressed,
    this.leftText,
    this.actionText,
    super.key,
  });

  final FooterMode mode;
  final VoidCallback onActionPressed;
  final String? leftText;
  final String? actionText;

  @override
  Widget build(BuildContext context) {
    final config = _getFooterConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: config.leftWidget != null
            ? Row(
                children: [
                  // Left side (status or price)
                  Expanded(
                    flex: 2,
                    child: config.leftWidget!,
                  ),

                  const SizedBox(width: 12),

                  // Right side (action button)
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: onActionPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: config.buttonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (config.buttonIcon != null) ...[
                            Icon(config.buttonIcon, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            actionText ?? config.buttonText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (config.buttonIcon != null) ...[
                      Icon(config.buttonIcon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      actionText ?? config.buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  _FooterConfig _getFooterConfig() {
    switch (mode) {
      case FooterMode.buyTicket:
        return _FooterConfig(
          leftWidget: null, // Remove price display
          buttonText: 'Bóora! Confirmar Presença!',
          buttonColor: const Color(0xFF9C27B0), // Purple
          buttonIcon: Icons.celebration,
        );

      case FooterMode.bora:
        return _FooterConfig(
          leftWidget: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  leftText ?? 'Tudo certo!\nPresença confirmada.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          buttonText: 'BORA? Agitar a galera!',
          buttonColor: const Color(0xFF9C27B0), // Purple
          buttonIcon: Icons.rocket_launch,
        );

      case FooterMode.viewQrCode:
        return _FooterConfig(
          leftWidget: null,
          buttonText: 'Ver meu QR Code de Acesso',
          buttonColor: Colors.blue,
          buttonIcon: Icons.qr_code,
        );

      case FooterMode.followArtists:
        return _FooterConfig(
          leftWidget: null,
          buttonText: 'Seguir todos os artistas',
          buttonColor: const Color(0xFF6A1B9A), // Deep Purple
          buttonIcon: Icons.star,
        );

      case FooterMode.traceRoute:
        return _FooterConfig(
          leftWidget: null,
          buttonText: 'Traçar Rota agora',
          buttonColor: const Color(0xFF00ACC1), // Cyan
          buttonIcon: Icons.navigation,
        );
    }
  }
}

class _FooterConfig {
  final Widget? leftWidget;
  final String buttonText;
  final Color buttonColor;
  final IconData? buttonIcon;

  _FooterConfig({
    this.leftWidget,
    required this.buttonText,
    required this.buttonColor,
    this.buttonIcon,
  });
}
