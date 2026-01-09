import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:push_handler/push_handler.dart';

class PushAnswerPersistence {
  PushAnswerPersistence({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _storagePrefix = 'push_onboarding_answer';

  final FlutterSecureStorage _storage;

  Future<void> persist({
    required AnswerPayload answer,
    required StepData step,
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
      key: _buildStorageKey(storeKey),
      value: jsonEncode(payload),
    );
  }

  Future<Map<String, dynamic>?> read(String storeKey) async {
    final raw = await _storage.read(key: _buildStorageKey(storeKey));
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  String _buildStorageKey(String storeKey) {
    return '$_storagePrefix:$storeKey';
  }
}
