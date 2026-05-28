import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_models.dart';
import '../../models/models.dart';
import '../../providers/inventory_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class MenuIngredientLinksScreen extends StatefulWidget {
  final MenuItem menuItem;

  const MenuIngredientLinksScreen({super.key, required this.menuItem});

  @override
  State<MenuIngredientLinksScreen> createState() =>
      _MenuIngredientLinksScreenState();
}

class _MenuIngredientLinksScreenState extends State<MenuIngredientLinksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InventoryProvider>();
      provider.fetchMenuLinks(widget.menuItem.id);
      if (provider.items.isEmpty) {
        provider.fetchItems();
      }
    });
  }

  void _showAddLink() {
    AppBottomSheet.show(
      context,
      title: 'Link Ingredient',
      child: _AddLinkForm(menuItemId: widget.menuItem.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.menuItem.name, style: AppTextStyles.headingS),
            Text(
              'Ingredient Links',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Link'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            onPressed: _showAddLink,
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (_, provider, __) {
          final links = provider.menuLinks;

          if (links.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.link_rounded,
              title: 'No ingredients linked',
              subtitle:
                  'Link ingredients from your inventory to track automatic stock deduction when orders are placed.',
              actionLabel: 'Link an Ingredient',
              onAction: _showAddLink,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 4),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderMedium,
                  border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3), width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_rounded,
                        color: AppColors.info, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Stock is automatically deducted from these ingredients when "${widget.menuItem.name}" is ordered.',
                        style: AppTextStyles.bodyS
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              // Links
              ...links.map(
                (link) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.kitchen_rounded,
                              color: AppColors.accent, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                link.inventoryItemName ?? 'Ingredient',
                                style: AppTextStyles.labelM,
                              ),
                              Text(
                                '${link.quantityUsedPerServing.toStringAsFixed(link.quantityUsedPerServing % 1 == 0 ? 0 : 2)} ${link.unit} per serving',
                                style: AppTextStyles.bodyS,
                              ),
                              if (link.inventoryItemCurrentStock != null)
                                Text(
                                  'In stock: ${link.inventoryItemCurrentStock!.toStringAsFixed(1)} ${link.unit}',
                                  style: AppTextStyles.bodyS.copyWith(
                                    color: (link.inventoryItemCurrentStock! <= 0)
                                        ? AppColors.stockOut
                                        : AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.link_off_rounded,
                              color: AppColors.error, size: 20),
                          onPressed: () => _confirmUnlink(link),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmUnlink(MenuItemIngredient link) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Ingredient'),
        content: Text(
          'Remove "${link.inventoryItemName}" from "${widget.menuItem.name}"? Stock will no longer be deducted for this ingredient.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final error = await context
          .read<InventoryProvider>()
          .unlinkIngredient(link.id, widget.menuItem.id);
      if (!mounted) return;
      if (error != null) {
        SnackBarHelper.showError(context, error);
      } else {
        SnackBarHelper.showSuccess(context, 'Ingredient unlinked');
      }
    }
  }
}

// ─── Add Link Form ────────────────────────────────────────────────────────────
class _AddLinkForm extends StatefulWidget {
  final String menuItemId;

  const _AddLinkForm({required this.menuItemId});

  @override
  State<_AddLinkForm> createState() => _AddLinkFormState();
}

class _AddLinkFormState extends State<_AddLinkForm> {
  String? _selectedInventoryItemId;
  final _quantityController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    if (_selectedInventoryItemId == null) {
      SnackBarHelper.showError(context, 'Select an ingredient');
      return;
    }
    final qty = double.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) {
      SnackBarHelper.showError(context, 'Enter a valid quantity');
      return;
    }

    setState(() => _isLoading = true);
    final error = await context.read<InventoryProvider>().linkIngredient(
          menuItemId: widget.menuItemId,
          inventoryItemId: _selectedInventoryItemId!,
          quantityUsedPerServing: qty,
        );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (error != null) {
      SnackBarHelper.showError(context, error);
    } else {
      SnackBarHelper.showSuccess(context, 'Ingredient linked successfully!');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final items = provider.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Ingredient', style: AppTextStyles.bodyM),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: _selectedInventoryItemId,
          dropdownColor: AppColors.surfaceElevated,
          style: AppTextStyles.bodyM,
          decoration: const InputDecoration(
            hintText: 'Choose ingredient',
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item.id,
                    child: Row(
                      children: [
                        Text(item.name),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '(${item.currentStock.toStringAsFixed(1)} ${item.unit})',
                          style: AppTextStyles.bodyS
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedInventoryItemId = v),
        ),
        const SizedBox(height: AppSpacing.md),
        Builder(builder: (context) {
          final selectedItem = _selectedInventoryItemId != null
              ? items.firstWhere(
                  (i) => i.id == _selectedInventoryItemId,
                  orElse: () => items.first,
                )
              : null;

          return AppTextField(
            label:
                'Quantity per serving${selectedItem != null ? ' (${selectedItem.unit})' : ''}',
            hint: 'e.g. 0.5',
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          );
        }),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Link Ingredient',
          onPressed: _link,
          isLoading: _isLoading,
          isFullWidth: true,
          icon: Icons.link_rounded,
        ),
      ],
    );
  }
}
