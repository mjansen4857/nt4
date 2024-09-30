import 'package:nt4/src/nt_client.dart';
import 'package:nt4/src/networktables/topic.dart';

class NetworkTableInstance {
  final NTClient _client;

  const NetworkTableInstance(this._client);

  void setPort(int port) {
    _client.setPort(port);
  }

  void setServer(String server) {
    _client.setServer(server);
  }

  void startClient([String? clientName]) {
    _client.start(clientName);
  }

  void setProperties(Topic topic) {
    // TODO: implement setProperties
  }

  Topic getTopicFromHandle(int handle) {
    // TODO: implement getTopicFromHandle
    throw UnimplementedError();
  }

  bool getTopicExists(int handle) {
    // TODO: implement getTopicExists
    throw UnimplementedError();
  }

  DateTime getEntryLastChange(int handle) {
    // TODO: implement getEntryLastChange
    throw UnimplementedError();
  }

  dynamic getValue(int handle) {
    // TODO: implement getValue
    throw UnimplementedError();
  }

  static NetworkTableInstance? _defaultInstance;

  static NetworkTableInstance getDefault() {
    _defaultInstance ??= NetworkTableInstance(NTClient());
    return _defaultInstance!;
  }
}
