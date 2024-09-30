import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/topic/int_list_topic.dart';

typedef TimestampedIntList = TimestampedValue<List<int>>;

abstract class IntListSubscriber extends Subscriber {
  @override
  IntListTopic get topic;

  List<int> get([List<int>? defaultValue]);

  TimestampedIntList? getAtomic([List<int>? defaultValue]);

  List<TimestampedIntList> readQueue();

  List<List<int>> readQueueValues();
}
