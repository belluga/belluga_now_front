import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_choice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DirectionsAppChooserSheet extends StatefulWidget {
  const DirectionsAppChooserSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.loadOptions,
    this.onLaunchFailure,
  });

  final String title;
  final String subtitle;
  final Future<List<DirectionsAppChoice>> Function() loadOptions;
  final VoidCallback? onLaunchFailure;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Future<List<DirectionsAppChoice>> Function() loadOptions,
    VoidCallback? onLaunchFailure,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DirectionsAppChooserSheet(
          title: title,
          subtitle: subtitle,
          loadOptions: loadOptions,
          onLaunchFailure: onLaunchFailure,
        );
      },
    );
  }

  @override
  State<DirectionsAppChooserSheet> createState() =>
      _DirectionsAppChooserSheetState();
}

class _DirectionsAppChooserSheetState extends State<DirectionsAppChooserSheet> {
  bool _isLoading = true;
  List<DirectionsAppChoice> _options = const <DirectionsAppChoice>[];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 56,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 2,
                      right: 0,
                      child: IconButton(
                        key: const Key('directionsChooserCloseButton'),
                        onPressed: () => context.router.maybePop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Fechar',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.92,
                          ),
                          foregroundColor: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Flexible(
                  child: Builder(
                    builder: (context) {
                      if (_isLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (_errorMessage.trim().isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: _options.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final option = _options[index];
                          return _DirectionsAppChoiceTile(
                            option: option,
                            onTap: () async {
                              context.router.maybePop();
                              final launched = await option.onSelected();
                              if (!launched) {
                                widget.onLaunchFailure?.call();
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadOptions() async {
    try {
      final options = await widget.loadOptions();
      if (!mounted) {
        return;
      }
      setState(() {
        if (options.isEmpty) {
          _errorMessage = 'Nenhum aplicativo disponível para abrir esta rota.';
          _options = const <DirectionsAppChoice>[];
        } else {
          _errorMessage = '';
          _options = options;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Não foi possível preparar os aplicativos de rota.';
        _options = const <DirectionsAppChoice>[];
        _isLoading = false;
      });
    }
  }
}

class _DirectionsAppChoiceTile extends StatelessWidget {
  const _DirectionsAppChoiceTile({
    required this.option,
    required this.onTap,
  });

  final DirectionsAppChoice option;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          unawaited(onTap());
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: _DirectionsAppChoiceLeading(option: option),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionsAppChoiceLeading extends StatelessWidget {
  const _DirectionsAppChoiceLeading({
    required this.option,
  });

  final DirectionsAppChoice option;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (option.visualType == DirectionsAppVisualType.mapAsset &&
        option.assetPath != null) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: SvgPicture.asset(
          option.assetPath!,
          colorFilter: ColorFilter.mode(
            colorScheme.onSecondaryContainer,
            BlendMode.srcIn,
          ),
        ),
      );
    }

    return Icon(
      directionsChoiceIcon(option.visualType),
      color: colorScheme.onSecondaryContainer,
    );
  }
}
