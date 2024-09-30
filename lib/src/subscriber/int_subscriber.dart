import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/timestamped_value.dart';
import 'package:nt4/src/topic/int_topic.dart';

typedef TimestampedInt = TimestampedValue<int>;

abstract class IntSubscriber extends Subscriber {
  @override
  IntTopic get topic;

  int get([int? defaultValue]);

  TimestampedInt? getAtomic([int? defaultValue]);

  List<TimestampedInt> readQueue();

  List<int> readQueueValues();
}
