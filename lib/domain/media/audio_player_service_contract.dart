import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class AudioPlayerServiceContract {
  StreamValue<PartnerMediaView?> get currentTrackStream;
  StreamValue<bool> get isPlayingStream;

  void play(PartnerMediaView track);
  void toggle();
  void stop();
}
