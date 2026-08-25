import 'dart:async';

import 'package:belluga_now/presentation/shared/widgets/controllers/public_rich_text_link_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class PublicRichTextHtml extends StatefulWidget {
  const PublicRichTextHtml({
    super.key,
    required this.html,
    this.style,
    this.launcher,
  });
  final String html;
  final Map<String, Style>? style;
  final PublicRichTextUrlLauncher? launcher;

  @override
  State<PublicRichTextHtml> createState() => _PublicRichTextHtmlState();
}

class _PublicRichTextHtmlState extends State<PublicRichTextHtml> {
  late PublicRichTextLinkController _linkController;
  StreamSubscription<void>? _failureSubscription;
  ScaffoldMessengerState? _messenger;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant PublicRichTextHtml oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.launcher == widget.launcher) return;
    _unbindController();
    _bindController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  void _bindController() {
    _linkController = PublicRichTextLinkController(launcher: widget.launcher);
    _failureSubscription = _linkController.failureEffects.listen((_) {
      _messenger?.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    });
  }

  void _unbindController() {
    final failureSubscription = _failureSubscription;
    if (failureSubscription != null) {
      unawaited(failureSubscription.cancel());
    }
    _failureSubscription = null;
    _linkController.dispose();
  }

  @override
  void dispose() {
    _messenger = null;
    _unbindController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkColor = _contrastSafeLinkColor(
      theme.colorScheme.primary,
      theme.scaffoldBackgroundColor,
      theme.colorScheme.onSurface,
    );
    return Html(
      data: widget.html,
      style: <String, Style>{
        'a': Style(
          color: linkColor,
          textDecoration: TextDecoration.underline,
          textDecorationColor: linkColor,
        ),
        ...?widget.style,
      },
      onLinkTap: (url, _, _) => unawaited(_linkController.launch(url)),
    );
  }
}

Color _contrastSafeLinkColor(Color primary, Color surface, Color onSurface) {
  if (_contrastRatio(primary, surface) >= 4.5) return primary;

  // Keep the theme's primary hue for as long as possible, moving only as far
  // toward its own on-surface color as WCAG AA requires.
  for (var step = 1; step <= 32; step++) {
    final candidate = Color.lerp(primary, onSurface, step / 32)!;
    if (_contrastRatio(candidate, surface) >= 4.5) return candidate;
  }
  return onSurface;
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
