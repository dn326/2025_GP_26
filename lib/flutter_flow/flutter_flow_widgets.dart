import 'package:flutter/material.dart';

import 'flutter_flow_theme.dart';

class FFButtonOptions {
  // الأساسيات (من كودك الأصلي)
  final double height;
  final double? width;
  final Color? color; // background color (enabled)
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? iconPadding;
  final double? elevation;

  // إضافات اختيارية بدون حذف أي شيء من الأساس
  // لون نص افتراضي (لو ما حطيتي color داخل textStyle)
  final Color? textColor;

  // حدود الزر في الحالة العادية
  final BorderSide? borderSide;

  // خصائص الـ Hover
  final Color? hoverColor;
  final Color? hoverTextColor;
  final double? hoverElevation;
  final BorderSide? hoverBorderSide;
  final Color? hoverShadowColor;

  // خصائص الـ Disabled (إضافة جديدة)
  final Color? disabledColor;
  final Color? disabledTextColor;

  const FFButtonOptions({
    this.height = 44,
    this.width,
    this.color,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.iconPadding,
    this.elevation = 0,

    // إضافات جديدة (كلها اختيارية)
    this.textColor,
    this.borderSide,
    this.hoverColor,
    this.hoverTextColor,
    this.hoverElevation,
    this.hoverBorderSide,
    this.hoverShadowColor,

    // خصائص الـ Disabled
    this.disabledColor,
    this.disabledTextColor,
  });
}

class FFButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final FFButtonOptions options;
  final Widget? icon;

  const FFButtonWidget({
    super.key,
    required this.text,
    required this.onPressed,
    required this.options,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    // قيم أساس (base)
    final Color baseBg = options.color ?? theme.primary;
    final Color baseFg =
        options.textColor ?? (options.textStyle?.color ?? Colors.white);
    final double baseElevation = options.elevation ?? 0;
    final BorderSide? baseSide = options.borderSide;
    final Color baseShadow = Colors.transparent;

    // نجهّز ButtonStyle باستخدام WidgetStateProperty (البديل الحديث)
    final ButtonStyle style = ButtonStyle(
      minimumSize: WidgetStateProperty.all<Size>(
        Size(options.width ?? 0, options.height),
      ),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
        options.padding ?? const EdgeInsets.symmetric(horizontal: 16),
      ),
      shape: WidgetStateProperty.all<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius:
              (options.borderRadius as BorderRadius?) ??
              BorderRadius.circular(12),
        ),
      ),
      side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return options.hoverBorderSide ?? baseSide;
        }
        return baseSide;
      }),
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return options.disabledColor ?? Colors.grey;
        }
        if (states.contains(WidgetState.hovered)) {
          return options.hoverColor ?? baseBg;
        }
        return baseBg;
      }),

      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return options.disabledTextColor ?? Colors.white70;
        }
        if (states.contains(WidgetState.hovered)) {
          return options.hoverTextColor ?? baseFg;
        }
        return baseFg;
      }),

      elevation: WidgetStateProperty.resolveWith<double>((states) {
        if (states.contains(WidgetState.hovered)) {
          return options.hoverElevation ?? baseElevation;
        }
        return baseElevation;
      }),
      shadowColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.hovered)) {
          return options.hoverShadowColor ?? baseShadow;
        }
        return baseShadow;
      }),
    );

    // نستخدم textStyle الممرّر كما هو
    final TextStyle labelStyle =
        options.textStyle ??
        theme.bodyMedium.copyWith(color: baseFg, fontWeight: FontWeight.w600);

    return SizedBox(
      height: options.height,
      width: options.width,
      child: icon == null
          ? ElevatedButton(
              onPressed: onPressed,
              style: style,
              child: Text(text, style: labelStyle),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Padding(
                padding: options.iconPadding ?? EdgeInsets.zero,
                child: icon!,
              ),
              label: Text(text, style: labelStyle),
              style: style,
            ),
    );
  }
}
