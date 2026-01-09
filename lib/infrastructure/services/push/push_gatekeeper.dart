import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_persistence.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:push_handler/push_handler.dart';

class PushGatekeeper {
  PushGatekeeper({
    required BuildContext? Function() contextProvider,
    PushAnswerPersistence? answerPersistence,
  })  : _contextProvider = contextProvider,
        _answerPersistence = answerPersistence ?? PushAnswerPersistence();

  final BuildContext? Function() _contextProvider;
  final PushAnswerPersistence _answerPersistence;

  Future<bool> check(StepData step) async {
    final gate = step.gate;
    if (gate == null) {
      return true;
    }

    switch (gate.type) {
      case 'notifications_permission':
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        final granted = settings.authorizationStatus ==
                AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
        if (!granted) {
          _showToast(gate.onFailToast);
        }
        return granted;
      case 'location_permission':
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _showToast(gate.onFailToast);
          return false;
        }
        final permission = await Geolocator.checkPermission();
        final granted = permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
        if (!granted) {
          _showToast(gate.onFailToast);
        }
        return granted;
      case 'friends_permission':
      case 'contacts_permission':
        final status = await Permission.contacts.status;
        final granted = status.isGranted;
        if (!granted) {
          _showToast(gate.onFailToast);
        }
        return granted;
      case 'favorites_min_selected':
      case 'selection_min':
        final allowed = await _checkMinSelected(step);
        if (!allowed) {
          _showToast(gate.onFailToast);
        }
        return allowed;
      default:
        return true;
    }
  }

  void _showToast(String? message) {
    if (message == null || message.isEmpty) {
      return;
    }
    final context = _contextProvider();
    final messenger = context != null ? ScaffoldMessenger.maybeOf(context) : null;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _checkMinSelected(StepData step) async {
    final storeKey = step.onSubmit?.storeKey ?? step.config?.storeKey;
    if (storeKey == null || storeKey.isEmpty) {
      return false;
    }
    final stored = await _answerPersistence.read(storeKey);
    final value = stored?['value'];
    final count = value is List ? value.length : value == null ? 0 : 1;
    final minSelected = step.config?.minSelected ?? 1;
    return count >= minSelected;
  }
}
