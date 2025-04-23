// order_history_screen.dart

import 'package:flutter/material.dart';
import 'models/order.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  // Función para formatear la fecha de manera sencilla
  String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Pedidos"),
      ),
      body: orders.isEmpty
          ? const Center(child: Text("No tienes pedidos aún"))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text("Pedido del ${formatDate(order.date)}"),
              subtitle: Text("Total: \$${order.total.toStringAsFixed(2)}"),
              onTap: () {
                // Aquí podrías mostrar más detalles del pedido
              },
            ),
          );
        },
      ),
    );
  }
}
