import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'package:restaurant_owner_app/screens/orders/order_detail_screen.dart';
import 'order_history_screen.dart';
import '../home_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.state == DashboardState.loading &&
              provider.totalOrders == 0) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (provider.state == DashboardState.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(provider.errorMessage ?? 'An error occurred',
                      style: AppTextStyles.bodyM),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Retry',
                    onPressed: () => provider.fetchDashboardStats(),
                    variant: AppButtonVariant.primary,
                  ),
                ],
              ),
            );
          }

          return isDesktop
              ? _buildDesktopLayout(context, provider)
              : _buildMobileLayout(context, provider);
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: isDesktop
          ? null
          : Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                onPressed: () => HomeScreen.openDrawer(),
              ),
            ),
      automaticallyImplyLeading: !isDesktop,
      title: const Text(
        'Dashboard',
        style: AppTextStyles.headingM,
      ),
      actions: [
        Consumer<DashboardProvider>(
          builder: (_, provider, __) => IconButton(
            icon: provider.state == DashboardState.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
                : const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => provider.fetchDashboardStats(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
            height: 1, color: AppColors.border),
      ),
    );
  }

  // ─── Desktop Layout ─────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(
      BuildContext context, DashboardProvider provider) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Stats
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Today\'s Performance'),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                              child: _statCard(
                                  'Today\'s Earnings',
                                  '₹${provider.todayEarnings.toStringAsFixed(0)}',
                                  Icons.today_rounded,
                                  AppColors.accent)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                              child: _statCard(
                                  'Today\'s Orders',
                                  '${provider.todayOrders}',
                                  Icons.receipt_long_rounded,
                                  AppColors.success)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                              child: _statCard(
                                  'Today\'s Avg',
                                  '₹${provider.todayAvgOrderValue.toStringAsFixed(0)}',
                                  Icons.analytics_rounded,
                                  AppColors.info)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _sectionLabel('All Time'),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                              child: _statCard(
                                  'Total Earnings',
                                  '₹${provider.totalEarnings.toStringAsFixed(0)}',
                                  Icons.account_balance_wallet_rounded,
                                  Colors.orange)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                              child: _statCard(
                                  'Total Orders',
                                  '${provider.totalOrders}',
                                  Icons.bar_chart_rounded,
                                  Colors.purple)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                              child: _statCard(
                                  'Avg Order Value',
                                  '₹${provider.avgOrderValue.toStringAsFixed(0)}',
                                  Icons.trending_up_rounded,
                                  Colors.pink)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              // Right: Order History panel
              Expanded(
                flex: 2,
                child: _buildHistoryPanel(context, provider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mobile Layout ───────────────────────────────────────────────────────────
  Widget _buildMobileLayout(
      BuildContext context, DashboardProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.fetchDashboardStats(),
      color: AppColors.accent,
      backgroundColor: AppColors.surfaceElevated,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _sectionLabel('Today\'s Performance'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                  child: _statCard('Today\'s Earnings',
                      '₹${provider.todayEarnings.toStringAsFixed(0)}',
                      Icons.today_rounded, AppColors.accent)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _statCard('Today\'s Orders', '${provider.todayOrders}',
                      Icons.receipt_long_rounded, AppColors.success)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _statCard('Today\'s Avg Order Value',
              '₹${provider.todayAvgOrderValue.toStringAsFixed(0)}',
              Icons.analytics_rounded, AppColors.info),
          const SizedBox(height: AppSpacing.lg),
          _sectionLabel('All Time'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                  child: _statCard('Total Earnings',
                      '₹${provider.totalEarnings.toStringAsFixed(0)}',
                      Icons.account_balance_wallet_rounded,
                      Colors.orange)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _statCard('Total Orders', '${provider.totalOrders}',
                      Icons.bar_chart_rounded, Colors.purple)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _statCard('Avg Order Value',
              '₹${provider.avgOrderValue.toStringAsFixed(0)}',
              Icons.trending_up_rounded, Colors.pink),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'View Full Order History',
            icon: Icons.history_rounded,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
            variant: AppButtonVariant.primary,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // ─── History Panel (Desktop right column) ───────────────────────────────────
  Widget _buildHistoryPanel(BuildContext context, DashboardProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Order History',
                  style: AppTextStyles.headingS,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                  child: Text('View All',
                      style: AppTextStyles.labelS.copyWith(color: AppColors.accent)),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: Consumer<DashboardProvider>(builder: (ctx, prov, _) {
              if (prov.orderHistory.isEmpty && !prov.isLoadingHistory) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  prov.fetchOrderHistory(refresh: true);
                });
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              if (prov.orderHistory.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.history_rounded,
                  title: 'No delivered orders',
                  subtitle: 'Completed orders will appear here',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemCount: prov.orderHistory.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (_, i) {
                  final order = prov.orderHistory[i];
                  return _compactHistoryCard(context, order);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Widgets ─────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Text(
        label,
        style: AppTextStyles.labelM,
      );

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: color.withValues(alpha: 0.08),
      border: Border.all(color: color.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.headingL,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String msg) => AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        // margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Center(
          child: Text(msg, style: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted)),
        ),
      );

  Widget _compactHistoryCard(BuildContext context, Order order) {
    final df = DateFormat('dd MMM • hh:mm a');
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  OrderDetailScreen(orderId: order.id, order: order))),
      child: AppCard(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: AppTextStyles.labelM,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Table ${order.tableNumber} • ${df.format(DateTime.parse(order.placedAt!))}',
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Text(
              '₹${order.totalAmount.toStringAsFixed(0)}',
              style: AppTextStyles.labelL.copyWith(color: AppColors.accent),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
