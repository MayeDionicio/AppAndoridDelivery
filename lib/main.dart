import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'login_screen.dart';
import 'catalog_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'tracking_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // No es necesario const si no se usa internamente
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Delivery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/catalog': (context) => CatalogScreen(),
        '/cart': (context) => CartScreen(),
        '/orderHistory': (context) => OrderHistoryScreen(),
        '/tracking': (context) => TrackingScreen(),
        '/profile': (context) => ProfileScreen(),
        '/productDetail': (context) => ProductDetailScreen(
          productName: "Producto de Ejemplo",
          productDescription:
          "Esta es la descripción del producto. Aquí puedes incluir detalles y características.",
        ),
      },
    );
  }
}

