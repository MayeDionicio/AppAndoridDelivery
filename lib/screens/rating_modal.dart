import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../data/current_user.dart';

class RatingModal extends StatefulWidget {
  final Product product;
  const RatingModal({Key? key, required this.product}) : super(key: key);

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
  double _rating = 3;
  final _commentController = TextEditingController();
  bool _loading = false;

  Future<void> _submitRating() async {
    final user = currentUser;

    if (user == null || user.token == null || user.token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe iniciar sesión para valorar.')),
      );
      return;
    }

    if ((user.usuarioId ?? 0) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID de usuario no válido.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await ApiService.crearValoracion(
        productoId: widget.product.productoId,
        usuarioId: user.usuarioId!,
        calificacion: _rating,
        comentario: _commentController.text,
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Valorar ${widget.product.nombre}'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) => setState(() => _rating = rating),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(labelText: 'Comentario (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton.icon(
          onPressed: _loading ? null : _submitRating,
          icon: const Icon(Icons.send),
          label: const Text("Enviar"),
        ),
      ],
    );
  }
}
