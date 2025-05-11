import 'package:flutter/material.dart';
import 'models/user.dart';
import 'data/current_user.dart';
import 'services/api_service.dart'; // Usamos ApiService para cargar token
import 'screens/biometric_login_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/product_create_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/edit_product_screen.dart';
import 'screens/user_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar token guardado y usuario desde storage
  await ApiService.loadUserFromStorage();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delivery App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/biometric', // 👈 Aquí redirige primero a biometría
      routes: {
        '/biometric':     (_) => const BiometricLoginScreen(),
        '/login':         (_) => const LoginScreen(),
        '/register':      (_) => const RegisterScreen(),
        '/catalog':       (_) => const CatalogScreen(),
        '/admin':         (_) => const AdminScreen(),
        '/cart':          (_) => const CartScreen(),
        '/orderHistory':  (_) => const OrderHistoryScreen(),
        '/tracking':      (_) => const TrackingScreen(),
        '/profile':       (_) => const ProfileScreen(),
        '/productCreate': (_) => const ProductCreateScreen(),
        '/editProduct': (context) => const EditProductScreen(),
        '/userList': (context) => const UserListScreen(),
        '/productDetail': (_) => const ProductDetailScreen(
          productName: 'Ejemplo',
          productDescription: 'Descripción básica',
        ),
      },
    );
  }
}
