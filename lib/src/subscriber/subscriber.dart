import 'package:nt4/src/pubsub.dart';

typedef TimestampedValue<T> = (DateTime timestamp, T value);

abstract class Subscriber extends PubSub {
  bool get exists;

  DateTime get lastChange;
}
