// ضع هذا الامتداد في أي ملف يتم استيراده قبل صفحاتك
import 'package:flutter/widgets.dart';

extension FFListDivide on List<Widget> {
  /// يُرجع نسخة من القائمة وبين كل عنصرين يضيف الويدجت [divider].
  List<Widget> divide(Widget divider) {
    if (length <= 1) return List<Widget>.from(this);
    final out = <Widget>[];
    for (var i = 0; i < length; i++) {
      out.add(this[i]);
      if (i < length - 1) out.add(divider);
    }
    return out;
  }
}
