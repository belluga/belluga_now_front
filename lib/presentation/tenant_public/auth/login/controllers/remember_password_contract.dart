abstract class RememberPasswordContract {
  Stream<bool> get stream;
  bool get value;

  void toggle();
  void set(bool value);
  void dispose();
}
