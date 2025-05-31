import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/current_user.dart';
import '../services/api_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late Future<void> _loadUserFuture;

  @override
  void initState() {
    super.initState();
    _loadUserFuture = ApiService.loadUserFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder(
        future: _loadUserFuture,
        builder: (context, snapshot) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              if (currentUser != null)
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.orange),
                  accountName: Text(currentUser!.nombre ?? 'Usuario'),
                  accountEmail: Text(currentUser!.email ?? 'correo@desconocido.com'),
                  currentAccountPicture: (currentUser!.fotoUrl != null && currentUser!.fotoUrl!.isNotEmpty)
                      ? CircleAvatar(backgroundImage: NetworkImage(currentUser!.fotoUrl!))
                      : const CircleAvatar(child: Icon(Icons.person, size: 32)),
                )
              else
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.orange),
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: const Text('Catálogo'),
                onTap: () => Navigator.pushNamed(context, '/catalog'),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Mi Perfil'),
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Historial de Pedidos'),
                onTap: () => Navigator.pushNamed(context, '/orderHistory'),
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Cerrar sesión'),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('token');
                  currentUser = null;
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
