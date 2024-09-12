import 'package:flutter/cupertino.dart';

enum SubscribeState { subscribed, unsubscribed, failed, subscribing }

class MqttSubscribeState extends ChangeNotifier {
  SubscribeState _currentState = SubscribeState.unsubscribed;

  SubscribeState get currentState => _currentState;

  void setSubscribeState(SubscribeState stateStatus) {
    _currentState = stateStatus;
    notifyListeners();
  }
}
