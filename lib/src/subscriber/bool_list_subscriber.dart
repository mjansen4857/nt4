import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/topic/bool_list_topic.dart';

typedef TimestampedBoolList = TimestampedValue<List<bool>>;

abstract class BoolListSubscriber extends Subscriber {
  @override
  BoolListTopic get topic;

  List<bool> get([List<bool>? defaultValue]);

  TimestampedBoolList? getAtomic([List<bool>? defaultValue]);

  List<TimestampedBoolList> readQueue();

  List<List<bool>> readQueueValues();
}
