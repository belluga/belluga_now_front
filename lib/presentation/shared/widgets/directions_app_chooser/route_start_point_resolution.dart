import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/route_instance_scope.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:flutter/material.dart';

class RouteStartPointResolution {
  const RouteStartPointResolution._();

  static Future<DirectionsLaunchTarget?> resolve({
    required BuildContext context,
    required DirectionsLaunchTarget target,
    required ProximityPreference? proximityPreference,
    required Future<void> Function(bool? useReferencePoint)
        persistRouteReferencePointPolicy,
    required ValueChanged<String> onStatusMessage,
  }) async {
    final reference = proximityPreference?.locationPreference.fixedReference;
    if (reference == null ||
        proximityPreference?.locationPreference.usesFixedReference != true) {
      return target;
    }

    final policy = proximityPreference!.routeReferencePointPolicyValue;
    if (policy.usesReferencePoint) {
      return _targetWithReferenceOrigin(target, reference);
    }
    if (policy.usesLiveLocation) {
      return target;
    }

    final decision = await _prompt(context, reference);
    if (!context.mounted || decision == null) {
      return null;
    }

    if (decision.persistChoice) {
      try {
        await persistRouteReferencePointPolicy(decision.useReferencePoint);
      } catch (_) {
        if (context.mounted) {
          onStatusMessage(
            'Não foi possível salvar sua preferência de ponto de partida.',
          );
        }
      }
      if (!context.mounted) {
        return null;
      }
    }

    return decision.useReferencePoint
        ? _targetWithReferenceOrigin(target, reference)
        : target;
  }

  static Future<_RouteStartPointDecision?> _prompt(
    BuildContext context,
    FixedLocationReference reference,
  ) {
    final referenceLabel = _referencePointLabel(reference);
    final accountProfilePath = _referenceAccountProfilePath(reference);
    return showRouteScopedDialog<_RouteStartPointDecision>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return _RouteStartPointDialog(
          referenceLabel: referenceLabel,
          canOpenAccountProfile: accountProfilePath != null,
          onOpenAccountProfile: accountProfilePath == null
              ? null
              : () {
                  dialogContext.router.pop();
                  if (!context.mounted) {
                    return;
                  }
                  unawaited(context.router.pushPath(accountProfilePath));
                },
        );
      },
    );
  }

  static DirectionsLaunchTarget _targetWithReferenceOrigin(
    DirectionsLaunchTarget target,
    FixedLocationReference reference,
  ) {
    final label = _referencePointLabel(reference);
    return DirectionsLaunchTarget(
      destinationName: target.destinationName,
      latitude: target.latitude,
      longitude: target.longitude,
      address: target.address,
      originName: label,
      originLatitude: reference.coordinate.latitude,
      originLongitude: reference.coordinate.longitude,
      originAddress: label,
    );
  }

  static String _referencePointLabel(FixedLocationReference reference) {
    final label = reference.label?.trim();
    if (reference.sourceKind ==
            FixedLocationReferenceSourceKind.entityReference &&
        reference.entityNamespace == 'account_profile' &&
        label != null &&
        label.isNotEmpty) {
      return label;
    }
    if (reference.sourceKind ==
        FixedLocationReferenceSourceKind.manualCoordinate) {
      return 'localização personalizada';
    }
    return label == null || label.isEmpty ? 'Ponto de referência' : label;
  }

  static String? _referenceAccountProfilePath(
      FixedLocationReference reference) {
    if (reference.sourceKind !=
            FixedLocationReferenceSourceKind.entityReference ||
        reference.entityNamespace != 'account_profile') {
      return null;
    }
    final slug = reference.entitySlug?.trim();
    if (slug == null || slug.isEmpty) {
      return null;
    }
    return '/parceiro/$slug';
  }
}

class _RouteStartPointDecision {
  const _RouteStartPointDecision({
    required this.useReferencePoint,
    required this.persistChoice,
  });

  final bool useReferencePoint;
  final bool persistChoice;
}

class _RouteStartPointDialog extends StatefulWidget {
  const _RouteStartPointDialog({
    required this.referenceLabel,
    required this.canOpenAccountProfile,
    required this.onOpenAccountProfile,
  });

  final String referenceLabel;
  final bool canOpenAccountProfile;
  final VoidCallback? onOpenAccountProfile;

  @override
  State<_RouteStartPointDialog> createState() => _RouteStartPointDialogState();
}

class _RouteStartPointDialogState extends State<_RouteStartPointDialog> {
  _RouteStartPointChoice _choice = _RouteStartPointChoice.liveLocation;
  bool _persistChoice = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Qual PONTO DE PARTIDA quer usar?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<_RouteStartPointChoice>(
              groupValue: _choice,
              onChanged: _selectChoice,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RadioListTile<_RouteStartPointChoice>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Sua localização atual'),
                    value: _RouteStartPointChoice.liveLocation,
                  ),
                  RadioListTile<_RouteStartPointChoice>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('O ponto de referência selecionado'),
                    subtitle: Text(widget.referenceLabel),
                    value: _RouteStartPointChoice.referencePoint,
                  ),
                ],
              ),
            ),
            if (widget.canOpenAccountProfile)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.onOpenAccountProfile,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ver perfil'),
                ),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Não perguntar de novo'),
              value: _persistChoice,
              onChanged: (value) {
                setState(() {
                  _persistChoice = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => unawaited(context.router.maybePop()),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            unawaited(
              context.router.maybePop(
                _RouteStartPointDecision(
                  useReferencePoint:
                      _choice == _RouteStartPointChoice.referencePoint,
                  persistChoice: _persistChoice,
                ),
              ),
            );
          },
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  void _selectChoice(_RouteStartPointChoice? value) {
    if (value == null) {
      return;
    }
    setState(() {
      _choice = value;
    });
  }
}

enum _RouteStartPointChoice { liveLocation, referencePoint }
