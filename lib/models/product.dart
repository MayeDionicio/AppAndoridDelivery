// models/product.dart
class Product {
  final String name;
  final String description;
  final double rating;

  Product({
    required this.name,
    required this.description,
    required this.rating,
  });
}

// Variable global para el carrito
List<Product> cart = [];
