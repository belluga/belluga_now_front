import 'dart:math';

mixin MockFunctions {
  String get fakeMongoId {
    const chars = 'abcdef0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(24, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }
}
