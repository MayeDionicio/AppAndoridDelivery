import 'package:flutter/material.dart';
import '../models/product.dart';
import '../data/cart.dart';
import '../services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double get totalPrice {
    return cart.fold<double>(
      0.0,
          (sum, product) => sum + product.precio * product.quantity,
    );
  }

  Future<void> confirmarPedido() async {
    try {
      final productos = cart.map((p) => {
        "productoId": p.productoId,
        "cantidad": p.quantity,
      }).toList();

      final pedido = {
        "productos": productos,
        "fecha": DateTime.now().toIso8601String(),
        "total": totalPrice,
      };

      await ApiService.createOrder(pedido);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Pedido confirmado correctamente")),
      );

      setState(() {
        cart.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al confirmar pedido: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Carrito de Compras")),
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
                  title: Text(product.nombre),
                  subtitle: Text(product.descripcion),
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
              "Total: Q${totalPrice.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: confirmarPedido,
                child: const Text("Confirmar Pedido"),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
