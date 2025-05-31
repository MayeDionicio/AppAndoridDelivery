import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/cart.dart';
import '../data/current_user.dart';
import '../services/api_service.dart';
import 'order_tracking_screen.dart';

class ConfirmOrderScreen extends StatefulWidget {
  const ConfirmOrderScreen({super.key});

  @override
  State<ConfirmOrderScreen> createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  final _metodoPagoController = TextEditingController();
  LatLng selectedPosition = LatLng(14.2978, -90.7869);

  double get total => cart.fold(0.0, (sum, p) => sum + p.precio * p.quantity);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirmar Pedido")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Resumen del pedido", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...cart.map((p) => ListTile(
            title: Text(p.nombre),
            subtitle: Text("Cantidad: ${p.quantity}"),
            trailing: Text("Q${(p.precio * p.quantity).toStringAsFixed(2)}"),
          )),
          const Divider(height: 30),
          TextField(
            controller: _metodoPagoController,
            decoration: const InputDecoration(labelText: "Método de pago"),
          ),
          const SizedBox(height: 16),
          const Text("Selecciona tu ubicación de entrega:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: selectedPosition,
                initialZoom: 15,
                onTap: (tapPosition, latlng) {
                  setState(() => selectedPosition = latlng);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedPosition,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                    )
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text("Total: Q${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text("Confirmar Pedido"),
                  onPressed: _confirmarPedido,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text("Cancelar"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _confirmarPedido() async {
    final user = currentUser;
    if (user == null || user.usuarioId == null || user.token == null) {
      _mostrarSnackBar(
        icon: Icons.warning,
        message: "Sesión inválida. Inicia sesión nuevamente.",
        color: Colors.orange,
      );
      return;
    }

    if (_metodoPagoController.text.trim().isEmpty) {
      _mostrarSnackBar(
        icon: Icons.payment,
        message: "Debes ingresar un método de pago.",
        color: Colors.blue,
      );
      return;
    }

    try {
      final metodo = await ApiService.createPaymentMethodAndReturnId(
        usuarioId: user.usuarioId!,
        tipo: _metodoPagoController.text.trim(),
      );

      final pedido = {
        "usuarioId": user.usuarioId,
        "total": total,
        "estado": "Pendiente",
        "fechaPedido": DateTime.now().toIso8601String(),
        "metodoPagoId": metodo["metodoPagoId"],
        "customerLat": selectedPosition.latitude,
        "customerLng": selectedPosition.longitude,
        "detalles": cart.map((p) => {
          "productoId": p.productoId,
          "cantidad": p.quantity,
          "precioUnitario": p.precio,
        }).toList()
      };

      final resp = await ApiService.createOrder(pedido);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        final pedidoId = data["pedidoId"];
        cart.clear();

        _mostrarSnackBar(
          icon: Icons.check_circle,
          message: "Pedido confirmado",
          color: Colors.green,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrderTrackingScreen(pedidoId: pedidoId)),
        );
      } else {
        final error = ApiService.extractErrorMessage(resp.body);
        _mostrarSnackBar(
          icon: Icons.error,
          message: "Error: $error",
          color: Colors.red,
        );
      }
    } catch (e) {
      _mostrarSnackBar(
        icon: Icons.error,
        message: "Error al confirmar: $e",
        color: Colors.red,
      );
    }
  }

  void _mostrarSnackBar({required IconData icon, required String message, required Color color}) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
