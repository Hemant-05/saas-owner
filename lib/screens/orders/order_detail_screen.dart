import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../utils/pdf_printer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final Order order;
  final bool isEmbedded;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.order,
    this.isEmbedded = false,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Bill? _bill;
  bool _loading = true;
  late Order _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _fetchBill();
  }

  Future<void> _fetchBill() async {
    final bill =
        await context.read<OrderProvider>().fetchBill(widget.orderId);
    if (mounted) {
      setState(() {
        _bill = bill;
        _loading = false;
      });
    }
  }

  Future<void> _markPaid(String method) async {
    final updated = await context.read<OrderProvider>().updatePaymentStatus(
          widget.orderId,
          'paid',
          paymentMethod: method,
        );
    if (updated != null && mounted) {
      setState(() => _order = updated);
      await _fetchBill();
    }
  }

  void _showMarkPaidDialog() {
    String selectedMethod =
        _order.paymentMethod == 'pay_later' ? 'cash' : _order.paymentMethod;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderLarge),
          title: const Text('Mark as Paid',
              style: AppTextStyles.headingM),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total: ₹${_order.totalAmount.toStringAsFixed(2)}',
                style: AppTextStyles.headingL.copyWith(color: AppColors.success),
              ),
              const SizedBox(height: AppSpacing.md),
              ...[
                ('cash', 'Cash', Icons.money_rounded),
                ('card', 'Card', Icons.credit_card_rounded),
              ].map((m) => RadioListTile<String>(
                    value: m.$1,
                    groupValue: selectedMethod,
                    onChanged: (v) =>
                        setDialogState(() => selectedMethod = v!),
                    title: Row(
                      children: [
                        Icon(m.$3, color: AppColors.textSecondary, size: 18),
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
              child: Text('Cancel',
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
            ),
            AppButton(
              label: 'Confirm',
              onPressed: () {
                Navigator.pop(ctx);
                _markPaid(selectedMethod);
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
    final restaurant = context.read<AuthProvider>().restaurant;

    final scrollBody = _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.accent))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                _buildReceiptCard(restaurant),
                const SizedBox(height: AppSpacing.lg),
                _buildActionButtons(context, restaurant),
              ],
            ),
          );

    if (widget.isEmbedded) {
      return Container(
        color: AppColors.background,
        child: Column(
          children: [
            _buildEmbeddedHeader(context, restaurant),
            Container(height: 1, color: AppColors.border),
            Expanded(child: scrollBody),
          ],
        ),
      );
    }

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
        title: Text(
          _order.orderNumber,
          style: AppTextStyles.headingS,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Container(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: AppColors.textSecondary),
            onPressed: () {
              if (restaurant != null) {
                PdfPrinterUtil.printReceipt(_order,
                    restaurantName: restaurant.name);
              }
            },
          ),
        ],
      ),
      body: scrollBody,
    );
  }

  Widget _buildEmbeddedHeader(BuildContext context, dynamic restaurant) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded,
              color: AppColors.accent, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _order.orderNumber,
            style: AppTextStyles.headingS,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.print_rounded, color: AppColors.textSecondary),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              if (restaurant != null) {
                PdfPrinterUtil.printReceipt(_order,
                    restaurantName: restaurant.name);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(dynamic restaurant) {
    return AppCard(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          // Restaurant logo
          if (restaurant?.logoUrl != null)
            CachedNetworkImage(
              imageUrl: restaurant!.logoUrl!,
              width: 60,
              height: 60,
              imageBuilder: (_, img) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: img, fit: BoxFit.cover),
                ),
              ),
              placeholder: (_, __) => Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceElevated,
                ),
                child: const Icon(Icons.restaurant, color: AppColors.textMuted),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceElevated,
                ),
                child: const Icon(Icons.restaurant, color: AppColors.textMuted),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _bill?.restaurantName ?? restaurant?.name ?? '',
            style: AppTextStyles.headingM,
          ),
          const SizedBox(height: 4),
          Text(
            'Table ${_order.tableNumber} — ${_order.tableName}',
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            _order.placedAt != null
                ? DateFormat('dd MMM yyyy, hh:mm a')
                    .format(DateTime.parse(_order.placedAt!).toLocal())
                : '',
            style: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          // Items
          ...(_bill?.items ?? _order.items).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${item.quantity}×',
                          style: AppTextStyles.bodyM.copyWith(
                            color: AppColors.textSecondary,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            item.name,
                            style: AppTextStyles.bodyM,
                          ),
                        ),
                        Text(
                          '₹${item.subtotal.toStringAsFixed(2)}',
                          style: AppTextStyles.labelM,
                        ),
                      ],
                    ),
                    if (item.customization.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 28, top: 2),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '📝 ${item.customization}',
                            style: AppTextStyles.bodyS.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          _summaryRow('Subtotal',
              '₹${_order.subtotal.toStringAsFixed(2)}', AppColors.textSecondary),
          const SizedBox(height: 6),
          _summaryRow('Tax (${_order.taxPercent.toInt()}%)',
              '₹${_order.taxAmount.toStringAsFixed(2)}', AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          _summaryRow(
            'Total',
            '₹${_order.totalAmount.toStringAsFixed(2)}',
            AppColors.textPrimary,
            bold: true,
            large: true,
          ),
          const SizedBox(height: AppSpacing.md),
          // Status badges
          Row(
            children: [
              _statusChip(
                'Order: ${_order.orderStatus.toUpperCase()}',
                _statusColor(_order.orderStatus),
              ),
              const SizedBox(width: AppSpacing.sm),
              _statusChip(
                _order.paymentStatus == 'paid' ? '✓ PAID' : 'PAYMENT PENDING',
                _order.paymentStatus == 'paid'
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, dynamic restaurant) {
    return Column(
      children: [
        if (_order.paymentStatus == 'pending') ...[
          AppButton(
            label: 'Mark as Paid',
            icon: Icons.payments_rounded,
            onPressed: _showMarkPaidDialog,
            variant: AppButtonVariant.primary,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppButton(
          label: 'Print Bill',
          icon: Icons.print_rounded,
          onPressed: () {
            if (restaurant != null) {
              PdfPrinterUtil.printReceipt(_order,
                  restaurantName: restaurant.name);
            }
          },
          variant: AppButtonVariant.secondary,
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, Color color,
      {bool bold = false, bool large = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color: color,
              fontSize: large ? 16 : 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            )),
        Text(value,
            style: TextStyle(
              color: color,
              fontSize: large ? 20 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            )),
      ],
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.borderSmall,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelS.copyWith(
          color: color,
          fontSize: 11,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'placed':
        return AppColors.accent;
      case 'preparing':
        return AppColors.warning;
      case 'ready':
        return AppColors.success;
      case 'delivered':
        return AppColors.textMuted;
      default:
        return AppColors.textMuted;
    }
  }
}
