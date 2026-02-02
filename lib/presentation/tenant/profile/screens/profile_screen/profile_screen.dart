import 'dart:io';
import 'dart:math' as math;
import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/presentation/landlord/auth/widgets/landlord_login_sheet.dart';
import 'package:belluga_now/presentation/tenant/profile/screens/profile_screen/controllers/profile_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/profile/screens/profile_screen/widgets/anonymous_profile_card.dart';
import 'package:belluga_now/presentation/tenant/profile/screens/profile_screen/widgets/profile_editable_tile.dart';
import 'package:belluga_now/presentation/tenant/profile/screens/profile_screen/widgets/profile_header.dart';
import 'package:belluga_now/presentation/tenant/profile/screens/profile_screen/widgets/profile_section_card.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
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

  @override
  void initState() {
    super.initState();
    _controller.syncFromUser(_controller.userStreamValue.value);
    _controller.loadAvatarPath();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: BackButton(
          onPressed: () {
            if (context.router.canPop()) {
              context.router.pop();
              return;
            }
            context.router.replaceAll([TenantHomeRoute()]);
          },
        ),
        actions: [
          StreamValueBuilder<UserContract?>(
            streamValue: _controller.userStreamValue,
            builder: (context, user) {
              if (user == null) {
                return const SizedBox.shrink();
              }
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
          builder: (context, user) {
            _controller.syncFromUser(user);
            if (user == null) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                children: [
                  AnonymousProfileCard(
                    onTapLogin: () =>
                        context.router.push(const AuthLoginRoute()),
                  ),
                ],
              );
            }
            final avatarUrl = user.profile.pictureUrlValue?.value?.toString();

            return StreamValueBuilder<int>(
              streamValue: _controller.formVersionStreamValue,
              builder: (context, _) {
                final hasPendingChanges = _controller.hasPendingChanges;

                return StreamValueBuilder<String?>(
                  streamValue: _controller.localAvatarPathStreamValue,
                  builder: (context, localPath) {
                    final avatarImage = _resolveAvatarImage(
                      localPath: localPath,
                      remoteUrl: avatarUrl,
                    );

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        ProfileHeader(
                          avatarImage: avatarImage,
                          displayName: _controller.nameController.text,
                          onChangeAvatar: _onChangeAvatar,
                          invitesSent: 0, // TODO(Delphi): bind convites enviados.
                          invitesAccepted: 0, // TODO(Delphi): bind convites aceitos.
                          hasPendingChanges: hasPendingChanges,
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
                              label: 'E-mail',
                              value: _controller.emailController.text,
                              icon: Icons.email_outlined,
                              onTap: () => _openEditField(
                                context,
                                label: 'E-mail',
                                controller: _controller.emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            ProfileEditableTile(
                              label: 'Telefone',
                              value: _controller.phoneController.text,
                              icon: Icons.phone_outlined,
                              onTap: () => _openEditField(
                                context,
                                label: 'Telefone',
                                controller: _controller.phoneController,
                                keyboardType: TextInputType.phone,
                              ),
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                );
                              },
                            ),
                            StreamValueBuilder<double>(
                              streamValue:
                                  _controller.maxRadiusMetersStreamValue,
                              builder: (context, radiusMeters) {
                                return ListTile(
                                  leading:
                                      const Icon(Icons.my_location_outlined),
                                  title: const Text('Raio máximo'),
                                  subtitle:
                                      Text(_formatRadiusLabel(radiusMeters)),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _openRadiusSelector(
                                    context,
                                    radiusMeters,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ProfileSectionCard(
                          title: 'Modo',
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: const Text('Modo Usuario'),
                              subtitle: const Text('Experiencia do app'),
                              trailing: const Icon(Icons.check_circle),
                              onTap: () => _switchToUserMode(context),
                            ),
                            ListTile(
                              leading: const Icon(Icons.shield_outlined),
                              title: const Text('Modo Admin'),
                              subtitle: const Text('Acesso landlord'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _switchToAdminMode(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ProfileSectionCard(
                          title: 'Privacidade & segurança',
                          children: [
                            ListTile(
                              leading: const Icon(Icons.visibility_outlined),
                              title: const Text('Visibilidade'),
                              subtitle: const Text(
                                'Público · Amigos verão convites em breve',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showComingSoon(context),
                            ),
                            ListTile(
                              leading: const Icon(Icons.shield_outlined),
                              title: const Text('Alterar senha'),
                              subtitle:
                                  const Text('Atualize a senha da sua conta'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showComingSoon(context),
                            ),
                            ListTile(
                              leading: const Icon(Icons.policy_outlined),
                              title: const Text('Política de privacidade'),
                              subtitle:
                                  const Text('Como tratamos seus dados'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showComingSoon(context),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await _controller.logout();
    _navigateToHome();
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
                  await _controller.pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () async {
                  ctx.router.pop();
                  await _controller.pickAvatar(ImageSource.gallery);
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
    await _controller.saveProfile();
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Em breve'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _switchToUserMode(BuildContext context) async {
    await _controller.switchToUserMode();
    if (!context.mounted) return;
    context.router.replaceAll([TenantHomeRoute()]);
  }

  Future<void> _switchToAdminMode(BuildContext context) async {
    var canEnter = await _controller.ensureAdminMode();
    if (!context.mounted) return;
    if (!canEnter) {
      canEnter = await showLandlordLoginSheet(
        context,
        controller: _controller.landlordLoginController,
      );
      if (!context.mounted) return;
    }
    if (!canEnter) {
      return;
    }
    if (!context.mounted) return;
    context.router.replaceAll([TenantAdminShellRoute()]);
  }

  static String _formatRadiusLabel(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(0)} km';
  }

  static String _formatRadiusInputValue(double km) {
    final normalized = km <= 0 ? 1 : km;
    final rounded = normalized.roundToDouble();
    if ((normalized - rounded).abs() < 0.01) {
      return rounded.toStringAsFixed(0);
    }
    final roundedOneDecimal = (normalized * 10).roundToDouble() / 10;
    return roundedOneDecimal.toStringAsFixed(1);
  }

  Future<void> _openRadiusSelector(
    BuildContext context,
    double selectedMeters,
  ) async {
    final theme = Theme.of(context);
    double initialKm = math.max(1, selectedMeters / 1000);
    _controller.radiusKmController.text =
        _formatRadiusInputValue(initialKm);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
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
                ListTile(
                  title: Text(
                    'Raio máximo',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Defina o raio em km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextField(
                  controller: _controller.radiusKmController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.my_location_outlined),
                    labelText: 'Raio (km)',
                    suffixText: 'km',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final parsed = double.tryParse(
                          _controller.radiusKmController.text
                              .replaceAll(',', '.'),
                        );
                      if (parsed == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Informe um valor válido'),
                          ),
                        );
                        return;
                      }
                      final km = parsed < 1 ? 1 : parsed;
                      _controller.setMaxRadiusMeters(km * 1000);
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
  }

  @override
  void dispose() {
    super.dispose();
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
