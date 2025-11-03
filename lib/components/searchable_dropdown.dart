import 'package:flutter/material.dart';

import '../flutter_flow/flutter_flow_theme.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String hint;
  final bool isError;

  const SearchableDropdown({
    super.key,
    required this.items,
    this.value,
    required this.onChanged,
    required this.hint,
    this.isError = false,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
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
  void didUpdateWidget(covariant SearchableDropdown<T> old) {
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
      decoration: inputDecoration(context, isError: widget.isError).copyWith(
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
}

InputDecoration inputDecoration(BuildContext context, {bool isError = false}) {
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

InputDecoration platformInputDecoration(
  BuildContext context, {
  bool isError = false,
}) {
  return inputDecoration(context, isError: isError);
}
