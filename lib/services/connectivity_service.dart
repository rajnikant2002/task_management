import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _connectivityController = StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool _isConnected = true;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    _connectivity.onConnectivityChanged.listen((result) {
      _isConnected = !result.contains(ConnectivityResult.none);
      _connectivityController.add(_isConnected);
    });

    final result = await _connectivity.checkConnectivity();
    _isConnected = !result.contains(ConnectivityResult.none);
    _connectivityController.add(_isConnected);
  }

  bool get isConnected => _isConnected;

  void dispose() {
    _connectivityController.close();
  }
}
