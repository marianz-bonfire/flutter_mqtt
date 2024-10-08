import 'package:flutter/cupertino.dart';

enum MqttAppConnectionState { connected, disconnected, connecting }

class MqttState extends ChangeNotifier {
  MqttAppConnectionState _appConnectionState =
      MqttAppConnectionState.disconnected;

  MqttAppConnectionState get currentState => _appConnectionState;

  void setAppConnectionState(MqttAppConnectionState stateStatus) {
    _appConnectionState = stateStatus;
    notifyListeners();
  }
}
