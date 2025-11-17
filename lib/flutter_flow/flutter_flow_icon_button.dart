import 'package:flutter/material.dart';

class FlutterFlowIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double buttonSize;
  final double borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final double borderWidth;
  final Icon icon;

  const FlutterFlowIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.buttonSize = 44,
    this.borderRadius = 12,
    this.fillColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fillColor ?? Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: borderColor != null
            ? BorderSide(color: borderColor!, width: borderWidth)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onPressed,
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Center(child: icon),
        ),
      ),
    );
  }
}
