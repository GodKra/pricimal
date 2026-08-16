import 'package:flutter/material.dart';
import 'package:pricimal/util.dart';

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

  Product? getProduct(String productId) {
    return _products[productId];
  }

  Shop? getShop(String shopId) {
    return _shops[shopId];
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

  void updateProductName(String id, String newName) {
    if (_products.containsKey(id)) {
      _products[id] = Product(id: id, name: newName);
      notifyListeners();
    }
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

  double getProductAvgPrice(String productId) {
    double sum = 0.0;
    int count = 0;

    _priceIndex.forEach((key, price) {
      if (key.endsWith('_$productId')) {
        sum += price;
        count++;
      }
    });

    return count == 0 ? 0.0 : sum / count;
  }

  List<Product> getProductsForShop(String shopId) {
    return _products.values.where((p) => _priceIndex.containsKey('${shopId}_${p.id}')).toList();
  }

  List<Product> getProductsForShops(List<String> shopIds) {
    if (shopIds.isEmpty) return [];

    return _products.values.where((p) {
      return shopIds.any((shopId) => _priceIndex.containsKey('${shopId}_${p.id}'));
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