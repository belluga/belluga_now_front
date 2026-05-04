import 'dart:async';
import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/self_profile.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/profile_screen/controllers/profile_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/profile_screen/widgets/profile_editable_tile.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/profile_screen/widgets/profile_header.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/profile_screen/widgets/profile_section_card.dart';
import 'package:belluga_now/presentation/shared/widgets/route_back_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileScreenController _controller =
      GetIt.I.get<ProfileScreenController>();
  StreamSubscription<String?>? _originPreferenceFeedbackSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.init());
    _originPreferenceFeedbackSubscription = _controller
        .originPreferenceFeedbackStreamValue.stream
        .listen(_handleOriginPreferenceFeedback);
  }

  @override
  void dispose() {
    _originPreferenceFeedbackSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backPolicy = buildCanonicalCurrentRouteBackPolicy(context);
    return RouteBackScope(
      backPolicy: backPolicy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Perfil',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            tooltip: 'Voltar',
            onPressed: backPolicy.handleBack,
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            StreamValueBuilder<UserContract?>(
              streamValue: _controller.userStreamValue,
              onNullWidget: const SizedBox.shrink(),
              builder: (context, user) {
                return IconButton(
                  tooltip: 'Sair',
                  onPressed: _logout,
                  icon: const Icon(Icons.exit_to_app),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: StreamValueBuilder<UserContract?>(
            streamValue: _controller.userStreamValue,
            onNullWidget: const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            builder: (context, user) {
              return StreamValueBuilder<bool>(
                streamValue: _controller.isProfileLoadingStreamValue,
                builder: (context, isProfileLoading) {
                  return StreamValueBuilder<SelfProfile?>(
                    streamValue: _controller.currentProfileStreamValue,
                    onNullWidget: isProfileLoading
                        ? const Center(
                            child: CircularProgressIndicator.adaptive(),
                          )
                        : _buildProfileContent(
                            context: context,
                            user: user,
                          ),
                    builder: (context, _) {
                      return _buildProfileContent(
                        context: context,
                        user: user,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent({
    required BuildContext context,
    required UserContract? user,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamValueBuilder<int>(
      streamValue: _controller.formVersionStreamValue,
      builder: (context, _) {
        final hasPendingChanges = _controller.hasPendingChanges;

        return StreamValueBuilder<String?>(
          streamValue: _controller.localAvatarPathStreamValue,
          builder: (context, localPath) {
            final avatarImage = _resolveAvatarImage(
              localPath: localPath,
              remoteUrl: _controller.currentAvatarUrl ??
                  user?.profile.pictureUrlValue?.value?.toString(),
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                StreamValueBuilder<int>(
                  streamValue: _controller.pendingInvitesCountStreamValue,
                  builder: (context, pendingInvitesCount) {
                    return StreamValueBuilder<int>(
                      streamValue:
                          _controller.confirmedEventsCountStreamValue,
                      builder: (context, confirmedEventsCount) {
                        return ProfileHeader(
                          avatarImage: avatarImage,
                          displayName: _controller.nameController.text,
                          onChangeAvatar: _onChangeAvatar,
                          pendingInvitesCount: pendingInvitesCount,
                          confirmedEventsCount: confirmedEventsCount,
                          hasPendingChanges: hasPendingChanges,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                ProfileSectionCard(
                  title: 'Seus dados',
                  children: [
                    ProfileEditableTile(
                      label: 'Nome',
                      value: _controller.nameController.text,
                      icon: Icons.person_outline,
                      onTap: () => _openEditField(
                        context,
                        label: 'Nome',
                        controller: _controller.nameController,
                        keyboardType: TextInputType.name,
                      ),
                    ),
                    ProfileEditableTile(
                      label: 'Descrição',
                      value: _controller.descriptionController.text,
                      icon: Icons.short_text,
                      onTap: () => _openEditField(
                        context,
                        label: 'Descrição',
                        controller: _controller.descriptionController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 3,
                      ),
                    ),
                    ProfileEditableTile(
                      label: 'Telefone',
                      value: _controller.phoneController.text,
                      icon: Icons.phone_outlined,
                      readOnly: true,
                      emptyValueLabel: 'Telefone verificado',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ProfileSectionCard(
                  title: 'Preferências',
                  children: [
                    StreamValueBuilder<ThemeMode?>(
                      streamValue: _controller.themeModeStreamValue,
                      builder: (context, mode) {
                        final isDark = mode == ThemeMode.dark;
                        return SwitchListTile.adaptive(
                          value: isDark,
                          onChanged: (value) => _controller.setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          ),
                          title: const Text('Tema escuro'),
                          subtitle: Text(
                            isDark
                                ? 'Usando tema escuro'
                                : 'Usando tema claro',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          secondary: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        );
                      },
                    ),
                    _buildRadiusPreferenceAction(),
                    StreamValueBuilder<String>(
                      streamValue: _controller.activeOriginSummaryStreamValue,
                      builder: (context, originSummary) {
                        return ListTile(
                          key: const Key(
                            'profileOriginPreferenceTile',
                          ),
                          leading: const Icon(Icons.place_outlined),
                          title: const Text('Minha localização'),
                          subtitle: Text(originSummary),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openOriginEditor(context),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ProfileSectionCard(
                  title: 'Privacidade',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.policy_outlined),
                      title: const Text('Política de privacidade'),
                      subtitle: const Text('Como tratamos seus dados'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.router.pushPath(
                        '/privacy-policy',
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openOriginEditor(BuildContext context) async {
    final theme = Theme.of(context);
    var useFixedOrigin = _controller.isUsingFixedOriginStreamValue.value;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minha localização',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            icon: Icon(Icons.my_location_outlined),
                            label: Text('Atual'),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            icon: Icon(Icons.place_outlined),
                            label: Text('Fixa'),
                          ),
                        ],
                        selected: {useFixedOrigin},
                        onSelectionChanged: (selection) {
                          if (selection.isEmpty) {
                            return;
                          }
                          setModalState(() {
                            useFixedOrigin = selection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (useFixedOrigin) ...[
                        TextFormField(
                          key: const Key('profileFixedOriginLatitudeField'),
                          controller: _controller.fixedOriginLatitudeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            hintText: 'Ex: -20.673600',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('profileFixedOriginLongitudeField'),
                          controller:
                              _controller.fixedOriginLongitudeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            hintText: 'Ex: -40.497600',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('profileFixedOriginLabelField'),
                          controller: _controller.fixedOriginLabelController,
                          decoration: const InputDecoration(
                            labelText: 'Rótulo (opcional)',
                            hintText: 'Ex: Hotel Base',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            key: const Key('profilePickOriginOnMapButton'),
                            onPressed: () async {
                              final selection = await _openOriginMapPicker(
                                context,
                              );
                              if (selection == null) {
                                return;
                              }
                              _controller.setFixedOriginCoordinate(
                                latitude: selection.latitude,
                                longitude: selection.longitude,
                              );
                              if (_controller
                                  .fixedOriginLabelController.text
                                  .trim()
                                  .isEmpty) {
                                _controller.fixedOriginLabelController.text =
                                    'Origem selecionada no mapa';
                              }
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Selecionar no mapa'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else
                        Text(
                          'Use a sua localização atual como origem padrão das distâncias no Home.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          key: const Key('profileSaveOriginPreferenceButton'),
                          onPressed: () {
                            final error = _controller.saveOriginPreference(
                              useFixedOrigin: useFixedOrigin,
                            );
                            if (!context.mounted) {
                              return;
                            }
                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error)),
                              );
                              return;
                            }
                            sheetContext.router.pop();
                          },
                          child: const Text('Salvar origem'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    await _controller.logout();
    _navigateToHome();
  }

  void _handleOriginPreferenceFeedback(String? message) {
    if (!mounted || message == null || message.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateToHome() {
    context.router.popUntilRoot();
  }

  void _onChangeAvatar() {
    _controller.requestAvatarUpdate();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tirar foto'),
                onTap: () async {
                  ctx.router.pop();
                  try {
                    await _controller.pickAvatar(ImageSource.camera);
                  } catch (error) {
                    _showProfileSaveError(error);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () async {
                  ctx.router.pop();
                  try {
                    await _controller.pickAvatar(ImageSource.gallery);
                  } catch (error) {
                    _showProfileSaveError(error);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) async {
    _controller.editFieldController.text = controller.text;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller.editFieldController,
                keyboardType: keyboardType,
                maxLines: maxLines,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => ctx.router.pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      controller.text = _controller.editFieldController.text;
                      ctx.router.pop();
                      _controller.bumpFormVersion();
                    },
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    try {
      await _controller.saveProfile();
    } catch (error) {
      _showProfileSaveError(error);
    }
  }

  Widget _buildRadiusPreferenceAction() {
    return StreamValueBuilder<double>(
      streamValue: _controller.maxRadiusMetersStreamValue,
      builder: (context, radiusMeters) {
        final theme = Theme.of(context);
        final effectiveRadiusMeters =
            radiusMeters.clamp(1000, 50000).toDouble();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.place_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raio máximo',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildRadiusAction(
                context: context,
                radiusMeters: effectiveRadiusMeters,
                onPressed: () => _openRadiusSelector(
                  context,
                  effectiveRadiusMeters,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatRadiusLabel(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(0)} km';
  }

  Future<void> _openRadiusSelector(
    BuildContext context,
    double selectedMeters,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    var draftRadiusKm = (selectedMeters / 1000).clamp(1, 50).toDouble();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.place_outlined,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Raio máximo',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Até ${draftRadiusKm.toStringAsFixed(0)} km',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: draftRadiusKm,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      onChanged: (value) {
                        setModalState(() {
                          draftRadiusKm = value;
                        });
                      },
                      onChangeEnd: (value) {
                        _controller.setMaxRadiusMeters(value * 1000);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(
                            '1 km',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '50 km',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          _controller.setMaxRadiusMeters(draftRadiusKm * 1000);
                          ctx.router.pop();
                        },
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRadiusAction({
    required BuildContext context,
    required double radiusMeters,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Tooltip(
      message: 'Raio ${_formatRadiusLabel(radiusMeters)}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            key: const ValueKey<String>('profile-radius-expanded'),
            constraints: const BoxConstraints(minWidth: 124),
            height: 40,
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 10, 8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Até ${_formatRadiusLabel(radiusMeters)}',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: colorScheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<_ProfileMapSelection?> _openOriginMapPicker(
    BuildContext context,
  ) async {
    final latitude = double.tryParse(
      _controller.fixedOriginLatitudeController.text.trim(),
    );
    final longitude = double.tryParse(
      _controller.fixedOriginLongitudeController.text.trim(),
    );
    return showModalBottomSheet<_ProfileMapSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return _ProfileOriginMapPickerSheet(
          initialSelection: latitude != null && longitude != null
              ? LatLng(latitude, longitude)
              : null,
        );
      },
    );
  }

  void _showProfileSaveError(Object error) {
    if (!mounted) {
      return;
    }
    final message = error
        .toString()
        .replaceFirst(RegExp(r'^(Exception|StateError|Bad state|Error):\s*'), '')
        .trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.isEmpty
              ? 'Nao foi possivel salvar o perfil agora. Tente novamente.'
              : message,
        ),
      ),
    );
  }

  ImageProvider? _resolveAvatarImage({
    required String? localPath,
    required String? remoteUrl,
  }) {
    final local = localPath?.trim();
    if (local != null && local.isNotEmpty) {
      final file = File(local);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    if (remoteUrl != null && remoteUrl.trim().isNotEmpty) {
      return NetworkImage(remoteUrl);
    }
    return null;
  }
}

class _ProfileMapSelection {
  const _ProfileMapSelection({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class _ProfileOriginMapPickerSheet extends StatefulWidget {
  const _ProfileOriginMapPickerSheet({
    this.initialSelection,
  });

  final LatLng? initialSelection;

  @override
  State<_ProfileOriginMapPickerSheet> createState() =>
      _ProfileOriginMapPickerSheetState();
}

class _ProfileOriginMapPickerSheetState
    extends State<_ProfileOriginMapPickerSheet> {
  static const LatLng _defaultCenter = LatLng(-20.6736, -40.4976);
  static const double _defaultZoom = 15.5;

  late LatLng? _selectedPoint = widget.initialSelection;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final selectedPoint = _selectedPoint;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.82,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: selectedPoint ?? _defaultCenter,
              initialZoom: _defaultZoom,
              minZoom: 12,
              maxZoom: 18,
              onTap: (_, point) {
                setState(() {
                  _selectedPoint = point;
                });
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                rotationWinGestures: MultiFingerGesture.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.belluganow.app',
              ),
              if (selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedPoint,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedPoint == null
                              ? 'Toque no mapa para selecionar.'
                              : 'Lat ${selectedPoint.latitude.toStringAsFixed(6)} · '
                                  'Lng ${selectedPoint.longitude.toStringAsFixed(6)}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: selectedPoint == null
                            ? null
                            : () {
                                context.router.pop(
                                  _ProfileMapSelection(
                                    latitude: selectedPoint.latitude,
                                    longitude: selectedPoint.longitude,
                                  ),
                                );
                              },
                        child: const Text('Confirmar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
