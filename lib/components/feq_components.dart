import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Unified label wrapper that can display a label, child widget, and error text
class FeqLabeled extends StatelessWidget {
  final String label;
  final Widget child;
  final String? errorText;
  final EdgeInsetsGeometry? labelPadding;
  final EdgeInsetsGeometry? childPadding;
  final EdgeInsetsGeometry? errorPadding;

  const FeqLabeled(
      this.label, {
        super.key,
        required this.child,
        this.errorText,
        this.labelPadding,
        this.childPadding,
        this.errorPadding,
      });

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: labelPadding ??
              const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5),
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
          padding: childPadding ??
              const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 6),
          child: child,
        ),
        if (errorText != null && errorText!.isNotEmpty)
          Padding(
            padding: errorPadding ??
                const EdgeInsetsDirectional.fromSTEB(0, 6, 24, 10),
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

/// Unified text field with consistent styling
class FeqTextFieldBox extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? hint;
  final String? Function(String?)? validator;
  final bool isError;
  final double? width;
  final TextAlign textAlign;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final InputDecoration? decoration;
  final VoidCallback? onTap;

  const FeqTextFieldBox({
    super.key,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.hint,
    this.validator,
    this.isError = false,
    this.width = 300,
    this.textAlign = TextAlign.start,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.decoration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        readOnly: !enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textAlign: textAlign,
        obscureText: obscureText,
        textCapitalization: textCapitalization,
        maxLines: maxLines,
        onTap: onTap,
        decoration: decoration ??
            InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: theme.secondaryText),
              isDense: true,
              filled: true,
              fillColor: theme.secondaryBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: enabled ? theme.primary : Colors.transparent,
                  width: enabled ? 1 : 0,
                ),
              ),
              errorBorder: isError
                  ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              )
                  : null,
              focusedErrorBorder: isError
                  ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              )
                  : null,
              suffixIcon: suffixIcon,
            ),
        style: theme.bodyMedium.override(
          fontFamily: 'Inter',
          color: theme.primaryText,
        ),
        cursorColor: theme.primaryText,
        validator: validator,
      ),
    );
  }
}

/// Convenience widget combining Labeled and TextFieldBox
class FeqLabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? hint;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool isError;
  final double? width;
  final TextAlign textAlign;
  final EdgeInsetsGeometry? labelPadding;
  final EdgeInsetsGeometry? childPadding;
  final EdgeInsetsGeometry? errorPadding;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final InputDecoration? decoration;
  final VoidCallback? onTap;

  const FeqLabeledTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.hint,
    this.validator,
    this.errorText,
    this.isError = false,
    this.width = 300,
    this.textAlign = TextAlign.start,
    this.labelPadding,
    this.childPadding,
    this.errorPadding,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.decoration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FeqLabeled(
      label,
      labelPadding: labelPadding,
      childPadding: childPadding,
      errorPadding: errorPadding,
      errorText: errorText,
      child: FeqTextFieldBox(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        hint: hint,
        validator: validator,
        isError: isError,
        width: width,
        textAlign: textAlign,
        obscureText: obscureText,
        suffixIcon: suffixIcon,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        decoration: decoration,
        onTap: onTap,
      ),
    );
  }
}

/// Searchable dropdown component
class FeqSearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String hint;
  final bool isError;

  const FeqSearchableDropdown({
    super.key,
    required this.items,
    this.value,
    required this.onChanged,
    required this.hint,
    this.isError = false,
  });

  @override
  State<FeqSearchableDropdown<T>> createState() =>
      _FeqSearchableDropdownState<T>();
}

class _FeqSearchableDropdownState<T> extends State<FeqSearchableDropdown<T>> {
  late final TextEditingController _controller;
  late List<T> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _controller = TextEditingController(text: _getText(widget.value));
    _controller.addListener(_filter);
  }

  String _getText(T? item) {
    if (item == null) return '';
    final obj = item as dynamic;
    return obj.nameAr?.toString() ?? item.toString();
  }

  void _filter() {
    final query = _controller.text.trim().toLowerCase();
    setState(() {
      _filtered = widget.items
          .where((e) => _getText(e).toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void didUpdateWidget(covariant FeqSearchableDropdown<T> old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.text = _getText(widget.value);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_filter);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textAlign: TextAlign.end,
      readOnly: true,
      decoration: _inputDecoration(context, isError: widget.isError).copyWith(
        hintText: widget.hint,
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      onTap: () => _showDropdown(context),
    );
  }

  void _showDropdown(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'ابحث...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => _filter(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final item = _filtered[i];
                  return ListTile(
                    title: Text(_getText(item), textAlign: TextAlign.end),
                    onTap: () {
                      widget.onChanged(item);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context,
      {bool isError = false}) {
    final t = FlutterFlowTheme.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final BorderSide normalSide = BorderSide.none;
    final BorderSide focusSide = BorderSide(color: t.primaryText, width: 2);
    final BorderSide errorSide = BorderSide(color: errorColor, width: 2);

    return InputDecoration(
      labelStyle: t.labelMedium.copyWith(color: t.primaryText),
      alignLabelWithHint: false,
      hintStyle: t.labelMedium.copyWith(color: t.primaryText),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: isError ? errorSide : normalSide,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: normalSide,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: errorSide,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: errorSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: isError ? errorSide : focusSide,
      ),
      filled: true,
      fillColor: t.primaryBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}