import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../data/current_user.dart';

class BiometricLoginScreen extends StatefulWidget {
  const BiometricLoginScreen({Key? key}) : super(key: key);

  @override
  _BiometricLoginScreenState createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends State<BiometricLoginScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _validarPreferenciaYBiometria();
  }

  Future<void> _validarPreferenciaYBiometria() async {
    final prefs = await SharedPreferences.getInstance();
    final usarBiometria = prefs.getBool('usarBiometria') ?? false;

    print('🔒 Preferencia biométrica activada: $usarBiometria');

    if (!usarBiometria) {
      await _redirigirSinBiometria();
      return;
    }

    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      List<BiometricType> tiposDisponibles = await auth.getAvailableBiometrics();

      print('🧪 ¿Puede usar biometría?: $canCheckBiometrics');
      print('🧪 Tipos disponibles: $tiposDisponibles');

      if (!canCheckBiometrics || tiposDisponibles.isEmpty) {
        print('❌ No hay biometría disponible o configurada.');
        await _redirigirSinBiometria();
        return;
      }

      setState(() => _isAuthenticating = true);

      bool isAuthenticated = await auth.authenticate(
        localizedReason: 'Autenticarse con huella o rostro',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      setState(() => _isAuthenticating = false);

      if (isAuthenticated) {
        await ApiService.loadUserFromStorage();
        final user = currentUser;

        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.fingerprint, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text('¡Bienvenido de nuevo, ${user.nombre ?? 'Usuario'}!')),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 1500));

          if (user.rol.toLowerCase() == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacementNamed(context, '/catalog');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        print('🚫 Autenticación cancelada o fallida');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('⚠️ Error durante autenticación biométrica: $e');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _redirigirSinBiometria() async {
    await ApiService.loadUserFromStorage();
    final user = currentUser;

    if (user != null) {
      if (user.rol.toLowerCase() == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/catalog');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
