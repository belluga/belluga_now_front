import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/presentation/common/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/common/widgets/button_loading.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:get_it/get_it.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({
    super.key,
    required this.initialState,
  });

  final LocationPermissionState initialState;

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  final LocationPermissionController _controller =
      GetIt.I.get<LocationPermissionController>();

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.initialState) {
      LocationPermissionState.serviceDisabled => 'Ative a localização',
      LocationPermissionState.denied => 'Permita a localização',
      LocationPermissionState.deniedForever => 'Permissão necessária',
    };

    final description = switch (widget.initialState) {
      LocationPermissionState.serviceDisabled =>
        'Para encontrar locais e endereços próximos, precisamos que os serviços de localização do seu aparelho estejam ativos.',
      LocationPermissionState.denied =>
        'Para mostrar locais próximos e ordenar por distância, precisamos da sua permissão de localização.',
      LocationPermissionState.deniedForever =>
        'A permissão de localização foi negada permanentemente. Abra as configurações do app para permitir e voltar ao mapa.',
    };

    final primaryLabel = switch (widget.initialState) {
      LocationPermissionState.serviceDisabled => 'Ativar serviços',
      LocationPermissionState.denied => 'Permitir localização',
      LocationPermissionState.deniedForever => 'Abrir configurações',
    };

    return StreamValueBuilder<bool?>(
      streamValue: _controller.resultStreamValue,
      builder: (context, result) {
        _handleResult(result);
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            automaticallyImplyLeading: false,
          ),
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
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Spacer(),
                  StreamValueBuilder(
                    streamValue: _controller.loading,
                    builder: (context, isLoading) {
                      return ButtonLoading(
                        label: primaryLabel,
                        isLoading: isLoading,
                        onPressed: _onPrimaryPressed,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _onNotNowPressed,
                    child: const Text('Agora não'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPrimaryPressed() {
    _controller.requestPermission(initialState: widget.initialState);
  }

  void _onNotNowPressed() {
    context.router.pop(false);
  }

  void _handleResult(bool? result) {
    if (result == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.router.pop(result);
      _controller.clearResult();
    });
  }
}
