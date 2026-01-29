import 'package:belluga_now/infrastructure/dal/dto/profile/profile_media_dto.dart';
import 'package:stream_value/core/stream_value.dart';

/// Simple mock audio player service with persistent state across screens.
class MockAudioPlayerService {
  MockAudioPlayerService();

  final currentTrackStream = StreamValue<ProfileMediaDTO?>(defaultValue: null);
  final isPlayingStream = StreamValue<bool>(defaultValue: false);

  void play(ProfileMediaDTO track) {
    currentTrackStream.addValue(track);
    isPlayingStream.addValue(true);
  }

  void toggle() {
    isPlayingStream.addValue(!(isPlayingStream.value));
  }

  void stop() {
    isPlayingStream.addValue(false);
  }
}
