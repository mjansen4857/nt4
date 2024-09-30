import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/topic/bool_topic.dart';

typedef TimestampedBool = TimestampedValue<bool>;

abstract class BoolSubscriber extends Subscriber {
  @override
  BoolTopic get topic;

  bool get([bool? defaultValue]);

  TimestampedBool? getAtomic([bool? defaultValue]);

  List<TimestampedBool> readQueue();

  List<bool> readQueueValues();
}
