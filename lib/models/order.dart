// lib/models/order.dart

import 'product.dart';

class Order {
  final List<Product> products;
  final DateTime date;
  final double total;

  Order({
    required this.products,
    required this.date,
    required this.total,
  });
}

// Variable global para almacenar los pedidos confirmados
List<Order> orders = [];
