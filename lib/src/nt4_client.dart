import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:messagepack/messagepack.dart';
import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NT4Client {
  static const int _pingIntervalMsV40 = 1000;
  static const int _pingIntervalMsV41 = 200;

  static const int _pingTimeoutMsV40 = 5000;
  static const int _pingTimeoutMsV41 = 1000;

  String serverBaseAddress;
  final void Function()? onConnect;
  final void Function()? onDisconnect;

  final int _startTime = DateTime.now().microsecondsSinceEpoch;

  final Map<int, NT4Subscription> _subscriptions = {};
  int _subscriptionUIDCounter = 0;
  int _publishUIDCounter = 0;
  final Map<String, NT4Topic> _clientPublishedTopics = {};
  final Map<int, NT4Topic> _announcedTopics = {};
  final Map<String, Object?> _lastAnnouncedValues = {};
  final Map<String, int> _lastAnnouncedTimestamps = {};
  int _clientId = 0;
  int _serverTimeOffsetUS = 0;

  bool _serverConnectionActive = false;
  bool _rttConnectionActive = false;
  bool _useRTT = false;

  Timer? _pingTimer;
  Timer? _pongTimer;

  int _lastReceivedTime = 0;

  int _pingInterval = _pingIntervalMsV40;
  int _timeoutInterval = _pingTimeoutMsV40;

  WebSocketChannel? _mainWebsocket;
  WebSocketChannel? _rttWebsocket;

  /// Create an NT4 client. This will connect to an NT4 server running at
  /// [serverBaseAddress]. This should be either 'localhost' if running a
  /// simulator, or 10.TE.AM.2 if running on a robot.
  /// Example: '10.30.15.2'
  ///
  /// [onConnect] and [onDisconnect] are callbacks that will be called when
  /// the connection status changes
  NT4Client({
    required this.serverBaseAddress,
    this.onConnect,
    this.onDisconnect,
  }) {
    _wsConnect();
  }

  /// Change the host address of the NT4 server
  ///
  /// This will attempt to close the current connection, then connect with
  /// the new address
  void setServerBaseAddress(String serverBaseAddress) {
    this.serverBaseAddress = serverBaseAddress;
    _wsOnClose();
  }

  /// Create a stream that represents the status of the connection
  /// to the NT4 server
  Stream<bool> connectionStatusStream() async* {
    yield _serverConnectionActive;
    bool lastYielded = _serverConnectionActive;

    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      if (_serverConnectionActive != lastYielded) {
        yield _serverConnectionActive;
        lastYielded = _serverConnectionActive;
      }
    }
  }

  /// Subscribe to a topic with the name [topic] and a period of [period]
  ///
  /// [topic] should be the full path to the topic you wish to subscribe to
  /// Example: '/SmartDashboard/SomeTopic'
  ///
  /// [period] represents how often the server should send updated data
  /// for this topic, in seconds
  NT4Subscription subscribePeriodic(String topic, [double period = 0.1]) {
    return subscribe(
        topic, NT4SubscriptionOptions(periodicRateSeconds: period));
  }

  /// Subscribe to a topic with the name [topic] and a period of [period]
  ///
  /// [topic] should be the full path to the topic you wish to subscribe to
  /// Example: '/SmartDashboard/SomeTopic'
  ///
  /// [options] The subscription options
  NT4Subscription subscribe(String topic, NT4SubscriptionOptions options) {
    NT4Subscription newSub = NT4Subscription(
      topic: topic,
      uid: getNewSubUID(),
      options: options,
    );

    if (_lastAnnouncedValues.containsKey(topic)) {
      newSub._updateValue(_lastAnnouncedValues[topic]);
    }
    if (_lastAnnouncedTimestamps.containsKey(topic)) {
      newSub._updateTimestamp(_lastAnnouncedTimestamps[topic]!);
    }

    _subscriptions[newSub.uid] = newSub;
    _wsSubscribe(newSub);
    return newSub;
  }

  /// Subscribe to all samples for a given topic with the name [topic].
  /// This will receive all data published to this topic instead of being
  /// limited to a given rate.
  ///
  /// [topic] should be the full path to the topic you wish to subscribe to
  /// Example: '/SmartDashboard/SomeTopic'
  NT4Subscription subscribeAllSamples(String topic) {
    NT4Subscription newSub = NT4Subscription(
      topic: topic,
      uid: getNewSubUID(),
      options: const NT4SubscriptionOptions(all: true),
    );

    if (_lastAnnouncedValues.containsKey(topic)) {
      newSub._updateValue(_lastAnnouncedValues[topic]);
    }
    if (_lastAnnouncedTimestamps.containsKey(topic)) {
      newSub._updateTimestamp(_lastAnnouncedTimestamps[topic]!);
    }

    _subscriptions[newSub.uid] = newSub;
    _wsSubscribe(newSub);
    return newSub;
  }

  /// Temporarily creates a subscription to the [topic] and returns the first value the server sends
  ///
  /// [topic] should be the full path to the topic you wish to retrieve data from
  /// Example: '/SmartDashboard/SomeTopic'
  ///
  /// [timeout] should be the maximum time the client should spend attempting to retrieve
  /// data from the topic before returning null, defaults to 2.5 seconds
  Future<T?> subscribeAndRetrieveData<T>(String topic,
      {timeout = const Duration(seconds: 2, milliseconds: 500)}) async {
    NT4Subscription subscription = subscribePeriodic(topic);

    T? value;

    try {
      value = subscription
          .stream()
          .firstWhere((element) => element != null && element is T)
          .timeout(timeout) as T?;
    } catch (e) {
      value = null;
    }

    unSubscribe(subscription);

    return value;
  }

  /// Unsubscribe from the given subscription, [sub]
  /// The client will stop receiving any data for this subscription
  void unSubscribe(NT4Subscription sub) {
    _subscriptions.remove(sub.uid);
    _wsUnsubscribe(sub);
  }

  /// Clear all subscriptions for the client. This will unsubscribe from
  /// all previously subscribed to topics
  void clearAllSubscriptions() {
    for (NT4Subscription sub in _subscriptions.values) {
      unSubscribe(sub);
    }
  }

  /// Set the properties of a [topic]
  ///
  /// If [isPersistent] is true, any data published to this topic will
  /// be saved to the local storage of the server, persisting when the server
  /// restarts.
  ///
  /// If [isRetained] is true, any data published to this topic will be
  /// retained by the server whenever the publisher (this client) disconnects.
  /// If this is false, the topic will be removed from the server when the
  /// client disconnects.
  void setProperties(NT4Topic topic, bool isPersistent, bool isRetained) {
    topic.properties['persistent'] = isPersistent;
    topic.properties['retained'] = isRetained;
    _wsSetProperties(topic);
  }

  /// Create and publish a new topic with a given [name] and [type]
  ///
  /// [name] should be the full path to the topic you wish to subscribe to
  /// Example: '/SmartDashboard/SomeTopic'
  ///
  /// Use [NT4TypeStr] to supply the type
  NT4Topic publishNewTopic(String name, String type) {
    NT4Topic newTopic = NT4Topic(name: name, type: type, properties: {});
    publishTopic(newTopic);
    return newTopic;
  }

  /// Publish a given [topic]
  void publishTopic(NT4Topic topic) {
    topic.pubUID = getNewPubUID();
    _clientPublishedTopics[topic.name] = topic;
    _wsPublish(topic);
  }

  /// Unpublish a given [topic]
  ///
  /// The client will no longer be able to send any data for this topic\
  /// to the server unless it is published again.
  void unpublishTopic(NT4Topic topic) {
    _clientPublishedTopics.remove(topic.name);
    _wsUnpublish(topic);
  }

  /// Add a sample of data for a given [topic]
  ///
  /// The [data] supplied should match the type of the topic when it
  /// was published.
  ///
  /// [timestamp] should not be specified
  void addSample(NT4Topic topic, dynamic data, [int? timestamp]) {
    timestamp ??= _getServerTimeUS();

    _lastAnnouncedValues[topic.name] = data;
    _lastAnnouncedTimestamps[topic.name] = timestamp;

    _wsSendBinary(
        serialize([topic.pubUID, timestamp, topic.getTypeId(), data]));
  }

  /// Add a sample of data for a topic with a given name, [topic]
  /// If the topic with the supplied name is not published, no data will
  /// be sent.
  ///
  /// The [data] supplied should match the type of the topic when it
  /// was published.
  ///
  /// [timestamp] should not be specified
  ///
  /// Returns true if the topic was found and data was sent
  bool addSampleFromName(String topic, dynamic data, [int? timestamp]) {
    for (NT4Topic t in _announcedTopics.values) {
      if (t.name == topic) {
        addSample(t, data, timestamp);
        return true;
      }
    }
    return false;
  }

  /// Returns the last sample of data the client receieved for the given [topic].
  ///
  /// This is only the last value that the client has received from the server, so
  /// if there is no subscription with the same name as the given [topic] name, it will
  /// return either an old outdated value, or null.
  Object? getLastAnnouncedValueByTopic(NT4Topic topic) {
    return getLastAnnouncedValueByName(topic.name);
  }

  /// Returns the last sample of data the client receieved for the given [topic].
  ///
  /// This is only the last value that the client has received from the server, so
  /// if there is no subscription with the same name as the given [topic], it will
  /// return either an old outdated value, or null.
  Object? getLastAnnouncedValueByName(String topic) {
    if (_lastAnnouncedValues.containsKey(topic)) {
      return _lastAnnouncedValues[topic];
    }

    return null;
  }

  /// Returns the timestamp of the last sample of data the client receieved for the given [topic].
  ///
  /// This is only the value of the last timestamp that the client has received from the server, so
  /// if there is no subscription with the same name as the given [topic], it will
  /// return either an old timestamp, or null.
  int? getLastTimestampByTopic(NT4Topic topic) {
    return getLastTimestampByName(topic.name);
  }

  /// Returns the timestamp of the last sample of data the client receieved for the given [topic].
  ///
  /// This is only the value of the last timestamp that the client has received from the server, so
  /// if there is no subscription with the same name as the given [topic], it will
  /// return either an old timestamp, or null.
  int? getLastTimestampByName(String topic) {
    return _lastAnnouncedTimestamps[topic];
  }

  /// Get an already announced topic with a given name, [topic]
  ///
  /// If there is not an announced topic with the name [topic], `null` will be returned
  NT4Topic? getTopicFromName(String topic) {
    return _announcedTopics.values.firstWhereOrNull((e) => e.name == topic);
  }

  int _getClientTimeUS() {
    return DateTime.now().microsecondsSinceEpoch - _startTime;
  }

  int _getServerTimeUS() {
    return _getClientTimeUS() + _serverTimeOffsetUS;
  }

  void _wsSendTimestamp() {
    var timeTopic = _announcedTopics[-1];
    if (timeTopic != null) {
      int timeToSend = _getClientTimeUS();

      var rawData =
          serialize([timeTopic.pubUID, 0, timeTopic.getTypeId(), timeToSend]);

      if (_useRTT) {
        _rttWebsocket?.sink.add(rawData);
      } else {
        _mainWebsocket?.sink.add(rawData);
      }
    }
  }

  void _wsHandleRecieveTimestamp(int serverTimestamp, int clientTimestamp) {
    int rxTime = _getClientTimeUS();

    int rtt = rxTime - clientTimestamp;
    int serverTimeAtRx = (serverTimestamp - rtt / 2.0).round();
    _serverTimeOffsetUS = serverTimeAtRx - rxTime;

    _lastReceivedTime = rxTime;
  }

  void _checkPingStatus(Timer timer) {
    if (!_serverConnectionActive || _lastReceivedTime == 0) {
      return;
    }

    int currentTime = _getClientTimeUS();

    if (currentTime - _lastReceivedTime > _timeoutInterval) {
      _wsOnClose();
    }
  }

  void _wsSubscribe(NT4Subscription sub) {
    _wsSendJSON('subscribe', sub._toSubscribeJson());
  }

  void _wsUnsubscribe(NT4Subscription sub) {
    _wsSendJSON('unsubscribe', sub._toUnsubscribeJson());
  }

  void _wsPublish(NT4Topic topic) {
    _wsSendJSON('publish', topic.toPublishJson());
  }

  void _wsUnpublish(NT4Topic topic) {
    _wsSendJSON('unpublish', topic.toUnpublishJson());
  }

  void _wsSetProperties(NT4Topic topic) {
    _wsSendJSON('setproperties', topic.toPropertiesJson());
  }

  void _wsSendJSON(String method, Map<String, dynamic> params) {
    _mainWebsocket?.sink.add(jsonEncode([
      {
        'method': method,
        'params': params,
      }
    ]));
  }

  void _wsSendBinary(dynamic data) {
    _mainWebsocket?.sink.add(data);
  }

  void _wsConnect() async {
    if (_serverConnectionActive) {
      return;
    }

    _clientId = Random().nextInt(99999999);

    String serverAddr = 'ws://$serverBaseAddress:5810/nt/DartClient_$_clientId';

    _mainWebsocket =
        WebSocketChannel.connect(Uri.parse(serverAddr), protocols: [
      'networktables.first.wpi.edu',
      'v4.1.networktables.first.wpi.edu',
    ]);

    // Prevents connecting to the wrong address when changing IP address
    if (!serverAddr.contains(serverBaseAddress)) {
      return;
    }

    try {
      await _mainWebsocket!.ready;
    } catch (e) {
      // Failed to connect... try again
      Future.delayed(const Duration(seconds: 1), _wsConnect);
      return;
    }

    _pingTimer?.cancel();
    _pongTimer?.cancel();

    if (_mainWebsocket!.protocol == 'v4.1.networktables.first.wpi.edu') {
      _useRTT = true;
      _pingInterval = _pingIntervalMsV41;
      _timeoutInterval = _pingTimeoutMsV41;
      _rttConnect();
    } else {
      _useRTT = false;
      _pingInterval = _pingIntervalMsV40;
      _timeoutInterval = _pingTimeoutMsV40;
    }

    _mainWebsocket!.stream.listen(
      (data) {
        if (!_serverConnectionActive) {
          _lastAnnouncedValues.clear();
          _lastAnnouncedTimestamps.clear();

          _serverConnectionActive = true;
          onConnect?.call();
        }
        _wsOnMessage(data);
      },
      onDone: _wsOnClose,
      onError: (err) {},
    );

    NT4Topic timeTopic = NT4Topic(
        name: "Time",
        type: NT4TypeStr.typeInt,
        id: -1,
        pubUID: -1,
        properties: {});
    _announcedTopics[timeTopic.id] = timeTopic;

    _lastReceivedTime = 0;
    _wsSendTimestamp();

    _pingTimer = Timer.periodic(Duration(milliseconds: _pingInterval), (timer) {
      _wsSendTimestamp();
    });
    _pongTimer =
        Timer.periodic(Duration(milliseconds: _pingInterval), _checkPingStatus);

    for (NT4Topic topic in _clientPublishedTopics.values) {
      _wsPublish(topic);
      _wsSetProperties(topic);
    }

    for (NT4Subscription sub in _subscriptions.values) {
      _wsSubscribe(sub);
    }
  }

  void _rttConnect() async {
    if (!_useRTT || _rttConnectionActive) {
      return;
    }

    String rttServerAddr = 'ws://$serverBaseAddress:5810/nt/elastic';
    _rttWebsocket = WebSocketChannel.connect(Uri.parse(rttServerAddr),
        protocols: ['rtt.networktables.first.wpi.edu']);

    try {
      await _rttWebsocket!.ready;
    } catch (e) {
      Future.delayed(const Duration(seconds: 1), _rttConnect);
      return;
    }

    // Prevents connecting to the wrong address when changing IP address
    if (!rttServerAddr.contains(serverBaseAddress)) {
      return;
    }

    _rttConnectionActive = true;

    _rttWebsocket!.stream.listen(
      (data) {
        if (data is! List<int>) {
          return;
        }

        var msg = Unpacker.fromList(data).unpackList();

        int topicID = msg[0] as int;
        int timestampUS = msg[1] as int;
        var value = msg[3];

        if (value is! int) {
          return;
        }

        if (topicID == -1) {
          _wsHandleRecieveTimestamp(timestampUS, value);
        }
      },
      onDone: _rttOnClose,
    );
  }

  void _rttOnClose() {
    _rttWebsocket?.sink.close();
    _rttWebsocket = null;

    _lastReceivedTime = 0;
    _rttConnectionActive = false;
    _useRTT = false;
  }

  void _wsOnClose() {
    _mainWebsocket?.sink.close();
    _rttWebsocket?.sink.close();

    _mainWebsocket = null;
    _rttWebsocket = null;

    _serverConnectionActive = false;
    _rttConnectionActive = false;
    _useRTT = false;

    _lastReceivedTime = 0;

    onDisconnect?.call();

    _announcedTopics.clear();

    Future.delayed(const Duration(seconds: 1), _wsConnect);
  }

  void _wsOnMessage(data) {
    if (data is String) {
      var rxArr = jsonDecode(data.toString());

      for (var msg in rxArr) {
        if (msg is! Map) {
          continue;
        }

        var method = msg['method'];
        var params = msg['params'];

        if (method == null || method is! String) {
          continue;
        }

        if (params == null || params is! Map) {
          continue;
        }

        if (method == 'announce') {
          NT4Topic? currentTopic;
          for (NT4Topic topic in _clientPublishedTopics.values) {
            if (params['name'] == topic.name) {
              currentTopic = topic;
            }
          }

          NT4Topic newTopic = NT4Topic(
              name: params['name'],
              type: params['type'],
              id: params['id'],
              pubUID: params['pubid'] ?? (currentTopic?.pubUID ?? 0),
              properties: params['properties']);
          _announcedTopics[newTopic.id] = newTopic;
        } else if (method == 'unannounce') {
          NT4Topic? removedTopic = _announcedTopics[params['id']];
          if (removedTopic == null) {
            return;
          }
          _announcedTopics.remove(removedTopic.id);
        } else if (method == 'properties') {
          String topicName = params['name'];
          NT4Topic? topic = getTopicFromName(topicName);

          if (topic == null) {
            return;
          }

          Map<String, dynamic> update = params['update'];
          for (MapEntry<String, dynamic> entry in update.entries) {
            if (entry.value == null) {
              topic.properties.remove(entry.key);
            } else {
              topic.properties[entry.key] = entry.value;
            }
          }
        } else {
          return;
        }
      }
    } else {
      var u = Unpacker.fromList(data);

      bool done = false;
      while (!done) {
        try {
          var msg = u.unpackList();

          int topicID = msg[0] as int;
          int timestampUS = msg[1] as int;
          // int typeID = msg[2] as int;
          var value = msg[3];

          if (topicID >= 0) {
            NT4Topic topic = _announcedTopics[topicID]!;
            _lastAnnouncedValues[topic.name] = value;
            _lastAnnouncedTimestamps[topic.name] = timestampUS;
            for (NT4Subscription sub in _subscriptions.values) {
              if (sub.topic == topic.name) {
                sub._updateValue(value);
              }
            }
          } else if (topicID == -1) {
            _wsHandleRecieveTimestamp(timestampUS, value as int);
          }
        } catch (err) {
          done = true;
        }
      }
    }
  }

  int getNewSubUID() {
    _subscriptionUIDCounter++;
    return _subscriptionUIDCounter + _clientId;
  }

  int getNewPubUID() {
    _publishUIDCounter++;
    return _publishUIDCounter + _clientId;
  }
}

class NT4SubscriptionOptions {
  final double periodicRateSeconds;
  final bool all;
  final bool topicsOnly;
  final bool prefix;

  const NT4SubscriptionOptions({
    this.periodicRateSeconds = 0.1,
    this.all = false,
    this.topicsOnly = false,
    this.prefix = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'periodic': periodicRateSeconds,
      'all': all,
      'topicsonly': topicsOnly,
      'prefix': prefix,
    };
  }
}

class NT4Topic {
  final String name;
  final String type;
  int id;
  int pubUID;
  final Map<String, dynamic> properties;

  NT4Topic({
    required this.name,
    required this.type,
    this.id = 0,
    this.pubUID = 0,
    required this.properties,
  });

  Map<String, dynamic> toPublishJson() {
    return {
      'name': name,
      'type': type,
      'pubuid': pubUID,
    };
  }

  Map<String, dynamic> toUnpublishJson() {
    return {
      'name': name,
      'pubuid': pubUID,
    };
  }

  Map<String, dynamic> toPropertiesJson() {
    return {
      'name': name,
      'update': properties,
    };
  }

  int getTypeId() {
    return NT4TypeStr.typeMap[type]!;
  }
}

class NT4Subscription {
  final String topic;
  final NT4SubscriptionOptions options;
  final int uid;

  Object? currentValue;
  int timestamp = 0;

  final List<Function(Object?)> _listeners = [];

  NT4Subscription({
    required this.topic,
    this.options = const NT4SubscriptionOptions(),
    this.uid = -1,
  });

  void listen(Function(Object?) onChanged) {
    _listeners.add(onChanged);
  }

  Stream<Object?> stream({bool yieldAll = false}) async* {
    yield currentValue;
    var lastYielded = currentValue;

    while (true) {
      await Future.delayed(
          Duration(milliseconds: (options.periodicRateSeconds * 1000).round()));
      if (currentValue != lastYielded || yieldAll) {
        yield currentValue;
        lastYielded = currentValue;
      }
    }
  }

  Stream<({Object? value, int timestamp})> timestampedStream(
      {bool yieldAll = false}) async* {
    yield (value: currentValue, timestamp: timestamp);
    var lastYielded = (value: currentValue, timestamp: timestamp);

    while (true) {
      await Future.delayed(
          Duration(milliseconds: (options.periodicRateSeconds * 1000).round()));

      var current = (value: currentValue, timestamp: timestamp);
      if (current != lastYielded || yieldAll) {
        yield current;
        lastYielded = current;
      }
    }
  }

  void _updateValue(Object? value) {
    currentValue = value;
    for (var listener in _listeners) {
      listener(currentValue);
    }
  }

  void _updateTimestamp(int timestamp) {
    this.timestamp = timestamp;
  }

  Map<String, dynamic> _toSubscribeJson() {
    return {
      'topics': [topic],
      'options': options.toJson(),
      'subuid': uid,
    };
  }

  Map<String, dynamic> _toUnsubscribeJson() {
    return {
      'subuid': uid,
    };
  }
}

class NT4ValueReq {
  final List<String> topics;

  const NT4ValueReq({
    this.topics = const [],
  });

  Map<String, dynamic> toGetValsJson() {
    return {
      'topics': topics,
    };
  }
}

class NT4TypeStr {
  static final Map<String, int> typeMap = {
    'boolean': 0,
    'double': 1,
    'int': 2,
    'float': 3,
    'string': 4,
    'json': 4,
    'raw': 5,
    'rpc': 5,
    'msgpack': 5,
    'protobuff': 5,
    'boolean[]': 16,
    'double[]': 17,
    'int[]': 18,
    'float[]': 19,
    'string[]': 20,
  };

  static const typeBool = 'boolean';
  static const typeFloat64 = 'double';
  static const typeInt = 'int';
  static const typeFloat32 = 'float';
  static const typeStr = 'string';
  static const typeJson = 'json';
  static const typeBinaryRaw = 'raw';
  static const typeBinaryRPC = 'rpc';
  static const typeBinaryMsgpack = 'msgpack';
  static const typeBinaryProtobuf = 'protobuf';
  static const typeBoolArr = 'boolean[]';
  static const typeFloat64Arr = 'double[]';
  static const typeIntArr = 'int[]';
  static const typeFloat32Arr = 'float[]';
  static const typeStrArr = 'string[]';
}
