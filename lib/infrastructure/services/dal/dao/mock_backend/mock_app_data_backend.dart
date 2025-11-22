import 'package:belluga_now/infrastructure/services/dal/dao/app_data_backend_contract.dart';

class MockAppDataBackend implements AppDataBackendContract {
  @override
  Future<Map<String, dynamic>> fetch() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'name': 'Guarappari',
      'type': 'tenant',
      'main_domain': 'https://guarappari.com.br',
      'domains': ['https://guarappari.com.br'],
      'app_domains': ['com.guarappari.app'],
      'theme_data_settings': {
        'light_scheme_data': {
          'brightness': 'light',
          'primary_seed_color': '#4FA0E3',
          'secondary_seed_color': '#E80D5D',
        },
        'dark_scheme_data': {
          'brightness': 'dark',
          'primary_seed_color': '#4FA0E3',
          'secondary_seed_color': '#E80D5D',
        },
      },
      // Extra fields for app owner avatar
      'icon_url':
          'https://logodownload.org/wp-content/uploads/2018/08/aurora-logo-0.png',
      'main_color': '#4FA0E3',
      'main_logo_url':
          'https://logodownload.org/wp-content/uploads/2018/08/aurora-logo-0.png',
    };
  }
}
