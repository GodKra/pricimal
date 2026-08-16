import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:pricimal/optimizer.dart';
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

  void _showCheapestBasketResults(BuildContext context, OptimizationResult? result, ShoppingRepository repository) {
    if (result == null) return;

    // Group purchases by shop
    final Map<String, List<String>> shopPurchases = {};
    result.purchases.forEach((productId, shopId) {
      shopPurchases.putIfAbsent(shopId, () => []).add(productId);
    });

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
              maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                        'Optimal Basket Result',
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
                  const SizedBox(height: 4),
                  Text(
                    'Best route and product breakdown to minimize overall cost.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Estimated Cost',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'RM ${result.totalCost.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Products: RM ${result.productCost.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Travel: RM ${result.travelCost.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  const Text(
                    'Store Route & Items to Buy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Sequential Route & Items List
                  Expanded(
                    child: result.route.isEmpty
                        ? const Center(
                            child: Text(
                              'No shops or items found for this optimization.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: result.route.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final shop = result.route[index];
                              final distance = result.routeDistance[index];

                              // Match purchases by shop
                              final itemsToBuy = shopPurchases[shop.name] ??
                                  shopPurchases[shop.id] ??
                                  [];

                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded: true,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        shop.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 8.0),
                                      Text(
                                        '${(distance/1000).toStringAsFixed(2)} km',
                                        style: const TextStyle(fontSize: 12.0)
                                      )
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${itemsToBuy.length} item(s) assigned',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                  children: [
                                    const Divider(height: 1),
                                    if (itemsToBuy.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Text(
                                          'No items to purchase at this stop.',
                                          style: TextStyle(color: Colors.grey, fontSize: 13),
                                        ),
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: itemsToBuy.length,
                                        itemBuilder: (context, itemIdx) {
                                          return ListTile(
                                            dense: true,
                                            leading: const Icon(
                                              Icons.check_circle_outline,
                                              size: 18,
                                              color: Colors.green,
                                            ),
                                            title: Text(
                                              repository.getProduct(itemsToBuy[itemIdx])!.name,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
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
    final optimizer = BruteForceOptimizer();
    final results = optimizer.optimize(
      basket: _productQuantities, 
      repository: repository, 
      home: LatLng(3.0647, 101.6091), 
      costPerMeter: 0.01
    );
    final cheapestCost = results != null ? results.totalCost : 0.0;

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
                onFindCheapest: () => _showCheapestBasketResults(context, results, repository),
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
                        'Estimated basket total (excl. travel)',
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
            SummaryRow(
              label: 'Estimated cost (incl. travel)',
              value: 'RM ${totalPrice.toStringAsFixed(2)}',
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