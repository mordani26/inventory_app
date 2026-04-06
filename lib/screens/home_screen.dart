import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService service = FirestoreService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  bool isEditing = false;
  String? editingId;

  void clearFields() {
    nameController.clear();
    quantityController.clear();
    priceController.clear();
    isEditing = false;
    editingId = null;
  }

  Future<void> saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final item = Item(
      id: editingId,
      name: nameController.text.trim(),
      quantity: int.parse(quantityController.text.trim()),
      price: double.parse(priceController.text.trim()),
    );

    if (isEditing) {
      await service.updateItem(item);
    } else {
      await service.addItem(item);
    }

    clearFields();
    setState(() {});
  }

  void loadItemForEdit(Item item) {
    nameController.text = item.name;
    quantityController.text = item.quantity.toString();
    priceController.text = item.price.toString();
    isEditing = true;
    editingId = item.id;
    setState(() {});
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory App'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter item name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter quantity';
                      }
                      final numValue = int.tryParse(value);
                      if (numValue == null || numValue < 0) {
                        return 'Enter a valid quantity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter price';
                      }
                      final numValue = double.tryParse(value);
                      if (numValue == null || numValue < 0) {
                        return 'Enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: saveItem,
                          child: Text(isEditing ? 'Update Item' : 'Add Item'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            clearFields();
                            setState(() {});
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            StreamBuilder<List<Item>>(
              stream: service.streamItems(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                double total = 0;

                for (var item in items) {
                  total += item.quantity * item.price;
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Total Value: \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<List<Item>>(
                stream: service.streamItems(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return const Center(child: Text('No items yet.'));
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Card(
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Qty: ${item.quantity} | Price: \$${item.price.toStringAsFixed(2)}',
                              ),
                              if (item.quantity < 2)
                                const Text(
                                  '⚠️ Low Stock',
                                  style: TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => loadItemForEdit(item),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await service.deleteItem(item.id!);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
