export 'push_option_selector_payload.dart';

import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_bool_value.dart';
import 'package:belluga_now/infrastructure/services/push/push_option_selector_payload.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get_it/get_it.dart';
import 'package:geolocator/geolocator.dart';
import 'package:push_handler/push_handler.dart';

class PushActionDispatcher {
  PushActionDispatcher({
    UserLocationRepositoryContract? userLocationRepository,
    Future<List<OptionItem>> Function(OptionSource source)? optionsBuilder,
    Future<void> Function(AnswerPayload answer, StepData step)? onStepSubmit,
    Future<List<dynamic>?> Function(PushOptionSelectorPayload payload)?
    onOpenSelector,
    void Function(String message)? onShowToast,
    Future<PermissionStatus> Function()? contactsPermissionRequester,
    Future<void> Function()? contactsSettingsOpener,
    Future<LocationPermission> Function()? locationPermissionChecker,
    Future<void> Function()? appSettingsOpener,
  }) : _userLocationRepository =
           userLocationRepository ??
           GetIt.I.get<UserLocationRepositoryContract>(),
       _optionsBuilder = optionsBuilder,
       _onStepSubmit = onStepSubmit,
       _onOpenSelector = onOpenSelector,
       _onShowToast = onShowToast,
       _contactsPermissionRequester = contactsPermissionRequester,
       _contactsSettingsOpener = contactsSettingsOpener,
       _locationPermissionChecker = locationPermissionChecker,
       _appSettingsOpener = appSettingsOpener;

  final UserLocationRepositoryContract _userLocationRepository;
  final Future<List<OptionItem>> Function(OptionSource source)? _optionsBuilder;
  final Future<void> Function(AnswerPayload answer, StepData step)?
  _onStepSubmit;
  final Future<List<dynamic>?> Function(PushOptionSelectorPayload payload)?
  _onOpenSelector;
  final void Function(String message)? _onShowToast;
  final Future<PermissionStatus> Function()? _contactsPermissionRequester;
  final Future<void> Function()? _contactsSettingsOpener;
  final Future<LocationPermission> Function()? _locationPermissionChecker;
  final Future<void> Function()? _appSettingsOpener;

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
        await _userLocationRepository.resolveUserLocation(
          requestPermissionIfNeededValue:
              UserLocationRepositoryContractBoolValue.fromRaw(
                true,
                defaultValue: true,
              ),
        );
        await _handleLocationPermissionFeedback(step);
        return;
      case 'request_contacts_permission':
      case 'request_friends_access':
        await _handleContactsPermission(step);
        return;
      case 'open_favorites_selector':
      case 'open_selector':
        await _openFavoritesSelector(step);
        return;
      case 'open_app_settings':
        await _openAppSettings();
        return;
      default:
        _showToast('Ação indisponível. Atualize o app ou tente novamente.');
        return;
    }
  }

  Future<void> _handleContactsPermission(StepData step) async {
    final contactsPermissionRequester = _contactsPermissionRequester;
    final status = contactsPermissionRequester != null
        ? await contactsPermissionRequester()
        : await FlutterContacts.permissions.request(PermissionType.read);
    if (_isContactsPermissionGranted(status)) {
      return;
    }
    if (status == PermissionStatus.permanentlyDenied ||
        status == PermissionStatus.restricted) {
      final contactsSettingsOpener = _contactsSettingsOpener;
      if (contactsSettingsOpener != null) {
        await contactsSettingsOpener();
      } else {
        await FlutterContacts.permissions.openSettings();
      }
      return;
    }
    _showToast(step.gate?.onFailToast);
  }

  Future<void> _handleLocationPermissionFeedback(StepData step) async {
    final locationPermissionChecker = _locationPermissionChecker;
    final status = locationPermissionChecker != null
        ? await locationPermissionChecker()
        : await Geolocator.checkPermission();
    if (_isLocationPermissionGranted(status)) {
      return;
    }
    if (status == LocationPermission.deniedForever) {
      await _openAppSettings();
      return;
    }
    _showToast(step.gate?.onFailToast);
  }

  Future<void> _openAppSettings() async {
    final appSettingsOpener = _appSettingsOpener;
    if (appSettingsOpener != null) {
      await appSettingsOpener();
      return;
    }
    await Geolocator.openAppSettings();
  }

  static bool _isContactsPermissionGranted(PermissionStatus status) {
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  static bool _isLocationPermissionGranted(LocationPermission status) {
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  Future<void> _openFavoritesSelector(StepData step) async {
    final openSelector = _onOpenSelector;
    if (openSelector == null) {
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

    final selectionMode = config.selectionMode ?? 'single';
    final maxSelected = selectionMode == 'single'
        ? 1
        : (config.maxSelected ?? 0);
    final initialSelected = _selectedFromOptions(
      options,
      maxSelected: maxSelected,
    );
    final selectedValues = await openSelector(
      PushOptionSelectorPayload(
        title: step.title.value,
        body: step.body.value,
        layout: config.layout ?? 'list',
        gridColumns: config.gridColumns ?? 2,
        selectionMode: selectionMode,
        options: options,
        minSelected: config.minSelected ?? 0,
        maxSelected: maxSelected,
        initialSelected: initialSelected,
      ),
    );
    if (selectedValues == null) {
      return;
    }

    final answer = AnswerPayload(
      stepSlug: step.slug,
      value: selectedValues,
      metadata: const {'source': 'custom_action'},
    );
    final handler = _onStepSubmit;
    if (handler != null) {
      await handler(answer, step);
    }
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

  List<dynamic> _selectedFromOptions(
    List<OptionItem> options, {
    int? maxSelected,
  }) {
    final selected = options
        .where((option) => option.isSelected)
        .map((option) => option.value)
        .toList();
    if (selected.isEmpty) {
      return const [];
    }
    if (maxSelected != null &&
        maxSelected > 0 &&
        selected.length > maxSelected) {
      return selected.take(maxSelected).toList();
    }
    return selected;
  }

  void _showToast(String? message) {
    if (message == null || message.isEmpty) {
      return;
    }
    final onShowToast = _onShowToast;
    if (onShowToast == null) {
      return;
    }
    onShowToast(message);
  }
}
