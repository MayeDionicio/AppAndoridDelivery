import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/current_user.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'product_list_screen.dart';
import 'qr_scanner_page.dart';
import 'profile_screen.dart';
import 'view_orders_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  User? user;
  bool loading = true;

  int totalPedidos = 0;
  int totalEntregados = 0;
  int totalPendientes = 0;
  double totalIngresos = 0;

  @override
  void initState() {
    super.initState();
    cargarPerfil();
  }

  Future<void> cargarPerfil() async {
    try {
      final perfil = await ApiService.fetchUserProfile();
      final orders = await ApiService.getOrders();

      totalPedidos = orders.length;
      totalEntregados = orders.where((o) => o['estado'] == 'Entregado').length;
      totalPendientes = orders.where((o) => o['estado'] == 'Pendiente').length;
      totalIngresos = orders
          .where((o) => o['estado'] == 'Entregado')
          .fold(0.0, (acc, o) => acc + (o['total'] ?? 0));

      setState(() {
        user = perfil;
        currentUser = perfil;
        loading = false;
      });
    } catch (e) {
      print('Error cargando perfil: $e');
      setState(() => loading = false);
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
              currentAccountPicture: (user?.fotoUrl != null && user!.fotoUrl!.isNotEmpty)
                  ? CircleAvatar(backgroundImage: NetworkImage(user!.fotoUrl!))
                  : const CircleAvatar(child: Icon(Icons.person, size: 32)),
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
                  MaterialPageRoute(builder: (_) => const ProductListScreen()),
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
                  MaterialPageRoute(builder: (_) => const ViewOrdersScreen()),
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
                  MaterialPageRoute(builder: (_) => const QRScannerPage()),
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
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
          : Container(
        color: const Color(0xFFF9F4FF), // fondo suave
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¡Bienvenido, ${user?.nombre ?? 'Administrador'}!',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Rol: ${user?.rol}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),

              /// Tarjetas resumen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard('Pedidos', totalPedidos.toString(), Colors.deepPurple),
                  _buildInfoCard('Entregados', totalEntregados.toString(), Colors.green),
                  _buildInfoCard('Pendientes', totalPendientes.toString(), Colors.amber),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard('Ingresos', 'Q${totalIngresos.toStringAsFixed(2)}', Colors.teal),

              const SizedBox(height: 32),
              const Center(
                child: Text('Estado de Pedidos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              _buildDonutChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.withOpacity(0.1),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart() {
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 40,
          sectionsSpace: 4,
          sections: [
            PieChartSectionData(
              value: totalEntregados.toDouble(),
              title: 'Entregados',
              color: Colors.green,
              radius: 60,
              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              value: totalPendientes.toDouble(),
              title: 'Pendientes',
              color: Colors.amber,
              radius: 60,
              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        swapAnimationDuration: const Duration(milliseconds: 500),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }
}
