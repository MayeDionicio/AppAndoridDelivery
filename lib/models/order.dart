class Order {
  final int id;
  final double total;
  final String estado;
  final DateTime date;
  final List<OrderDetail> detalles;
  final int usuarioId;

  Order({
    required this.id,
    required this.total,
    required this.estado,
    required this.date,
    required this.detalles,
    required this.usuarioId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['pedidoId'],
      total: (json['total'] as num).toDouble(),
      estado: json['estado'],
      date: DateTime.parse(json['fechaPedido']),
      detalles: (json['detalles'] as List)
          .map((d) => OrderDetail.fromJson(d))
          .toList(),
      usuarioId: json['usuario']?['usuarioId'] ?? 0,
    );
  }
}

class OrderDetail {
  final int productoId;
  final int cantidad;
  final double precioUnitario;
  final String nombreProducto;

  OrderDetail({
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.nombreProducto,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      productoId: json['productoId'],
      cantidad: json['cantidad'],
      precioUnitario: (json['precioUnitario'] as num).toDouble(),
      nombreProducto: json['nombreProducto'],
    );
  }
}
