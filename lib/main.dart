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
      home: ChangeNotifierProvider<MqttState>(
          create: (_) => MqttState(),
          child: MyHomePage(title: 'Flutter Demo Home Page')),
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
    setState(() {

    });
  }

  void disconnect() {
    manager!.disconnect();
    setState(() {});
  }

  void subscribe() {
    manager!.subscribe('jay#');
    setState(() {});
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
              onPressed: appState.appConnectionState ==
                  MqttAppConnectionState.connected
                  ? null
                  : () {
                connect(appState);
              },
              child: const Text('Connect'),
            ),
            ElevatedButton(
              onPressed: appState.appConnectionState ==
                  MqttAppConnectionState.disconnected
                  ? null
                  : () {
                disconnect();
              },
              child: const Text('Disconnect'),
            ),
            ElevatedButton(
              onPressed: appState.appConnectionState ==
                  MqttAppConnectionState.disconnected
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
            Text(appState.appConnectionState == MqttAppConnectionState.connected
                ? 'connected'
                : appState.appConnectionState ==
                MqttAppConnectionState.connecting
                ? 'connecting'
                : appState.appConnectionState ==
                MqttAppConnectionState.disconnected
                ? 'disconnected'
                : '-'),
            manager == null
                ? const Expanded(child: SizedBox())
                : Expanded(
              child:
              StreamBuilder<List<MqttReceivedMessage<MqttMessage>>>(
                stream: manager!.client!.updates,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final MqttPublishMessage recMessage = snapshot
                        .data!.first.payload as MqttPublishMessage;
                    final String pt =
                    MqttPublishPayload.bytesToStringAsString(
                        recMessage.payload.message);

                    chats.add(pt);
                    chats.reversed;

                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(chats[index].toString()),
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
