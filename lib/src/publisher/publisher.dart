import 'package:nt4/src/pubsub.dart';

abstract class Publisher<T> extends PubSub {
  void set(T value, DateTime? time);

  void setDefault(T value);
}
