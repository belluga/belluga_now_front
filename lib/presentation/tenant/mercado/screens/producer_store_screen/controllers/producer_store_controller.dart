import 'package:belluga_now/presentation/tenant/mercado/models/mercado_producer.dart';
import 'package:get_it/get_it.dart' show Disposable;
import 'package:stream_value/core/stream_value.dart';

class ProducerStoreController implements Disposable {
  ProducerStoreController()
      : isFollowingStreamValue = StreamValue<bool>(defaultValue: false);

  MercadoProducer? _producer;
  final StreamValue<bool> isFollowingStreamValue;

  MercadoProducer? get producer => _producer;

  void attachProducer(MercadoProducer producer) {
    _producer = producer;
    isFollowingStreamValue.addValue(false);
  }

  void toggleFollow() {
    final current = isFollowingStreamValue.value;
    isFollowingStreamValue.addValue(!current);
  }

  @override
  void onDispose() {
    isFollowingStreamValue.dispose();
  }
}
