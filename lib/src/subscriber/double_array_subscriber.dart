import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/timestamped_value.dart';
import 'package:nt4/src/topic/double_array_topic.dart';

typedef TimestampedDoubleArray = TimestampedValue<List<double>>;

abstract class DoubleArraySubscriber extends Subscriber {
  @override
  DoubleArrayTopic get topic;

  List<double> get([List<double>? defaultValue]);

  TimestampedDoubleArray? getAtomic([List<double>? defaultValue]);

  List<TimestampedDoubleArray> readQueue();

  List<List<double>> readQueueValues();
}
