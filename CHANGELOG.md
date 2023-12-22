## 1.3.2

- Fix crash on reconnecting to server
- Ignore rtt protocol topic ID

## 1.3.1

- Fix connections being timed out too quickly

## 1.3.0

- Added ability to retrieve cached values
- Added a method to temporarily subscribe to a topic and receive the first announced value
- Topic properties will be updated if method is received from web socket
- If supported, will use the nt 4.1 RTT protocol to check connection status
- Added the ability to get a timestamped stream from a subscription
- 
## 1.2.0

- Add method to subscribe with custom options

## 1.1.1

- Potentially fix crash when client fails to connect
- Remove prints to console

## 1.1.0

- Add method to create a connection status stream

## 1.0.0

- Initial version.
