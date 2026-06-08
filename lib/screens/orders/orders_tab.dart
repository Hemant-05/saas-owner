import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'order_detail_screen.dart';
import '../home_screen.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with SingleTickerProviderStateMixin {
  Order? _selectedOrder;
  late TabController _tabController;

  bool get _isDesktop => MediaQuery.of(context).size.width > 900;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<OrderProvider>(
          builder: (_, op, __) {
            if (op.isLoading && op.activeOrders.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B35)));
            }
            if (_isDesktop) {
              return _buildDesktopLayout(context, op);
            }
            return _buildMobileLayout(context, op);
          },
        ),
      ),
    );
  }

  // ─── Desktop: Kanban + Detail split ─────────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context, OrderProvider op) {
    final showRightPanel = _selectedOrder != null;
    return Column(
      children: [
        _buildAppBar(context, op),
        _buildLowStockBanner(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: order list
              Expanded(
                flex: showRightPanel ? 1 : 2,
                child: Container(
                  decoration: BoxDecoration(
                    border: showRightPanel ? const Border(
                      right: BorderSide(color: AppColors.border, width: 0.5),
                    ) : null,
                  ),
                  child: _buildDesktopKanban(context, op),
                ),
              ),
              // ── Right: order detail
              if (showRightPanel)
                Expanded(
                  flex: 1,
                  child: _buildDetailPanel(context, op),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopKanban(BuildContext context, OrderProvider op) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _KanbanColumn(
            title: 'New',
            color: AppColors.statusPlaced,
            icon: Icons.fiber_new_rounded,
            orders: op.newOrders,
            nextStatus: 'preparing',
            nextLabel: 'Start Preparing',
            nextIcon: Icons.local_fire_department_rounded,
            orderProvider: op,
            onTap: (o) => setState(() => _selectedOrder = o),
            isSelectedId: _selectedOrder?.id,
          ),
        ),
        Container(width: 0.5, color: AppColors.border),
        Expanded(
          child: _KanbanColumn(
            title: 'Preparing',
            color: AppColors.statusPreparing,
            icon: Icons.local_fire_department_rounded,
            orders: op.preparingOrders,
            nextStatus: 'ready',
            nextLabel: 'Mark Ready',
            nextIcon: Icons.check_circle_outline_rounded,
            orderProvider: op,
            onTap: (o) => setState(() => _selectedOrder = o),
            isSelectedId: _selectedOrder?.id,
          ),
        ),
        Container(width: 0.5, color: AppColors.border),
        Expanded(
          child: _KanbanColumn(
            title: 'Ready',
            color: AppColors.statusReady,
            icon: Icons.check_circle_rounded,
            orders: op.readyOrders,
            nextStatus: 'delivered',
            nextLabel: 'Mark Delivered',
            nextIcon: Icons.delivery_dining_rounded,
            orderProvider: op,
            onTap: (o) => setState(() => _selectedOrder = o),
            isSelectedId: _selectedOrder?.id,
          ),
        ),
      ],
    );
  }

  // ─── Low Stock Banner ───────────────────────────────────────────────────────
  Widget _buildLowStockBanner() {
    return Consumer<InventoryProvider>(
      builder: (_, ip, __) {
        final lowStockCount = ip.stats.lowStockCount;
        final outOfStockCount = ip.stats.outOfStockCount;

        if (lowStockCount == 0 && outOfStockCount == 0) {
          return const SizedBox.shrink();
        }

        final isError = outOfStockCount > 0;
        final color = isError ? AppColors.error : AppColors.warning;
        final icon = isError ? Icons.error_rounded : Icons.warning_rounded;
        final msgParts = [];
        if (outOfStockCount > 0) msgParts.add('$outOfStockCount out of stock');
        if (lowStockCount > 0) msgParts.add('$lowStockCount running low');

        return Container(
          width: double.infinity,
          color: color.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Inventory Alert: ${msgParts.join(' • ')}',
                  style: AppTextStyles.labelM.copyWith(color: color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Mobile: horizontal Kanban ────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, OrderProvider op) {
    return Column(
      children: [
        _buildAppBar(context, op),
        _buildLowStockBanner(),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: _KanbanColumn(
                    title: 'New Orders',
                    color: AppColors.statusPlaced,
                    icon: Icons.fiber_new_rounded,
                    orders: op.newOrders,
                    nextStatus: 'preparing',
                    nextLabel: 'Start Preparing',
                    nextIcon: Icons.local_fire_department_rounded,
                    orderProvider: op,
                    onTap: (o) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id, order: o)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: _KanbanColumn(
                    title: 'Preparing',
                    color: AppColors.statusPreparing,
                    icon: Icons.local_fire_department_rounded,
                    orders: op.preparingOrders,
                    nextStatus: 'ready',
                    nextLabel: 'Mark Ready',
                    nextIcon: Icons.check_circle_outline_rounded,
                    orderProvider: op,
                    onTap: (o) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id, order: o)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: _KanbanColumn(
                    title: 'Ready',
                    color: AppColors.statusReady,
                    icon: Icons.check_circle_rounded,
                    orders: op.readyOrders,
                    nextStatus: 'delivered',
                    nextLabel: 'Mark Delivered',
                    nextIcon: Icons.delivery_dining_rounded,
                    orderProvider: op,
                    onTap: (o) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id, order: o)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── App bar ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, OrderProvider op) {
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
          const Text('Live Orders', style: AppTextStyles.headingM),
          const Spacer(),
          // Total count chip
          Consumer<OrderProvider>(
            builder: (_, op2, __) {
              final total = op2.activeOrders.length;
              if (total == 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: AppRadius.borderFull,
                ),
                child: Text('$total active',
                    style: AppTextStyles.labelS.copyWith(color: AppColors.accent)),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => op.fetchActiveOrders(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }


  // ─── Right: detail panel ──────────────────────────────────────────────────────
  Widget _buildDetailPanel(BuildContext context, OrderProvider op) {
    if (_selectedOrder == null) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long_rounded,
        title: 'No Order Selected',
        subtitle: 'Select an order from the list to view details',
      );
    }

    return Column(
      children: [
        // Mini header
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _selectedOrder!.orderNumber,
                style: AppTextStyles.headingS,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 20),
                onPressed: () =>
                    setState(() => _selectedOrder = null),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.border),
        Expanded(
          child: OrderDetailScreen(
            key: ValueKey(_selectedOrder!.id),
            orderId: _selectedOrder!.id,
            order: _selectedOrder!,
            isEmbedded: true,
          ),
        ),
      ],
    );
  }
}

// ─── Kanban Column (mobile only) ──────────────────────────────────────────────
class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<Order> orders;
  final String nextStatus;
  final String nextLabel;
  final IconData nextIcon;
  final OrderProvider orderProvider;
  final ValueChanged<Order>? onTap;
  final String? isSelectedId;

  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.icon,
    required this.orders,
    required this.nextStatus,
    required this.nextLabel,
    required this.nextIcon,
    required this.orderProvider,
    required this.onTap,
    this.isSelectedId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderSmall,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: AppTextStyles.labelM.copyWith(color: color)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderFull,
                  ),
                  child: Text('${orders.length}',
                      style: AppTextStyles.labelS.copyWith(color: color)),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No orders here',
                    style: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted)),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.md),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (ctx, i) => _MobileOrderCard(
                  order: orders[i],
                  accentColor: color,
                  nextStatus: nextStatus,
                  nextLabel: nextLabel,
                  nextIcon: nextIcon,
                  orderProvider: orderProvider,
                  onTap: onTap,
                  isSelected: isSelectedId == orders[i].id,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileOrderCard extends StatelessWidget {
  final Order order;
  final Color accentColor;
  final String nextStatus;
  final String nextLabel;
  final IconData nextIcon;
  final OrderProvider orderProvider;
  final ValueChanged<Order>? onTap;
  final bool isSelected;

  const _MobileOrderCard({
    required this.order,
    required this.accentColor,
    required this.nextStatus,
    required this.nextLabel,
    required this.nextIcon,
    required this.orderProvider,
    this.onTap,
    this.isSelected = false,
  });

  String _timeElapsed() {
    if (order.placedAt == null) return '';
    final placed = DateTime.tryParse(order.placedAt!) ?? DateTime.now();
    final diff = DateTime.now().difference(placed);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ${diff.inMinutes % 60}m ago';
  }

  Future<void> _handleAction(BuildContext context) async {
    if (nextStatus == 'delivered' && order.paymentStatus == 'pending') {
      _showPaymentDialog(context);
    } else {
      await orderProvider.updateOrderStatus(order.id, nextStatus);
    }
  }

  void _showPaymentDialog(BuildContext context) {
    String selectedMethod =
        order.paymentMethod == 'pay_later' ? 'cash' : order.paymentMethod;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLarge),
          title: const Text('Collect Payment', style: AppTextStyles.headingS),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('₹${order.totalAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.headingL.copyWith(color: AppColors.paymentPaid)),
              const SizedBox(height: AppSpacing.lg),
              ...[
                ('cash', 'Cash', Icons.money_rounded),
                ('card', 'Card', Icons.credit_card_rounded),
              ].map((m) => RadioListTile<String>(
                    value: m.$1,
                    groupValue: selectedMethod,
                    onChanged: (v) => setDs(() => selectedMethod = v!),
                    title: Row(
                      children: [
                        Icon(m.$3, color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(m.$2, style: AppTextStyles.bodyM),
                      ],
                    ),
                    activeColor: AppColors.accent,
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppTextStyles.labelM.copyWith(color: AppColors.textMuted)),
            ),
            AppButton(
              label: 'Paid & Delivered',
              onPressed: () async {
                Navigator.pop(ctx);
                await orderProvider.updateOrderStatus(order.id, 'delivered');
                await orderProvider.updatePaymentStatus(order.id, 'paid', paymentMethod: selectedMethod);
              },
              variant: AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!(order);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: order.id, order: order),
            ),
          );
        }
      },
      child: AppCard(
        color: isSelected ? accentColor.withValues(alpha: 0.1) : AppColors.surface,
        border: Border.all(
          color: isSelected ? accentColor : AppColors.border,
          width: isSelected ? 1.5 : 0.5,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(order.orderNumber, style: AppTextStyles.labelM),
                const Spacer(),
                Text(_timeElapsed(),
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.table_bar_rounded, color: accentColor, size: 14),
                const SizedBox(width: 4),
                Text('Table ${order.tableNumber}',
                    style: AppTextStyles.labelS.copyWith(color: accentColor)),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            ...order.items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('${item.quantity}×',
                          style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                          child: Text(item.name,
                              style: AppTextStyles.bodyS,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                )),
            if (order.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('+ ${order.items.length - 3} more items',
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted, fontStyle: FontStyle.italic)),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('₹${order.totalAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.labelM),
                const Spacer(),
                StatusBadge(status: order.paymentStatus, compact: true),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: nextLabel,
                icon: nextIcon,
                onPressed: () => _handleAction(context),
                variant: AppButtonVariant.primary,
                height: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
