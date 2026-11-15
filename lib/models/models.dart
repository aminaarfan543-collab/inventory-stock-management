class User {
  final int id;
  final String username;
  final String fullName;
  final String? email;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: int.tryParse('${j['id']}') ?? 0,
    username: j['username']?.toString() ?? '',
    fullName: j['full_name']?.toString() ?? j['name']?.toString() ?? '',
    email: j['email']?.toString(),
  );
}

class Category {
  final int id;
  final String name;
  final String description;

  Category({required this.id, required this.name, this.description = ''});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: int.tryParse('${j['id']}') ?? 0,
    name: j['name']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {'name': name, 'description': description};
}

class Supplier {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String address;

  Supplier({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
  });

  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
    id: int.tryParse('${j['id']}') ?? 0,
    name: j['name']?.toString() ?? '',
    phone: j['phone']?.toString() ?? '',
    email: j['email']?.toString() ?? '',
    address: j['address']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
  };
}

class Product {
  final int id;
  final String name;
  final String sku;
  final String description;
  final int? categoryId;
  final int? supplierId;
  final double unitPrice;
  final double costPrice;
  final int quantity;
  final int reorderLevel;
  final String? createdAt;
  final String? categoryName;
  final String? supplierName;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.description = '',
    this.categoryId,
    this.supplierId,
    required this.unitPrice,
    required this.costPrice,
    required this.quantity,
    required this.reorderLevel,
    this.createdAt,
    this.categoryName,
    this.supplierName,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: int.tryParse('${j['id']}') ?? 0,
    name: j['name']?.toString() ?? '',
    sku: j['sku']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    categoryId: j['category_id'] != null
        ? int.tryParse('${j['category_id']}')
        : null,
    supplierId: j['supplier_id'] != null
        ? int.tryParse('${j['supplier_id']}')
        : null,
    unitPrice: double.tryParse('${j['unit_price'] ?? j['price']}') ?? 0,
    costPrice: double.tryParse('${j['cost_price'] ?? j['cost']}') ?? 0,
    quantity: int.tryParse('${j['quantity'] ?? j['stock']}') ?? 0,
    reorderLevel: int.tryParse('${j['reorder_level'] ?? j['reorder']}') ?? 10,
    createdAt: j['created_at']?.toString(),
    categoryName: j['category_name']?.toString(),
    supplierName: j['supplier_name']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'sku': sku,
    'description': description,
    'category_id': categoryId,
    'supplier_id': supplierId,
    'unit_price': unitPrice,
    'cost_price': costPrice,
    'quantity': quantity,
    'reorder_level': reorderLevel,
  };

  bool get isLowStock => quantity <= reorderLevel;
  bool get isOutOfStock => quantity <= 0;
}

class Service {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? createdAt;

  Service({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.createdAt,
  });

  factory Service.fromJson(Map<String, dynamic> j) => Service(
    id: int.tryParse('${j['id']}') ?? 0,
    name: j['name']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    price: double.tryParse('${j['price']}') ?? 0,
    createdAt: j['created_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'price': price,
  };
}

class StockMovement {
  final int id;
  final int productId;
  final String type;
  final int quantity;
  final String note;
  final int? userId;
  final String? createdAt;
  final String? productName;
  final String? userName;

  StockMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    this.note = '',
    this.userId,
    this.createdAt,
    this.productName,
    this.userName,
  });

  factory StockMovement.fromJson(Map<String, dynamic> j) => StockMovement(
    id: int.tryParse('${j['id']}') ?? 0,
    productId: int.tryParse('${j['product_id']}') ?? 0,
    type: j['type']?.toString().toUpperCase() ?? 'STOCK_IN',
    quantity: int.tryParse('${j['quantity']}') ?? 0,
    note: j['note']?.toString() ?? '',
    userId: j['user_id'] != null ? int.tryParse('${j['user_id']}') : null,
    createdAt: j['created_at']?.toString(),
    productName: j['product_name']?.toString(),
    userName: j['user_name']?.toString(),
  );
}

class DashboardStats {
  final int totalProducts;
  final int totalStockUnits;
  final int lowStockCount;
  final int totalCategories;
  final int totalSuppliers;
  final double inventoryValue;
  final int totalServices;

  DashboardStats({
    required this.totalProducts,
    required this.totalStockUnits,
    required this.lowStockCount,
    required this.totalCategories,
    required this.totalSuppliers,
    required this.inventoryValue,
    required this.totalServices,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    totalProducts: int.tryParse('${j['total_products'] ?? 0}') ?? 0,
    totalStockUnits:
        int.tryParse('${j['total_stock'] ?? j['total_stock_units'] ?? 0}') ?? 0,
    lowStockCount: int.tryParse('${j['low_stock_count'] ?? 0}') ?? 0,
    totalCategories: int.tryParse('${j['total_categories'] ?? 0}') ?? 0,
    totalSuppliers: int.tryParse('${j['total_suppliers'] ?? 0}') ?? 0,
    inventoryValue: double.tryParse('${j['inventory_value'] ?? 0}') ?? 0,
    totalServices: int.tryParse('${j['total_services'] ?? 0}') ?? 0,
  );
}
