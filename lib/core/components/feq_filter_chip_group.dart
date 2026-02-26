import 'package:flutter/material.dart';

class FeqFilterChipGroup<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final List<T> selectedItems;
  final String Function(T item) labelBuilder;
  final void Function(T item, bool selected) onSelectionChanged;
  final bool initiallyExpanded;
  final TextDirection textDirection;

  const FeqFilterChipGroup({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.labelBuilder,
    required this.onSelectionChanged,
    this.initiallyExpanded = false,
    this.textDirection = TextDirection.rtl,
  });

  @override
  State<FeqFilterChipGroup<T>> createState() => _FeqFilterChipGroupState<T>();
}

class _FeqFilterChipGroupState<T> extends State<FeqFilterChipGroup<T>> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    // Wrap everything in Directionality so crossAxisAlignment.stretch
    // and all children respect the correct reading direction.
    return Directionality(
      textDirection: widget.textDirection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Section header row ──────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                // Title at the start edge, arrow at the end edge.
                // In RTL: start = right → title on right, arrow on left. ✓
                // In LTR: start = left  → title on left,  arrow on right. ✓
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (widget.selectedItems.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.selectedItems.length}',
                        style: TextStyle(
                          color: onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Chip list (animated) ────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Wrap(
                // Wrap also inherits Directionality, but be explicit:
                textDirection: widget.textDirection,
                spacing: 8,
                runSpacing: 8,
                children: widget.items.map((item) {
                  final isSelected = widget.selectedItems.contains(item);
                  return FilterChip(
                    label: Text(widget.labelBuilder(item)),
                    selected: isSelected,
                    onSelected: (selected) =>
                        widget.onSelectionChanged(item, selected),
                    // ── Consistent styling across the whole app ──
                    selectedColor: primaryColor.withValues(alpha: 0.15),
                    checkmarkColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? primaryColor : null,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? primaryColor
                            : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}