import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'package:restaurant_owner_app/screens/orders/order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  Order? _selectedOrder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchOrderHistory(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final prov = context.read<DashboardProvider>();
        if (!prov.isLoadingHistory) {
          prov.fetchOrderHistory();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order History',
          style: AppTextStyles.headingM,
        ),
        actions: [
          Consumer<DashboardProvider>(
            builder: (_, prov, __) => IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.textSecondary),
              onPressed: () => prov.fetchOrderHistory(refresh: true),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.orderHistory.isEmpty && provider.isLoadingHistory) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }

          if (provider.orderHistory.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history_rounded,
              title: 'No delivered orders',
              subtitle: 'Completed orders will appear here',
            );
          }
          
          // Automatically select the first order if none is selected
          if (_selectedOrder == null && provider.orderHistory.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedOrder == null) {
                setState(() => _selectedOrder = provider.orderHistory.first);
              }
            });
          }

          if (isDesktop) {
            return _buildDesktopLayout(context, provider);
          }
          return _buildMobileLayout(context, provider);
        },
      ),
    );
  }

  // ─── Desktop: split list + detail ───────────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context, DashboardProvider provider) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: list
              SizedBox(
                width: 380,
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchOrderHistory(refresh: true),
                  color: AppColors.accent,
                  backgroundColor: AppColors.surfaceElevated,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 40),
                    itemCount: provider.orderHistory.length +
                        (provider.isLoadingHistory ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.orderHistory.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.accent)),
                        );
                      }
                      final order = provider.orderHistory[index];
                      final isSelected = _selectedOrder?.id == order.id;
                      return _buildListCard(
                        context,
                        order,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedOrder = order),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Right: detail panel
              Expanded(
                child: _selectedOrder == null
                    ? Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.borderLarge,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const EmptyStateWidget(
                          icon: Icons.receipt_long_rounded,
                          title: 'Select an order',
                          subtitle: 'Order details will appear here',
                        ),
                      )
                    : ClipRRect(
                        borderRadius: AppRadius.borderLarge,
                        child: OrderDetailScreen(
                          key: ValueKey(_selectedOrder!.id),
                          orderId: _selectedOrder!.id,
                          order: _selectedOrder!,
                          isEmbedded: true,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mobile: navigate to detail ──────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, DashboardProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.fetchOrderHistory(refresh: true),
      color: AppColors.accent,
      backgroundColor: AppColors.surfaceElevated,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: provider.orderHistory.length +
                (provider.isLoadingHistory ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.orderHistory.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.accent)),
                );
              }
              final order = provider.orderHistory[index];
              return _buildListCard(context, order,
                  onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(
                              orderId: order.id, order: order),
                        ),
                      ));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(
    BuildContext context,
    Order order, {
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy • hh:mm a');
    final isPaid = order.paymentStatus == 'paid';

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        color: isSelected
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.surface,
        border: Border.all(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.4)
              : AppColors.border,
        ),
        // margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  order.orderNumber,
                  style: AppTextStyles.labelM,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: AppRadius.borderSmall,
                  ),
                  child: Text(
                    'DELIVERED',
                    style: AppTextStyles.labelS.copyWith(
                      color: AppColors.success,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.table_bar_rounded,
                    color: AppColors.textMuted, size: 13),
                const SizedBox(width: 4),
                Text(
                  'Table ${order.tableNumber}',
                  style:
                      AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.access_time_rounded,
                    color: AppColors.textSecondary, size: 12),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(DateTime.parse(order.placedAt!).toLocal()),
                  style: AppTextStyles.bodyS
                      .copyWith(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Item summary (first 2)
            ...order.items.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Text('${item.quantity}×',
                          style: AppTextStyles.labelS
                              .copyWith(color: AppColors.accent)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(item.name, style: AppTextStyles.bodyS)),
                      Text('₹${item.subtotal.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyS
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                )),
            if (order.items.length > 2)
              Text(
                '+${order.items.length - 2} more items',
                style: AppTextStyles.bodyS
                    .copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isPaid ? AppColors.success : AppColors.warning)
                        .withValues(alpha: 0.12),
                    borderRadius: AppRadius.borderSmall,
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'PENDING',
                    style: AppTextStyles.labelS.copyWith(
                      color: isPaid ? AppColors.success : AppColors.warning,
                      fontSize: 9,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style:
                      AppTextStyles.headingS.copyWith(color: AppColors.accent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
