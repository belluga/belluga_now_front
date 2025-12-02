import 'package:belluga_now/application/application_contract.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:video_player_web_hls/video_player_web_hls.dart';

abstract class ApplicationWebContract extends ApplicationContract {
  ApplicationWebContract({super.key});

  @override
  Future<void> initialSettingsPlatform() async {
    setUrlStrategy(PathUrlStrategy());
    VideoPlayerPluginHls.registerWith(webPluginRegistrar);
  }
}
