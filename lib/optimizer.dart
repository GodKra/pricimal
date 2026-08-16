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

  final Map<String, String> purchases;

  const OptimizationResult({
    required this.productCost,
    required this.travelCost,
    required this.totalCost,
    required this.shops,
    required this.route,
    required this.purchases,
  });
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
    final usedShops = <Shop>[];
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

    final travelDistance = calculateRouteDistance(
      home: home,
      route: route,
    );

    final travelCost = travelDistance * costPerMeter;


    final totalCost = productCost + travelCost;


    return OptimizationResult(
      productCost: productCost,
      travelCost: travelCost,
      totalCost: totalCost,
      shops: usedShops,
      route: route,
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
        final distance = distanceBetweenLocations(
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
  double calculateRouteDistance({
    required LatLng home,
    required List<Shop> route,
  }) {

    if (route.isEmpty) {
      return 0;
    }

    double totalDistance = 0;

    LatLng currentLocation = home;

    for (final shop in route) {
      totalDistance += distanceBetweenLocations(
        currentLocation,
        shop.location,
      );

      currentLocation = shop.location;
    }


    // return back home
    totalDistance += distanceBetweenLocations(
      currentLocation,
      home,
    );

    return totalDistance;
  }


  /// HAVERSINE DISTANCE
  double distanceBetweenLocations(
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