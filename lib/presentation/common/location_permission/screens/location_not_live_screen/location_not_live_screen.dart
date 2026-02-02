import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/presentation/common/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/common/widgets/button_loading.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class LocationNotLiveScreen extends StatefulWidget {
  const LocationNotLiveScreen({
    super.key,
    required this.blockerState,
    required this.addressLabel,
    required this.capturedAt,
  });

  final LocationPermissionState blockerState;
  final String? addressLabel;
  final DateTime? capturedAt;

  @override
  State<LocationNotLiveScreen> createState() => _LocationNotLiveScreenState();
}

class _LocationNotLiveScreenState extends State<LocationNotLiveScreen> {
  final LocationPermissionController _controller =
      GetIt.I.get<LocationPermissionController>();

  @override
  Widget build(BuildContext context) {
    final title = 'Ative a localização ao vivo';
    final address = widget.addressLabel?.trim();
    final subtitle = address == null || address.isEmpty
        ? 'Não conseguimos acessar sua localização ao vivo agora.'
        : address;

    final capturedAt = widget.capturedAt;
    final ageLabel = capturedAt == null ? null : _relativeAge(capturedAt);

    final primaryLabel = switch (widget.blockerState) {
      LocationPermissionState.serviceDisabled => 'Ativar serviços',
      LocationPermissionState.denied => 'Permitir localização',
      LocationPermissionState.deniedForever => 'Abrir configurações',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Localização')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (ageLabel != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Última localização conhecida: $ageLabel (pode estar desatualizada).',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ative a localização ao vivo para mostrar lugares próximos e ordenar por distância com mais precisão.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              StreamValueBuilder(
                streamValue: _controller.loading,
                builder: (context, isLoading) {
                  return ButtonLoading(
                    label: primaryLabel,
                    isLoading: isLoading,
                    onPressed: _onEnablePressed,
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.router.pop(true),
                child: const Text('Continuar sem localização ao vivo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onEnablePressed() async {
    final granted = await _controller.ensureReady(
      initialState: widget.blockerState,
    );
    if (!mounted || !granted) return;
    context.router.pop(true);
  }

  String _relativeAge(DateTime capturedAt) {
    final diff = DateTime.now().difference(capturedAt);
    if (diff.inMinutes < 2) return 'agora há pouco';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 48) return 'há ${diff.inHours} h';
    return 'há ${diff.inDays} d';
  }
}
