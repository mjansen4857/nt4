import 'dart:typed_data';

import 'package:nt4/src/subscriber/subscriber.dart';
import 'package:nt4/src/timestamped_value.dart';
import 'package:nt4/src/topic/raw_topic.dart';

typedef TimestampedRaw = TimestampedValue<Uint8List>;

abstract class RawSubscriber extends Subscriber {
  @override
  RawTopic get topic;

  Uint8List get([Uint8List? defaultValue]);

  TimestampedRaw? getAtomic([Uint8List? defaultValue]);

  List<TimestampedRaw> readQueue();

  List<Uint8List> readQueueValues();
}
