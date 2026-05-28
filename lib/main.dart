import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_owner_app/firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/table_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/inventory_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'package:flutter/gestures.dart';
import 'theme/app_theme.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase — wrapped in try-catch so the app starts
  // even if Firebase config is missing or has an issue.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('[Main] Firebase initialized successfully.');
  } catch (e) {
    debugPrint('[Main] Firebase init failed (non-fatal): $e');
  }

  // Initialize FCM notification service — also non-fatal
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('[Main] NotificationService init failed (non-fatal): $e');
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const QRCafeOwnerApp());
}

class QRCafeOwnerApp extends StatelessWidget {
  const QRCafeOwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TableProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
      ],
      child: MaterialApp(
        title: 'QR Cafe — Owner',
        debugShowCheckedModeBanner: false,
        // Use the centralized dark theme from app_theme.dart
        theme: AppTheme.darkTheme,
        scrollBehavior: AppScrollBehavior(),
        home: const SplashScreen(),
      ),
    );
  }
}
