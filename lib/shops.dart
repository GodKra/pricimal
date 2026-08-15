import 'package:flutter/material.dart';
import 'package:pricimal/util.dart';

class ShopData {
  final String id;
  final String name;
  final List<Product> items;

  const ShopData({
    required this.id,
    required this.name,
    required this.items,
  });
}

final List<ShopData> _availableShops = [
  ShopData(id: '1', name: "Jaya Grocer", items: [])
];

const List<Product> availableProducts = [
  Product(id: '1', name: 'Milk 1L', price: 7.90),
  Product(id: '2', name: 'Eggs 10-pack', price: 6.90),
  Product(id: '3', name: 'Bread', price: 4.50),
];


class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();

}

class _ShopPageState extends State<ShopPage> {
  final List<ShopData> _selectedShops = [];


  void _selectShop(ShopData shop) {
    setState(() {
      if (!_selectedShops.any((s) => s.id == shop.id)) {
        _selectedShops.add(shop);
      }
    });
  }

  void _unselectShop(ShopData shop) {
    setState(() {
      _selectedShops.remove(shop);
    });
  }

  Future<void> _openShopDialog([ShopData? existingShop]) async {
    final result = await showDialog<ShopData>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShopEditDialog(existingShop: existingShop),
    );

    if (result != null) {
      setState(() {
        final index = _selectedShops.indexWhere((s) => s.id == result.id);
        if (index != -1) {
          _selectedShops[index] = result;
        } else {
          _selectedShops.add(result);
        }

        final availableIndex = _availableShops.indexWhere((s) => s.id == result.id);
        if (availableIndex != -1) {
          _availableShops[availableIndex] = result;
        } else {
          _availableShops.add(result);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Shops',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _openShopDialog(),
              icon: const Icon(Icons.add),
              label: const Text('New Shop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),

        Text(
          'Add shops that you would like to purchase from.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),

        const SizedBox(height: 20),

        GenericSearchBox<ShopData>(
          items: _availableShops, 
          hintText: "Search existing shops...",
          onSelectItem: (shop) => _selectShop(shop), 
          labelBuilder: (shop) => shop.name, 
          trailingBuilder: (shop) => '${shop.items.length} items',
        ),

        ShopCard(
          shops: _selectedShops, 
          onEdit: (shop) => _openShopDialog(shop),
          onDelete: (shop) => _unselectShop(shop),
        )
      ],
    );
  }

}

class ShopEditDialog extends StatefulWidget {
  final ShopData? existingShop;

  const ShopEditDialog({super.key, this.existingShop});

  @override
  State<ShopEditDialog> createState() => _ShopEditDialogState();
}

class _ShopEditDialogState extends State<ShopEditDialog> {
  late TextEditingController _nameController;
  late List<Product> _shopItems;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingShop?.name ?? '');
    _shopItems = List.from(widget.existingShop?.items ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addProductToShop(Product product) {
    setState(() {
      if (!_shopItems.any((p) => p.id == product.id)) {
        _shopItems.add(product);
      }
    });
  }

  void _removeProductFromShop(int index) {
    setState(() {
      _shopItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingShop != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Shop' : 'Add New Shop'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Shop Name',
                  hintText: 'e.g., Jaya Grocer, Lotus\'s',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Shop Products',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GenericSearchBox<Product>(
                items: availableProducts,
                onSelectItem: _addProductToShop,
                labelBuilder: (product) => product.name,
                trailingBuilder: (product) =>
                    'RM ${product.price.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              _shopItems.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No items added to this shop yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _shopItems.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _shopItems[index];
                    return ListTile(
                      dense: true,
                      title: Text(item.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('RM ${item.price.toStringAsFixed(2)}'),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _removeProductFromShop(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final nameText = _nameController.text.trim();
            if (nameText.isEmpty) return;

            final savedShop = ShopData(
              id: widget.existingShop?.id ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              name: nameText,
              items: _shopItems,
            );
            Navigator.of(context).pop(savedShop);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Shop'),
        ),
      ],
    );
  }
}

class ShopCard extends StatelessWidget {
  final List<ShopData> shops;
  final ValueChanged<ShopData> onEdit;
  final ValueChanged<ShopData> onDelete;

  const ShopCard({
    super.key,
    required this.shops,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: shops.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    'You have no selected shops',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shops.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final shop = shops[index];
                return ShopListing(
                  shop: shop,
                  onEdit: () => onEdit(shop),
                  onDelete: () => onDelete(shop),
                );
              },
            ),
      ),
    );
  }
}

class ShopListing extends StatelessWidget {
  final ShopData shop;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ShopListing({
    super.key,
    required this.shop,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shop,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              shop.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 15),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
