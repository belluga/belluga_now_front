import 'dart:typed_data';

Future<Uint8List> loadBellugaSafeWebImageBytes(String url) {
  throw UnsupportedError(
    'Safe web image byte loading is only available on web targets.',
  );
}

bool shouldUseBellugaSafeWebImageLoader(String url) => false;
