import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  final String? errorText;

  const Labeled(this.label, {super.key, required this.child, this.errorText});

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5),
          child: Text(
            label,
            style: t.bodyMedium.override(
              fontFamily: 'Inter',
              color: t.primaryText,
              fontSize: 16,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 6),
          child: child,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 2, 24, 10),
            child: Text(
              errorText!,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
