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

class ShoppingRepository extends ChangeNotifier {
  final Map<String, Product> _products = {};
  final Map<String, Shop> _shops = {};
  final Map<String, double> _priceIndex = {};
  final Set<String> _selectedShops = {};

  List<Product> get allProducts => _products.values.toList();
  List<Shop> get allShops => _shops.values.toList();
  List<Shop> get selectedShops => _selectedShops
      .map((id) => _shops[id])
      .whereType<Shop>()
      .toList();

  void initializeRepository(List<Product> products, List<Shop> shops, List<ShopProductPrice> prices) {
    for (Product p in products) {
      _products[p.id] = p;
    }
    for (Shop s in shops) {
      _shops[s.id] = s;
    }

    for (ShopProductPrice pp in prices) {
      _priceIndex[pp.lookupKey] = pp.price;
    }
  }

  double? getPrice(String shopId, String productId) {
    return _priceIndex['${shopId}_$productId'];
  }

  void setPrice(String shopId, String productId, double price) {
    _priceIndex['${shopId}_$productId'] = price;
    notifyListeners();
  }

  void selectShop(Shop shop) {
    _selectedShops.add(shop.id);
    notifyListeners();
  }

  void unselectShop(Shop shop) {
    _selectedShops.remove(shop.id);
    notifyListeners();
  }

  void addProduct(Product product) {
    _products[product.id] = product;
    notifyListeners();
  }

  void addShop(Shop shop) {
    _shops[shop.id] = shop;
    notifyListeners();
  }

  void addShopWithPrices(Shop shop, Map<String, double> productPrices) {
    debugPrint("adding new shop");
    _shops[shop.id] = shop;
    _selectedShops.add(shop.id); // should be auto selected

    productPrices.forEach((productId, price) {
      _priceIndex['${shop.id}_$productId'] = price;
    });

    debugPrint("new shop added ${shop.id}: ${_shops[shop.id]}\n${_shops}");


    notifyListeners();
  }

  void removeShop(String shopId) {
    _shops.remove(shopId);
    _priceIndex.removeWhere((key, _) => key.startsWith('${shopId}_'));
    notifyListeners();
  }

  void removeProduct(String productId) {
    _products.remove(productId);
    _priceIndex.removeWhere((key, _) => key.endsWith('_$productId'));
    notifyListeners();
  }

  List<Product> getProductsForShop(String shopId) {
    return _products.values.where((p) => _priceIndex.containsKey('${shopId}_${p.id}')).toList();
  }

  List<Product> getProductsForShops(List<String> shopIds) {
    if (shopIds.isEmpty) return [];

    return _products.values.where((p) {
      return shopIds.every((shopId) => _priceIndex.containsKey('${shopId}_${p.id}'));
    }).toList();
  }

  List<Shop> getShopsForProduct(String productId) {
    return _shops.values.where((s) => _priceIndex.containsKey('${s.id}_$productId')).toList();
  }

  Map<String, double> getPricesForShop(String shopId) {
    final Map<String, double> result = {};

    for (Product product in _products.values) {
      final price = getPrice(shopId, product.id);
      if (price != null) {
        result[product.id] = price;
      }
    }
    return result;
  }
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