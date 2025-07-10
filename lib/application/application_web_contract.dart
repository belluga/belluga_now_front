import 'package:unifast_portal/application/application_contract.dart';
import 'package:unifast_portal/application/helpers/url_strategy/url_strategy.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:video_player_web_hls/video_player_web_hls.dart';

abstract class ApplicationWebContract extends ApplicationContract {
  ApplicationWebContract({super.key});

  @override
  Future<void> initialSettingsPlatform() async {
    setupUrlStrategy();
    VideoPlayerPluginHls.registerWith(webPluginRegistrar);
  }
}
