import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Listens to network state changes. 
/// Can be provided globally via Provider or get_it.
class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _init();
  }

  void _init() async {
    // Check initial state
    final results = await _connectivity.checkConnectivity();
    _updateState(results);

    // Listen to changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateState);
  }

  void _updateState(List<ConnectivityResult> results) {
    // If the list is empty or only contains 'none', we are offline.
    final hasConnection = results.isNotEmpty && 
                          !results.contains(ConnectivityResult.none);
    
    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
