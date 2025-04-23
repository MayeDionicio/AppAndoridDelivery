// cart_screen.dart (fragmento relevante)
import 'package:flutter/material.dart';
import 'models/product.dart';
import 'models/order.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final double productPrice = 10.0;

  double get totalPrice {
    return cart.length * productPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carrito de Compras"),
      ),
      body: cart.isEmpty
          ? const Center(child: Text("No hay productos en el carrito"))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final product = cart[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text(product.description),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        cart.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Total: \$${totalPrice.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () {
                // Crear el pedido y agregarlo a la lista global de pedidos
                final newOrder = Order(
                  products: List.from(cart),
                  date: DateTime.now(),
                  total: totalPrice,
                );
                orders.add(newOrder);
                // Mostrar mensaje de confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pedido confirmado")),
                );
                // Limpiar el carrito
                setState(() {
                  cart.clear();
                });
              },
              child: const Text("Confirmar Pedido"),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
