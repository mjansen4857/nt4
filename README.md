[![CI](https://github.com/mjansen4857/nt4/actions/workflows/ci.yaml/badge.svg)](https://github.com/mjansen4857/nt4/actions/workflows/ci.yaml)

Dart implementation of the WPILib NT4 protocol

## Usage

```dart
// Connect to NT4 server at 10.30.15.2
NT4Client client = NT4Client(
  serverBaseAddress: '10.30.15.2',
  onConnect: () {
    print('NT4 Client Connected');
  },
  onDisconnect: () {
    print('NT4 Client Disconnected');
  },
);

// Publish a topic and send data
NT4Topic examplePub =
    client.publishNewTopic('/SmartDashboard/CoolNumber', NT4TypeStr.typeInt);
client.addSample(examplePub, 123456);

// Subscribe to a topic
NT4Subscription exampleSub = client.subscribe('/SmartDashboard/Example');

// Recieve data from subscription with a callback or stream
exampleSub.listen((data) => print('Recieved data from callback: $data'));

await for (Object? data in exampleSub.stream()) {
  print('Recieved data from stream: $data');
}

// Temporarily subscribe to a topic to retrieve its data
double? oneTimeValue = await client.subscribeAndRetrieveData<double>('/SmartDashboard/ConstantValue');

if (oneTimeValue != null) {
  print('Receieved one time value from server: $oneTimeValue');
} else {
  print('Client receieved no value after 2.5 seconds');
}
```
