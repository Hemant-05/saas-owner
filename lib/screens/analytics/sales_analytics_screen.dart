import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboardStats();
    }); 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sales Analytics',
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: theme.dividerColor.withOpacity(0.1)),
        ),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.state == DashboardState.loading && provider.totalOrders == 0) {
            return Center(child: CircularProgressIndicator(color: theme.primaryColor));
          }

          if (provider.state == DashboardState.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(provider.errorMessage ?? 'An error occurred', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => provider.fetchDashboardStats(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Revenue Chart', theme),
                    const SizedBox(height: AppSpacing.md),
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
                                theme.primaryColor,
                                theme)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                            child: _statCard(
                                'Total Orders',
                                '${provider.totalOrders}',
                                Icons.bar_chart_rounded,
                                theme.primaryColor,
                                theme)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                            child: _statCard(
                                'Avg Value',
                                '₹${provider.avgOrderValue.toStringAsFixed(0)}',
                                Icons.trending_up_rounded,
                                theme.primaryColor,
                                theme)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodyLarge?.color,
                letterSpacing: -1),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(ThemeData theme, DashboardProvider provider) {
    final now = DateTime.now();
    final List<double> weeklyData = List.filled(7, 0.0);
    
    for (final order in provider.orderHistory) {
      if (order.placedAt != null) {
        final date = DateTime.parse(order.placedAt!).toLocal();
        final difference = DateTime(now.year, now.month, now.day)
            .difference(DateTime(date.year, date.month, date.day))
            .inDays;
        
        if (difference >= 0 && difference < 7) {
          final index = 6 - difference;
          weeklyData[index] += order.totalAmount;
        }
      }
    }
    
    if (provider.todayEarnings > weeklyData[6]) {
      weeklyData[6] = provider.todayEarnings.toDouble();
    }
    
    final currentMaxY = weeklyData.reduce((a, b) => a > b ? a : b);
    final chartMaxY = currentMaxY > 0 ? (currentMaxY * 1.5).clamp(100.0, double.infinity) : 1000.0;

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
              Text('Total Revenue (Last 7 Days)',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                  borderRadius: AppRadius.borderMedium,
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: theme.iconTheme.color?.withOpacity(0.5)),
                    const SizedBox(width: 6),
                    Text('This Week', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: provider.totalOrders == 0
                ? Center(
                    child: Text('Not enough data to display chart',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
                  )
                : BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.dividerColor.withOpacity(0.1),
                            strokeWidth: 1,
                            dashArray: [4, 4],
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
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold);
                              String text;
                              final dayIndex = (now.weekday - 1 - (6 - value.toInt())) % 7;
                              final adjustedIndex = dayIndex < 0 ? dayIndex + 7 : dayIndex;
                              switch (adjustedIndex) {
                                case 0:
                                  text = 'Mon';
                                  break;
                                case 1:
                                  text = 'Tue';
                                  break;
                                case 2:
                                  text = 'Wed';
                                  break;
                                case 3:
                                  text = 'Thu';
                                  break;
                                case 4:
                                  text = 'Fri';
                                  break;
                                case 5:
                                  text = 'Sat';
                                  break;
                                case 6:
                                  text = 'Sun';
                                  break;
                                default:
                                  text = '';
                                  break;
                              }
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(text,
                                    style: style.copyWith(
                                        color: value.toInt() == 6 ? theme.primaryColor : theme.textTheme.bodyMedium?.color
                                            ?.withOpacity(0.5))),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  value == 0 ? '0' : '₹${value.toInt()}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      maxY: chartMaxY,
                      barGroups: [
                        _buildBarGroup(0, weeklyData[0], false, theme, chartMaxY),
                        _buildBarGroup(1, weeklyData[1], false, theme, chartMaxY),
                        _buildBarGroup(2, weeklyData[2], false, theme, chartMaxY),
                        _buildBarGroup(3, weeklyData[3], false, theme, chartMaxY),
                        _buildBarGroup(4, weeklyData[4], false, theme, chartMaxY),
                        _buildBarGroup(5, weeklyData[5], false, theme, chartMaxY),
                        _buildBarGroup(6, weeklyData[6], true, theme, chartMaxY),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, bool isToday, ThemeData theme, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isToday ? theme.primaryColor : AppColors.borderLight,
          width: 40,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: AppColors.backgroundLight.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
