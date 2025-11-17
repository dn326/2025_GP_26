import 'package:flutter/material.dart';

import '../components/feq_components.dart';

/// A reusable password field widget with live validation rules display
class PasswordFieldWithValidation extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String? hint;
  final bool showValidationRules;
  final InputDecoration? decoration;
  final TextStyle? labelStyle;
  final VoidCallback? onTap;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final EdgeInsetsGeometry? labelPadding;
  final EdgeInsetsGeometry? childPadding;

  const PasswordFieldWithValidation({
    super.key,
    required this.controller,
    this.focusNode,
    required this.label,
    this.hint,
    this.showValidationRules = true,
    this.decoration,
    this.labelStyle,
    this.onTap,
    this.onFieldSubmitted,
    this.textInputAction,
    this.labelPadding,
    this.childPadding,
  });

  @override
  State<PasswordFieldWithValidation> createState() =>
      PasswordFieldWithValidationState();
}

class PasswordFieldWithValidationState
    extends State<PasswordFieldWithValidation> {
  bool _obscureText = true;
  bool _showRules = false;

  // Live password validation flags
  bool _hasMinLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validatePassword);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validatePassword);
    super.dispose();
  }

  void _validatePassword() {
    String pwd = widget.controller.text;
    setState(() {
      _hasMinLength = pwd.length >= 8;
      _hasUpper = pwd.contains(RegExp(r'[A-Z]'));
      _hasLower = pwd.contains(RegExp(r'[a-z]'));
      _hasNumber = pwd.contains(RegExp(r'[0-9]'));
    });
  }

  /// Check if password meets all requirements
  bool get isPasswordValid =>
      _hasMinLength && _hasUpper && _hasLower && _hasNumber;

  Widget _buildPasswordRuleRow(String label, bool valid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            valid ? Icons.check : Icons.close,
            size: 14,
            color: valid ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            textAlign: TextAlign.start,
            style: TextStyle(
              color: valid ? Colors.green : Colors.red,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          if (widget.label.isNotEmpty)
            Padding(
              padding: widget.labelPadding ?? EdgeInsets.zero,
              child: FeqLabeled(widget.label),
            ),

          Padding(
            padding: widget.childPadding ??
                const EdgeInsets.only(top: 8, bottom: 4),
            child: TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              obscureText: _obscureText,
              obscuringCharacter: '•',
              enableSuggestions: false,
              autocorrect: false,
              keyboardType: TextInputType.visiblePassword,
              textAlign: TextAlign.start,
              textInputAction: widget.textInputAction ?? TextInputAction.next,
              onTap: widget.showValidationRules
                  ? () {
                setState(() => _showRules = true);
                widget.onTap?.call();
              }
                  : widget.onTap,
              onFieldSubmitted: widget.onFieldSubmitted,
              decoration: (widget.decoration ?? const InputDecoration()).copyWith(
                hintText: widget.hint ?? '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureText = !_obscureText);
                  },
                ),
              ),
            ),
          ),

          // Validation rules display
          if (widget.showValidationRules && _showRules)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordRuleRow('8 أحرف على الأقل', _hasMinLength),
                  _buildPasswordRuleRow('حرف كبير واحد على الأقل', _hasUpper),
                  _buildPasswordRuleRow('حرف صغير واحد على الأقل', _hasLower),
                  _buildPasswordRuleRow('رقم واحد على الأقل', _hasNumber),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Extension to easily check if a password controller's value is valid
extension PasswordValidation on TextEditingController {
  bool get isPasswordValid {
    final pwd = text;
    return pwd.length >= 8 &&
        pwd.contains(RegExp(r'[A-Z]')) &&
        pwd.contains(RegExp(r'[a-z]')) &&
        pwd.contains(RegExp(r'[0-9]'));
  }
}