import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/timestamped_value.dart';
import 'package:nt4/src/topic/bool_topic.dart';

typedef TimestampedBoolean = TimestampedValue<bool>;

abstract class BoolSubscriber extends Subscriber {
  @override
  BoolTopic get topic;

  bool get([bool? defaultValue]);

  TimestampedBoolean? getAtomic([bool? defaultValue]);

  List<TimestampedBoolean> readQueue();

  List<bool> readQueueValues();
}
