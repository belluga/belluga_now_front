import 'dart:io';
import 'dart:math' as math;
import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/presentation/tenant/profile/screens/profile_screen/controllers/profile_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileScreenController _controller =
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
        leading: const BackButton(),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: _logout,
            icon: const Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamValueBuilder<UserContract?>(
          streamValue: _controller.userStreamValue,
          builder: (context, user) {
            _controller.syncFromUser(user);
            final avatarUrl = user?.profile.pictureUrlValue?.value?.toString();
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
                    _ProfileHeader(
                      avatarImage: avatarImage,
                      displayName: _controller.nameController.text,
                      onChangeAvatar: _onChangeAvatar,
                      invitesSent: 0, // TODO(Delphi): bind convites enviados.
                      invitesAccepted: 0, // TODO(Delphi): bind convites aceitos.
                      hasPendingChanges: hasPendingChanges,
                    ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Seus dados',
                  children: [
                    _EditableTile(
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
                    _EditableTile(
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
                    _EditableTile(
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
                    _EditableTile(
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
                _SectionCard(
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
                    StreamValueBuilder<double>(
                      streamValue: _controller.maxRadiusMetersStreamValue,
                      builder: (context, radiusMeters) {
                        return ListTile(
                          leading: const Icon(Icons.my_location_outlined),
                          title: const Text('Raio máximo'),
                          subtitle: Text(_formatRadiusLabel(radiusMeters)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              _openRadiusSelector(context, radiusMeters),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Privacidade & segurança',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.visibility_outlined),
                      title: const Text('Visibilidade'),
                      subtitle:
                          const Text('Público · Amigos verão convites em breve'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showComingSoon(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.shield_outlined),
                      title: const Text('Alterar senha'),
                      subtitle: const Text('Atualize a senha da sua conta'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showComingSoon(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.policy_outlined),
                      title: const Text('Política de privacidade'),
                      subtitle: const Text('Como tratamos seus dados'),
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
                  Navigator.of(ctx).pop();
                  await _controller.pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () async {
                  Navigator.of(ctx).pop();
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
    final tempController = TextEditingController(text: controller.text);
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
                controller: tempController,
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
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      controller.text = tempController.text;
                      Navigator.of(ctx).pop();
                      setState(() {});
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
    final controller =
        TextEditingController(text: _formatRadiusInputValue(initialKm));
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
                  controller: controller,
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
                        controller.text.replaceAll(',', '.'),
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
                      Navigator.of(ctx).pop();
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    this.avatarImage,
    required this.displayName,
    required this.onChangeAvatar,
    required this.invitesSent,
    required this.invitesAccepted,
    required this.hasPendingChanges,
  });

  final ImageProvider? avatarImage;
  final String displayName;
  final VoidCallback onChangeAvatar;
  final int invitesSent;
  final int invitesAccepted;
  final bool hasPendingChanges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Icon(Icons.person, color: colorScheme.primary, size: 32)
                    : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Material(
                  color: colorScheme.surface,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    onPressed: onChangeAvatar,
                    icon: Icon(
                      Icons.photo_camera_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName.isNotEmpty ? displayName : 'Seu perfil',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasPendingChanges)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Alterado',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Convites aceitos valem mais que likes.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricPill(
                      value: invitesSent,
                      icon: BooraIcons.invite_outlined,
                      iconColor: colorScheme.secondary,
                      backgroundColor:
                          colorScheme.secondary.withValues(alpha: 0.14),
                    ),
                    _MetricPill(
                      value: invitesAccepted,
                      icon: BooraIcons.invite_solid,
                      iconColor: colorScheme.primary,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final int value;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _EditableTile extends StatelessWidget {
  const _EditableTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(label),
      subtitle: Text(
        value.isEmpty ? 'Toque para preencher' : value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: value.isEmpty
              ? colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).toInt())
              : colorScheme.onSurface,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
