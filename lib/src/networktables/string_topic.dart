import 'package:nt4/src/network_table_instance.dart';
import 'package:nt4/src/network_table_type.dart';
import 'package:nt4/src/networktables/topic.dart';

typedef TimestampedString = TimestampedValue<String>;

class StringTopic extends Topic {
  StringTopic(int handle, String name)
      : super(handle, name, NetworkTableType.kString);
}

class StringEntry with PubSub, Subscriber<String>, Publisher<String> {
  @override
  final int handle;
  @override
  final String defaultValue;

  StringEntry(this.handle, this.defaultValue);

  @override
  StringTopic get topic => super.topic as StringTopic;

  @override
  String get([String? defaultValue]) {
    final value = NetworkTableInstance.getDefault().getValue(handle);
    if (value == null || value is! String) {
      return defaultValue ?? this.defaultValue;
    }
    return value;
  }

  @override
  TimestampedString? getAtomic([String? defaultValue]) {
    defaultValue ??= this.defaultValue;
    // TODO: implement getAtomic
    throw UnimplementedError();
  }

  @override
  List<TimestampedString> readQueue() {
    // TODO: implement readQueue
    throw UnimplementedError();
  }

  @override
  List<String> readQueueValues() {
    // TODO: implement readQueueValues
    throw UnimplementedError();
  }

  @override
  void set(String value, [DateTime? time]) {
    // TODO: implement set
  }

  @override
  void setDefault(String value) {
    // TODO: implement setDefault
  }
}
