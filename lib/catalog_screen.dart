// catalog_screen.dart (fragmento relevante)
import 'package:flutter/material.dart';
import 'models/product.dart'; // Asegúrate de importar el modelo

class CatalogScreen extends StatefulWidget {
  CatalogScreen({Key? key}) : super(key: key);

  @override
  _CatalogScreenState createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  // Lista de productos de ejemplo
  final List<Product> products = [
    Product(
      name: 'Producto 1',
      description: 'Descripción detallada del producto 1.',
      rating: 4.0,
    ),
    Product(
      name: 'Producto 2',
      description: 'Descripción detallada del producto 2.',
      rating: 3.5,
    ),
    // Agrega más productos según necesites
  ];

  // Función para agregar producto al carrito
  void _addToCart(Product product) {
    setState(() {
      cart.add(product);
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} agregado al carrito'))
    );
  }

  // Función para construir las estrellas de calificación (igual que antes)
  Widget _buildRatingStars(double rating) {
    int fullStars = rating.floor();
    bool halfStar = (rating - fullStars) >= 0.5;
    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index == fullStars && halfStar) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          // Icono de carrito con burbuja
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart').then((_) {
                    setState(() {}); // Se refresca la pantalla al volver del carrito
                  });
                },
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
      drawer: Drawer(
        // Mismo código para el Drawer (menú hamburguesa)
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Mi App Delivery',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '¡Bienvenido!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            // Opciones del menú...
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mi Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial de Pedidos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/orderHistory');
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Seguimiento de Pedido'),
              onTap: () {
                Navigator.pop(context); // Cierra el Drawer
                Navigator.pushNamed(context, '/tracking');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("Ver detalles del producto"),
              onTap: () {
                Navigator.pushNamed(context, '/productDetail');
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            margin: const EdgeInsets.all(8),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(product.description),
                  const SizedBox(height: 8),
                  _buildRatingStars(product.rating),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _addToCart(product),
                      child: const Text('Agregar al carrito'),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
