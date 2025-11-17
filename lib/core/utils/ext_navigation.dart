import 'package:flutter/cupertino.dart';

extension FeqExtNavigator on BuildContext {
  Future<T?> pushNamed<T>(String routeName, {Map<String, dynamic>? extra}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: extra);
  }
}