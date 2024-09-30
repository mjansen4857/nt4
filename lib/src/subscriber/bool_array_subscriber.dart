import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/timestamped_value.dart';
import 'package:nt4/src/topic/bool_array_topic.dart';

typedef TimestampedBooleanArray = TimestampedValue<List<bool>>;

abstract class BoolArraySubscriber extends Subscriber {
  @override
  BoolArrayTopic get topic;

  List<bool> get([List<bool>? defaultValue]);

  TimestampedBooleanArray? getAtomic([List<bool>? defaultValue]);

  List<TimestampedBooleanArray> readQueue();

  List<List<bool>> readQueueValues();
}
