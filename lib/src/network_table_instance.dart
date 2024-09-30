import 'package:nt4/src/nt_client.dart';
import 'package:nt4/src/topic/topic.dart';

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
    // TODO: send over ws
  }

  static NetworkTableInstance? _defaultInstance;

  static NetworkTableInstance getDefault() {
    _defaultInstance ??= NetworkTableInstance(NTClient());
    return _defaultInstance!;
  }
}
