import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:push_handler/push_handler.dart';

class PushAnswerPersistence {
  PushAnswerPersistence({
    FlutterSecureStorage? storage,
    String? Function()? messageInstanceIdProvider,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _messageInstanceIdProvider = messageInstanceIdProvider;

  static const _storagePrefix = 'push_onboarding_answer';

  final FlutterSecureStorage _storage;
  final String? Function()? _messageInstanceIdProvider;

  Future<void> persist({
    required AnswerPayload answer,
    required StepData step,
    String? messageInstanceId,
  }) async {
    final storeKey = step.onSubmit?.storeKey ?? step.config?.storeKey;
    if (storeKey == null || storeKey.isEmpty) {
      return;
    }

    final payload = {
      'step_slug': answer.stepSlug,
      'value': answer.value,
      'metadata': answer.metadata,
      'stored_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _storage.write(
      key: _buildStorageKey(storeKey, messageInstanceId: messageInstanceId),
      value: jsonEncode(payload),
    );
  }

  Future<Map<String, dynamic>?> read(
    String storeKey, {
    String? messageInstanceId,
  }) async {
    final raw = await _storage.read(
      key: _buildStorageKey(storeKey, messageInstanceId: messageInstanceId),
    );
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  String _buildStorageKey(
    String storeKey, {
    String? messageInstanceId,
  }) {
    final instanceId = _resolveMessageInstanceId(messageInstanceId);
    if (instanceId == null || instanceId.isEmpty) {
      return '$_storagePrefix:$storeKey';
    }
    return '$_storagePrefix:$instanceId:$storeKey';
  }

  String? _resolveMessageInstanceId(String? messageInstanceId) {
    final explicit = messageInstanceId?.trim() ?? '';
    if (explicit.isNotEmpty) {
      return explicit;
    }
    return _messageInstanceIdProvider?.call()?.trim();
  }
}
