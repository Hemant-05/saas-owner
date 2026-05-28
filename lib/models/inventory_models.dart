/// Inventory data models for the Restaurant Owner App
library;

class InventoryItem {
  final String id;
  final String restaurantId;
  final String name;
  final String? imageUrl;
  final String? imagePublicId;
  final String unit;
  final double currentStock;
  final double lowStockThreshold;
  final double? costPerUnit;
  final bool isActive;
  final bool isLowStock;
  final String? createdAt;
  final String? updatedAt;

  const InventoryItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.imageUrl,
    this.imagePublicId,
    required this.unit,
    required this.currentStock,
    required this.lowStockThreshold,
    this.costPerUnit,
    required this.isActive,
    required this.isLowStock,
    this.createdAt,
    this.updatedAt,
  });

  bool get isOutOfStock => currentStock == 0;

  /// Ratio from 0.0 to 1.0+ for the stock level indicator bar
  double get stockRatio {
    if (lowStockThreshold == 0) return 1.0;
    return (currentStock / (lowStockThreshold * 2)).clamp(0.0, 1.0);
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['_id'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'],
      imagePublicId: json['imagePublicId'],
      unit: json['unit'] ?? '',
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toDouble() ?? 10.0,
      costPerUnit: (json['costPerUnit'] as num?)?.toDouble(),
      isActive: json['isActive'] ?? true,
      isLowStock: json['isLowStock'] ?? false,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'restaurantId': restaurantId,
        'name': name,
        'imageUrl': imageUrl,
        'unit': unit,
        'currentStock': currentStock,
        'lowStockThreshold': lowStockThreshold,
        'costPerUnit': costPerUnit,
        'isActive': isActive,
        'isLowStock': isLowStock,
      };

  InventoryItem copyWith({
    double? currentStock,
    bool? isLowStock,
  }) {
    return InventoryItem(
      id: id,
      restaurantId: restaurantId,
      name: name,
      imageUrl: imageUrl,
      imagePublicId: imagePublicId,
      unit: unit,
      currentStock: currentStock ?? this.currentStock,
      lowStockThreshold: lowStockThreshold,
      costPerUnit: costPerUnit,
      isActive: isActive,
      isLowStock: isLowStock ?? this.isLowStock,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class InventoryStats {
  final int totalItems;
  final int lowStockCount;
  final int outOfStockCount;

  const InventoryStats({
    required this.totalItems,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  factory InventoryStats.fromJson(Map<String, dynamic> json) {
    return InventoryStats(
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      outOfStockCount: (json['outOfStockCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory InventoryStats.empty() =>
      const InventoryStats(totalItems: 0, lowStockCount: 0, outOfStockCount: 0);
}

class StockTransaction {
  final String id;
  final String restaurantId;
  final String inventoryItemId;
  final String inventoryItemName;
  final String unit;
  final String transactionType;
  final double quantityChanged;
  final double quantityBefore;
  final double quantityAfter;
  final String? referenceOrderId;
  final String note;
  final String createdBy;
  final String? createdAt;

  const StockTransaction({
    required this.id,
    required this.restaurantId,
    required this.inventoryItemId,
    required this.inventoryItemName,
    required this.unit,
    required this.transactionType,
    required this.quantityChanged,
    required this.quantityBefore,
    required this.quantityAfter,
    this.referenceOrderId,
    required this.note,
    required this.createdBy,
    this.createdAt,
  });

  bool get isAddition => quantityChanged > 0;

  String get humanReadableType {
    switch (transactionType) {
      case 'manual_add':
        return 'Stock Added';
      case 'manual_remove':
        return 'Stock Removed';
      case 'order_deduction':
        return 'Order Deduction';
      case 'order_restoration':
        return 'Stock Restored — Order Cancelled';
      case 'adjustment':
        return 'Manual Adjustment';
      default:
        return transactionType;
    }
  }

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['_id'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      inventoryItemId: json['inventoryItemId'] ?? '',
      inventoryItemName: json['inventoryItemName'] ?? '',
      unit: json['unit'] ?? '',
      transactionType: json['transactionType'] ?? '',
      quantityChanged: (json['quantityChanged'] as num?)?.toDouble() ?? 0.0,
      quantityBefore: (json['quantityBefore'] as num?)?.toDouble() ?? 0.0,
      quantityAfter: (json['quantityAfter'] as num?)?.toDouble() ?? 0.0,
      referenceOrderId: json['referenceOrderId'],
      note: json['note'] ?? '',
      createdBy: json['createdBy'] ?? 'system',
      createdAt: json['createdAt'],
    );
  }
}

class MenuItemIngredient {
  final String id;
  final String restaurantId;
  final String menuItemId;
  final String inventoryItemId;
  final double quantityUsedPerServing;
  final String unit;

  // Populated fields (optional)
  final String? menuItemName;
  final String? inventoryItemName;
  final double? inventoryItemCurrentStock;

  const MenuItemIngredient({
    required this.id,
    required this.restaurantId,
    required this.menuItemId,
    required this.inventoryItemId,
    required this.quantityUsedPerServing,
    required this.unit,
    this.menuItemName,
    this.inventoryItemName,
    this.inventoryItemCurrentStock,
  });

  factory MenuItemIngredient.fromJson(Map<String, dynamic> json) {
    // Handle populated vs unpopulated inventoryItemId
    String invItemId = '';
    String? invItemName;
    double? invItemStock;
    String unitValue = json['unit'] ?? '';

    if (json['inventoryItemId'] is Map) {
      final inv = json['inventoryItemId'] as Map<String, dynamic>;
      invItemId = inv['_id'] ?? '';
      invItemName = inv['name'];
      invItemStock = (inv['currentStock'] as num?)?.toDouble();
      if (unitValue.isEmpty) unitValue = inv['unit'] ?? '';
    } else {
      invItemId = json['inventoryItemId'] ?? '';
    }

    String menuItemId = '';
    String? menuItemName;
    if (json['menuItemId'] is Map) {
      final mi = json['menuItemId'] as Map<String, dynamic>;
      menuItemId = mi['_id'] ?? '';
      menuItemName = mi['name'];
    } else {
      menuItemId = json['menuItemId'] ?? '';
    }

    return MenuItemIngredient(
      id: json['_id'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      menuItemId: menuItemId,
      inventoryItemId: invItemId,
      quantityUsedPerServing: (json['quantityUsedPerServing'] as num?)?.toDouble() ?? 0.0,
      unit: unitValue,
      menuItemName: menuItemName,
      inventoryItemName: invItemName,
      inventoryItemCurrentStock: invItemStock,
    );
  }
}
