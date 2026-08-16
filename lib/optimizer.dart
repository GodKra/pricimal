import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:pricimal/repository.dart';
import 'package:pricimal/util.dart';

class OptimizationResult {
  final double productCost;
  final double travelCost;
  final double totalCost;

  final List<Shop> shops;
  final List<Shop> route;
  final List<double> routeDistance;

  final Map<String, String> purchases;

  const OptimizationResult({
    required this.productCost,
    required this.travelCost,
    required this.totalCost,
    required this.shops,
    required this.route,
    required this.routeDistance,
    required this.purchases,
  });
}

class BruteForceOptimizer {
  OptimizationResult? optimize({
    required Map<String, int> basket,
    required ShoppingRepository repository,
    required LatLng home,
    required double costPerMeter,
  }) {
    if (basket.isEmpty) return null;

    double optimalCost = double.infinity;
    OptimizationResult? optimalResult;

    final subsets = _generateSubsets(repository.allShops);

    for (final shopSubset in subsets) {
      double productCost = 0.0;
      final Map<String, String> purchases = {};
      final Set<Shop> usedShops = {};
      bool hasAllProducts = true;

      for (final productId in basket.keys) {
        double cheapestPrice = double.infinity;
        Shop? cheapestShop;

        for (final shop in shopSubset) {
          final price = repository.getPrice(shop.id, productId);
          if (price != null && price < cheapestPrice) {
            cheapestPrice = price;
            cheapestShop = shop;
          }
        }

        if (cheapestShop == null) {
          hasAllProducts = false;
          break; // subset cannot fulfill the basket
        }

        productCost += cheapestPrice;
        purchases[productId] = cheapestShop.name;
        usedShops.add(cheapestShop);
      }

      if (!hasAllProducts) continue;

      if (productCost >= optimalCost) continue; // no point in checking the travel cost

      final usedShopList = usedShops.toList();
      double minDist = double.infinity;
      List<Shop> bestRoute = [];
      List<double> bestRouteDistances = [];

      if (usedShopList.length <= 1) {
        minDist = Helper.distanceBetweenLocations(home, usedShopList.first.location);
        bestRoute = usedShopList;
        bestRouteDistances.add(minDist);
      } else {
        final permutations = _generatePermutations(usedShopList);
        for (final routeCandidate in permutations) {
          // starting at home
          double totalDistance =  Helper.distanceBetweenLocations(home, routeCandidate.first.location);
          List<double> routeDistances = [totalDistance];

          for (int i = 0; i < routeCandidate.length - 1; i++) {
            final from = routeCandidate[i];
            final to = routeCandidate[i + 1];
            final distance = Helper.distanceBetweenLocations(from.location, to.location);
            routeDistances.add(distance);
            totalDistance += distance;
          }

          if (totalDistance < minDist) {
            minDist = totalDistance;
            bestRoute = routeCandidate;
            bestRouteDistances = routeDistances;
          }
        }
      }

      final travelCost = minDist * costPerMeter;
      final totalCost = productCost + travelCost;

      if (totalCost < optimalCost) {
        optimalCost = totalCost;
        optimalResult = OptimizationResult(
          productCost: productCost,
          travelCost: travelCost,
          totalCost: totalCost,
          shops: usedShopList,
          route: bestRoute,
          routeDistance: bestRouteDistances,
          purchases: purchases,
        );
      }
    }
    return optimalResult;
  }

  /// Generates all subsets of a list
  List<List<T>> _generateSubsets<T>(List<T> list) {
    List<List<T>> subsets = [[]];
    for (var element in list) {
      int len = subsets.length;
      for (int i = 0; i < len; i++) {
        subsets.add([...subsets[i], element]);
      }
    }
    subsets.removeWhere((sub) => sub.isEmpty);
    return subsets;
  }

  /// Generates all permutations of a list
  List<List<T>> _generatePermutations<T>(List<T> list) {
    if (list.length <= 1) return [list];
    List<List<T>> result = [];
    for (int i = 0; i < list.length; i++) {
      var item = list[i];
      var remaining = List<T>.from(list)..removeAt(i);
      for (var perm in _generatePermutations(remaining)) {
        result.add([item, ...perm]);
      }
    }
    return result;
  }
}

class GreedyOptimizer {
  OptimizationResult? optimize({
    required Map<String, int> basket,
    required ShoppingRepository repository,
    required LatLng home,
    required double costPerMeter,
  }) {
    final purchases = <String, String>{};
    final productPrices = <String, double>{};

    // Get the cheapest shop for every product
    for (var MapEntry(key: productId, value: quantity) in basket.entries) {

      // Make sure the product actually exists.
      if (repository.getProduct(productId) == null) {
        continue;
      }

      double? cheapestPrice;
      String? cheapestShopId;

      // Look through all shops the user selected.
      for (final shop in repository.selectedShops) {
        final price = repository.getPrice(shop.id, productId);

        // shop does not sell product
        if (price == null) {
          continue;
        }

        // found cheaper price
        if (cheapestPrice == null || price < cheapestPrice) {
          cheapestPrice = price;
          cheapestShopId = shop.id;
        }
      }

      // no shop sells the product so basket is impossible to fulfill
      if (cheapestShopId == null || cheapestPrice == null) {
        return null;
      }

      purchases[productId] = cheapestShopId;
      productPrices[productId] = cheapestPrice * quantity;
    }


    double productCost = 0;
    for (final price in productPrices.values) {
      productCost += price;
    }

    // identify shops that needs to be travelled through
    final usedShopIds = purchases.values.toSet();
    final List<Shop> usedShops = [];
    for (final shopId in usedShopIds) {
      final shop = repository.getShop(shopId);

      if (shop != null) {
        usedShops.add(shop);
      }
    }

    final route = findGreedyRoute(
      home: home,
      shops: usedShops,
    );

    final routeDist = calculateRouteDistance(
      home: home,
      route: route,
    );

    final travelCost = routeDist.fold(0.0, (a, b) => a + b) * costPerMeter;


    final totalCost = productCost + travelCost;


    return OptimizationResult(
      productCost: productCost,
      travelCost: travelCost,
      totalCost: totalCost,
      shops: usedShops,
      route: route,
      routeDistance: routeDist,
      purchases: purchases,
    );
  }

  /// Greedy algorithm to find the travel route. Always choses the nearest neighbour.
  List<Shop> findGreedyRoute({
    required LatLng home,
    required List<Shop> shops,
  }) {
    if (shops.isEmpty) {
      return [];
    }

    final remaining = List<Shop>.from(shops);
    final route = <Shop>[];

    LatLng currentLocation = home;

    while (remaining.isNotEmpty) {
      Shop? closestShop;
      double? closestDistance;

      for (final shop in remaining) {
        final distance = Helper.distanceBetweenLocations(
          currentLocation,
          shop.location,
        );

        if (closestDistance == null || distance < closestDistance) {
          closestDistance = distance;
          closestShop = shop;
        }
      }

      if (closestShop == null) {
        break;
      }

      route.add(closestShop);
      remaining.remove(closestShop);

      currentLocation = closestShop.location;
    }

    return route;
  }



  /// Calculate the total distance for the route
  List<double> calculateRouteDistance({
    required LatLng home,
    required List<Shop> route,
  }) {

    if (route.isEmpty) {
      return [];
    }

    // double totalDistance = 0;
    List<double> routeDist = [];

    LatLng currentLocation = home;

    for (final shop in route) {
      routeDist.add(Helper.distanceBetweenLocations(
        currentLocation,
        shop.location,
      ));

      currentLocation = shop.location;
    }

    return routeDist;
  }
}

class Helper {
    /// HAVERSINE DISTANCE
  static double distanceBetweenLocations(
    LatLng a,
    LatLng b,
  ) {

    const earthRadius = 6371000.0;

    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;

    final deltaLat =
        (b.latitude - a.latitude) * pi / 180;

    final deltaLon =
        (b.longitude - a.longitude) * pi / 180;


    final h =
        sin(deltaLat / 2) *
            sin(deltaLat / 2) +
        cos(lat1) *
            cos(lat2) *
            sin(deltaLon / 2) *
            sin(deltaLon / 2);
    final c =
        2 * atan2(
          sqrt(h),
          sqrt(1 - h),
        );
    return earthRadius * c;
  }
}