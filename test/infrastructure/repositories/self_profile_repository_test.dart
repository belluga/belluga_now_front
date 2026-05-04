import 'dart:typed_data';

import 'package:belluga_now/domain/user/user_profile_media_upload.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_profile_media_bytes_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_timezone_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/self_profile_backend_contract.dart';
import 'package:belluga_now/infrastructure/repositories/self_profile_repository.dart';
import 'package:belluga_now/infrastructure/user/dtos/self_profile_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

void main() {
  test('fetchCurrentProfile stores the canonical self profile in stream',
      () async {
    final backend = _FakeSelfProfileBackend(
      fetchResult: const SelfProfileDto(
        userId: '507f1f77bcf86cd799439011',
        accountProfileId: '507f1f77bcf86cd799439012',
        displayName: 'Perfil Atual',
        bio: 'Bio atual',
        phone: '+55 27 99876-1234',
        avatarUrl: 'https://tenant.test/avatar.png',
        pendingInvitesCount: 2,
        confirmedEventsCount: 5,
        timezone: 'America/Sao_Paulo',
      ),
    );
    final repository = SelfProfileRepository(backend: backend);

    final profile = await repository.fetchCurrentProfile();

    expect(profile.displayName, 'Perfil Atual');
    expect(repository.currentProfileStreamValue.value?.displayName,
        'Perfil Atual');
    expect(repository.currentProfileStreamValue.value?.pendingInvitesCount, 2);
  });

  test('updateCurrentProfile refreshes and exposes the latest backend profile',
      () async {
    final backend = _FakeSelfProfileBackend(
      fetchResult: const SelfProfileDto(
        userId: '507f1f77bcf86cd799439011',
        accountProfileId: '507f1f77bcf86cd799439012',
        displayName: 'Perfil Atualizado',
        bio: 'Nova bio',
        phone: '+55 27 99876-1234',
        avatarUrl: null,
        pendingInvitesCount: 1,
        confirmedEventsCount: 9,
        timezone: 'America/Sao_Paulo',
      ),
    );
    final repository = SelfProfileRepository(backend: backend);
    final displayNameValue =
        UserDisplayNameValue(isRequired: false, minLenght: null)
          ..parse('Perfil Atualizado');
    final bioValue = DescriptionValue(defaultValue: '', minLenght: null)
      ..parse('Nova bio');
    final timezoneValue = UserTimezoneValue()..parse('America/Sao_Paulo');
    final removeAvatarValue = DomainBooleanValue(defaultValue: false)
      ..parse('true');

    final updated = await repository.updateCurrentProfile(
      displayNameValue: displayNameValue,
      bioValue: bioValue,
      timezoneValue: timezoneValue,
      removeAvatarValue: removeAvatarValue,
    );

    expect(backend.updateCalls, 2);
    expect(backend.updateSnapshots[0].displayName, 'Perfil Atualizado');
    expect(backend.updateSnapshots[0].bio, 'Nova bio');
    expect(backend.updateSnapshots[0].timezone, 'America/Sao_Paulo');
    expect(backend.updateSnapshots[0].removeAvatar, isNull);
    expect(backend.updateSnapshots[1].displayName, isNull);
    expect(backend.updateSnapshots[1].bio, isNull);
    expect(backend.updateSnapshots[1].timezone, isNull);
    expect(backend.updateSnapshots[1].removeAvatar, isTrue);
    expect(updated.displayName, 'Perfil Atualizado');
    expect(updated.confirmedEventsCount, 9);
    expect(repository.currentProfileStreamValue.value?.displayName,
        'Perfil Atualizado');
  });

  test(
    'mixed text and avatar updates split backend mutations and refresh once',
    () async {
      final backend = _FakeSelfProfileBackend(
        fetchResult: const SelfProfileDto(
          userId: '507f1f77bcf86cd799439011',
          accountProfileId: '507f1f77bcf86cd799439012',
          displayName: 'Perfil Atualizado',
          bio: 'Bio atualizada',
          phone: '+55 27 99876-1234',
          avatarUrl: 'https://tenant.test/avatar.png',
          pendingInvitesCount: 1,
          confirmedEventsCount: 4,
          timezone: 'America/Sao_Paulo',
        ),
      );
      final repository = SelfProfileRepository(backend: backend);
      final displayNameValue =
          UserDisplayNameValue(isRequired: false, minLenght: null)
            ..parse('Perfil Atualizado');
      final avatarUpload = UserProfileMediaUpload(
        bytesValue: UserProfileMediaBytesValue()
          ..set(Uint8List.fromList([1, 2, 3])),
        fileNameValue: GenericStringValue(isRequired: true, minLenght: null)
          ..parse('avatar.png'),
        mimeTypeValue: GenericStringValue(isRequired: false, minLenght: null)
          ..parse('image/png'),
      );

      await repository.updateCurrentProfile(
        displayNameValue: displayNameValue,
        avatarUpload: avatarUpload,
      );

      expect(backend.updateCalls, 2);
      expect(backend.updateSnapshots[0].displayName, 'Perfil Atualizado');
      expect(backend.updateSnapshots[0].avatarUpload, isNull);
      expect(backend.updateSnapshots[1].displayName, isNull);
      expect(backend.updateSnapshots[1].avatarUpload, isNotNull);
      expect(backend.fetchCalls, 1);
    },
  );
}

class _FakeSelfProfileBackend implements SelfProfileBackendContract {
  _FakeSelfProfileBackend({required this.fetchResult});

  SelfProfileDto fetchResult;
  int updateCalls = 0;
  int fetchCalls = 0;
  String? lastDisplayName;
  String? lastBio;
  String? lastTimezone;
  bool? lastRemoveAvatar;
  UserProfileMediaUpload? lastAvatarUpload;
  final List<_UpdateSnapshot> updateSnapshots = <_UpdateSnapshot>[];

  @override
  Future<SelfProfileDto> fetchCurrentProfile() async {
    fetchCalls += 1;
    return fetchResult;
  }

  @override
  Future<void> updateCurrentProfile({
    UserDisplayNameValue? displayNameValue,
    DescriptionValue? bioValue,
    UserTimezoneValue? timezoneValue,
    UserProfileMediaUpload? avatarUpload,
    DomainBooleanValue? removeAvatarValue,
  }) async {
    updateCalls += 1;
    lastDisplayName = displayNameValue?.value;
    lastBio = bioValue?.value;
    lastTimezone = timezoneValue?.value;
    lastRemoveAvatar = removeAvatarValue?.value;
    lastAvatarUpload = avatarUpload;
    updateSnapshots.add(
      _UpdateSnapshot(
        displayName: displayNameValue?.value,
        bio: bioValue?.value,
        timezone: timezoneValue?.value,
        removeAvatar: removeAvatarValue?.value,
        avatarUpload: avatarUpload,
      ),
    );
  }
}

class _UpdateSnapshot {
  const _UpdateSnapshot({
    required this.displayName,
    required this.bio,
    required this.timezone,
    required this.removeAvatar,
    required this.avatarUpload,
  });

  final String? displayName;
  final String? bio;
  final String? timezone;
  final bool? removeAvatar;
  final UserProfileMediaUpload? avatarUpload;
}
