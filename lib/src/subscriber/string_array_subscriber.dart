import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/timestamped_value.dart';
import 'package:nt4/src/topic/string_array_topic.dart';

typedef TimestampedStringArray = TimestampedValue<List<String>>;

abstract class StringArraySubscriber extends Subscriber {
  @override
  StringArrayTopic get topic;

  List<String> get([List<String>? defaultValue]);

  TimestampedStringArray? getAtomic([List<String>? defaultValue]);

  List<TimestampedStringArray> readQueue();

  List<List<String>> readQueueValues();
}
