import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/topic/string_list_topic.dart';

typedef TimestampedStringList = TimestampedValue<List<String>>;

abstract class StringListSubscriber extends Subscriber {
  @override
  StringListTopic get topic;

  List<String> get([List<String>? defaultValue]);

  TimestampedStringList? getAtomic([List<String>? defaultValue]);

  List<TimestampedStringList> readQueue();

  List<List<String>> readQueueValues();
}
