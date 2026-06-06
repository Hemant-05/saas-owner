import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';
import 'package:restaurant_owner_app/screens/orders/order_detail_screen.dart';
import 'order_history_screen.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, theme),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.state == DashboardState.loading &&
              provider.totalOrders == 0) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          }

          if (provider.state == DashboardState.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: theme.colorScheme.error, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(provider.errorMessage ?? 'An error occurred',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => provider.fetchDashboardStats(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return isDesktop
              ? _buildDesktopLayout(context, provider, theme)
              : _buildMobileLayout(context, provider, theme);
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ThemeData theme) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      leading: isDesktop
          ? null
          : Builder(
              builder: (ctx) => IconButton(
                icon: Icon(Icons.menu_rounded, color: theme.iconTheme.color),
                onPressed: () => HomeScreen.openDrawer(),
              ),
            ),
      automaticallyImplyLeading: !isDesktop,
      title: Text(
        'Dashboard',
        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      actions: [
        Consumer<DashboardProvider>(
          builder: (_, provider, __) => IconButton(
            icon: provider.state == DashboardState.loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: theme.primaryColor, strokeWidth: 2))
                : Icon(Icons.refresh_rounded, color: theme.iconTheme.color),
            onPressed: () => provider.fetchDashboardStats(),
          ),
        ),
        IconButton(
          icon: Icon(Icons.history_rounded, color: theme.iconTheme.color),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: theme.dividerColor.withOpacity(0.1)),
      ),
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, DashboardProvider provider, ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Today\'s Overview', theme),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                              child: _statCard(
                                  'Earnings',
                                  '₹${provider.todayEarnings.toStringAsFixed(0)}',
                                  Icons.payments_rounded,
                                  theme.primaryColor,
                                  theme)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                              child: _statCard(
                                  'Orders',
                                  '${provider.todayOrders}',
                                  Icons.receipt_long_rounded,
                                  AppColors.success,
                                  theme)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                              child: _statCard(
                                  'Avg Order',
                                  '₹${provider.todayAvgOrderValue.toStringAsFixed(0)}',
                                  Icons.analytics_rounded,
                                  AppColors.info,
                                  theme)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildChartSection(theme, provider),
                      const SizedBox(height: AppSpacing.xl),
                      _sectionLabel('Lifetime Stats', theme),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                              child: _statCard(
                                  'Total Earnings',
                                  '₹${provider.totalEarnings.toStringAsFixed(0)}',
                                  Icons.account_balance_wallet_rounded,
                                  Colors.orange,
                                  theme)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                              child: _statCard(
                                  'Total Orders',
                                  '${provider.totalOrders}',
                                  Icons.bar_chart_rounded,
                                  Colors.purple,
                                  theme)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                              child: _statCard(
                                  'Avg Value',
                                  '₹${provider.avgOrderValue.toStringAsFixed(0)}',
                                  Icons.trending_up_rounded,
                                  Colors.pink,
                                  theme)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                flex: 2,
                child: _buildHistoryPanel(context, provider, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, DashboardProvider provider, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () => provider.fetchDashboardStats(),
      color: theme.primaryColor,
      backgroundColor: theme.colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _sectionLabel('Today\'s Overview', theme),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                  child: _statCard(
                      'Earnings',
                      '₹${provider.todayEarnings.toStringAsFixed(0)}',
                      Icons.payments_rounded,
                      theme.primaryColor,
                      theme)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _statCard(
                      'Orders',
                      '${provider.todayOrders}',
                      Icons.receipt_long_rounded,
                      AppColors.success,
                      theme)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _statCard(
              'Avg Order Value',
              '₹${provider.todayAvgOrderValue.toStringAsFixed(0)}',
              Icons.analytics_rounded,
              AppColors.info,
              theme),
          const SizedBox(height: AppSpacing.xl),
          _buildChartSection(theme, provider),
          const SizedBox(height: AppSpacing.xl),
          _sectionLabel('Lifetime Stats', theme),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                  child: _statCard(
                      'Total Earnings',
                      '₹${provider.totalEarnings.toStringAsFixed(0)}',
                      Icons.account_balance_wallet_rounded,
                      Colors.orange,
                      theme)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _statCard(
                      'Total Orders',
                      '${provider.totalOrders}',
                      Icons.bar_chart_rounded,
                      Colors.purple,
                      theme)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _statCard(
              'Avg Value',
              '₹${provider.avgOrderValue.toStringAsFixed(0)}',
              Icons.trending_up_rounded,
              Colors.pink,
              theme),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            label: const Text('View Full Order History'),
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildChartSection(ThemeData theme, DashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text('Revenue Trend',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: provider.totalOrders == 0
                ? Center(
                    child: Text('Not enough data to display chart',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.dividerColor.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold);
                              String text;
                              switch (value.toInt()) {
                                case 1:
                                  text = 'Mon';
                                  break;
                                case 3:
                                  text = 'Wed';
                                  break;
                                case 5:
                                  text = 'Fri';
                                  break;
                                case 7:
                                  text = 'Sun';
                                  break;
                                default:
                                  text = '';
                                  break;
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(text,
                                    style: style.copyWith(
                                        color: theme.textTheme.bodyMedium?.color
                                            ?.withOpacity(0.5))),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 1,
                      maxX: 7,
                      minY: 0,
                      maxY: provider.todayEarnings > 0 ? provider.todayEarnings * 1.5 : 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            const FlSpot(1, 150),
                            const FlSpot(2, 200),
                            const FlSpot(3, 100),
                            const FlSpot(4, 300),
                            const FlSpot(5, 250),
                            const FlSpot(6, 400),
                            FlSpot(7, provider.todayEarnings.toDouble()),
                          ],
                          isCurved: true,
                          color: theme.primaryColor,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: theme.primaryColor.withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel(
      BuildContext context, DashboardProvider provider, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: theme.primaryColor, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text('Recent Orders',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OrderHistoryScreen())),
                  child: Text('View All',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.primaryColor)),
                ),
              ],
            ),
          ),
          Divider(color: theme.dividerColor.withOpacity(0.1), height: 1),
          Expanded(
            child: Consumer<DashboardProvider>(builder: (ctx, prov, _) {
              if (prov.isLoadingHistory && prov.orderHistory.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(color: theme.primaryColor),
                );
              }
              if (prov.orderHistory.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded,
                          size: 48,
                          color: theme.iconTheme.color?.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text('No recent orders',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.5))),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemCount: prov.orderHistory.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (_, i) {
                  final order = prov.orderHistory[i];
                  return _compactHistoryCard(context, order, theme);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, ThemeData theme) => Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      );

  Widget _statCard(
      String label, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _compactHistoryCard(BuildContext context, Order order, ThemeData theme) {
    final df = DateFormat('dd MMM • hh:mm a');
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  OrderDetailScreen(orderId: order.id, order: order))),
      borderRadius: AppRadius.borderSmall,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
          borderRadius: AppRadius.borderSmall,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long, size: 16, color: theme.primaryColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Table ${order.tableNumber} • ${df.format(DateTime.parse(order.placedAt!))}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Text(
              '₹${order.totalAmount.toStringAsFixed(0)}',
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: theme.primaryColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded,
                color: theme.iconTheme.color?.withOpacity(0.3), size: 18),
          ],
        ),
      ),
    );
  }
}
