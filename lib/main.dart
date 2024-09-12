import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:provider/provider.dart';

import 'mqtt_service/mqtt_manager.dart';
import 'mqtt_service/mqtt_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: ChangeNotifierProvider<MqttState>(
        create: (_) => MqttState(),
        child: const MyHomePage(title: 'Flutter MQTT Demo'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController chat = TextEditingController();
  List chats = [];
  MqttManager? manager;

  void Function()? connect(MqttState state) {
    String osPrefix = 'Flutter_iOS';
    if (Platform.isAndroid) {
      osPrefix = 'Flutter_Android';
    }

    osPrefix = 'mqttx_53552333';

    manager = MqttManager(
      host: 'broker.hivemq.com',
      topic: 'jay',
      identifier: osPrefix,
      mqttAppConnectionState: state,
    );
    manager!.initMqttClient();
    manager!.connect();
    setState(() {});
  }

  void disconnect() {
    manager!.disconnect();
    setState(() {});
  }

  void subscribe() {
    manager!.subscribe('jay#');
    setState(() {});
  }

  Widget connectionStatus(MqttState appState) {
    String status = '-';
    Color statusColor = Colors.white;
    if (appState.currentState == MqttAppConnectionState.connected) {
      status = 'CONNECTED';
      statusColor = Colors.green;
    } else if (appState.currentState == MqttAppConnectionState.connecting) {
      status = 'CONNECTING...';
      statusColor = Colors.blue;
    } else if (appState.currentState == MqttAppConnectionState.disconnected) {
      status = 'DISCONNECTED';
      statusColor = Colors.red;
    } else {
      status = '-';
    }
    return Container(
      width: double.infinity,
      color: statusColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          status,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MqttState appState = Provider.of<MqttState>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: appState.currentState == MqttAppConnectionState.connected
                  ? null
                  : () {
                      connect(appState);
                    },
              child: const Text('Connect'),
            ),
            ElevatedButton(
              onPressed: appState.currentState == MqttAppConnectionState.disconnected
                  ? null
                  : () {
                      disconnect();
                    },
              child: const Text('Disconnect'),
            ),
            ElevatedButton(
              onPressed: appState.currentState == MqttAppConnectionState.disconnected
                  ? null
                  : () {
                      subscribe();
                    },
              child: const Text('Subscribe'),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            connectionStatus(appState),
            manager == null
                ? const Expanded(child: SizedBox())
                : Expanded(
                    child: StreamBuilder<List<MqttReceivedMessage<MqttMessage>>>(
                      stream: manager!.client!.updates,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final MqttPublishMessage recMessage = snapshot.data!.first.payload as MqttPublishMessage;
                          final String pt = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

                          chats.add(pt);
                          chats.reversed;

                          return ListView.builder(
                            itemCount: chats.length,
                            itemBuilder: (context, index) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(chats[index].toString()),
                                  ),
                                  Divider(),
                                ],
                              );
                            },
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: chat,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (manager != null) {
                        manager!.publish(chat.text);
                        chat.clear();
                        FocusScope.of(context).unfocus();
                      }
                    },
                    child: const Text('Publish'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
