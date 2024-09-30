import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/timestamped_value.dart';
import 'package:nt4/src/topic/double_topic.dart';

typedef TimestampedDouble = TimestampedValue<double>;

abstract class DoubleSubscriber extends Subscriber {
  @override
  DoubleTopic get topic;

  double get([double? defaultValue]);

  TimestampedDouble? getAtomic([double? defaultValue]);

  List<TimestampedDouble> readQueue();

  List<double> readQueueValues();
}
