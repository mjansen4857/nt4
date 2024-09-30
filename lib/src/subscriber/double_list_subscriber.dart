import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/topic/double_list_topic.dart';

typedef TimestampedDoubleList = TimestampedValue<List<double>>;

abstract class DoubleListSubscriber extends Subscriber {
  @override
  DoubleListTopic get topic;

  List<double> get([List<double>? defaultValue]);

  TimestampedDoubleList? getAtomic([List<double>? defaultValue]);

  List<TimestampedDoubleList> readQueue();

  List<List<double>> readQueueValues();
}
