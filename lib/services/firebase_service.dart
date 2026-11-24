import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart' hide User;

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static bool get isLoggedIn => _auth.currentUser != null;
  static User? get currentUser => _auth.currentUser;

  static Future<void> init() async {
    _auth.authStateChanges().listen((_) {});
  }

  // =========== AUTH ===========

  static Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    }
  }

  static Future<void> register(
      String email, String password, String fullName) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        'full_name': fullName,
        'email': email.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      return {
        'id': user.uid,
        'username': user.email ?? '',
        'full_name': user.email?.split('@').first ?? 'User',
        'email': user.email ?? '',
      };
    }
    final data = doc.data()!;
    return {
      'id': user.uid,
      'username': data['full_name'] ?? user.email?.split('@').first ?? 'User',
      'full_name': data['full_name'] ?? 'User',
      'email': user.email ?? '',
    };
  }

  // =========== CATEGORIES ===========

  static Future<List<Category>> getCategories() async {
    final snap = await _db.collection('categories').orderBy('name').get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return Category.fromJson({
        'id': doc.id,
        'name': data['name'] ?? '',
        'description': data['description'] ?? '',
        'created_at': _timestampToIso(data['created_at']),
      });
    }).toList();
  }

  static Future<void> addCategory(String name, String description) async {
    await _db.collection('categories').add({
      'name': name,
      'description': description,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateCategory(
      String id, String name, String description) async {
    await _db.collection('categories').doc(id).update({
      'name': name,
      'description': description,
    });
  }

  static Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  // =========== SUPPLIERS ===========

  static Future<List<Supplier>> getSuppliers() async {
    final snap = await _db.collection('suppliers').orderBy('name').get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return Supplier.fromJson({
        'id': doc.id,
        'name': data['name'] ?? '',
        'phone': data['phone'] ?? '',
        'email': data['email'] ?? '',
        'address': data['address'] ?? '',
        'created_at': _timestampToIso(data['created_at']),
      });
    }).toList();
  }

  static Future<void> addSupplier(Map<String, dynamic> data) async {
    await _db.collection('suppliers').add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateSupplier(
      String id, Map<String, dynamic> data) async {
    await _db.collection('suppliers').doc(id).update(data);
  }

  static Future<void> deleteSupplier(String id) async {
    await _db.collection('suppliers').doc(id).delete();
  }

  // =========== PRODUCTS ===========

  static Future<List<Product>> getProducts({
    String? search,
    String? categoryId,
    bool lowStockOnly = false,
    String sort = 'name_asc',
  }) async {
    Query query = _db.collection('products');

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('category_id', isEqualTo: categoryId);
    }

    final snap = await query.get();
    var products = snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Product.fromJson({
        'id': doc.id,
        'name': data['name'] ?? '',
        'sku': data['sku'] ?? '',
        'description': data['description'] ?? '',
        'category_id': data['category_id'],
        'supplier_id': data['supplier_id'],
        'unit_price': (data['unit_price'] ?? 0).toDouble(),
        'cost_price': (data['cost_price'] ?? 0).toDouble(),
        'quantity': (data['quantity'] ?? 0).toInt(),
        'reorder_level': (data['reorder_level'] ?? 10).toInt(),
        'created_at': _timestampToIso(data['created_at']),
        'category_name': data['category_name'],
        'supplier_name': data['supplier_name'],
      });
    }).toList();

    if (search != null && search.isNotEmpty) {
      final term = search.toLowerCase();
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(term) ||
              p.sku.toLowerCase().contains(term))
          .toList();
    }

    if (lowStockOnly) {
      products = products.where((p) => p.quantity <= p.reorderLevel).toList();
    }

    switch (sort) {
      case 'name_desc':
        products.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'stock_asc':
        products.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'stock_desc':
        products.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case 'price_asc':
        products.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
        break;
      case 'price_desc':
        products.sort((a, b) => b.unitPrice.compareTo(a.unitPrice));
        break;
      case 'name_asc':
      default:
        products.sort((a, b) => a.name.compareTo(b.name));
    }

    return products;
  }

  static Future<Product> getProduct(String id) async {
    final doc = await _db.collection('products').doc(id).get();
    if (!doc.exists) throw Exception('Product not found');
    final data = doc.data()!;
    return Product.fromJson({
      'id': doc.id,
      'name': data['name'] ?? '',
      'sku': data['sku'] ?? '',
      'description': data['description'] ?? '',
      'category_id': data['category_id'],
      'supplier_id': data['supplier_id'],
      'unit_price': (data['unit_price'] ?? 0).toDouble(),
      'cost_price': (data['cost_price'] ?? 0).toDouble(),
      'quantity': (data['quantity'] ?? 0).toInt(),
      'reorder_level': (data['reorder_level'] ?? 10).toInt(),
      'created_at': _timestampToIso(data['created_at']),
      'category_name': data['category_name'],
      'supplier_name': data['supplier_name'],
    });
  }

  static Future<String> addProduct(Map<String, dynamic> data) async {
    final docRef = await _db.collection('products').add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    final qty = (data['quantity'] ?? 0) as int;
    if (qty > 0) {
      await _db.collection('transactions').add({
        'product_id': docRef.id,
        'type': 'STOCK_IN',
        'quantity': qty,
        'note': 'Initial stock on product creation',
        'user_id': currentUser?.uid ?? '',
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    return docRef.id;
  }

  static Future<void> updateProduct(
      String id, Map<String, dynamic> data) async {
    await _db.collection('products').doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteProduct(String id) async {
    final txSnap = await _db
        .collection('transactions')
        .where('product_id', isEqualTo: id)
        .get();
    for (final doc in txSnap.docs) {
      await doc.reference.delete();
    }
    await _db.collection('products').doc(id).delete();
  }

  // =========== STOCK IN / OUT ===========

  static Future<int> stockMovement(
      String productId, String type, int quantity, String note) async {
    final productDoc = await _db.collection('products').doc(productId).get();
    if (!productDoc.exists) throw Exception('Product not found');
    final productData = productDoc.data()!;
    final currentQty = (productData['quantity'] ?? 0) as int;

    int newQty;
    if (type == 'STOCK_IN') {
      newQty = currentQty + quantity;
    } else {
      if (quantity > currentQty) {
        throw Exception('Cannot remove $quantity - only $currentQty in stock');
      }
      newQty = currentQty - quantity;
    }

    await _db.collection('products').doc(productId).update({
      'quantity': newQty,
      'updated_at': FieldValue.serverTimestamp(),
    });

    await _db.collection('transactions').add({
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'note': note,
      'user_id': currentUser?.uid ?? '',
      'created_at': FieldValue.serverTimestamp(),
    });

    return newQty;
  }

  // =========== TRANSACTIONS ===========

  static Future<List<StockMovement>> getTransactions(
      {String? productId, int limit = 200}) async {
    Query query = _db.collection('transactions');

    if (productId != null) {
      query = query.where('product_id', isEqualTo: productId);
    }

    final snap =
        await query.orderBy('created_at', descending: true).limit(limit).get();

    final allTxs = <StockMovement>[];
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;

      String productName = '';
      String userName = '';
      try {
        final productDoc = await _db
            .collection('products')
            .doc(data['product_id'] ?? '')
            .get();
        if (productDoc.exists) {
          productName = (productDoc.data()?['name'] ?? '') as String;
        }
      } catch (_) {}

      try {
        final userDoc =
            await _db.collection('users').doc(data['user_id'] ?? '').get();
        if (userDoc.exists) {
          userName = (userDoc.data()?['full_name'] ?? '') as String;
        }
      } catch (_) {}

      allTxs.add(StockMovement.fromJson({
        'id': doc.id,
        'product_id': data['product_id'] ?? '',
        'type': data['type'] ?? 'STOCK_IN',
        'quantity': (data['quantity'] ?? 0) as int,
        'note': data['note'] ?? '',
        'user_id': data['user_id'] ?? '',
        'created_at': _timestampToIso(data['created_at']),
        'product_name': productName,
        'user_name': userName,
      }));
    }

    return allTxs;
  }

  // =========== SERVICES ===========

  static Future<List<Service>> getServices() async {
    final snap = await _db.collection('services').orderBy('name').get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return Service.fromJson({
        'id': doc.id,
        'name': data['name'] ?? '',
        'description': data['description'] ?? '',
        'price': (data['price'] ?? 0).toDouble(),
        'created_at': _timestampToIso(data['created_at']),
      });
    }).toList();
  }

  static Future<Service> getService(String id) async {
    final doc = await _db.collection('services').doc(id).get();
    if (!doc.exists) throw Exception('Service not found');
    final data = doc.data()!;
    return Service.fromJson({
      'id': doc.id,
      'name': data['name'] ?? '',
      'description': data['description'] ?? '',
      'price': (data['price'] ?? 0).toDouble(),
      'created_at': _timestampToIso(data['created_at']),
    });
  }

  static Future<void> addService(Map<String, dynamic> data) async {
    await _db.collection('services').add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateService(
      String id, Map<String, dynamic> data) async {
    await _db.collection('services').doc(id).update(data);
  }

  static Future<void> deleteService(String id) async {
    await _db.collection('services').doc(id).delete();
  }

  // =========== DASHBOARD STATS ===========

  static Future<DashboardStats> getDashboardStats() async {
    final products = await getProducts();
    final categories = await getCategories();
    final suppliers = await getSuppliers();
    final services = await getServices();

    final totalStock = products.fold<int>(0, (acc, p) => acc + p.quantity);
    final lowStockCount =
        products.where((p) => p.quantity <= p.reorderLevel).length;
    final inventoryValue = products.fold<double>(
        0.0, (acc, p) => acc + (p.quantity * p.costPrice));

    return DashboardStats(
      totalProducts: products.length,
      totalStockUnits: totalStock,
      lowStockCount: lowStockCount,
      totalCategories: categories.length,
      totalSuppliers: suppliers.length,
      inventoryValue: inventoryValue,
      totalServices: services.length,
    );
  }

  // =========== LOW STOCK ===========

  static Future<List<Product>> getLowStockProducts() async {
    final products = await getProducts();
    final lowStock =
        products.where((p) => p.quantity <= p.reorderLevel).toList();
    lowStock.sort((a, b) =>
        (a.quantity - a.reorderLevel).compareTo(b.quantity - b.reorderLevel));
    return lowStock;
  }

  // =========== HELPER ===========

  static String _timestampToIso(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    return value.toString();
  }
}
