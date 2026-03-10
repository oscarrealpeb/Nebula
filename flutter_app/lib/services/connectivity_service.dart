import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract class ConnectivityService {
  Future<bool> isOnlineNow();
  Stream<bool> get onStatusChanged;
  void dispose();
}

class InternetConnectivityService implements ConnectivityService {
  final InternetConnection _connection = InternetConnection();

  @override
  Future<bool> isOnlineNow() async {
    return _connection.hasInternetAccess;
  }

  @override
  Stream<bool> get onStatusChanged {
    return _connection.onStatusChange
        .map((status) => status == InternetStatus.connected)
        .distinct();
  }

  @override
  void dispose() {}
}

class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({required bool initialOnline}) : _online = initialOnline;

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> isOnlineNow() async => _online;

  @override
  Stream<bool> get onStatusChanged => _controller.stream;

  void emit(bool online) {
    _online = online;
    _controller.add(online);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
