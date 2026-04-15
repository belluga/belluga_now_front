import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/boundary_route_dismissal.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/presentation/shared/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/shared/widgets/button_loading.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:get_it/get_it.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({
    super.key,
    this.initialState,
    this.allowContinueWithoutLocation = true,
    this.onResult,
    this.popRouteAfterResult = false,
  });

  final LocationPermissionState? initialState;
  final bool allowContinueWithoutLocation;
  final ValueChanged<LocationPermissionGateResult>? onResult;
  final bool popRouteAfterResult;

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  final LocationPermissionController _controller =
      GetIt.I.get<LocationPermissionController>();

  @override
  void initState() {
    super.initState();
    unawaited(
      _controller.ensureInitialState(
        initialState: widget.initialState,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<LocationPermissionState?>(
      streamValue: _controller.initialStateStreamValue,
      onNullWidget: const Scaffold(
        body: Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      ),
      builder: (context, initialState) {
        final resolvedInitialState = initialState!;
        final primaryLabel = switch (resolvedInitialState) {
          LocationPermissionState.serviceDisabled => 'Ativar localização',
          LocationPermissionState.denied => 'Permitir localização',
          LocationPermissionState.deniedForever =>
            kIsWeb ? 'Tentar novamente' : 'Abrir configurações',
        };
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;

        return StreamValueBuilder<bool?>(
          streamValue: _controller.resultStreamValue,
          builder: (context, result) {
            _handleResult(result);
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) {
                  return;
                }
                unawaited(_finishFlow(LocationPermissionGateResult.cancelled));
              },
              child: Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TopBar(onBackPressed: _onBackPressed),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final content = ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 420),
                                child: resolvedInitialState ==
                                        LocationPermissionState.deniedForever
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _TitleBlock(
                                            textTheme: textTheme,
                                            colorScheme: colorScheme,
                                          ),
                                          const SizedBox(height: 24),
                                          _HeroCard(
                                            colorScheme: colorScheme,
                                            textTheme: textTheme,
                                          ),
                                          const SizedBox(height: 24),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Como liberar:',
                                                  style: textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                ..._deniedForeverSteps().map(
                                                  (step) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      bottom: 6,
                                                    ),
                                                    child: Text(
                                                      step,
                                                      style: textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : SizedBox(
                                        height: constraints.maxHeight,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _TitleBlock(
                                              textTheme: textTheme,
                                              colorScheme: colorScheme,
                                            ),
                                            const SizedBox(height: 24),
                                            Expanded(
                                              child: Center(
                                                child: _HeroCard(
                                                  colorScheme: colorScheme,
                                                  textTheme: textTheme,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              );

                              if (resolvedInitialState ==
                                  LocationPermissionState.deniedForever) {
                                return SingleChildScrollView(
                                  child: Center(child: content),
                                );
                              }

                              return Center(child: content);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                StreamValueBuilder(
                                  streamValue: _controller.loading,
                                  builder: (context, isLoading) {
                                    return ButtonLoading(
                                      label: primaryLabel,
                                      isLoading: isLoading,
                                      onPressed: () => _onPrimaryPressed(
                                        resolvedInitialState,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(56),
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        shape: const StadiumBorder(),
                                        elevation: 0,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _onSecondaryPressed,
                                  child: Text(
                                    widget.allowContinueWithoutLocation
                                        ? 'Continuar sem localização'
                                        : 'Agora não',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onPrimaryPressed(LocationPermissionState initialState) {
    _controller.requestPermission(initialState: initialState);
  }

  Future<void> _onBackPressed() async {
    await _finishFlow(LocationPermissionGateResult.cancelled);
  }

  Future<void> _onSecondaryPressed() async {
    await _finishFlow(
      widget.allowContinueWithoutLocation
          ? LocationPermissionGateResult.continueWithoutLocation
          : LocationPermissionGateResult.cancelled,
    );
  }

  Future<void> _finishFlow(LocationPermissionGateResult result) async {
    _controller.clearResult();

    final onResult = widget.onResult;
    if (onResult != null) {
      onResult(result);
      if (!widget.popRouteAfterResult) {
        return;
      }
    }

    final router = context.router;
    if (router.canPop()) {
      router.pop(result);
      return;
    }
    await replaceAllWithBoundaryDismissRoute(
      router: router,
      kind: BoundaryDismissKind.locationPermission,
    );
  }

  void _handleResult(bool? result) {
    if (result == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (result == true) {
        unawaited(_finishFlow(LocationPermissionGateResult.granted));
        return;
      }

      _controller.clearResult();
      if (!mounted) return;
      final message = kIsWeb
          ? 'No navegador, se a localização foi bloqueada, libere em Permissões do site e tente novamente.'
          : 'Não foi possível liberar a localização.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  List<String> _deniedForeverSteps() {
    if (kIsWeb) {
      return const [
        '1. Clique no cadeado ao lado do endereço do site.',
        '2. Abra as permissões/configurações do site.',
        '3. Em Localização, selecione Permitir.',
        '4. Recarregue a página e toque em Tentar novamente.',
      ];
    }
    return const [
      '1. Toque em Abrir configurações.',
      '2. Entre em Permissões > Localização.',
      '3. Escolha Permitir durante o uso do app.',
      '4. Volte para o app e tente novamente.',
    ];
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.textTheme,
    required this.colorScheme,
  });

  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Veja o que está perto de você',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ative sua localização para mostrar eventos e lugares mais relevantes próximos de você.',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBackPressed,
  });

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          onPressed: onBackPressed,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Voltar',
        ),
        Expanded(
          child: Center(
            child: Text(
              'PERMISSÃO',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.colorScheme,
    required this.textTheme,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surfaceContainerHigh,
            colorScheme.surfaceContainer,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: _HeroPatternPainter(
                  strokeColor: colorScheme.onSurface.withAlpha(18),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.1),
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(46),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.location_on_rounded,
                size: 42,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.secondaryContainer,
                    ),
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      size: 20,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'MAIS PRÓXIMO',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Eventos e Gastronomia • 400m',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
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
        ],
      ),
    );
  }
}

class _HeroPatternPainter extends CustomPainter {
  _HeroPatternPainter({
    required this.strokeColor,
  });

  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const spacing = 28.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeroPatternPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor;
  }
}
