import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../data/current_user.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({Key? key}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  Product? producto;
  bool loading = true;

  late int productoId;
  String nombre = '';
  String descripcion = '';
  double precio = 0;
  int stock = 0;
  File? nuevaImagen;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    productoId = ModalRoute.of(context)?.settings.arguments as int;
    _cargarProducto();
  }

  Future<void> _cargarProducto() async {
    try {
      final p = await ApiService.getProductoById(productoId);
      setState(() {
        producto = p;
        nombre = p.nombre;
        descripcion = p.descripcion;
        precio = p.precio;
        stock = p.stock;
        loading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar producto: $e')),
      );
      Navigator.pop(context);
    }
  }

  void _seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        nuevaImagen = File(picked.path);
      });
    }
  }

  void _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    print('🟢 Enviando a la API:');
    print('Nombre: $nombre');
    print('Descripción: $descripcion');
    print('Precio: $precio');
    print('Stock: $stock');

    try {
      await ApiService.actualizarProductoConImagen(
        id: productoId,
        nombre: nombre,
        descripcion: descripcion,
        precio: precio,
        stock: stock,
        imagen: nuevaImagen, // puede ser null
        imagenUrlAnterior: producto!.imagenUrl,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Producto actualizado correctamente'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (nuevaImagen != null)
                Image.file(nuevaImagen!, height: 150)
              else
                Image.network(
                  producto!.imagenUrl,
                  height: 150,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 100),
                ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _seleccionarImagen,
                icon: const Icon(Icons.photo),
                label: const Text('Cambiar Imagen'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: nombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                onSaved: (value) => nombre = value!,
              ),
              TextFormField(
                initialValue: descripcion,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                onSaved: (value) => descripcion = value!,
              ),
              TextFormField(
                initialValue: precio.toString(),
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || double.tryParse(value) == null
                    ? 'Ingresa un número válido'
                    : null,
                onSaved: (value) => precio = double.parse(value!),
              ),
              TextFormField(
                initialValue: stock.toString(),
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || int.tryParse(value) == null
                    ? 'Ingresa un número válido'
                    : null,
                onSaved: (value) => stock = int.parse(value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _guardarCambios,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
