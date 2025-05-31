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

    if (!usarBiometria) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      List<BiometricType> tiposDisponibles = await auth.getAvailableBiometrics();

      if (!canCheckBiometrics || tiposDisponibles.isEmpty) {
        Navigator.pushReplacementNamed(context, '/login');
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
          await Future.delayed(const Duration(milliseconds: 800));
          Navigator.pushReplacementNamed(
            context,
            user.rol.toLowerCase() == 'admin' ? '/admin' : '/catalog',
          );
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('⚠️ Error durante autenticación biométrica: $e');
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
