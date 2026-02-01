import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction.dart';

class ProductShop {
  final String shopName;
  final String? area;
  final double avgPrice;
  final double lastPrice;
  final DateTime lastPurchased;

  ProductShop({
    required this.shopName,
    this.area,
    required this.avgPrice,
    required this.lastPrice,
    required this.lastPurchased,
  });

  Map<String, dynamic> toJson() => {
        'shopName': shopName,
        'area': area,
        'avgPrice': avgPrice,
        'lastPrice': lastPrice,
        'lastPurchased': Timestamp.fromDate(lastPurchased),
      };

  factory ProductShop.fromJson(Map<String, dynamic> json) => ProductShop(
        shopName: json['shopName'],
        area: json['area'],
        avgPrice: (json['avgPrice'] as num).toDouble(),
        lastPrice: (json['lastPrice'] as num).toDouble(),
        lastPurchased: (json['lastPurchased'] as Timestamp).toDate(),
      );
}

class Product {
  final String id;
  final String name;
  final String? emoji;
  final String? brand;
  final Category category;
  final String? subcategory;
  final double avgPrice;
  final double lowestPrice;
  final double highestPrice;
  final int totalPurchases;
  final DateTime lastPurchased;
  final List<ProductShop> shops;

  Product({
    required this.id,
    required this.name,
    this.emoji,
    this.brand,
    required this.category,
    this.subcategory,
    required this.avgPrice,
    required this.lowestPrice,
    required this.highestPrice,
    required this.totalPurchases,
    required this.lastPurchased,
    this.shops = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'brand': brand,
        'category': category.label,
        'subcategory': subcategory,
        'avgPrice': avgPrice,
        'lowestPrice': lowestPrice,
        'highestPrice': highestPrice,
        'totalPurchases': totalPurchases,
        'lastPurchased': Timestamp.fromDate(lastPurchased),
        'shops': shops.map((e) => e.toJson()).toList(),
      };

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'],
      emoji: data['emoji'],
      brand: data['brand'],
      category: Category.values.firstWhere((e) => e.label == data['category'], orElse: () => Category.other),
      subcategory: data['subcategory'],
      avgPrice: (data['avgPrice'] as num).toDouble(),
      lowestPrice: (data['lowestPrice'] as num).toDouble(),
      highestPrice: (data['highestPrice'] as num).toDouble(),
      totalPurchases: data['totalPurchases'],
      lastPurchased: (data['lastPurchased'] as Timestamp).toDate(),
      shops: (data['shops'] as List?)?.map((e) => ProductShop.fromJson(e)).toList() ?? [],
    );
  }
}
