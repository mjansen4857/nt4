import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/timestamped_value.dart';
import 'package:nt4/src/topic/string_topic.dart';

typedef TimestampedString = TimestampedValue<String>;

abstract class StringSubscriber extends Subscriber {
  @override
  StringTopic get topic;

  String get([String? defaultValue]);

  TimestampedString? getAtomic([String? defaultValue]);

  List<TimestampedString> readQueue();

  List<String> readQueueValues();
}
