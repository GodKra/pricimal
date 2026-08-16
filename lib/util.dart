import 'package:flutter/material.dart';

List<Product> sampleProducts = [
  Product(id: '1', name: 'Milk 1L'),
  Product(id: '2', name: 'Eggs 10-pack'),
  Product(id: '3', name: 'Bread'),
  Product(id: '4', name: 'Chicken Breast 500g'),
  Product(id: '5', name: 'Apples 1kg'),
  Product(id: '6', name: 'Rice 5kg'),
  Product(id: '7', name: 'Cooking Oil 2L'),
  Product(id: '8', name: 'Cereal 500g'),
  Product(id: '9', name: 'Cereal 0g'),
  Product(id: '10', name: 'Cereal 50g'),
  Product(id: '11', name: 'Cereal 0g'),
  Product(id: '12', name: 'Cerea0g'),
  Product(id: '13', name: 'Cereal g'),
];

List<Shop> sampleShops = [
  Shop(id: '1', name: 'Jaya Grocer'),
  Shop(id: '2', name: 'Watsons'),
  Shop(id: '3', name: 'Lotus')
];

List<ShopProductPrice> samplePrices = [
  ShopProductPrice(shopId: '1', productId: '1', price: 7.99),
  ShopProductPrice(shopId: '1', productId: '2', price: 8.99),
  ShopProductPrice(shopId: '1', productId: '4', price: 9.99),
  ShopProductPrice(shopId: '1', productId: '5', price: 4.99),
  ShopProductPrice(shopId: '2', productId: '1', price: 4.99),
  ShopProductPrice(shopId: '2', productId: '4', price: 4.99),
  ShopProductPrice(shopId: '3', productId: '2', price: 4.99),
  ShopProductPrice(shopId: '3', productId: '5', price: 4.99),
];

class Product {
  final String id;
  final String name;

  const Product({
    required this.id,
    required this.name,
  });
}

class Shop {
  final String id;
  final String name;

  const Shop({
    required this.id, 
    required this.name
  });
}

class ShopProductPrice {
  final String shopId;
  final String productId;
  final double price;

  const ShopProductPrice({
    required this.shopId,
    required this.productId,
    required this.price,
  });

  String get lookupKey => '${shopId}_$productId';
}

class ShopBasketResult {
  final Shop shop;
  final double totalCost;
  final int foundItemsCount;
  final int totalItemsCount;
  final List<Product> missingProducts;

  ShopBasketResult({
    required this.shop,
    required this.totalCost,
    required this.foundItemsCount,
    required this.totalItemsCount,
    required this.missingProducts,
  });

  bool get isComplete => missingProducts.isEmpty;
}

class GenericSearchBox<T extends Object> extends StatelessWidget {
  final List<T> items;
  final ValueChanged<T> onSelectItem;
  final String Function(T item) labelBuilder;
  final String Function(T item) trailingBuilder;
  final String hintText;

  const GenericSearchBox({
    super.key,
    required this.items,
    required this.onSelectItem,
    required this.labelBuilder,
    required this.trailingBuilder,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController? fieldController; // used to clear the text after selection

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Autocomplete<T>(
                key: ValueKey(items.length), // force update the autocomplete
                displayStringForOption: labelBuilder,
                optionsBuilder: (TextEditingValue t) {
                  if (t.text.isEmpty) {
                    return items;
                  }
                  return items.where((T option) {
                    final label = labelBuilder(option).toLowerCase();
                    return label.contains(t.text.toLowerCase());
                  });
                },
                onSelected: (T selection) {
                  onSelectItem(selection);
                  fieldController?.clear();
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onEditingComplete) {
                  fieldController = controller;

                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: InputDecoration(
                      hintText: hintText,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final T option = options.elementAt(index);
                            return ListTile(
                              leading: Icon(Icons.add),
                              title: Text(
                                labelBuilder(option),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              trailing: Text(
                                trailingBuilder(option),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () {
                                onSelected(option);
                              },
                            );
                          },
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
    );
  }
}