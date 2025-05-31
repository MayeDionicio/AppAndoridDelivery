import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class ViewOrdersScreen extends StatefulWidget {
  const ViewOrdersScreen({super.key});

  @override
  State<ViewOrdersScreen> createState() => _ViewOrdersScreenState();
}

class _ViewOrdersScreenState extends State<ViewOrdersScreen> {
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
      final data = await ApiService.fetchOrders();
      setState(() => orders = data);
    } catch (e) {
      mostrarSnack("Error al cargar pedidos: $e", color: Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> entregarPedido(int id) async {
    final confirmado = await mostrarDialogo(
      "¿Entregar pedido?",
      "¿Confirmas que el pedido #$id fue entregado?",
    );
    if (confirmado) {
      try {
        await ApiService.entregarPedido(id);
        setState(() {
          final index = orders.indexWhere((o) => o.id == id);
          if (index != -1) {
            final pedido = orders[index];
            orders[index] = Order(
              id: pedido.id,
              total: pedido.total,
              estado: "Entregado",
              date: pedido.date,
              detalles: pedido.detalles,
              usuarioId: pedido.usuarioId,
            );
          }
        });
        mostrarSnack("Pedido #$id entregado", color: Colors.green);
      } catch (e) {
        mostrarSnack("Error al entregar pedido", color: Colors.red);
      }
    }
  }

  Future<void> eliminarPedido(int id) async {
    final confirmado = await mostrarDialogo(
      "¿Eliminar pedido?",
      "Esta acción no se puede deshacer.",
    );
    if (confirmado) {
      try {
        await ApiService.eliminarPedido(id);
        setState(() {
          orders.removeWhere((o) => o.id == id);
        });
        mostrarSnack("Pedido #$id eliminado", color: Colors.orange);
      } catch (e) {
        mostrarSnack("Error al eliminar pedido", color: Colors.red);
      }
    }
  }

  void mostrarSnack(String mensaje, {Color color = Colors.blue}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> mostrarDialogo(String titulo, String contenido) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Text(contenido),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirmar"),
          ),
        ],
      ),
    ) ??
        false;
  }

  Widget buildDetalles(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: order.detalles.map((d) {
        return Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: Text("• ${d.nombreProducto} x${d.cantidad} (Q${d.precioUnitario})"),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(child: Text("No hay pedidos aún"))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final isEntregado = order.estado.toLowerCase() == 'entregado';

          return Card(
            margin: const EdgeInsets.all(10),
            color: isEntregado ? Colors.green[50] : Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Row(
                      children: [
                        Icon(
                          isEntregado ? Icons.check_circle : Icons.pending_actions,
                          color: isEntregado ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Pedido #${order.id}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isEntregado ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Estado: ${order.estado}"),
                        Text("Total: Q${order.total}"),
                        Text("Fecha: ${order.date.toLocal()}"),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'entregar') {
                          entregarPedido(order.id);
                        } else if (value == 'eliminar') {
                          eliminarPedido(order.id);
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isEntregado)
                          const PopupMenuItem(
                            value: 'entregar',
                            child: Text('Entregar'),
                          ),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Text('Eliminar'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Productos:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  buildDetalles(order),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
