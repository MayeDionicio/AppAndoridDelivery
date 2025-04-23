import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _personalFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Datos personales (simulados)
  String name = 'John Doe';
  String email = 'johndoe@example.com';

  // Controladores para cambio de contraseña
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _savePersonalData() {
    if (_personalFormKey.currentState!.validate()) {
      _personalFormKey.currentState!.save();
      // Aquí enviarías la actualización al backend o la almacenarías localmente.
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos personales actualizados'))
      );
    }
  }

  void _changePassword() {
    if (_passwordFormKey.currentState!.validate()) {
      // Lógica para cambiar la contraseña, por ejemplo, validando la contraseña actual y actualizando la nueva.
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada'))
      );
      // Limpiar campos tras el cambio
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Datos Personales
            const Text(
              'Datos Personales',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Form(
              key: _personalFormKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      icon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese su nombre';
                      }
                      return null;
                    },
                    onSaved: (value) => name = value!,
                  ),
                  TextFormField(
                    initialValue: email,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      icon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese su correo electrónico';
                      }
                      // Aquí podrías agregar validación adicional del formato de email
                      return null;
                    },
                    onSaved: (value) => email = value!,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _savePersonalData,
                    child: const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Sección de Cambio de Contraseña
            const Text(
              'Cambiar Contraseña',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Form(
              key: _passwordFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña actual',
                      icon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese su contraseña actual';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                      icon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese la nueva contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _confirmNewPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar nueva contraseña',
                      icon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirme la nueva contraseña';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _changePassword,
                    child: const Text('Cambiar contraseña'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
