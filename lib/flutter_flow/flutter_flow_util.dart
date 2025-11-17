import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension NavExt on BuildContext {
  void pop<T extends Object?>([T? result]) => Navigator.of(this).pop<T>(result);
}

bool isiOS(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.iOS;

T valueOrDefault<T>(T? value, T defaultValue) => value ?? defaultValue;

// ✅ التعريف الصحيح كـ Getter
DateTime get getCurrentTimestamp => DateTime.now();

String dateTimeFormat(String pattern, DateTime? dateTime) {
  if (dateTime == null) return '';
  return DateFormat(pattern).format(dateTime);
}

extension TextStyleOverride on TextStyle {
  TextStyle override({
    String? fontFamily,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    TextDecoration? decoration,
    double? height,
  }) {
    return copyWith(
      fontFamily: fontFamily,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      decoration: decoration,
      height: height,
    );
  }
}

T createModel<T>(BuildContext context, T Function() create) => create();

extension ValidatorExtensions on String? Function(BuildContext, String?)? {
  FormFieldValidator<String>? asValidator(BuildContext context) {
    return this != null ? (value) => this!(context, value) : null;
  }
}
