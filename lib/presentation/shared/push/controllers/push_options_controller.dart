import 'package:push_handler/push_handler.dart';

class PushOptionsController {
  PushOptionsController();

  Future<List<OptionItem>> resolve(OptionSource source) async {
    if (source.type.trim().toLowerCase() != 'method') {
      return const [];
    }
    final method = _normalizeMethodName(source.name);
    if (method == 'getfavorites') {
      return _loadFavorites();
    }
    if (method == 'gettags') {
      return _loadTags();
    }
    return const [];
  }

  String _normalizeMethodName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<List<OptionItem>> _loadFavorites() async {
    return _staticFavorites();
  }

  List<OptionItem> _loadTags() {
    return _staticTags();
  }

  List<OptionItem> _staticFavorites() {
    const entries = [
      {'value': 'praia_do_morro', 'label': 'Praia do Morro'},
      {'value': 'centro_historico', 'label': 'Centro Histórico'},
      {'value': 'passeio_de_barco', 'label': 'Passeio de Barco'},
      {'value': 'gastronomia_local', 'label': 'Gastronomia Local'},
      {'value': 'mirante', 'label': 'Mirante'},
      {'value': 'vida_noturna', 'label': 'Vida Noturna'},
    ];
    return entries
        .map((entry) =>
            OptionItem(value: entry['value'], label: entry['label']))
        .toList(growable: false);
  }

  List<OptionItem> _staticTags() {
    const tags = [
      'praias',
      'restaurantes',
      'experiencias_no_mar',
      'trilhas',
      'cultura',
      'familia',
      'romantico',
    ];
    return tags
        .map((tag) => OptionItem(value: tag, label: tag))
        .toList(growable: false);
  }

}
