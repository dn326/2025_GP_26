import 'package:flutter/material.dart';

/// بديل مبسّط لقاعدة الـ Model في FlutterFlow
abstract class FlutterFlowModel<T extends StatefulWidget>
    extends ChangeNotifier {
  void initState(BuildContext context) {}

  void onUpdate() {
    notifyListeners();
  }

  void maybeDispose() {
    dispose();
  }
}

/// بديل createModel المستخدم في صفحات FF
M createModel<M>(BuildContext context, M Function() creator) => creator();

/// بديل safeSetState بصيغة extension.
/// ملاحظة: setState محمية؛ نكتم تحذير الأنانلايزر لأنها مستخدمة ضمن State.
extension SafeSetState on State {
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    setState(fn);
  }
}
