import 'package:flutter/material.dart';
import '../data/current_user.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'qr_scanner_page.dart';
import 'profile_screen.dart';
import 'product_list_screen.dart';
import 'view_orders_screen.dart';



class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  User? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarPerfil();
  }

  Future<void> cargarPerfil() async {
    try {
      final perfil = await ApiService.fetchUserProfile();
      setState(() {
        user = perfil;
        currentUser = perfil;
        loading = false;
      });
    } catch (e) {
      print('Error cargando perfil: $e');
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Administrador')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.nombre ?? 'Cargando...'),
              accountEmail: Text('Rol: ${user?.rol ?? ''}'),
              currentAccountPicture: (user?.fotoUrl != null &&
                  user!.fotoUrl!.isNotEmpty)
                  ? CircleAvatar(
                backgroundImage: NetworkImage(user!.fotoUrl!),
              )
                  : const CircleAvatar(
                child: Icon(Icons.person, size: 32),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Agregar Producto'),
              onTap: () => Navigator.pushNamed(context, '/productCreate'),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Lista de Productos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Ver Pedidos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewOrdersScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Entregar con QR'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScannerPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mi Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Gestionar Usuarios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/userList');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                await ApiService.logout();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sesión cerrada correctamente'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                    ),
                  );

                  await Future.delayed(const Duration(milliseconds: 1500));
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Bienvenido, ${user?.nombre ?? 'Administrador'}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rol: ${user?.rol ?? ''}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            const Text('Selecciona una opción del menú lateral'),
          ],
        ),
      ),
    );
  }
}
