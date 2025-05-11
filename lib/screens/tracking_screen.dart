import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Coordenadas simuladas para el comercio y para el usuario
    final LatLng storeLocation = LatLng(37.42796133580664, -122.085749655962);
    final LatLng userLocation = LatLng(37.42496133180663, -122.081743655960);

    // Definición de los marcadores usando el parámetro "child"
    final markers = <Marker>[
      Marker(
        width: 80,
        height: 80,
        point: storeLocation,
        child: const Icon(
          Icons.store,
          color: Colors.blue,
          size: 40,
        ),
      ),
      Marker(
        width: 80,
        height: 80,
        point: userLocation,
        child: const Icon(
          Icons.person_pin_circle,
          color: Colors.red,
          size: 40,
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Pedido'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: storeLocation, // Posición central inicial
          initialZoom: 15.0,            // Nivel de zoom inicial
        ),
        children: [
          TileLayer(
            urlTemplate:
            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: markers,
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: [storeLocation, userLocation],
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
