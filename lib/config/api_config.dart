/// API configuration — update BASE_URL to your backend server's address
class ApiConfig {
  // Change this to your actual backend URL
  // For Android emulator: use http://10.0.2.2:5000
  // For physical device: use your machine's local IP e.g. http://192.168.29.174:5000
  // Note: For Android emulator, use http://10.0.2.2:5000
  static const String baseUrl = 'http://10.11.53.2:5000/api';
  static const String socketUrl = 'http://10.11.53.2:5000';

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';
  static const String updateProfile = '$baseUrl/auth/update-profile';

  // Table endpoints
  static const String tables = '$baseUrl/tables';
  static String tableById(String id) => '$baseUrl/tables/$id';

  // Menu endpoints
  static const String menu = '$baseUrl/menu';
  static const String menuAll = '$baseUrl/menu/all';
  static String menuItemById(String id) => '$baseUrl/menu/$id';

  // Public endpoints (customer)
  static String publicMenu(String restaurantId, String tableId) =>
      '$baseUrl/public/menu/$restaurantId/$tableId';

  // Order endpoints
  static const String placeOrder = '$baseUrl/orders/place';
  static const String restaurantOrders = '$baseUrl/orders/restaurant';
  static const String activeOrders = '$baseUrl/orders/restaurant/active';
  static String orderStatus(String orderId) => '$baseUrl/orders/status/$orderId';
  static String orderPayment(String orderId) => '$baseUrl/orders/payment/$orderId';
  static String bill(String orderId) => '$baseUrl/orders/bill/$orderId';

  // Payment endpoints
  static const String createRazorpayOrder = '$baseUrl/payment/create-razorpay-order';
  static const String verifyRazorpay = '$baseUrl/payment/verify-razorpay';

  // Analytics
  static String get dashboardStats => '$baseUrl/analytics/dashboard';
  static String get orderHistory => '$baseUrl/analytics/orders';

  // ── Inventory endpoints ────────────────────────────────────────────────────
  static const String inventoryItems = '$baseUrl/inventory/items';
  static const String inventoryLowStock = '$baseUrl/inventory/items/low-stock';
  static const String inventoryTransactions = '$baseUrl/inventory/transactions';
  static const String inventoryMenuLinksBase = '$baseUrl/inventory/menu-links';

  static String inventoryItemById(String id) => '$baseUrl/inventory/items/$id';
  static String inventoryAdjust(String id) => '$baseUrl/inventory/items/$id/adjust';
  static String inventoryItemTransactions(String id) =>
      '$baseUrl/inventory/items/$id/transactions';
  static String inventoryMenuLinks(String menuItemId) =>
      '$baseUrl/inventory/menu-links/$menuItemId';
  static String inventoryMenuLinkById(String linkId) =>
      '$baseUrl/inventory/menu-links/$linkId';

  // ── Notification endpoints ────────────────────────────────────────────────
  static const String registerRestaurantToken =
      '$baseUrl/notifications/register-restaurant-token';
  static const String registerCustomerToken =
      '$baseUrl/notifications/register-customer-token';
}

