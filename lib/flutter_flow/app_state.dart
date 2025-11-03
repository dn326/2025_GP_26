import 'package:flutter/foundation.dart';

class FFAppState extends ChangeNotifier {
  static final FFAppState _instance = FFAppState._();

  factory FFAppState() => _instance;

  FFAppState._();

  void update(VoidCallback cb) {
    cb();
    notifyListeners();
  }
}
