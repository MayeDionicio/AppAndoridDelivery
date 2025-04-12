import 'package:flutter/material.dart';
import 'models/review.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productName;
  final String productDescription;

  const ProductDetailScreen({
    Key? key,
    required this.productName,
    required this.productDescription,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final List<Review> reviews = []; // Lista local de reseñas
  final TextEditingController _reviewController = TextEditingController();
  double _currentRating = 0.0;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitReview() {
    if (_currentRating > 0 && _reviewController.text.isNotEmpty) {
      setState(() {
        reviews.add(Review(
          reviewer: "Usuario", // Aquí podrías obtener el nombre del usuario logueado
          rating: _currentRating,
          comment: _reviewController.text,
          date: DateTime.now(),
        ));
      });
      _reviewController.clear();
      _currentRating = 0.0;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, ingresa una calificación y un comentario"),
        ),
      );
    }
  }

  // Widget para ingresar la calificación usando estrellas
  Widget _buildStarRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        int starIndex = index + 1;
        return IconButton(
          icon: Icon(
            _currentRating >= starIndex ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () {
            setState(() {
              _currentRating = starIndex.toDouble();
            });
          },
        );
      }),
    );
  }

  // Widget para mostrar la lista de reseñas
  Widget _buildReviewsList() {
    if (reviews.isEmpty) {
      return const Center(child: Text("No hay valoraciones aún."));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(review.reviewer),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    review.rating >= i + 1 ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
              Text(review.comment),
              Text(
                "${review.date.day}/${review.date.month}/${review.date.year}",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.productDescription,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              "Valoraciones y Comentarios",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildReviewsList(),
            const Divider(),
            const Text(
              "Agrega tu valoración",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            _buildStarRating(),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: "Comentario",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitReview,
              child: const Text("Enviar Valoración"),
            ),
          ],
        ),
      ),
    );
  }
}
