import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'edit_user_screen.dart'; // Asegúrate de importar esta pantalla

class UserListScreen extends StatefulWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<User> usuarios = [];
  List<User> filtrados = [];
  bool loading = true;
  String search = '';

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    try {
      final lista = await ApiService.fetchUsers();
      setState(() {
        usuarios = lista;
        filtrados = lista;
        loading = false;
      });
    } catch (e) {
      print('Error al cargar usuarios: $e');
      setState(() => loading = false);
    }
  }

  void _eliminarUsuario(int usuarioId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar usuario?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.eliminarUsuario(usuarioId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Usuario eliminado correctamente'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      cargarUsuarios();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar usuario: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildFoto(User u) {
    if (u.fotoUrl != null && u.fotoUrl!.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(u.fotoUrl!));
    } else {
      return const CircleAvatar(child: Icon(Icons.person));
    }
  }

  void _filtrarUsuarios(String value) {
    setState(() {
      search = value.toLowerCase();
      filtrados = usuarios.where((u) =>
      (u.nombre?.toLowerCase().contains(search) ?? false) ||
          (u.email?.toLowerCase().contains(search) ?? false)).toList();
    });
  }

  String obtenerRolLegible(User user) {
    return user.rol.toLowerCase() == 'true' || user.rol.toLowerCase() == 'admin' ? 'admin' : 'usuario';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Usuarios')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filtrarUsuarios,
            ),
          ),
          Expanded(
            child: filtrados.isEmpty
                ? const Center(child: Text('No hay usuarios registrados.'))
                : ListView.builder(
              itemCount: filtrados.length,
              itemBuilder: (context, index) {
                final u = filtrados[index];
                final esAdmin = u.rol.toLowerCase() == 'admin' || u.rol.toLowerCase() == 'true';
                final rolColor = esAdmin ? Colors.deepPurple : Colors.teal;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: _buildFoto(u),
                    title: Text(u.nombre ?? 'Sin nombre'),
                    subtitle: Row(
                      children: [
                        const Text('Rol: '),
                        Text(
                          obtenerRolLegible(u),
                          style: TextStyle(color: rolColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            final actualizado = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditUserScreen(user: u)),
                            );
                            if (actualizado == true) cargarUsuarios();
                          },
                        ),
                        if (u.usuarioId != null)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarUsuario(u.usuarioId!),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
