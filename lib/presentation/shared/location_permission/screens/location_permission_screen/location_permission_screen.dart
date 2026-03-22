import 'package:auto_route/auto_route.dart';
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
      LocationPermissionState.deniedForever => kIsWeb
          ? 'A localização foi bloqueada no navegador. Para liberar novamente, abra as permissões do site no navegador e permita Localização.'
          : 'A permissão de localização foi negada permanentemente. Abra as configurações do app para permitir e voltar ao mapa.',
    };

    final primaryLabel = switch (widget.initialState) {
      LocationPermissionState.serviceDisabled => 'Ativar serviços',
      LocationPermissionState.denied => 'Permitir localização',
      LocationPermissionState.deniedForever =>
        kIsWeb ? 'Tentar novamente' : 'Abrir configurações',
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
                  if (widget.initialState ==
                      LocationPermissionState.deniedForever) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Como liberar:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._deniedForeverSteps().map(
                            (step) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(step),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
      if (result == true) {
        context.router.pop(true);
        _controller.clearResult();
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
