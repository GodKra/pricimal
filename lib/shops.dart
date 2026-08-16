import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pricimal/util.dart';


class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();

}

class _ShopPageState extends State<ShopPage> {
  Future<void> _openShopDialog([Shop? existingShop]) async {
    final repository = context.read<ShoppingRepository>();

    final result = await showDialog<List>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ShopEditDialog(
        existingShop: existingShop,
      ),
    );

    debugPrint("shop finished");

    if (result != null) {
      final Shop shop = result[0];
      final Map<String, double> prices = result[1];
      repository.addShopWithPrices(shop, prices);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<ShoppingRepository>();

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

        GenericSearchBox<Shop>(
          items: repository.allShops, 
          hintText: "Search existing shops...",
          onSelectItem: (shop) => repository.selectShop(shop), 
          labelBuilder: (shop) => shop.name, 
          trailingBuilder: (shop) => '',
        ),

        ShopCard(
          shops: repository.selectedShops, 
          onEdit: (shop) => _openShopDialog(shop),
          onDelete: (shop) => repository.unselectShop(shop),
        )
      ],
    );
  }

}

class ShopEditDialog extends StatefulWidget {
  final Shop? existingShop;

  const ShopEditDialog({
    super.key, 
    this.existingShop,
  });

  @override
  State<ShopEditDialog> createState() => _ShopEditDialogState();
}

class _ShopEditDialogState extends State<ShopEditDialog> {
  late TextEditingController _nameController;
  final Map<String, double> _localProductPrices = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingShop?.name ?? '');

    // populate an existing shop's products
    if (widget.existingShop != null) {
      final repository = context.read<ShoppingRepository>();
      _localProductPrices.addAll(repository.getPricesForShop(widget.existingShop!.id));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _promptPriceAndAdd(Product product) {
    final priceController = TextEditingController(
      text: _localProductPrices[product.id]?.toStringAsFixed(2) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Price for ${product.name}'),
        content: TextField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Price (RM)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(priceController.text);
              if (val != null && val >= 0) {
                setState(() => _localProductPrices[product.id] = val);
              }
              Navigator.pop(context);
            },
            child: const Text('Save Price'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ShoppingRepository>();
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
              GenericSearchBox<Product>(
                items: repository.allProducts,
                onSelectItem: _promptPriceAndAdd,
                labelBuilder: (p) => p.name,
                trailingBuilder: (_) => '',
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _localProductPrices.length,
                itemBuilder: (context, index) {
                  final productId = _localProductPrices.keys.elementAt(index);
                  final price = _localProductPrices[productId]!;
                  final prod = repository.allProducts.firstWhere((p) => p.id == productId);

                  return ListTile(
                    title: Text(prod.name),
                    trailing: Text('RM ${price.toStringAsFixed(2)}'),
                    onTap: () => _promptPriceAndAdd(prod),
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
            if (_nameController.text.isEmpty) return;
            final shopId = widget.existingShop?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
            final shop = Shop(id: shopId, name: _nameController.text);

            Navigator.pop(context, [shop, _localProductPrices]);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class ShopCard extends StatelessWidget {
  final List<Shop> shops;
  final ValueChanged<Shop> onEdit;
  final ValueChanged<Shop> onDelete;

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
  final Shop shop;
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
