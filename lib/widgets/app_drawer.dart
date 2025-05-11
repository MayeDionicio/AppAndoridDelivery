import 'package:flutter/material.dart';
import '../data/current_user.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (user != null)
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              accountName: Text(user.nombre ?? 'Usuario'),
              accountEmail: Text(user.email ?? 'correo@desconocido.com'),
              currentAccountPicture: (user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
                  ? CircleAvatar(
                backgroundImage: NetworkImage(user.fotoUrl!),
              )
                  : const CircleAvatar(
                child: Icon(Icons.person, size: 32),
              ),
            )
          else
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
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
            leading: const Icon(Icons.map),
            title: const Text('Seguimiento de Pedido'),
            onTap: () => Navigator.pushNamed(context, '/tracking'),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Cerrar sesión'),
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
    );
  }
}
