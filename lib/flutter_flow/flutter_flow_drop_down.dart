// lib/flutter_flow/flutter_flow_drop_down.dart
import 'package:flutter/material.dart';

import 'form_field_controller.dart';

class FlutterFlowDropDown<T> extends StatelessWidget {
  final List<DropdownMenuItem<T>>? options;
  final FormFieldController<T>? controller;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final bool isExpanded;
  final double? width;
  final double? height;
  final Color? fillColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const FlutterFlowDropDown({
    super.key,
    this.options,
    this.controller,
    this.onChanged,
    this.hintText,
    this.isExpanded = true,
    this.width,
    this.height,
    this.fillColor,
    this.borderColor,
    this.borderWidth = 1,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final value = controller?.value;
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<T>(
        isExpanded: isExpanded,
        initialValue: value,
        items: options,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
        ),
        onChanged: (v) {
          if (controller != null) controller!.value = v;
          onChanged?.call(v);
        },
      ),
    );
  }
}
