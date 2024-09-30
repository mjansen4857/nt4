import 'dart:convert';

import 'package:nt4/src/network_table_instance.dart';
import 'package:nt4/src/network_table_type.dart';

typedef TimestampedValue<T> = (DateTime timestamp, T value);

class Topic {
  final int _handle;
  String _name;
  NetworkTableType _type;

  final Map<String, dynamic> _properties = {};

  Topic(this._handle, this._name, this._type);

  int get handle => _handle;

  String get name => _name;

  bool get isValid => handle != 0;

  NetworkTableType get type => _type;

  String get typeString => type.valueStr;

  void setPersistent(bool persistent) {
    _properties['persistent'] = persistent;
    NetworkTableInstance.getDefault().setProperties(this);
  }

  bool get isPersistent => _properties['persistent'] ?? false;

  void setRetained(bool retained) {
    _properties['retained'] = retained;
    NetworkTableInstance.getDefault().setProperties(this);
  }

  bool get isRetained => _properties['retained'] ?? false;

  void setCached(bool cached) {
    _properties['cached'] = cached;
    NetworkTableInstance.getDefault().setProperties(this);
  }

  bool get iscached => _properties['cached'] ?? false;

  String getPropertiesJson() {
    return jsonEncode(_properties);
  }

  void setProperties(String propertiesJson) {
    Map<String, dynamic> props = jsonDecode(propertiesJson);

    _properties.clear();
    _properties.addAll(props);
  }

  @override
  bool operator ==(Object other) {
    return other is Topic &&
        other.runtimeType == runtimeType &&
        _handle == other.handle;
  }

  @override
  int get hashCode => handle;
}

mixin PubSub {
  int get handle;

  bool get isValid => handle != 0;

  Topic get topic =>
      NetworkTableInstance.getDefault().getTopicFromHandle(handle);
}

mixin Subscriber<T> on PubSub {
  T get defaultValue;

  bool get exists => NetworkTableInstance.getDefault().getTopicExists(handle);

  DateTime get lastChange =>
      NetworkTableInstance.getDefault().getEntryLastChange(handle);

  T get([T? defaultValue]);

  TimestampedValue<T>? getAtomic([T? defaultValue]);

  List<TimestampedValue<T>> readQueue();

  List<T> readQueueValues();
}

mixin Publisher<T> on PubSub {
  void set(T value, [DateTime? time]);

  void setDefault(T value);
}
