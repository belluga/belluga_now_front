import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_persistence.dart';
import 'package:belluga_now/presentation/common/push/push_option_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:push_handler/push_handler.dart';

class PushActionDispatcher {
  PushActionDispatcher({
    BuildContext? Function()? contextProvider,
    UserLocationRepositoryContract? userLocationRepository,
    PushAnswerPersistence? answerPersistence,
    Future<List<OptionItem>> Function(OptionSource source)? optionsBuilder,
  })  : _userLocationRepository =
            userLocationRepository ??
                GetIt.I.get<UserLocationRepositoryContract>(),
        _contextProvider = contextProvider,
        _answerPersistence = answerPersistence ?? PushAnswerPersistence(),
        _optionsBuilder = optionsBuilder;

  final UserLocationRepositoryContract _userLocationRepository;
  final BuildContext? Function()? _contextProvider;
  final PushAnswerPersistence _answerPersistence;
  final Future<List<OptionItem>> Function(OptionSource source)? _optionsBuilder;

  Future<void> dispatch({
    required ButtonData button,
    required StepData step,
  }) async {
    final action = button.customAction.value.trim();
    if (action.isEmpty) {
      return;
    }

    switch (action) {
      case 'request_location_permission':
      case 'request_location':
        await _userLocationRepository.resolveUserLocation();
        await _handleLocationPermissionFeedback(step);
        return;
      case 'request_contacts_permission':
      case 'request_friends_access':
        await _handleContactsPermission(step);
        return;
      case 'open_favorites_selector':
        await _openFavoritesSelector(step);
        return;
      case 'open_app_settings':
        await openAppSettings();
        return;
      default:
        _showToast(
          'Ação indisponível. Atualize o app ou tente novamente.',
        );
        return;
    }
  }

  Future<void> _handleContactsPermission(StepData step) async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      return;
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    _showToast(step.gate?.onFailToast);
  }

  Future<void> _handleLocationPermissionFeedback(StepData step) async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      return;
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    _showToast(step.gate?.onFailToast);
  }

  Future<void> _openFavoritesSelector(StepData step) async {
    final context = _contextProvider?.call();
    if (context == null) {
      return;
    }
    final config = step.config;
    if (config == null) {
      return;
    }

    final options = await _resolveOptions(config);
    if (options.isEmpty) {
      return;
    }

    final initialSelected = await _loadSelectedValues(config.storeKey);
    if (!context.mounted) {
      return;
    }
    final selectedValues = await PushOptionSelectorSheet.show(
      context: context,
      title: step.title.value,
      body: step.body.value,
      layout: config.layout ?? 'list',
      gridColumns: config.gridColumns ?? 2,
      selectionMode: config.selectionMode ?? 'single',
      options: options,
      minSelected: config.minSelected ?? 0,
      maxSelected: config.maxSelected ?? 0,
      initialSelected: initialSelected,
    );
    if (selectedValues == null) {
      return;
    }

    final answer = AnswerPayload(
      stepSlug: step.slug,
      value: selectedValues,
      metadata: const {'source': 'custom_action'},
    );
    await _answerPersistence.persist(answer: answer, step: step);
  }

  Future<List<OptionItem>> _resolveOptions(StepConfig config) async {
    final source = config.optionSource;
    if (source != null) {
      final builder = _optionsBuilder;
      if (builder == null) {
        return const [];
      }
      return builder(source);
    }
    return config.options;
  }

  Future<List<dynamic>> _loadSelectedValues(String? storeKey) async {
    if (storeKey == null || storeKey.isEmpty) {
      return const [];
    }
    final stored = await _answerPersistence.read(storeKey);
    final value = stored?['value'];
    if (value is List) {
      return List<dynamic>.from(value);
    }
    return const [];
  }

  void _showToast(String? message) {
    if (message == null || message.isEmpty) {
      return;
    }
    final context = _contextProvider?.call();
    final messenger = context != null ? ScaffoldMessenger.maybeOf(context) : null;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
