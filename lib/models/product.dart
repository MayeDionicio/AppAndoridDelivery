class Product {
  final int productoId;
  final String nombre;
  final String descripcion;
  final double precio;
  final String imagenUrl;
  final int stock;
  final double calificacion; // ⭐ Nuevo campo

  int quantity;

  Product({
    required this.productoId,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagenUrl,
    required this.stock,
    this.calificacion = 0.0, // ⭐ Por defecto 0.0
    this.quantity = 1,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productoId: json['productoId'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      precio: (json['precio'] as num).toDouble(),
      imagenUrl: json['imagenUrl'] as String,
      stock: json['stock'] as int,
      calificacion: json['calificacion'] != null
          ? (json['calificacion'] as num).toDouble()
          : 0.0, // ⭐ Manejo si no viene
    );
  }

  Map<String, dynamic> toJson() => {
    'productoId': productoId,
    'nombre': nombre,
    'descripcion': descripcion,
    'precio': precio,
    'imagenUrl': imagenUrl,
    'stock': stock,
    'calificacion': calificacion, // ⭐ Incluir al enviar
  };
}
