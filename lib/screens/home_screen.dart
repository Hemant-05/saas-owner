import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/table_provider.dart';
import '../providers/inventory_provider.dart';
import '../services/notification_service.dart';
import '../services/offline_sync_service.dart';
import '../theme/app_theme.dart';
import 'orders/orders_tab.dart';
import 'menu/menu_tab.dart';
import 'tables/tables_tab.dart';
import 'dashboard/dashboard_tab.dart';
import '../providers/dashboard_provider.dart';
import 'profile/profile_tab.dart';
import 'auth/login_screen.dart';
import 'inventory/inventory_tab.dart';
import 'notifications/notification_history_screen.dart';

/// Navigation destinations
const _kNavItems = [
  (icon: Icons.dashboard_rounded, label: 'Dashboard'),
  (icon: Icons.receipt_long_rounded, label: 'Orders'),
  (icon: Icons.restaurant_menu_rounded, label: 'Menu'),
  (icon: Icons.table_bar_rounded, label: 'Tables'),
  (icon: Icons.inventory_2_rounded, label: 'Inventory'),
  (icon: Icons.notifications_rounded, label: 'Notifications'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  static void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    DashboardTab(),
    OrdersTab(),
    MenuTab(),
    TablesTab(),
    InventoryTab(),
    NotificationHistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  Future<void> _initializeData() async {
    final auth = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();
    final menuProvider = context.read<MenuProvider>();
    final tableProvider = context.read<TableProvider>();
    final inventoryProvider = context.read<InventoryProvider>();

    if (auth.restaurant != null) {
      await orderProvider.initNotifications();
      final dashboardProvider = context.read<DashboardProvider>();
      orderProvider.connectSocket(
        auth.restaurant!.id,
        onOrderEvent: () {
          tableProvider.fetchTables(silent: true);
          dashboardProvider.fetchDashboardStats(silent: true);
        },
      );
      orderProvider.fetchActiveOrders();
      menuProvider.fetchMenuItems();
      tableProvider.fetchTables();
      inventoryProvider.fetchLowStockItems(); // pre-fetch for alert badge
    }
  }

  void _navigate(int index) {
    setState(() => _currentIndex = index);
    // Close drawer if open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _logout() async {
    final scaffold = HomeScreen.scaffoldKey.currentState;
    if (scaffold?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout',
            style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: AppColors.textSecondaryLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondaryLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4757)),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);

    return Scaffold(
      key: HomeScreen.scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: isDesktop ? null : _buildDrawer(context),
      bottomNavigationBar: isDesktop ? null : _buildBottomNavBar(context),
      body: Stack(
        children: [
          Column(
            children: [
              const _OfflineSyncBanner(),
              Expanded(
                child: isDesktop
                    ? _buildDesktopLayout(context)
                    : _buildMobileLayout(context),
              ),
            ],
          ),
          // Sticky Notification Bell
          Positioned(
            top: isDesktop ? 24 : MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: ValueListenableBuilder<int>(
              valueListenable: NotificationService().unreadCount,
              builder: (context, count, child) {
                if (count == 0) return const SizedBox.shrink();
                return FloatingActionButton(
                  mini: true,
                  backgroundColor: AppColors.surfaceElevated,
                  elevation: 6,
                  onPressed: () => _navigate(5),
                  child: Badge(
                    label: Text('$count'),
                    backgroundColor: const Color(0xFFFF4757),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: AppColors.accent),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Desktop: permanent side nav rail ────────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final restaurant = auth.restaurant;
    final theme = Theme.of(context);

    return Row(
      children: [
        // Permanent sidebar
        Container(
          width: 220,
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              // Brand
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.accent, Color(0xFFFF9A3C)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant_rounded,
                          color: AppColors.textPrimary, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'RestaurantOS',
                        style: AppTextStyles.headingM,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Nav items
              ...List.generate(_kNavItems.length, (i) {
                final item = _kNavItems[i];
                return _sideNavItem(i, item.icon, item.label);
              }),
              const Spacer(),
              const Divider(color: AppColors.border),
              // Profile row
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 4),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                  backgroundImage: restaurant?.logoUrl != null
                      ? NetworkImage(restaurant!.logoUrl!)
                      : null,
                  child: restaurant?.logoUrl == null
                      ? Text(
                          (restaurant?.name ?? 'R').substring(0, 1),
                          style: AppTextStyles.labelM
                              .copyWith(color: AppColors.accent),
                        )
                      : null,
                ),
                title: Text(
                  restaurant?.name ?? '',
                  style: AppTextStyles.labelM,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textSecondary, size: 18),
                    onPressed: () => _showProfileMenu(ctx),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
        // Thin divider
        Container(width: 1, color: AppColors.border),
        // Main content
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),
        ),
      ],
    );
  }

  void _showProfileMenu(BuildContext ctx) {
    final RenderBox box = ctx.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    showMenu(
      context: ctx,
      position: RelativeRect.fromLTRB(offset.dx, offset.dy,
          offset.dx + box.size.width, offset.dy + box.size.height),
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          onTap: () => _openProfile(ctx),
          child: const Row(
            children: [
              Icon(Icons.person_rounded,
                  color: AppColors.textSecondaryLight, size: 16),
              SizedBox(width: 8),
              Text('Profile',
                  style: TextStyle(color: AppColors.textPrimaryLight)),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: _logout,
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFFF4757), size: 16),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: Color(0xFFFF4757))),
            ],
          ),
        ),
      ],
    );
  }

  void _openProfile(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 480,
          constraints: const BoxConstraints(maxHeight: 700),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: const ProfileTab(),
        ),
      ),
    );
  }

  Widget _sideNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: AppRadius.borderMedium,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: AppRadius.borderMedium,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive
                    ? AppColors.accent
                    : AppColors.textSecondaryLight,
                size: 20,
              ),
              if (index == 5)
                ValueListenableBuilder<int>(
                  valueListenable: NotificationService().unreadCount,
                  builder: (_, count, child) =>
                      count > 0 ? _NavUnreadDot(count: count) : child!,
                  child: const SizedBox.shrink(),
                ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.labelM.copyWith(
                  color: isActive
                      ? AppColors.accent
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mobile: Bottom Nav ────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: _tabs,
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final theme = Theme.of(context);
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _navigate,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
      unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
      backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
      items: _kNavItems.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        );
      }).toList(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final restaurant = auth.restaurant;

    return Drawer(
      backgroundColor: AppColors.surfaceElevated,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            // Brand + restaurant
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                    backgroundImage: restaurant?.logoUrl != null
                        ? NetworkImage(restaurant!.logoUrl!)
                        : null,
                    child: restaurant?.logoUrl == null
                        ? Text(
                            (restaurant?.name ?? 'R').substring(0, 1),
                            style: AppTextStyles.headingM
                                .copyWith(color: AppColors.accent),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant?.name ?? 'Restaurant',
                          style: AppTextStyles.labelM,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          restaurant?.email ?? '',
                          style: AppTextStyles.bodyS
                              .copyWith(color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            // Nav items
            ...List.generate(_kNavItems.length, (i) {
              final item = _kNavItems[i];
              return _drawerNavItem(i, item.icon, item.label);
            }),
            const Divider(color: AppColors.border),
            // Profile
            ListTile(
              leading: const Icon(Icons.person_rounded,
                  color: AppColors.textSecondary, size: 20),
              title: const Text('Profile', style: AppTextStyles.labelM),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const Scaffold(
                            backgroundColor: AppColors.background,
                            body: SafeArea(child: ProfileTab()),
                          )),
                );
              },
            ),
            // Logout
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: AppColors.error, size: 20),
              title: Text('Logout',
                  style: AppTextStyles.labelM.copyWith(color: AppColors.error)),
              onTap: _logout,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _drawerNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.accent : AppColors.textSecondaryLight,
            size: 20,
          ),
          if (index == 5)
            Positioned(
              right: -8,
              top: -6,
              child: ValueListenableBuilder<int>(
                valueListenable: NotificationService().unreadCount,
                builder: (_, count, child) =>
                    count > 0 ? _NavUnreadDot(count: count) : child!,
                child: const SizedBox.shrink(),
              ),
            ),
        ],
      ),
      title: Text(
        label,
        style: AppTextStyles.labelM.copyWith(
          color: isActive ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
      tileColor: isActive
          ? AppColors.accent.withValues(alpha: 0.08)
          : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMedium),
      onTap: () => _navigate(index),
    );
  }
}

class _NavUnreadDot extends StatelessWidget {
  final int count;

  const _NavUnreadDot({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: AppRadius.borderFull,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _OfflineSyncBanner extends StatelessWidget {
  const _OfflineSyncBanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<OfflineSyncState>(
      valueListenable: OfflineSyncService.notifier,
      builder: (context, state, _) {
        final shouldShow =
            !state.isOnline || state.isSyncing || state.pendingActions > 0;
        if (!shouldShow) return const SizedBox.shrink();

        final color = !state.isOnline
            ? AppColors.warning
            : state.isSyncing
                ? AppColors.info
                : AppColors.success;
        final icon = !state.isOnline
            ? Icons.cloud_off_rounded
            : state.isSyncing
                ? Icons.sync_rounded
                : Icons.cloud_done_rounded;
        final message = !state.isOnline
            ? state.pendingActions > 0
                ? '${state.pendingActions} saved change${state.pendingActions == 1 ? '' : 's'} will sync automatically'
                : 'Showing saved data'
            : state.isSyncing
                ? 'Syncing saved changes'
                : '${state.pendingActions} change${state.pendingActions == 1 ? '' : 's'} waiting to sync';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          color: color.withValues(alpha: 0.12),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.labelS.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (state.pendingActions > 0 && !state.isSyncing)
                TextButton(
                  onPressed: OfflineSyncService.flushQueuedRequests,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Sync',
                    style: AppTextStyles.labelS.copyWith(color: color),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
