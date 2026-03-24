import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TransactionDB {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  initDb() async {
    String path = join(await getDatabasesPath(), 'pos.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 🛍 สินค้า
        await db.execute('''
        CREATE TABLE products(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          price INTEGER
        )
        ''');

        // 🛒 ตะกร้า
        await db.execute('''
        CREATE TABLE cart(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          price INTEGER,
          qty INTEGER,
          total INTEGER
        )
        ''');
      },
    );
  }

  // ================== PRODUCT ==================

  // ➕ เพิ่มสินค้า
  insertProduct(Map<String, dynamic> data) async {
    var dbClient = await db;
    return dbClient.insert('products', data);
  }

  // 📋 ดูสินค้า
  getProducts() async {
    var dbClient = await db;
    return dbClient.query('products');
  }

  // ✏️ แก้ไขสินค้า
  updateProduct(int id, Map<String, dynamic> data) async {
    var dbClient = await db;
    return dbClient.update(
      'products',
      data,
      where: 'id=?',
      whereArgs: [id],
    );
  }

  // 🗑 ลบสินค้า
  deleteProduct(int id) async {
    var dbClient = await db;
    return dbClient.delete(
      'products',
      where: 'id=?',
      whereArgs: [id],
    );
  }

  // ================== CART ==================

  // ➕ เพิ่มลงตะกร้า (มีคำนวณ total)
  insertCart(Map<String, dynamic> data) async {
    var dbClient = await db;

    int price = data['price'];
    int qty = data['qty'];
    int total = price * qty;

    data['total'] = total;

    return dbClient.insert('cart', data);
  }

  // 📋 ดูตะกร้า
  getCart() async {
    var dbClient = await db;
    return dbClient.query('cart');
  }

  // ✏️ แก้ไขจำนวนสินค้าในตะกร้า
  updateCart(int id, int price, int qty) async {
    var dbClient = await db;

    int total = price * qty;

    return dbClient.update(
      'cart',
      {
        'qty': qty,
        'total': total,
      },
      where: 'id=?',
      whereArgs: [id],
    );
  }

  // 🗑 ลบสินค้าในตะกร้า
  deleteCart(int id) async {
    var dbClient = await db;
    return dbClient.delete(
      'cart',
      where: 'id=?',
      whereArgs: [id],
    );
  }

  // 💰 รวมยอดในตะกร้า
  getTotalCart() async {
    var dbClient = await db;
    var res = await dbClient.rawQuery(
        "SELECT SUM(total) as total FROM cart");

    return res.first['total'] ?? 0;
  }

  // 🧹 ล้างตะกร้า (ตอนจ่ายเงิน)
  clearCart() async {
    var dbClient = await db;
    return dbClient.delete('cart');
  }
}