import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_models.dart';
import '../../providers/inventory_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class AdjustStockBottomSheet extends StatefulWidget {
  final InventoryItem item;

  const AdjustStockBottomSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, {required InventoryItem item}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdjustStockBottomSheet(item: item),
    );
  }

  @override
  State<AdjustStockBottomSheet> createState() => _AdjustStockBottomSheetState();
}

class _AdjustStockBottomSheetState extends State<AdjustStockBottomSheet> {
  bool _isAdding = true;
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  double? _previewStock;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final qty = double.tryParse(_quantityController.text) ?? 0;
    setState(() {
      _previewStock = _isAdding
          ? widget.item.currentStock + qty
          : (widget.item.currentStock - qty).clamp(0, double.infinity);
    });
  }

  Future<void> _confirm() async {
    final qty = double.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) {
      SnackBarHelper.showError(context, 'Enter a valid quantity');
      return;
    }

    if (!_isAdding && _noteController.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Please add a note for stock removal');
      return;
    }

    setState(() => _isLoading = true);

    final type = _isAdding ? 'manual_add' : 'manual_remove';
    final error = await context.read<InventoryProvider>().adjustStock(
          itemId: widget.item.id,
          quantity: qty,
          transactionType: type,
          note: _noteController.text.trim().isNotEmpty
              ? _noteController.text.trim()
              : null,
        );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (error != null) {
      SnackBarHelper.showError(context, error);
    } else {
      SnackBarHelper.showSuccess(
        context,
        _isAdding
            ? 'Added $qty ${widget.item.unit} to ${widget.item.name}'
            : 'Removed $qty ${widget.item.unit} from ${widget.item.name}',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.borderFull,
                ),
              ),
            ),

            // Item info
            Row(
              children: [
                const Icon(Icons.kitchen_rounded,
                    color: AppColors.accent, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item.name, style: AppTextStyles.headingS),
                      Text(
                        'Current: ${widget.item.currentStock.toStringAsFixed(1)} ${widget.item.unit}',
                        style: AppTextStyles.bodyS.copyWith(
                          color: widget.item.isLowStock
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_previewStock != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: _isAdding
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.error.withValues(alpha: 0.15),
                      borderRadius: AppRadius.borderMedium,
                    ),
                    child: Text(
                      '→ ${_previewStock!.toStringAsFixed(1)} ${widget.item.unit}',
                      style: AppTextStyles.labelS.copyWith(
                        color: _isAdding ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Toggle: Add / Remove
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.borderMedium,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _ToggleButton(
                    label: 'Add Stock',
                    icon: Icons.add_rounded,
                    isSelected: _isAdding,
                    color: AppColors.success,
                    onTap: () => setState(() => _isAdding = true),
                  ),
                  _ToggleButton(
                    label: 'Remove Stock',
                    icon: Icons.remove_rounded,
                    isSelected: !_isAdding,
                    color: AppColors.error,
                    onTap: () => setState(() => _isAdding = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Quantity
            AppTextField(
              label: 'Quantity (${widget.item.unit})',
              hint: '0',
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _updatePreview(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Note
            AppTextField(
              label: !_isAdding ? 'Reason (required)' : 'Note (optional)',
              hint: _isAdding
                  ? 'e.g. Weekly restocking'
                  : 'e.g. Spoilage, Wastage',
              controller: _noteController,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Confirm button
            AppButton(
              label: _isAdding ? 'Confirm — Add Stock' : 'Confirm — Remove Stock',
              onPressed: _confirm,
              isLoading: _isLoading,
              isFullWidth: true,
              icon: _isAdding
                  ? Icons.add_circle_outline_rounded
                  : Icons.remove_circle_outline_rounded,
            ),
          ],
        ),
      ),
    ),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: AppRadius.borderMedium,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? color : AppColors.textMuted, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelS.copyWith(
                    color: isSelected ? color : AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
