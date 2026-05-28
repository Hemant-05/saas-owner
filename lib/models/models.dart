
class Restaurant {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final String? logoUrl;
  final bool isActive;
  final String? createdAt;

  const Restaurant({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    this.logoUrl,
    required this.isActive,
    this.createdAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'],
      logoUrl: json['logoUrl'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'logoUrl': logoUrl,
        'isActive': isActive,
        'createdAt': createdAt,
      };
}

class TableModel {
  final String id;
  final String restaurantId;
  final int tableNumber;
  final String tableName;
  final String? qrCodeUrl;
  final String? qrCodeData;
  final bool isActive;
  final bool isServiceable;
  final bool isOccupied;

  const TableModel({
    required this.id,
    required this.restaurantId,
    required this.tableNumber,
    required this.tableName,
    this.qrCodeUrl,
    this.qrCodeData,
    required this.isActive,
    this.isServiceable = true,
    this.isOccupied = false,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['_id'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      tableNumber: (json['tableNumber'] as num?)?.toInt() ?? 0,
      tableName: json['tableName'] ?? '',
      qrCodeUrl: json['qrCodeUrl'],
      qrCodeData: json['qrCodeData'],
      isActive: json['isActive'] ?? true,
      isServiceable: json['isServiceable'] ?? true,
      isOccupied: json['isOccupied'] ?? false,
    );
  }
}

class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imageUrl;
  final bool isAvailable;
  final bool isVeg;

  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.isAvailable,
    required this.isVeg,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['_id'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
      isVeg: json['isVeg'] ?? true,
    );
  }

  MenuItem copyWith({bool? isAvailable}) {
    return MenuItem(
      id: id,
      restaurantId: restaurantId,
      name: name,
      description: description,
      price: price,
      category: category,
      imageUrl: imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isVeg: isVeg,
    );
  }
}

class OrderItem {
  final String? menuItemId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final String customization;

  const OrderItem({
    this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.customization,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItemId'],
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      customization: json['customization'] ?? '',
    );
  }
}

class Order {
  final String id;
  final String restaurantId;
  final String tableId;
  final int tableNumber;
  final String tableName;
  final String orderNumber;
  final List<OrderItem> items;
  final double subtotal;
  final double taxPercent;
  final double taxAmount;
  final double totalAmount;
  final String orderStatus;
  final String paymentMethod;
  final String paymentStatus;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? paidAt;
  final String? placedAt;

  const Order({
    required this.id,
    required this.restaurantId,
    required this.tableId,
    required this.tableNumber,
    required this.tableName,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.taxPercent,
    required this.taxAmount,
    required this.totalAmount,
    required this.orderStatus,
    required this.paymentMethod,
    required this.paymentStatus,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.paidAt,
    this.placedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      tableId: json['tableId'] ?? '',
      tableNumber: (json['tableNumber'] as num?)?.toInt() ?? 0,
      tableName: json['tableName'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => OrderItem.fromJson(i))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 5.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      orderStatus: json['orderStatus'] ?? 'placed',
      paymentMethod: json['paymentMethod'] ?? 'cash',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      razorpayOrderId: json['razorpayOrderId'],
      razorpayPaymentId: json['razorpayPaymentId'],
      paidAt: json['paidAt'],
      placedAt: json['placedAt'],
    );
  }

  Order copyWith({
    String? orderStatus,
    String? paymentStatus,
    String? paymentMethod,
    String? paidAt,
  }) {
    return Order(
      id: id,
      restaurantId: restaurantId,
      tableId: tableId,
      tableNumber: tableNumber,
      tableName: tableName,
      orderNumber: orderNumber,
      items: items,
      subtotal: subtotal,
      taxPercent: taxPercent,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      paidAt: paidAt ?? this.paidAt,
      placedAt: placedAt,
    );
  }
}

class Bill {
  final String id;
  final String orderId;
  final String restaurantName;
  final String? restaurantLogoUrl;
  final int tableNumber;
  final String tableName;
  final String orderNumber;
  final List<OrderItem> items;
  final double subtotal;
  final double taxPercent;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String? generatedAt;

  const Bill({
    required this.id,
    required this.orderId,
    required this.restaurantName,
    this.restaurantLogoUrl,
    required this.tableNumber,
    required this.tableName,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.taxPercent,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.generatedAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'] ?? '',
      orderId: json['orderId'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      restaurantLogoUrl: json['restaurantLogoUrl'],
      tableNumber: (json['tableNumber'] as num?)?.toInt() ?? 0,
      tableName: json['tableName'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => OrderItem.fromJson(i))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 5.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? 'cash',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      generatedAt: json['generatedAt'],
    );
  }
}
