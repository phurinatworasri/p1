import 'package:flutter/material.dart';
import 'login.dart';
import '../db/transaction_db.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Mini POS"),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            buildMenu(context, "เพิ่มสินค้า", Icons.add, Colors.green),
            buildMenu(context, "รายการสินค้า", Icons.list, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget buildMenu(BuildContext context, String text, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        if (text == "เพิ่มสินค้า") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddProductPage()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductPage()),
          );
        }
      },
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(text),
        ),
      ),
    );
  }
}

// ---------------- เพิ่มสินค้า ----------------
class AddProductPage extends StatefulWidget {
  final Map? item; // 👈 ใช้ตอนแก้ไข

  AddProductPage({this.item});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  TextEditingController name = TextEditingController();
  TextEditingController price = TextEditingController();

  final db = TransactionDB();

  @override
  void initState() {
    super.initState();

    // 👇 ถ้ามีข้อมูล = โหมดแก้ไข
    if (widget.item != null) {
      name.text = widget.item!['name'];
      price.text = widget.item!['price'].toString();
    }
  }

  save() async {
    if (name.text.isEmpty || price.text.isEmpty) {
      showMsg("กรอกข้อมูลให้ครบ");
      return;
    }

    if (widget.item == null) {
      // ➕ เพิ่ม
      await db.insertProduct({
        'name': name.text,
        'price': int.parse(price.text),
      });
    } else {
      // ✏️ แก้ไข
      await db.updateProduct(widget.item!['id'], {
        'name': name.text,
        'price': int.parse(price.text),
      });
    }

    Navigator.pop(context);
  }

  showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? "เพิ่มสินค้า" : "แก้ไขสินค้า"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: "ชื่อสินค้า"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "ราคา"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: save,
              child: Text("บันทึก"),
            )
          ],
        ),
      ),
    );
  }
}

// ---------------- รายการสินค้า ----------------
class ProductPage extends StatefulWidget {
  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final db = TransactionDB();
  List data = [];

  loadData() async {
    var res = await db.getProducts();
    setState(() {
      data = res;
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  delete(int id) async {
    await db.deleteProduct(id);
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("รายการสินค้า")),
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (_, i) {
          var item = data[i];

          return Card(
            child: ListTile(
              title: Text(item['name']),
              subtitle: Text("ราคา: ${item['price']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✏️ แก้ไข
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.orange),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddProductPage(item: item),
                        ),
                      );
                      loadData();
                    },
                  ),

                  // 🗑 ลบ
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      delete(item['id']);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}