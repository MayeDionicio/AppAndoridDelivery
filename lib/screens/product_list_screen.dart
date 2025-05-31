import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> productos = [];
  List<Product> productosFiltrados = [];
  bool loading = true;
  String filtro = '';

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  Future<void> cargarProductos() async {
    try {
      final lista = await ApiService.fetchProducts();
      setState(() {
        productos = lista;
        productosFiltrados = lista;
        loading = false;
      });
    } catch (e) {
      print('Error al cargar productos: $e');
      setState(() => loading = false);
    }
  }

  void eliminarProducto(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.eliminarProducto(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Producto eliminado')
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      cargarProductos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  void filtrarProductos(String texto) {
    setState(() {
      filtro = texto;
      productosFiltrados = productos
          .where((p) => p.nombre.toLowerCase().contains(texto.toLowerCase()))
          .toList();
    });
  }

  void _abrirEdicion(int productoId) async {
    final result = await Navigator.pushNamed(context, '/editProduct', arguments: productoId);
    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Producto actualizado correctamente')
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
    cargarProductos();
  }

  void _abrirCreacion() async {
    final result = await Navigator.pushNamed(context, '/productCreate');
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Producto creado correctamente')
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      cargarProductos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listado de Productos')),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirCreacion,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: filtrarProductos,
            ),
          ),
          Expanded(
            child: productosFiltrados.isEmpty
                ? const Center(child: Text('No hay productos registrados.'))
                : ListView.builder(
              itemCount: productosFiltrados.length,
              itemBuilder: (context, index) {
                final p = productosFiltrados[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        p.imagenUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                      ),
                    ),
                    title: Text(p.nombre),
                    subtitle: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'Q${p.precio.toStringAsFixed(2)}'),
                          const TextSpan(text: ' - '),
                          TextSpan(
                            text: 'Stock: ${p.stock}',
                            style: TextStyle(
                              color: p.stock < 5 ? Colors.red : Colors.black,
                              fontWeight: p.stock < 5 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _abrirEdicion(p.productoId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => eliminarProducto(p.productoId),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
