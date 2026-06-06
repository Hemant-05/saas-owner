import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/table_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../home_screen.dart';
import 'table_detail_screen.dart';

enum _TablePanelMode { none, detail, addNew }

class TablesTab extends StatefulWidget {
  const TablesTab({super.key});

  @override
  State<TablesTab> createState() => _TablesTabState();
}

class _TablesTabState extends State<TablesTab> {
  TableModel? _selectedTable;
  _TablePanelMode _panelMode = _TablePanelMode.none;

  // Add table form controllers
  final _tableNumberCtrl = TextEditingController();
  final _tableNameCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '4');
  final _addFormKey = GlobalKey<FormState>();
  bool _isAddingTable = false;

  bool get _isDesktop => MediaQuery.of(context).size.width > 900;

  @override
  void dispose() {
    _tableNumberCtrl.dispose();
    _tableNameCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  void _selectTable(TableModel table) {
    setState(() {
      _selectedTable = table;
      _panelMode = _TablePanelMode.detail;
    });
  }

  void _openAddNew() {
    if (_isDesktop) {
      _tableNumberCtrl.clear();
      _tableNameCtrl.clear();
      _capacityCtrl.text = '4';
      setState(() {
        _selectedTable = null;
        _panelMode = _TablePanelMode.addNew;
      });
    } else {
      _showAddTableDialog(context);
    }
  }

  Future<void> _submitAddTable(BuildContext context) async {
    if (!_addFormKey.currentState!.validate()) return;
    setState(() => _isAddingTable = true);

    final tableNumber = int.parse(_tableNumberCtrl.text.trim());
    final tableName = _tableNameCtrl.text.trim().isNotEmpty
        ? _tableNameCtrl.text.trim()
        : 'Table $tableNumber';
    final capacity = int.parse(_capacityCtrl.text.trim());

    final result = await context.read<TableProvider>().addTable(tableNumber, tableName, capacity);
    setState(() => _isAddingTable = false);

    if (result != null) {
      _tableNumberCtrl.clear();
      _tableNameCtrl.clear();
      setState(() {
        _selectedTable = result;
        _panelMode = _TablePanelMode.detail;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Table added!'),
            backgroundColor: AppColors.success),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                context.read<TableProvider>().errorMessage ?? 'Failed to add table'),
            backgroundColor: const Color(0xFFFF4757),
          ),
        );
      }
    }
  }

  void _showAddTableDialog(BuildContext context) {
    final tableNumberCtrl = TextEditingController();
    final tableNameCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '4');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLarge),
          title: const Text('Add New Table', style: AppTextStyles.headingS),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: tableNumberCtrl,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyM,
                  decoration: _inputDecor('Table Number (e.g., 1)'),
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (int.tryParse(v) == null || int.parse(v) < 1) {
                      return 'Must be a positive integer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: tableNameCtrl,
                  style: AppTextStyles.bodyM,
                  decoration: _inputDecor('Table Name (e.g., Window Seat)'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: capacityCtrl,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyM,
                  decoration: _inputDecor('Capacity (e.g., 4)'),
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (int.tryParse(v) == null || int.parse(v) < 1) {
                      return 'Must be at least 1';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppTextStyles.labelM.copyWith(color: AppColors.textMuted)),
            ),
            AppButton(
              label: 'Add Table',
              isLoading: isLoading,
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => isLoading = true);
                final number = int.parse(tableNumberCtrl.text.trim());
                final name = tableNameCtrl.text.trim().isNotEmpty
                    ? tableNameCtrl.text.trim()
                    : 'Table $number';
                final capacity = int.parse(capacityCtrl.text.trim());
                final result = await context
                    .read<TableProvider>()
                    .addTable(number, name, capacity);
                if (ctx.mounted) Navigator.pop(ctx);
                if (result == null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context
                              .read<TableProvider>()
                              .errorMessage ??
                          'Failed to add table'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              variant: AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  static InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        border: OutlineInputBorder(
            borderRadius: AppRadius.borderSmall,
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderSmall,
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderSmall,
            borderSide: const BorderSide(color: AppColors.accent)),
        errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderSmall,
            borderSide: const BorderSide(color: AppColors.error)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<TableProvider>(
          builder: (context, tableProv, _) {
            if (tableProv.isLoading && tableProv.tables.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent));
            }

            if (_isDesktop) {
              return _buildDesktopLayout(context, tableProv);
            }
            return _buildMobileLayout(context, tableProv);
          },
        ),
      ),
    );
  }

  // ─── Desktop: master-detail ───────────────────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context, TableProvider tableProv) {
    final showRightPanel = _panelMode != _TablePanelMode.none;
    return Column(
      children: [
        _buildAppBar(context, tableProv),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: table list
              Expanded(
                flex: showRightPanel ? 1 : 2,
                child: Container(
                  decoration: BoxDecoration(
                    border: showRightPanel ? const Border(
                      right: BorderSide(color: AppColors.border, width: 0.5),
                    ) : null,
                  ),
                  child: tableProv.tables.isEmpty
                      ? _emptyTablesState()
                      : _buildTableList(context, tableProv),
                ),
              ),
              // ── Right: detail / add
              if (showRightPanel)
                Expanded(
                  flex: 1,
                  child: _buildRightPanel(context, tableProv),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Mobile: list + navigate ──────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, TableProvider tableProv) {
    return Column(
      children: [
        _buildAppBar(context, tableProv),
        Expanded(
          child: tableProv.tables.isEmpty
              ? _emptyTablesState()
              : _buildTableGrid(context, tableProv),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, TableProvider tableProv) {
    // Summary counts
    final occupied = tableProv.tables.where((t) => t.isOccupied).length;
    final free = tableProv.tables.length - occupied;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
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
          const Text('Tables', style: AppTextStyles.headingM),
          const SizedBox(width: AppSpacing.md),
          // Summary chips
          if (tableProv.tables.isNotEmpty) ...[
            _chip('$occupied occupied', AppColors.error),
            const SizedBox(width: AppSpacing.xs),
            _chip('$free free', AppColors.success),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => tableProv.fetchTables(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            label: 'Add Table',
            icon: Icons.add_rounded,
            onPressed: _openAddNew,
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.borderFull,
        ),
        child: Text(label, style: AppTextStyles.labelS.copyWith(color: color)),
      );

  // ─── Left: list of tables (desktop)
  Widget _buildTableList(BuildContext context, TableProvider tableProv) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: tableProv.tables.length,
      itemBuilder: (_, idx) {
        final table = tableProv.tables[idx];
        final isSelected = _selectedTable?.id == table.id;
        final statusColor = table.isOccupied ? AppColors.error : AppColors.success;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => _selectTable(table),
            child: AppCard(
              color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surface,
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: isSelected ? 1.5 : 0.5,
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  // Status dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Table info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Table ${table.tableNumber}', style: AppTextStyles.labelM),
                        Text(table.tableName, style: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  // Status text
                  Text(
                    table.isOccupied ? 'Occupied' : 'Free',
                    style: AppTextStyles.labelS.copyWith(color: statusColor),
                  ),
                  if (!table.isServiceable) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('OFF',
                          style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Grid (mobile)
  Widget _buildTableGrid(BuildContext context, TableProvider tableProv) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.80,
      ),
      itemCount: tableProv.tables.length,
      itemBuilder: (_, idx) {
        final table = tableProv.tables[idx];
        return _MobileTableCard(table: table);
      },
    );
  }

  // ─── Right Panel ──────────────────────────────────────────────────────────────
  Widget _buildRightPanel(BuildContext context, TableProvider tableProv) {
    if (_panelMode == _TablePanelMode.addNew) {
      return Column(
        children: [
          _panelHeader('Add New Table',
              icon: Icons.add_circle_outline_rounded,
              color: AppColors.accent),
          Expanded(child: _buildAddTableForm(context)),
        ],
      );
    }

    if (_panelMode == _TablePanelMode.detail && _selectedTable != null) {
      // Get fresh table from provider
      final freshTable = tableProv.tables.firstWhere(
          (t) => t.id == _selectedTable!.id,
          orElse: () => _selectedTable!);
      return Column(
        children: [
          _panelHeader('Table ${freshTable.tableNumber} — ${freshTable.tableName}',
              icon: Icons.table_bar_rounded,
              color: freshTable.isOccupied
                  ? AppColors.error
                  : AppColors.success),
          Expanded(
            child: TableDetailPanel(
              table: freshTable,
              onDeleted: () => setState(() {
                _panelMode = _TablePanelMode.none;
                _selectedTable = null;
              }),
            ),
          ),
        ],
      );
    }

    return const EmptyStateWidget(
      icon: Icons.table_bar_rounded,
      title: 'Select a table to view details',
      subtitle: 'or tap + Add Table',
    );
  }

  Widget _buildAddTableForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _addFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Table Number', style: AppTextStyles.labelS.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _tableNumberCtrl,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyM,
              decoration: _inputDecor('e.g., 5'),
              validator: (v) {
                if (v!.isEmpty) return 'Required';
                if (int.tryParse(v) == null || int.parse(v) < 1) {
                  return 'Must be a positive integer';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Table Name (optional)', style: AppTextStyles.labelS.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _tableNameCtrl,
              style: AppTextStyles.bodyM,
              decoration: _inputDecor('e.g., Window Seat'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Capacity', style: AppTextStyles.labelS.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _capacityCtrl,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyM,
              decoration: _inputDecor('e.g., 4'),
              validator: (v) {
                if (v!.isEmpty) return 'Required';
                if (int.tryParse(v) == null || int.parse(v) < 1) {
                  return 'Must be at least 1';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Add Table',
                isLoading: _isAddingTable,
                onPressed: () => _submitAddTable(context),
                variant: AppButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelHeader(String title,
      {required IconData icon, required Color color}) {
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
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
            onPressed: () => setState(() {
              _panelMode = _TablePanelMode.none;
              _selectedTable = null;
            }),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _emptyTablesState() => EmptyStateWidget(
        icon: Icons.table_bar_rounded,
        title: 'No tables yet',
        subtitle: 'Add your first table to get started.',
        actionLabel: 'Add First Table',
        onAction: _openAddNew,
      );
}

// ─── Mobile Table Card ────────────────────────────────────────────────────────
class _MobileTableCard extends StatelessWidget {
  final TableModel table;
  const _MobileTableCard({required this.table});

  @override
  Widget build(BuildContext context) {
    return Consumer<TableProvider>(
      builder: (context, tp, _) {
        final currentTable = tp.tables.firstWhere(
            (t) => t.id == table.id,
            orElse: () => table);
            
        final statusColor = currentTable.isOccupied ? AppColors.error : AppColors.success;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TableDetailScreen(table: currentTable)),
          ),
          child: AppCard(
            color: AppColors.surface,
            border: Border.all(
                color: statusColor.withValues(alpha: currentTable.isOccupied ? 0.35 : 0.12)),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentTable.isOccupied ? 'OCC' : 'FREE',
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (!currentTable.isServiceable)
                      const Text('OFF',
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.borderMedium,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: currentTable.qrCodeData != null
                        ? QrImageView(
                            data: currentTable.qrCodeData!,
                            version: QrVersions.auto,
                            foregroundColor: const Color(0xFF1a1a2e),
                          )
                        : const Icon(Icons.qr_code_rounded,
                            size: 40, color: Colors.black38),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Table ${currentTable.tableNumber}', style: AppTextStyles.labelM.copyWith(color: AppColors.accent)),
                Text(
                  currentTable.tableName,
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 24,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: Switch(
                      value: currentTable.isServiceable,
                      onChanged: (val) => tp.toggleServiceable(currentTable.id, val),
                      activeThumbColor: AppColors.accent,
                      activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
                      inactiveThumbColor: AppColors.textMuted,
                      inactiveTrackColor: AppColors.border,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
