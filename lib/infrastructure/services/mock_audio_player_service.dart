import 'package:belluga_now/domain/media/audio_player_service_contract.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:stream_value/core/stream_value.dart';

/// Simple mock audio player service with persistent state across screens.
class MockAudioPlayerService implements AudioPlayerServiceContract {
  MockAudioPlayerService();

  @override
  final currentTrackStream =
      StreamValue<PartnerMediaView?>(defaultValue: null);
  @override
  final isPlayingStream = StreamValue<bool>(defaultValue: false);

  @override
  void play(PartnerMediaView track) {
    currentTrackStream.addValue(track);
    isPlayingStream.addValue(true);
  }

  @override
  void toggle() {
    isPlayingStream.addValue(!(isPlayingStream.value));
  }

  @override
  void stop() {
    isPlayingStream.addValue(false);
  }
}
