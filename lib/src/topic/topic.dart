import 'dart:convert';

import 'package:nt4/src/network_table_instance.dart';
import 'package:nt4/src/network_table_type.dart';
import 'package:nt4/src/topic/topic_info.dart';

class Topic {
  final NetworkTableInstance _instance;
  final TopicInfo _info;
  final Map<String, dynamic> _properties = {};

  Topic(this._instance, this._info);

  int get handle => _info.handle;

  String get name => _info.name;

  bool get isValid => handle != 0;

  NetworkTableType get type => _info.type;

  String get typeString => type.valueStr;

  void setPersistent(bool persistent) {
    _properties['persistent'] = persistent;
    _instance.setProperties(this);
  }

  bool get isPersistent => _properties['persistent'] ?? false;

  void setRetained(bool retained) {
    _properties['retained'] = retained;
    _instance.setProperties(this);
  }

  bool get isRetained => _properties['retained'] ?? false;

  void setCached(bool cached) {
    _properties['cached'] = cached;
    _instance.setProperties(this);
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
        _info.handle == other.handle;
  }

  @override
  int get hashCode => handle;
}
