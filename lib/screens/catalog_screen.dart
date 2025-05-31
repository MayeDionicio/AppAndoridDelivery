import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../data/cart.dart';
import '../screens/cart_screen.dart';
import 'rating_modal.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = ApiService.fetchProducts();
  }

  void _refreshCatalog() {
    setState(() {
      _futureProducts = ApiService.fetchProducts();
    });
  }

  int get cartItemCount => cart.fold(0, (sum, item) => sum + item.quantity);

  void _addToCart(Product product) {
    final existing = cart.firstWhere(
          (item) => item.productoId == product.productoId,
      orElse: () => Product(
        productoId: -1,
        nombre: '',
        descripcion: '',
        precio: 0,
        imagenUrl: '',
        stock: 0,
      ),
    );

    if (existing.productoId == -1) {
      cart.add(Product(
        productoId: product.productoId,
        nombre: product.nombre,
        descripcion: product.descripcion,
        precio: product.precio,
        imagenUrl: product.imagenUrl,
        stock: product.stock,
      ));
    } else {
      existing.quantity += 1;
    }

    setState(() {});

    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.add_shopping_cart, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${product.nombre} agregado al carrito',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.orange,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          if (ModalRoute.of(context)?.settings.name != '/cart')
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                    setState(() {});
                  },
                ),
                if (cartItemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child: Text(
                        cartItemCount.toString(),
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return FutureBuilder<double>(
                future: ApiService.fetchCalificacionPromedio(product.productoId),
                builder: (context, calificacionSnapshot) {
                  final promedio = calificacionSnapshot.data ?? 0.0;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              product.imagenUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.nombre,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(product.descripcion),
                                Text('Q${product.precio.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                RatingBarIndicator(
                                  rating: promedio,
                                  itemBuilder: (context, _) =>
                                  const Icon(Icons.star, color: Colors.amber),
                                  itemCount: 5,
                                  itemSize: 20.0,
                                  direction: Axis.horizontal,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    child: const Text('Valorar'),
                                    onPressed: () async {
                                      final result = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => RatingModal(product: product),
                                      );
                                      if (result == true) _refreshCatalog();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _addToCart(product),
                            child: const Text('Agregar'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
