import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ─── AppButton ───────────────────────────────────────────────────────────────
/// Custom button with variants: primary, secondary, ghost, danger.
/// Supports loading state and icon.
enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;
  final double? height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = false,
    this.height,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  Color get _bgColor {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.accent;
      case AppButtonVariant.secondary:
        return Colors.transparent;
      case AppButtonVariant.ghost:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return AppColors.error;
    }
  }

  Color get _fgColor {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return Colors.white;
      case AppButtonVariant.secondary:
        return AppColors.accent;
      case AppButtonVariant.ghost:
        return AppColors.textSecondary;
      case AppButtonVariant.danger:
        return Colors.white;
    }
  }

  Border? get _border {
    if (widget.variant == AppButtonVariant.secondary) {
      return Border.all(color: AppColors.accent, width: 1.5);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: isDisabled ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: widget.isFullWidth ? double.infinity : null,
            height: widget.height ?? 46,
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: AppRadius.borderMedium,
              border: _border,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize:
                    widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _fgColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ] else if (widget.icon != null) ...[
                    Icon(widget.icon, color: _fgColor, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    widget.label,
                    style: AppTextStyles.labelM.copyWith(color: _fgColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ─── AppCard ─────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? color;
  final Border? border;
  final double? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.border,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.medium),
        splashColor: AppColors.accent.withValues(alpha: 0.08),
        highlightColor: AppColors.accent.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? AppColors.surface,
            borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.medium),
            border: border ?? Border.all(color: AppColors.border, width: 0.5),
            boxShadow: AppShadows.sm,
          ),
          padding: padding ?? AppSpacing.paddingCard,
          child: child,
        ),
      ),
    );
  }
}

/// ─── AppTextField ─────────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final bool enabled;
  final String? initialValue;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.initialValue,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      enabled: enabled,
      focusNode: focusNode,
      initialValue: controller == null ? initialValue : null,
      style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// ─── StatusBadge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'placed':
        return AppColors.statusPlaced;
      case 'preparing':
        return AppColors.statusPreparing;
      case 'ready':
        return AppColors.statusReady;
      case 'delivered':
        return AppColors.statusDelivered;
      case 'cancelled':
        return AppColors.statusCancelled;
      case 'paid':
        return AppColors.paymentPaid;
      case 'pending':
        return AppColors.paymentPending;
      case 'failed':
        return AppColors.paymentFailed;
      default:
        return AppColors.textMuted;
    }
  }

  String get _label {
    switch (status.toLowerCase()) {
      case 'placed':
        return 'New';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: AppRadius.borderFull,
        border: Border.all(color: _color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        _label.toUpperCase(),
        style: (compact ? AppTextStyles.labelS : AppTextStyles.labelM).copyWith(
          color: _color,
          fontSize: compact ? 9 : 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// ─── EmptyStateWidget ─────────────────────────────────────────────────────────
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.borderXL,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.textMuted, size: 32),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.headingS.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ─── SnackBarHelper ───────────────────────────────────────────────────────────
class SnackBarHelper {
  SnackBarHelper._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle_rounded);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.error, Icons.error_rounded);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, AppColors.warning, Icons.warning_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.info, Icons.info_rounded);
  }

  static void _show(
      BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }
}

/// ─── SectionHeader ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: AppTextStyles.headingS),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!,
                style: AppTextStyles.labelM.copyWith(color: AppColors.accent)),
          ),
      ],
    );
  }
}

/// ─── AppBottomSheet ───────────────────────────────────────────────────────────
class AppBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final double? initialChildSize;
  final double? maxChildSize;
  final bool isDismissible;

  const AppBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.initialChildSize = 0.6,
    this.maxChildSize = 0.95,
    this.isDismissible = true,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    double initialChildSize = 0.6,
    double maxChildSize = 0.95,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppBottomSheet(
        title: title,
        initialChildSize: initialChildSize,
        maxChildSize: maxChildSize,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize!,
      minChildSize: 0.3,
      maxChildSize: maxChildSize!,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.borderFull,
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: AppTextStyles.headingS),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.xxl),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── AnimatedCounter ──────────────────────────────────────────────────────────
class AnimatedCounter extends StatefulWidget {
  final double value;
  final String suffix;
  final TextStyle? style;
  final int decimalPlaces;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.suffix = '',
    this.style,
    this.decimalPlaces = 0,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    _previousValue = widget.value;
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0);
      _previousValue = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        final val = _animation.value;
        final formatted = widget.decimalPlaces == 0
            ? val.toStringAsFixed(0)
            : val.toStringAsFixed(widget.decimalPlaces);
        return Text(
          '$formatted${widget.suffix}',
          style: widget.style ?? AppTextStyles.headingM,
        );
      },
    );
  }
}

/// ─── LoadingOverlay ───────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
      ],
    );
  }
}
