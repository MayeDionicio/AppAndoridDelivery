import 'package:flutter/material.dart';
import '../models/product.dart';
import '../data/cart.dart';
import 'catalog_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double get totalPrice {
    return cart.fold(0.0, (sum, p) => sum + p.precio * p.quantity);
  }

  int get cartItemCount => cart.fold(0, (sum, item) => sum + item.quantity);

  void _removeProduct(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  void _confirmarPedido() {
    if (cart.isEmpty) {
      final snackBar = SnackBar(
        content: Row(
          children: const [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Carrito vacío. Agrega productos.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    Navigator.pushNamed(context, '/confirmOrder');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carrito de Compras"),
      ),
      body: cart.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("No hay productos en el carrito", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CatalogScreen()),
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text("Volver al Catálogo"),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final p = cart[index];
                return ListTile(
                  leading: Image.network(p.imagenUrl, width: 60, height: 60, fit: BoxFit.cover),
                  title: Text(p.nombre),
                  subtitle: Text('Q${p.precio} x ${p.quantity}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeProduct(index),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Total: Q${totalPrice.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmarPedido,
                icon: const Icon(Icons.check_circle),
                label: const Text("Confirmar Pedido"),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
