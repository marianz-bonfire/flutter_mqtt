import 'package:flutter_mqtt/mqtt_service/mqtt_state.dart';
import 'package:flutter_mqtt/mqtt_service/mqtt_subscribe_state.dart';
import 'package:flutter_mqtt/utils/logger.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttManager {
  final String identifier;
  final String host;
  final String topic;
  final MqttState mqttAppConnectionState;
  final MqttSubscribeState? mqttSubscribeState;

  MqttManager({
    required this.identifier,
    required this.host,
    required this.topic,
    required this.mqttAppConnectionState,
    this.mqttSubscribeState,
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

    Logger.info('mosquitto client connecting...');

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
    Logger.info('disconnect');
    client!.disconnect();
    mqttAppConnectionState.setAppConnectionState(MqttAppConnectionState.disconnected);
  }

  void publish(String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    try {
      client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    } catch (e) {
      Logger.error('PUBLISH ERROR: ${e.toString()}');
    }
  }

  void subscribe(String topic) {
    mqttSubscribeState?.setSubscribeState(SubscribeState.subscribing);
    client!.subscribe(topic, MqttQos.atMostOnce);
  }

  void onSubscribed(String topic) {
    mqttSubscribeState?.setSubscribeState(SubscribeState.subscribed);
    Logger.info('you subscribe this topic $topic');
  }

  void onDisconnected() {
    Logger.info('onDisconnected');
    if (client!.connectionStatus!.returnCode == MqttConnectReturnCode.noneSpecified) {
      Logger.info('onDisconnected callback is solicited, this is correct');
    }
    mqttAppConnectionState.setAppConnectionState(MqttAppConnectionState.disconnected);
    mqttSubscribeState?.setSubscribeState(SubscribeState.unsubscribed);
  }

  void onConnected() {
    mqttAppConnectionState.setAppConnectionState(MqttAppConnectionState.connected);
    Logger.info('mosquitto client connected...');
    client!.subscribe(topic, MqttQos.atMostOnce);
    client!.updates!.listen((event) {
      final MqttPublishMessage recMessage = event.first.payload as MqttPublishMessage;

      final String pt = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

      Logger.info('Change notification:: topic is <${event.first.topic}>, payload is <-- $pt -->');
    });
  }

  // subscribe to topic failed
  void onSubscribeFail(String topic) {
    Logger.info('Failed to subscribe $topic');
    mqttSubscribeState?.setSubscribeState(SubscribeState.failed);
  }

  // unsubscribe succeeded
  void onUnsubscribed(String? topic) {
    Logger.info('Unsubscribed topic: $topic');
    mqttSubscribeState?.setSubscribeState(SubscribeState.unsubscribed);
  }

  // PING response received
  void pong() {
    Logger.info('Ping response client callback invoked');
  }
}
