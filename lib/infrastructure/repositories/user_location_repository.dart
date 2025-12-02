import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stream_value/main.dart';

class UserLocationRepository {
  final userLocationStreamValue = StreamValue<CityCoordinate?>();

  Future<String?> resolveUserLocation() async {

    final _currentLocation = userLocationStreamValue.value;

    if(_currentLocation != null){
      return null;
    }

    return await _getCurrentUserLocation();
  }

  Future<String?> _getCurrentUserLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    
    if (!serviceEnabled) {
      return Future.value(
          'Ative os servicos de localizacao para ver sua posicao. Exibindo pontos padrao da cidade.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return Future.value(
          'Permita o acesso a localizacao para localizar pontos proximos. Exibindo pontos padrao da cidade.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );

    final coordinate = CityCoordinate(
      latitudeValue: LatitudeValue()..parse(position.latitude.toString()),
      longitudeValue: LongitudeValue()..parse(position.longitude.toString()),
    );

    userLocationStreamValue.addValue(coordinate);

    return null;
  }
}
