import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';

class MockAppDataBackend implements AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final json = {
      'name': 'Boilerplate',
      'type': 'tenant',
      'subdomain': 'boilerplate',
      'main_domain': 'https://boilerplate.belluga.space',
      'domains': <String>[],
      'app_domains': ['com.boilerplatebellugatenant.app'],
      'theme_data_settings': {
        'brightness_default': 'dark',
        'primary_seed_color': '#A36CE3',
        'secondary_seed_color': '#FF6E00',
      },
      'main_color': '#A36CE3',
      'main_logo_light_url':
          'https://boilerplate.belluga.space/storage/landlord/logos/light_logo.png',
      'main_logo_dark_url':
          'https://boilerplate.belluga.space/storage/landlord/logos/dark_logo.png',
      'main_icon_light_url':
          'https://boilerplate.belluga.space/storage/landlord/logos/light_icon.png',
      'main_icon_dark_url':
          'https://boilerplate.belluga.space/storage/landlord/logos/dark_icon.png',
    };

    return AppDataDTO.fromJson(json);
  }
}
