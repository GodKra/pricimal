import 'package:flutter/material.dart';
import 'package:pricimal/util.dart';
import 'package:provider/provider.dart';


class BasketItemData {
  final Product product;
  int quantity;

  BasketItemData({
    required this.product,
    this.quantity = 1,
  });
}

class BasketPage extends StatefulWidget {
  const BasketPage({super.key});

  @override
  State<BasketPage> createState() => _BasketPageState();
}

class _BasketPageState extends State<BasketPage> {
  final List<BasketItemData> _basketItems = [];

  void _addProductToBasket(Product product) {
    setState(() {
      final existingIndex =
          _basketItems.indexWhere((item) => item.product.id == product.id);

      if (existingIndex != -1) {
        _basketItems[existingIndex].quantity++;
      } else {
        _basketItems.add(BasketItemData(product: product));
      }
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _basketItems.removeAt(index);
    });
  }

  void _updateQuantity(int index, int amount) {
    setState(() {
      final updatedQty = _basketItems[index].quantity + amount;
      if (updatedQty > 0) {
        _basketItems[index].quantity = updatedQty;
      } else {
        _basketItems.removeAt(index);
      }
    });
  }

  // double get _totalPrice => _basketItems.fold(
  //       0.0,
  //       (sum, item) => sum + (item.product.price * item.quantity),
  //     );

  int get _totalItems => _basketItems.fold(
        0,
        (sum, item) => sum + item.quantity,
      );

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<ShoppingRepository>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Basket',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          'Add the items you need and we will find the cheapest way to buy them.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),

        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  GenericSearchBox<Product>(
                    onSelectItem: _addProductToBasket,
                    items: repository.getProductsForShops(repository.selectedShops.map((s) => s.id).toList()),
                    hintText: 'Search product (e.g., Milk, Eggs, Rice)...',
                    labelBuilder: (product) => product.name,
                    trailingBuilder: (product) => '',
                  ),

                  const SizedBox(height: 20),

                  BasketCard(
                    items: _basketItems,
                    totalPrice: 0.0,
                    onDelete: _removeProduct,
                    onQuantityChanged: _updateQuantity,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 30),

            Expanded(
              child: SummaryCard(
                totalItems: _totalItems,
                totalPrice: 0.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class BasketCard extends StatelessWidget {
  final List<BasketItemData> items;
  final double totalPrice;
  final ValueChanged<int> onDelete;
  final void Function(int index, int amount) onQuantityChanged;

  const BasketCard({
    super.key,
    required this.items,
    required this.totalPrice,
    required this.onDelete,
    required this.onQuantityChanged,
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
        child: items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    'Your basket is empty',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            : Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return BasketItem(
                        item: item,
                        onDelete: () => onDelete(index),
                        onIncrease: () => onQuantityChanged(index, 1),
                        onDecrease: () => onQuantityChanged(index, -1),
                      );
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated basket total',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'RM ${totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class BasketItem extends StatelessWidget {
  final BasketItemData item;
  final VoidCallback onDelete;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const BasketItem({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onIncrease,
    required this.onDecrease,
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
              Icons.shopping_basket_outlined,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              item.product.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: onDecrease,
                color: Colors.grey.shade700,
              ),
              Text(
                '${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: onIncrease,
                color: Colors.grey.shade700,
              ),
            ],
          ),
          const SizedBox(width: 20),
          Text(
            '0.0',
            // 'RM ${(item.product.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
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

class SummaryCard extends StatelessWidget {
  final int totalItems;
  final double totalPrice;

  const SummaryCard({
    super.key,
    required this.totalItems,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFF202223),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ready to save?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We\'ll compare your basket across your selected shops and calculate travel costs.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            SummaryRow(
              label: 'Items',
              value: '$totalItems',
            ),
            SummaryRow(
              label: 'Current estimate',
              value: 'RM ${totalPrice.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: totalItems > 0 ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Find Cheapest Basket',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}