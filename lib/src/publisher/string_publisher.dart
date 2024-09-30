import 'package:nt4/src/publisher/publisher.dart';
import 'package:nt4/src/topic/string_topic.dart';

abstract class StringPublisher extends Publisher<String> {
  @override
  StringTopic get topic;
}
