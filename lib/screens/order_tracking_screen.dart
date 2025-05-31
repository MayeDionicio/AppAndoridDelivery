import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:delivery_app/data/current_user.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int pedidoId;

  const OrderTrackingScreen({Key? key, required this.pedidoId}) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  LatLng? storeLatLng;
  LatLng? customerLatLng;
  List<LatLng> routeCoords = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadTrackingData();
  }

  Future<void> loadTrackingData() async {
    try {
      final token = currentUser?.token;
      if (token == null) {
        setState(() {
          error = 'Token no disponible';
          isLoading = false;
        });
        return;
      }

      print("🔍 Obteniendo datos del pedido con ID: ${widget.pedidoId}");

      final response = await http.get(
        Uri.parse('https://deliverylp.shop/api/Pedidos/${widget.pedidoId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("📦 Respuesta pedido: ${response.statusCode} - ${response.body}");

      if (response.statusCode != 200) {
        setState(() {
          error = 'Pedido no encontrado';
          isLoading = false;
        });
        return;
      }

      final data = jsonDecode(response.body);
      final store = LatLng(data['storeLat'], data['storeLng']);
      final customer = LatLng(data['customerLat'], data['customerLng']);

      final coords = [
        [store.longitude, store.latitude],
        [customer.longitude, customer.latitude]
      ];

      final routeResp = await http.post(
        Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car/geojson'),
        headers: {
          'Authorization': '5b3ce3597851110001cf6248a305f1584b5642799cf5256fd6a283c1',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'coordinates': coords}),
      );

      final routeData = jsonDecode(routeResp.body);
      final steps = routeData['features'][0]['geometry']['coordinates'] as List;

      setState(() {
        storeLatLng = store;
        customerLatLng = customer;
        routeCoords = steps.map((p) => LatLng(p[1], p[0])).toList();
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error al cargar pedido: $e");
      setState(() {
        error = 'Error cargando el pedido';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rastreo del Pedido")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : FlutterMap(
        options: MapOptions(
          initialCenter: storeLatLng!,
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.delivery_app',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: routeCoords,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 40,
                height: 40,
                point: storeLatLng!,
                child: const Icon(Icons.store, color: Colors.green, size: 40),
              ),
              Marker(
                width: 40,
                height: 40,
                point: customerLatLng!,
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
