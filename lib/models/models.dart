class Restaurant {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final String? gstNumber;
  final String? logoUrl;
  final bool isActive;
  final bool isAcceptingOrders;
  final String businessType;
  final String? truckQrCodeUrl;
  final String? createdAt;

  const Restaurant({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    this.gstNumber,
    this.logoUrl,
    required this.isActive,
    this.isAcceptingOrders = true,
    this.businessType = 'cafe_restaurant',
    this.truckQrCodeUrl,
    this.createdAt,
  });

  bool get isFoodTruck => businessType == 'food_truck';

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'],
      gstNumber: json['gstNumber'],
      logoUrl: json['logoUrl'],
      isActive: json['isActive'] ?? true,
      isAcceptingOrders: json['isAcceptingOrders'] ?? true,
      businessType: json['businessType'] ?? 'cafe_restaurant',
      truckQrCodeUrl: json['truckQrCodeUrl'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'gstNumber': gstNumber,
        'logoUrl': logoUrl,
        'isActive': isActive,
        'isAcceptingOrders': isAcceptingOrders,
        'businessType': businessType,
        'truckQrCodeUrl': truckQrCodeUrl,
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

  Map<String, dynamic> toJson() => {
        '_id': id,
        'restaurantId': restaurantId,
        'tableNumber': tableNumber,
        'tableName': tableName,
        'qrCodeUrl': qrCodeUrl,
        'qrCodeData': qrCodeData,
        'isActive': isActive,
        'isServiceable': isServiceable,
        'isOccupied': isOccupied,
      };

  TableModel copyWith({
    String? tableName,
    bool? isServiceable,
    bool? isOccupied,
  }) {
    return TableModel(
      id: id,
      restaurantId: restaurantId,
      tableNumber: tableNumber,
      tableName: tableName ?? this.tableName,
      qrCodeUrl: qrCodeUrl,
      qrCodeData: qrCodeData,
      isActive: isActive,
      isServiceable: isServiceable ?? this.isServiceable,
      isOccupied: isOccupied ?? this.isOccupied,
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

  Map<String, dynamic> toJson() => {
        '_id': id,
        'restaurantId': restaurantId,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'isAvailable': isAvailable,
        'isVeg': isVeg,
      };

  MenuItem copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    bool? isVeg,
  }) {
    return MenuItem(
      id: id,
      restaurantId: restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isVeg: isVeg ?? this.isVeg,
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

  Map<String, dynamic> toJson() => {
        'menuItemId': menuItemId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
        'customization': customization,
      };
}

class Order {
  final String id;
  final String restaurantId;
  final String tableId;
  final int tableNumber;
  final String tableName;
  final String businessType;
  final int? orderPickupNumber;
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
    this.businessType = 'cafe_restaurant',
    this.orderPickupNumber,
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
      businessType: json['businessType'] ?? 'cafe_restaurant',
      orderPickupNumber: (json['orderPickupNumber'] as num?)?.toInt(),
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

  Map<String, dynamic> toJson() => {
        '_id': id,
        'restaurantId': restaurantId,
        'tableId': tableId,
        'tableNumber': tableNumber,
        'tableName': tableName,
        'businessType': businessType,
        'orderPickupNumber': orderPickupNumber,
        'orderNumber': orderNumber,
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'taxPercent': taxPercent,
        'taxAmount': taxAmount,
        'totalAmount': totalAmount,
        'orderStatus': orderStatus,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'paidAt': paidAt,
        'placedAt': placedAt,
      };

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
      businessType: businessType,
      orderPickupNumber: orderPickupNumber,
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
  final String? restaurantPhone;
  final String? restaurantGstNumber;
  final int tableNumber;
  final String tableName;
  final String businessType;
  final int? orderPickupNumber;
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
    this.restaurantPhone,
    this.restaurantGstNumber,
    required this.tableNumber,
    required this.tableName,
    this.businessType = 'cafe_restaurant',
    this.orderPickupNumber,
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
      restaurantPhone: json['restaurantPhone'],
      restaurantGstNumber: json['restaurantGstNumber'],
      tableNumber: (json['tableNumber'] as num?)?.toInt() ?? 0,
      tableName: json['tableName'] ?? '',
      businessType: json['businessType'] ?? 'cafe_restaurant',
      orderPickupNumber: (json['orderPickupNumber'] as num?)?.toInt(),
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

  Map<String, dynamic> toJson() => {
        '_id': id,
        'orderId': orderId,
        'restaurantName': restaurantName,
        'restaurantLogoUrl': restaurantLogoUrl,
        'restaurantPhone': restaurantPhone,
        'restaurantGstNumber': restaurantGstNumber,
        'tableNumber': tableNumber,
        'tableName': tableName,
        'businessType': businessType,
        'orderPickupNumber': orderPickupNumber,
        'orderNumber': orderNumber,
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'taxPercent': taxPercent,
        'taxAmount': taxAmount,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'generatedAt': generatedAt,
      };
}
