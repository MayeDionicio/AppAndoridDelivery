import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  String nombre = '';
  String email = '';
  String direccion = '';
  String telefono = '';
  String? fotoUrl;

  bool isLoading = true;
  File? nuevaFoto;
  bool usarBiometria = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
    _cargarPreferenciaBiometrica();
  }

  void _cargarPreferenciaBiometrica() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      usarBiometria = prefs.getBool('usarBiometria') ?? false;
    });
  }

  void _actualizarPreferenciaBiometrica(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('usarBiometria', value);
    setState(() {
      usarBiometria = value;
    });

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            value ? Icons.fingerprint : Icons.lock_open,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value
                  ? 'Huella activada. No cierres sesión, solo la app, para usarla luego.'
                  : 'Huella desactivada. Ya no se solicitará.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: value ? Colors.green : Colors.red,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _cargarPerfil() async {
    try {
      final perfil = await ApiService.fetchUserProfile();
      setState(() {
        nombre = perfil.nombre ?? '';
        email = perfil.email ?? '';
        direccion = perfil.direccion ?? '';
        telefono = perfil.telefono ?? '';
        fotoUrl = perfil.fotoUrl;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar perfil: $e')),
      );
    }
  }

  void _actualizarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      await ApiService.actualizarPerfil(
        nombre: nombre,
        email: email,
        direccion: direccion,
        telefono: telefono,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar perfil: $e')),
      );
    }
  }

  void _seleccionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        nuevaFoto = File(picked.path);
      });
    }
  }

  void _subirFoto() async {
    if (nuevaFoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona una imagen')),
      );
      return;
    }

    try {
      final url = await ApiService.subirFotoPerfil(nuevaFoto!);
      setState(() {
        fotoUrl = url;
        nuevaFoto = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto actualizada exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir foto: $e')),
      );
    }
  }

  void _eliminarFoto() async {
    try {
      await ApiService.eliminarFotoPerfil();
      setState(() {
        fotoUrl = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto eliminada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar foto: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (fotoUrl != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(fotoUrl!),
              )
            else
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _seleccionarFoto,
                  icon: const Icon(Icons.photo),
                  label: const Text('Seleccionar'),
                ),
                ElevatedButton.icon(
                  onPressed: _subirFoto,
                  icon: const Icon(Icons.upload),
                  label: const Text('Subir'),
                ),
                ElevatedButton.icon(
                  onPressed: _eliminarFoto,
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
            const Divider(height: 30),

            // ✅ Switch con mensaje visual
            SwitchListTile(
              title: const Text('Usar huella digital para iniciar sesión'),
              value: usarBiometria,
              onChanged: _actualizarPreferenciaBiometrica,
            ),

            const SizedBox(height: 8),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: nombre,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
                    onSaved: (value) => nombre = value!,
                  ),
                  TextFormField(
                    initialValue: email,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
                    onSaved: (value) => email = value!,
                  ),
                  TextFormField(
                    initialValue: telefono,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    onSaved: (value) => telefono = value ?? '',
                  ),
                  TextFormField(
                    initialValue: direccion,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    onSaved: (value) => direccion = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _actualizarPerfil,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Cambios'),
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
