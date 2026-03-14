import 'package:belluga_now/infrastructure/dal/dao/http/raw_json_envelope_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/landlord/landlord_auth_login_payload.dart';

class LandlordAuthResponseDecoder {
  const LandlordAuthResponseDecoder({
    RawJsonEnvelopeDecoder? envelopeDecoder,
  }) : _envelopeDecoder = envelopeDecoder ?? const RawJsonEnvelopeDecoder();

  final RawJsonEnvelopeDecoder _envelopeDecoder;

  LandlordAuthLoginPayload decodeLogin(Object? rawResponse) {
    final data = _envelopeDecoder.decodeDataMap(
      rawResponse,
      label: 'landlord auth login',
      fallbackToRoot: false,
    );
    final token = data['token']?.toString() ?? '';
    final user = data['user'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    return LandlordAuthLoginPayload(
      token: token,
      userId: userMap?['id']?.toString(),
    );
  }

  String? decodeProfileUserId(Object? rawResponse) {
    final data = _envelopeDecoder.decodeDataMap(
      rawResponse,
      label: 'landlord profile',
      fallbackToRoot: false,
    );
    return data['user_id']?.toString();
  }
}
