import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/timestamped_value.dart';
import 'package:nt4/src/topic/int_array_topic.dart';

typedef TimestampedIntArray = TimestampedValue<List<int>>;

abstract class IntArraySubscriber extends Subscriber {
  @override
  IntArrayTopic get topic;

  List<int> get([List<int>? defaultValue]);

  TimestampedIntArray? getAtomic([List<int>? defaultValue]);

  List<TimestampedIntArray> readQueue();

  List<List<int>> readQueueValues();
}
