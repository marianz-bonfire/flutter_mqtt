import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'mqtt_state.dart';

class MqttManager {
  final String identifier;
  final String host;
  final String topic;
  final MqttState mqttAppConnectionState;

  MqttManager({
    required this.identifier,
    required this.host,
    required this.topic,
    required this.mqttAppConnectionState,
  });

  MqttServerClient? client;

  void initMqttClient() {
    client = MqttServerClient(host, identifier)
      ..logging(on: true)
      ..port = 1883
      ..keepAlivePeriod = 60
      ..onConnected = onConnected
      ..onSubscribed = onSubscribed
      ..onDisconnected = onDisconnected
      ..onUnsubscribed = onUnsubscribed
      ..onSubscribeFail = onSubscribeFail
      ..pongCallback = pong;

    final connMessage = MqttConnectMessage()
      ..withClientIdentifier(identifier)
      ..withWillTopic('willTopic')
      ..withWillMessage('will Message')
      ..withWillQos(MqttQos.atMostOnce)
      ..startClean();

    print('mosquitto client connecting...');

    client!.connectionMessage = connMessage;
  }

  void connect() async {
    assert(client != null);
    try {
      mqttAppConnectionState.setAppConnectionState(MqttAppConnectionState.connecting);
      await client!.connect();
    } on Exception catch (e) {
      disconnect();
    }
  }

  void disconnect() {
    print('disconnect');
    client!.disconnect();
    mqttAppConnectionState.setAppConnectionState(MqttAppConnectionState.disconnected);
  }

  void publish(String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    try {
      client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    } catch (e) {
      print(e);
    }
  }

  void subscribe(String topic) {
    client!.subscribe(topic,  MqttQos.atMostOnce);
  }

  void onSubscribed(String topic) {
    print('you subscribe this topic $topic');
  }

  void onDisconnected() {
    print('you disconnect');
    if (client!.connectionStatus!.returnCode == MqttConnectReturnCode.noneSpecified) {
      print('onDisconnected callback is solicited, this is correct');
    }
    mqttAppConnectionState.setAppConnectionState(MqttAppConnectionState.disconnected);
  }

  void onConnected() {
    mqttAppConnectionState.setAppConnectionState(MqttAppConnectionState.connected);
    print('mosquitto client connected...');
    client!.subscribe(topic, MqttQos.atMostOnce);
    client!.updates!.listen((event) {
      final MqttPublishMessage recMessage = event.first.payload as MqttPublishMessage;

      final String pt = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

      print('Change notification:: topic is <${event.first.topic}>, payload is <-- $pt -->');
    });
  }

  // subscribe to topic failed
  void onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

  // unsubscribe succeeded
  void onUnsubscribed(String? topic) {
    print('Unsubscribed topic: $topic');
  }

  // PING response received
  void pong() {
    print('Ping response client callback invoked');
  }
}
