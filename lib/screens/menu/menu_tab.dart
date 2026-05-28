import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/menu_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'add_edit_item_screen.dart';
import '../home_screen.dart';

enum _MenuPanelMode { none, detail, addNew }

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  MenuItem? _selectedItem;
  _MenuPanelMode _panelMode = _MenuPanelMode.none;

  // Key to reset the AddEditItemPanel when item changes
  Key _panelKey = UniqueKey();

  bool get _isDesktop => MediaQuery.of(context).size.width > 900;

  void _selectItem(MenuItem item) {
    setState(() {
      _selectedItem = item;
      _panelMode = _MenuPanelMode.detail;
      _panelKey = UniqueKey();
    });
  }

  void _openAddNew() {
    if (_isDesktop) {
      setState(() {
        _selectedItem = null;
        _panelMode = _MenuPanelMode.addNew;
        _panelKey = UniqueKey();
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
      );
    }
  }

  void _onPanelSaved() {
    // After save, refresh and reset to none or re-select
    setState(() {
      _panelMode = _MenuPanelMode.none;
      _selectedItem = null;
    });
  }

  void _onPanelDeleted() {
    setState(() {
      _panelMode = _MenuPanelMode.none;
      _selectedItem = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<MenuProvider>(
          builder: (_, menuProv, __) {
            if (menuProv.isLoading && menuProv.items.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent));
            }

            final categories = menuProv.grouped.keys.toList()..sort();

            // No default selection on first load. It stays _MenuPanelMode.none

            if (_isDesktop) {
              return _buildDesktopLayout(context, categories, menuProv);
            }
            return _buildMobileLayout(context, categories, menuProv);
          },
        ),
      ),
    );
  }

  // ─── Desktop: master-detail ───────────────────────────────────────────────────
  Widget _buildDesktopLayout(
      BuildContext context, List<String> categories, MenuProvider menuProv) {
    final showRightPanel = _panelMode != _MenuPanelMode.none;
    return Column(
      children: [
        // App bar
        _buildAppBar(context, menuProv),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: Category columns
              Expanded(
                flex: showRightPanel ? 1 : 2,
                child: Container(
                  decoration: BoxDecoration(
                    border: showRightPanel ? const Border(
                      right: BorderSide(color: AppColors.border, width: 0.5),
                    ) : null,
                  ),
                  child: menuProv.items.isEmpty
                      ? _emptyMenuState()
                      : _buildCategoryColumns(context, categories, menuProv),
                ),
              ),
              // ── Right: Detail / Add panel
              if (showRightPanel)
                Expanded(
                  flex: 1,
                  child: _buildRightPanel(context, menuProv),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Mobile: single list + navigate ──────────────────────────────────────────
  Widget _buildMobileLayout(
      BuildContext context, List<String> categories, MenuProvider menuProv) {
    return Column(
      children: [
        _buildAppBar(context, menuProv),
        Expanded(
          child: menuProv.items.isEmpty
              ? _emptyMenuState()
              : _buildItemList(context, categories, menuProv),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, MenuProvider menuProv) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          // Hamburger on mobile only
          if (!_isDesktop) ...[
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                onPressed: () => HomeScreen.openDrawer(),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          const Text('Menu', style: AppTextStyles.headingM),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => menuProv.fetchMenuItems(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            label: 'Add Item',
            icon: Icons.add_rounded,
            onPressed: _openAddNew,
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  // ─── Horizontal Category Columns (Desktop) ──────────────────────────────────
  Widget _buildCategoryColumns(
      BuildContext context, List<String> categories, MenuProvider menuProv) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (ctx, i) {
        final cat = categories[i];
        final items = menuProv.grouped[cat] ?? [];
        return SizedBox(
          width: 320, // fixed width per column
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryHeader(cat, items.length),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, j) {
                    final item = items[j];
                    final isSelected = _selectedItem?.id == item.id;
                    return _buildItemRow(context, item, isSelected);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Flat item list (Mobile) ─────────────────────────────────────────────
  Widget _buildItemList(
      BuildContext context, List<String> categories, MenuProvider menuProv) {
    // Build flat list: category header + items
    final List<dynamic> flatList = [];
    for (final cat in categories) {
      flatList.add(_CategoryHeader(cat));
      flatList.addAll(menuProv.grouped[cat]!);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: flatList.length,
      itemBuilder: (_, i) {
        final entry = flatList[i];
        if (entry is _CategoryHeader) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
            child: _buildCategoryHeader(entry.name, menuProv.grouped[entry.name]!.length),
          );
        }
        final item = entry as MenuItem;
        final isSelected = _isDesktop && _selectedItem?.id == item.id;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          child: _buildItemRow(context, item, isSelected),
        );
      },
    );
  }

  Widget _buildCategoryHeader(String name, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(name, style: AppTextStyles.labelM),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: AppRadius.borderFull,
            ),
            child: Text(
              '$count',
              style: AppTextStyles.labelS.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, MenuItem item, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (_isDesktop) {
          _selectItem(item);
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddEditItemScreen(item: item)));
        }
      },
      child: AppCard(
        color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surface,
        border: Border.all(
          color: isSelected ? AppColors.accent : AppColors.border,
          width: isSelected ? 1.5 : 0.5,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: AppRadius.borderMedium,
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _itemImageFallback(),
                    )
                  : _itemImageFallback(),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: item.isVeg
                              ? AppColors.success
                              : AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTextStyles.labelM,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: AppTextStyles.labelS.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ),
            // Availability dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.isAvailable
                    ? AppColors.success
                    : AppColors.textMuted.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemImageFallback() => Container(
        width: 56,
        height: 56,
        color: AppColors.surfaceElevated,
        child: const Icon(Icons.fastfood_rounded, color: AppColors.textMuted, size: 24),
      );

  // ─── Right Panel ──────────────────────────────────────────────────────────────
  Widget _buildRightPanel(BuildContext context, MenuProvider menuProv) {
    if (_panelMode == _MenuPanelMode.addNew) {
      return Column(
        children: [
          _panelHeader('Add New Item',
              icon: Icons.add_circle_outline_rounded,
              color: const Color(0xFFFF6B35),
              onClose: () {
                setState(() {
                  _panelMode = _MenuPanelMode.none;
                  _selectedItem = null;
                });
              }),
          Expanded(
            child: AddEditItemPanel(
              key: _panelKey,
              item: null,
              onSaved: () {
                _onPanelSaved();
                menuProv.fetchMenuItems();
              },
              onDeleted: _onPanelDeleted,
            ),
          ),
        ],
      );
    }

    if (_panelMode == _MenuPanelMode.detail && _selectedItem != null) {
      return Column(
        children: [
          _panelHeader(
            _selectedItem!.name,
            icon: Icons.edit_rounded,
            color: const Color(0xFF06D6A0),
            onClose: () {
              setState(() {
                _panelMode = _MenuPanelMode.none;
                _selectedItem = null;
              });
            },
          ),
          Expanded(
            child: AddEditItemPanel(
              key: _panelKey,
              item: _selectedItem,
              onSaved: () {
                _onPanelSaved();
                menuProv.fetchMenuItems();
              },
              onDeleted: () {
                _onPanelDeleted();
                menuProv.fetchMenuItems();
              },
            ),
          ),
        ],
      );
    }

    // Empty state
    return const EmptyStateWidget(
      icon: Icons.touch_app_rounded,
      title: 'Select an item to edit',
      subtitle: 'or tap + Add Item',
    );
  }

  Widget _panelHeader(String title,
      {required IconData icon, required Color color, VoidCallback? onClose}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.headingS,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _emptyMenuState() => EmptyStateWidget(
        icon: Icons.restaurant_menu_rounded,
        title: 'No menu items yet',
        subtitle: 'Add your first menu item to get started.',
        actionLabel: 'Add First Item',
        onAction: _openAddNew,
      );
}

class _CategoryHeader {
  final String name;
  const _CategoryHeader(this.name);
}
