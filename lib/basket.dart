import 'package:flutter/material.dart';
import 'package:pricimal/util.dart';
import 'package:provider/provider.dart';
import 'package:pricimal/repository.dart';



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

  double _basketTotal(ShoppingRepository repository) {
    return _basketItems.fold(
      0.0,
      (sum, item) => sum + (repository.getProductAvgPrice(item.product.id) * item.quantity),
    );
  }
  int get _totalItems => _basketItems.fold(
    0,
    (sum, item) => sum + item.quantity,
  );

  Map<String, int> get _productQuantities => {
    for (var item in _basketItems) item.product.id: item.quantity,
  };

void _showCheapestBasketResults(BuildContext context, List<ShopBasketResult> results) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cheapest Shops Comparison',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prices compared across selected stores for your current basket.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Results List
                  Expanded(
                    child: results.isEmpty
                        ? const Center(
                            child: Text(
                              'No selected shops found. Select shops to compare prices.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: results.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final result = results[index];
                              final isCheapest =
                                  index == 0 && result.isComplete;

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: isCheapest
                                      ? Border.all(
                                          color: Colors.green.shade200)
                                      : null,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: isCheapest
                                        ? Colors.green.shade100
                                        : Colors.grey.shade200,
                                    child: Icon(
                                      isCheapest
                                          ? Icons.emoji_events
                                          : Icons.store,
                                      color: isCheapest
                                          ? Colors.green.shade800
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        result.shop.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      if (isCheapest) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Best Deal',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      result.isComplete
                                          ? 'All ${result.totalItemsCount} items available'
                                          : '${result.foundItemsCount}/${result.totalItemsCount} items available (Missing: ${result.missingProducts.map((p) => p.name).join(", ")})',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: result.isComplete
                                            ? Colors.grey.shade600
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                  trailing: Text(
                                    'RM ${result.totalCost.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isCheapest
                                          ? Colors.green.shade700
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<ShoppingRepository>();
    final results = _basketItems.isNotEmpty
        ? repository.getCheapestShops(_productQuantities)
        : <ShopBasketResult>[];
    final cheapestCost = results.isNotEmpty ? results.first.totalCost : 0.0;

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
                    totalPrice: _basketTotal(repository),
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
                totalPrice: cheapestCost,
                onFindCheapest: () => _showCheapestBasketResults(context, results),
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
    final repository = context.read<ShoppingRepository>();

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
            'RM ${(repository.getProductAvgPrice(item.product.id) * item.quantity).toStringAsFixed(2)}',
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
  final VoidCallback onFindCheapest;

  const SummaryCard({
    super.key,
    required this.totalItems,
    required this.totalPrice,
    required this.onFindCheapest,
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
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: totalItems > 0 ? onFindCheapest : null,
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