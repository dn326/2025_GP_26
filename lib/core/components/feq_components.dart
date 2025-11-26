import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/setting/presentation/account_settings_widget.dart';
import '../../flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Unified label wrapper that can display a label, child widget, and error text
class FeqLabeled extends StatelessWidget {
  final String label;
  final Widget? child;
  final String? errorText;
  final EdgeInsetsGeometry? labelPadding;
  final EdgeInsetsGeometry? childPadding;
  final EdgeInsetsGeometry? errorPadding;
  final bool required;
  final TextDirection textDirection;

  const FeqLabeled(
    this.label, {
    super.key,
    this.child,
    this.errorText,
    this.labelPadding,
    this.childPadding,
    this.errorPadding,
    this.required = true,
    this.textDirection = TextDirection.rtl,
  });

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Directionality(
      textDirection: textDirection,
      child: Column(
        crossAxisAlignment: textDirection == TextDirection.rtl ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Padding(
            padding:
                labelPadding ??
                (textDirection == TextDirection.rtl
                    ? const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 5)
                    : const EdgeInsetsDirectional.fromSTEB(20, 5, 0, 5)),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: t.bodyMedium.override(fontFamily: 'Inter', color: t.primaryText, fontSize: 16),
                  ),
                  if (required)
                    TextSpan(
                      text: ' *',
                      style: t.bodyMedium.override(fontFamily: 'Inter', color: Colors.red, fontSize: 16),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding:
                childPadding ??
                (textDirection == TextDirection.rtl
                    ? const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 6)
                    : const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 6)),
            child: child,
          ),
          if (errorText != null && errorText!.isNotEmpty)
            Padding(
              padding:
                  errorPadding ??
                  (textDirection == TextDirection.rtl
                      ? const EdgeInsetsDirectional.fromSTEB(0, 6, 24, 10)
                      : const EdgeInsetsDirectional.fromSTEB(24, 6, 0, 10)),
              child: Text(
                errorText!,
                textAlign: textDirection == TextDirection.rtl ? TextAlign.start : TextAlign.end,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// Unified text field with consistent styling
class FeqTextFieldBox extends StatelessWidget {
  final String? initialValue;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? hint;
  final String? Function(String?)? validator;
  final bool isError;
  final double? width;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final InputDecoration? decoration;
  final VoidCallback? onTap;
  final TextDirection textDirection;
  final List<TextInputFormatter>? inputFormatters;

  const FeqTextFieldBox({
    super.key,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.hint,
    this.validator,
    this.isError = false,
    this.width = 300,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.decoration,
    this.onTap,
    this.textDirection = TextDirection.rtl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Directionality(
      textDirection: textDirection,
      child: SizedBox(
        width: width,
        child: TextFormField(
          initialValue: initialValue,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: !enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          onTap: onTap,
          decoration:
              decoration ??
              InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: theme.secondaryText),
                isDense: true,
                filled: true,
                fillColor: theme.secondaryBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: enabled ? theme.primary : Colors.transparent, width: enabled ? 1 : 0),
                ),
                errorBorder: isError
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      )
                    : null,
                focusedErrorBorder: isError
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      )
                    : null,
                suffixIcon: suffixIcon,
              ),
          style: theme.bodyMedium.override(fontFamily: 'Inter', color: theme.primaryText),
          cursorColor: theme.primaryText,
          validator: validator,
          inputFormatters: inputFormatters,
        ),
      ),
    );
  }
}

/// Convenience widget combining Labeled and TextFieldBox
class FeqLabeledTextField extends StatelessWidget {
  final String label;
  final String? initialValue;
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
  final EdgeInsetsGeometry? labelPadding;
  final EdgeInsetsGeometry? childPadding;
  final EdgeInsetsGeometry? errorPadding;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final InputDecoration? decoration;
  final VoidCallback? onTap;
  final bool required;
  final TextDirection textDirection;
  final List<TextInputFormatter>? inputFormatters;

  const FeqLabeledTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.hint,
    this.validator,
    this.errorText,
    this.isError = false,
    this.width = double.infinity,
    this.labelPadding,
    this.childPadding,
    this.errorPadding,
    this.inputFormatters,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.decoration,
    this.onTap,
    this.required = true,
    this.textDirection = TextDirection.rtl,
  });

  @override
  Widget build(BuildContext context) {
    return FeqLabeled(
      label,
      labelPadding: labelPadding,
      childPadding: childPadding,
      errorPadding: errorPadding,
      errorText: errorText,
      required: required,
      textDirection: textDirection,
      child: FeqTextFieldBox(
        initialValue: initialValue,
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        hint: hint,
        validator: validator,
        isError: isError,
        width: width,
        obscureText: obscureText,
        suffixIcon: suffixIcon,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        decoration: decoration,
        onTap: onTap,
        textDirection: textDirection,
      ),
    );
  }
}

class FeqDropDownList {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? domain; // only for platforms

  const FeqDropDownList({required this.id, required this.nameAr, required this.nameEn, this.domain});

  factory FeqDropDownList.fromJson(Map<String, dynamic> json) => FeqDropDownList(
    id: (json['id'] is int) ? json['id'] : int.parse(json['id'].toString()),
    nameAr: json['name_ar'] as String,
    nameEn: json['name_en'] as String,
    domain: json['domain'] as String?,
  );

  @override
  String toString() => nameAr;
}

/// Searchable dropdown component
class FeqSearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String hint;
  final bool isError;
  final TextDirection textDirection;
  final String Function(T)? itemLabel;

  const FeqSearchableDropdown({
    super.key,
    required this.items,
    this.value,
    required this.onChanged,
    required this.hint,
    this.isError = false,
    this.textDirection = TextDirection.rtl,
    this.itemLabel,
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
    return widget.itemLabel?.call(item) ?? item.toString();
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
        if (mounted) _controller.text = _getText(widget.value);
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
    return Directionality(
      textDirection: widget.textDirection,
      child: TextField(
        controller: _controller,
        textAlign:
        widget.textDirection == TextDirection.rtl ? TextAlign.start : TextAlign.end,
        readOnly: true,
        decoration: _inputDecoration(context, isError: widget.isError).copyWith(
          hintText: widget.hint,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.value != null)
                GestureDetector(
                  onTap: () {
                    widget.onChanged(null);
                    _controller.clear();
                  },
                  child: const Icon(Icons.clear, size: 20),
                ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        onTap: () => _showDropdown(context),
      ),
    );
  }

  void _showDropdown(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Directionality(
        textDirection: widget.textDirection,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, ctrl) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  textAlign: widget.textDirection == TextDirection.rtl
                      ? TextAlign.start
                      : TextAlign.end,
                  decoration: InputDecoration(
                    hintText: widget.textDirection == TextDirection.rtl
                        ? 'إبحث...'
                        : 'Search...',
                    prefixIcon: widget.textDirection == TextDirection.rtl
                        ? null
                        : const Icon(Icons.search),
                    suffixIcon: widget.textDirection == TextDirection.rtl
                        ? const Icon(Icons.search)
                        : null,
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
                      title: Text(
                        _getText(item),
                        textAlign: widget.textDirection == TextDirection.rtl
                            ? TextAlign.start
                            : TextAlign.end,
                      ),
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
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, {bool isError = false}) {
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
          borderRadius: BorderRadius.circular(12), borderSide: normalSide),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: errorSide),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: errorSide),
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

class FeqVerifiedNameWidget extends StatelessWidget {
  final String name;
  final bool isVerified;

  const FeqVerifiedNameWidget({super.key, required this.name, this.isVerified = false});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: theme.headlineSmall.override(
              fontFamily: GoogleFonts.interTight().fontFamily,
              fontSize: 22,
              letterSpacing: 0.0,
            ),
          ),
          if (isVerified) ...[
            const SizedBox(width: 6),
            Container(
              decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              padding: const EdgeInsets.all(3),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class FeqAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool showLeading;
  final String? backRoute;

  const FeqAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.showLeading = false,
    this.backRoute,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56.0),
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              color: Color(0x33000000),
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          elevation: 0,
          titleSpacing: 0,
          leading: showLeading
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: const AlignmentDirectional(-1, 1),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AccountSettingsPage.routeName,
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsetsDirectional.fromSTEB(16, 0, 0, 16),
                    child: FaIcon(
                      FontAwesomeIcons.bahai,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          )
              : null,
          title: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).headlineSmall
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (showBack)
                      Align(
                        alignment: Alignment.centerRight,
                        child: FlutterFlowIconButton(
                          borderRadius: 8.0,
                          buttonSize: 40.0,
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
