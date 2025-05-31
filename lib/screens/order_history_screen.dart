import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../data/current_user.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> orders = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    cargarPedidos();
  }

  Future<void> cargarPedidos() async {
    setState(() => isLoading = true);
    try {
      final todos = await ApiService.fetchOrders();
      final userId = currentUser?.usuarioId;
      final propios = todos.where((o) => o.usuarioId == userId).toList();

      setState(() => orders = propios);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar pedidos: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial de Pedidos")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(child: Text("No hay pedidos registrados."))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final isEntregado = order.estado.toLowerCase() == "entregado";

          return Card(
            margin: const EdgeInsets.all(10),
            color: isEntregado ? Colors.green[50] : Colors.red[50],
            child: ListTile(
              title: Text(
                "Pedido #${order.id}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isEntregado ? Colors.green[800] : Colors.red[800],
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    "Estado: ${order.estado}",
                    style: TextStyle(
                      color: isEntregado ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text("Total: Q${order.total.toStringAsFixed(2)}"),
                  Text("Fecha: ${order.date.toLocal()}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
