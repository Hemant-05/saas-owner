import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_models.dart';
import '../../providers/inventory_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'package:intl/intl.dart';

class StockTransactionScreen extends StatefulWidget {
  final InventoryItem item;

  const StockTransactionScreen({super.key, required this.item});

  @override
  State<StockTransactionScreen> createState() => _StockTransactionScreenState();
}

class _StockTransactionScreenState extends State<StockTransactionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchItemTransactions(widget.item.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item.name, style: AppTextStyles.headingS),
            Text(
              'Stock History',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<InventoryProvider>().fetchItemTransactions(widget.item.id),
          ),
        ],
      ),
      body: Column(
        children: [
          // Current stock header
          Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            child: AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Stock', style: AppTextStyles.bodyS),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          AnimatedCounter(
                            value: widget.item.currentStock,
                            decimalPlaces: 1,
                            style: AppTextStyles.headingM.copyWith(
                              color: widget.item.isOutOfStock
                                  ? AppColors.stockOut
                                  : widget.item.isLowStock
                                      ? AppColors.stockLow
                                      : AppColors.stockHealthy,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(widget.item.unit,
                              style: AppTextStyles.bodyS.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Threshold', style: AppTextStyles.bodyS),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.item.lowStockThreshold.toStringAsFixed(1)} ${widget.item.unit}',
                        style: AppTextStyles.labelM.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Transactions list
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (_, provider, __) {
                final transactions = provider.transactions;

                if (transactions.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.history_rounded,
                    title: 'No transactions yet',
                    subtitle: 'Stock changes will appear here.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.xxl),
                  itemCount: transactions.length,
                  itemBuilder: (_, i) =>
                      _TransactionTile(transaction: transactions[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final StockTransaction transaction;

  const _TransactionTile({required this.transaction});

  IconData get _icon {
    switch (transaction.transactionType) {
      case 'manual_add':
        return Icons.add_circle_rounded;
      case 'manual_remove':
        return Icons.remove_circle_rounded;
      case 'order_deduction':
        return Icons.restaurant_rounded;
      case 'order_restoration':
        return Icons.restore_rounded;
      case 'adjustment':
        return Icons.tune_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  Color get _color {
    switch (transaction.transactionType) {
      case 'manual_add':
        return AppColors.success;
      case 'manual_remove':
        return AppColors.error;
      case 'order_deduction':
        return AppColors.warning;
      case 'order_restoration':
        return AppColors.info;
      case 'adjustment':
        return AppColors.textSecondary;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.quantityChanged > 0;
    final changeText = isPositive
        ? '+${transaction.quantityChanged.toStringAsFixed(1)} ${transaction.unit}'
        : '${transaction.quantityChanged.toStringAsFixed(1)} ${transaction.unit}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            // Timeline icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.humanReadableType,
                      style: AppTextStyles.labelM),
                  if (transaction.note.isNotEmpty)
                    Text(
                      transaction.note,
                      style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${transaction.quantityBefore.toStringAsFixed(1)} → ${transaction.quantityAfter.toStringAsFixed(1)} ${transaction.unit}',
                        style: AppTextStyles.bodyS,
                      ),
                    ],
                  ),
                  if (transaction.referenceOrderId != null)
                    Text(
                      'Order: #${transaction.referenceOrderId}',
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Quantity change + time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  changeText,
                  style: AppTextStyles.labelM.copyWith(
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.createdAt),
                  style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
