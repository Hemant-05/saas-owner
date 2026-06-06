import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'add_edit_inventory_screen.dart';
import '../home_screen.dart';
import 'stock_transaction_screen.dart';
import 'adjust_stock_bottom_sheet.dart';

enum InventoryFilter { all, lowStock, outOfStock }

class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  final TextEditingController _searchController = TextEditingController();
  InventoryFilter _filter = InventoryFilter.all;
  String _searchQuery = '';

  bool get _isDesktop => MediaQuery.of(context).size.width > 900;
  InventoryItem? _selectedItem; // for desktop split panel

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InventoryItem> _filteredItems(List<InventoryItem> items) {
    var result = items;

    // Apply filter
    switch (_filter) {
      case InventoryFilter.lowStock:
        result = result.where((i) => i.isLowStock && !i.isOutOfStock).toList();
        break;
      case InventoryFilter.outOfStock:
        result = result.where((i) => i.isOutOfStock).toList();
        break;
      case InventoryFilter.all:
        break;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Consumer<InventoryProvider>(
                builder: (_, provider, __) {
                  if (provider.state == InventoryState.loading &&
                      provider.items.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    );
                  }

                  if (provider.state == InventoryState.error &&
                      provider.items.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.error_outline_rounded,
                      title: 'Failed to load inventory',
                      subtitle: provider.errorMessage ?? 'Something went wrong',
                      actionLabel: 'Retry',
                      onAction: () => provider.fetchItems(),
                    );
                  }

                  if (_isDesktop) {
                    return _buildDesktopLayout(provider);
                  }
                  return _buildMobileLayout(provider);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddItem(),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item', style: AppTextStyles.labelM),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          if (!_isDesktop)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: () => HomeScreen.openDrawer(),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          const SizedBox(width: AppSpacing.sm),
          const Text('Inventory', style: AppTextStyles.headingM),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => context.read<InventoryProvider>().fetchItems(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(InventoryStats stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Total Items',
              value: stats.totalItems,
              color: AppColors.info,
              icon: Icons.inventory_2_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              label: 'Low Stock',
              value: stats.lowStockCount,
              color: AppColors.warning,
              icon: Icons.warning_amber_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              label: 'Out of Stock',
              value: stats.outOfStockCount,
              color: AppColors.error,
              icon: Icons.remove_shopping_cart_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: AppTextStyles.bodyM,
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              hintText: 'Search ingredients...',
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppColors.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: InventoryFilter.values.map((f) {
                final isSelected = _filter == f;
                final label = f == InventoryFilter.all
                    ? 'All'
                    : f == InventoryFilter.lowStock
                        ? 'Low Stock'
                        : 'Out of Stock';
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.accent,
                    checkmarkColor: Colors.white,
                    labelStyle: AppTextStyles.labelS.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(InventoryProvider provider) {
    final filtered = _filteredItems(provider.items);

    return Column(
      children: [
        _buildStatsRow(provider.stats),
        _buildSearchAndFilters(),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: filtered.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.inventory_2_outlined,
                  title: 'No inventory items',
                  subtitle: 'Add ingredients to track your stock levels.',
                  actionLabel: 'Add Item',
                  onAction: _openAddItem,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _InventoryItemCard(
                    item: filtered[i],
                    onEdit: () => _openEditItem(filtered[i]),
                    onAdjust: () => _openAdjustStock(filtered[i]),
                    onHistory: () => _openHistory(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(InventoryProvider provider) {
    final filtered = _filteredItems(provider.items);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: list
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Column(
              children: [
                _buildStatsRow(provider.stats),
                _buildSearchAndFilters(),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.inventory_2_outlined,
                          title: 'No items',
                          subtitle: 'Add ingredients to get started.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, i) => _InventoryItemCard(
                            item: filtered[i],
                            isSelected: _selectedItem?.id == filtered[i].id,
                            onTap: () =>
                                setState(() => _selectedItem = filtered[i]),
                            onEdit: () => _openEditItem(filtered[i]),
                            onAdjust: () => _openAdjustStock(filtered[i]),
                            onHistory: () => _openHistory(filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        // Right: detail / add panel
        Expanded(
          child: _selectedItem == null
              ? const EmptyStateWidget(
                  icon: Icons.inventory_2_outlined,
                  title: 'Select an item',
                  subtitle: 'Tap an inventory item to see details.',
                )
              : _DesktopItemDetail(
                  item: _selectedItem!,
                  onEdit: () => _openEditItem(_selectedItem!),
                  onAdjust: () => _openAdjustStock(_selectedItem!),
                  onHistory: () => _openHistory(_selectedItem!),
                  onClose: () => setState(() => _selectedItem = null),
                ),
        ),
      ],
    );
  }

  void _openAddItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const AddEditInventoryScreen()),
    ).then((_) => context.read<InventoryProvider>().fetchItems());
  }

  void _openEditItem(InventoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddEditInventoryScreen(item: item)),
    ).then((_) => context.read<InventoryProvider>().fetchItems());
  }

  void _openAdjustStock(InventoryItem item) {
    AdjustStockBottomSheet.show(context, item: item);
  }

  void _openHistory(InventoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => StockTransactionScreen(item: item)),
    );
  }
}

// ─── Stat Card Widget ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.xs),
          AnimatedCounter(
            value: value.toDouble(),
            style: AppTextStyles.headingM.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.bodyS),
        ],
      ),
    );
  }
}

// ─── Inventory Item Card ──────────────────────────────────────────────────────
class _InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onAdjust;
  final VoidCallback onHistory;

  const _InventoryItemCard({
    required this.item,
    this.isSelected = false,
    this.onTap,
    required this.onEdit,
    required this.onAdjust,
    required this.onHistory,
  });

  Color get _stockColor {
    if (item.isOutOfStock) return AppColors.stockOut;
    if (item.isLowStock) return AppColors.stockLow;
    return AppColors.stockHealthy;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      border: isSelected
          ? Border.all(color: AppColors.accent, width: 1.5)
          : Border.all(color: AppColors.border, width: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Item image or placeholder
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.borderSmall,
                  border: Border.all(color: AppColors.border),
                ),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: AppRadius.borderSmall,
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.kitchen_rounded,
                            color: AppColors.textMuted,
                            size: 22,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.kitchen_rounded,
                        color: AppColors.textMuted,
                        size: 22,
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppTextStyles.labelM),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${item.currentStock.toStringAsFixed(item.currentStock % 1 == 0 ? 0 : 1)} ${item.unit}',
                          style: AppTextStyles.bodyM.copyWith(
                            color: _stockColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (item.isOutOfStock)
                          const StatusBadge(status: 'out_of_stock', compact: true),
                        if (item.isLowStock && !item.isOutOfStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: AppRadius.borderFull,
                            ),
                            child: Text(
                              'LOW',
                              style: AppTextStyles.labelS.copyWith(
                                  color: AppColors.warning, fontSize: 9),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionIcon(
                      icon: Icons.edit_rounded,
                      color: AppColors.textSecondary,
                      onTap: onEdit),
                  _ActionIcon(
                      icon: Icons.add_circle_outline_rounded,
                      color: AppColors.accent,
                      onTap: onAdjust),
                  _ActionIcon(
                      icon: Icons.history_rounded,
                      color: AppColors.textMuted,
                      onTap: onHistory),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Stock level bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Threshold: ${item.lowStockThreshold.toStringAsFixed(item.lowStockThreshold % 1 == 0 ? 0 : 1)} ${item.unit}',
                    style: AppTextStyles.bodyS,
                  ),
                  Text(
                    '${(item.stockRatio * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.labelS.copyWith(color: _stockColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: AppRadius.borderFull,
                child: LinearProgressIndicator(
                  value: item.stockRatio,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(_stockColor),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderFull,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ─── Desktop Detail Panel ─────────────────────────────────────────────────────
class _DesktopItemDetail extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onAdjust;
  final VoidCallback onHistory;
  final VoidCallback onClose;

  const _DesktopItemDetail({
    required this.item,
    required this.onEdit,
    required this.onAdjust,
    required this.onHistory,
    required this.onClose,
  });

  Color get _stockColor {
    if (item.isOutOfStock) return AppColors.stockOut;
    if (item.isLowStock) return AppColors.stockLow;
    return AppColors.stockHealthy;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: AppRadius.borderMedium,
                  child: Image.network(
                    item.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.borderMedium,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.kitchen_rounded,
                      color: AppColors.textMuted, size: 36),
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppTextStyles.headingM),
                    const SizedBox(height: 4),
                    Text(
                      '${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                      style: AppTextStyles.headingS.copyWith(color: _stockColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Stock bar
          ClipRRect(
            borderRadius: AppRadius.borderFull,
            child: LinearProgressIndicator(
              value: item.stockRatio,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(_stockColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current: ${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                  style: AppTextStyles.bodyS),
              Text('Threshold: ${item.lowStockThreshold.toStringAsFixed(1)} ${item.unit}',
                  style: AppTextStyles.bodyS),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Details grid
          _DetailRow('Unit', item.unit),
          if (item.costPerUnit != null)
            _DetailRow('Cost per unit', '₹${item.costPerUnit!.toStringAsFixed(2)}'),
          _DetailRow('Status', item.isOutOfStock
              ? 'Out of Stock'
              : item.isLowStock
                  ? 'Low Stock'
                  : 'Healthy'),
          const SizedBox(height: AppSpacing.lg),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Adjust Stock',
                  icon: Icons.tune_rounded,
                  onPressed: onAdjust,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'History',
                  icon: Icons.history_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: onHistory,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Edit Item',
            icon: Icons.edit_rounded,
            variant: AppButtonVariant.ghost,
            isFullWidth: true,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text('$label: ',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.labelM),
        ],
      ),
    );
  }
}
