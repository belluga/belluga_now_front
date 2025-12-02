class EnumFunctions {
  static T enumFromString<T>(
      {required Iterable<T> values,
      required String enumItem,
      required T defaultValue}) {
    T enumReturn = values.firstWhere(
      (e) => e.toString() == enumItem,
      orElse: () => defaultValue,
    );

    return enumReturn;
  }
}
