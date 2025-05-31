import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../data/current_user.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class ApiService {
  static const String _baseUrl = 'https://deliverylp.shop/api';

  // -------------------- AUTENTICACIÓN --------------------


  static Future<User> login(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/Auth/login');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'contrasena': password}),
    );

    print('LOGIN ${resp.statusCode}: ${resp.body}');

    if (resp.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(resp.body);

      // ✅ Decodificar el token JWT para extraer usuarioId
      final token = json['token'];
      final payload = JwtDecoder.decode(token);
      print('🎯 Payload JWT: $payload');

      final usuarioId = int.tryParse(payload['usuarioId'] ?? payload['id'] ?? '0') ?? 0;

      // ✅ Inyectar usuarioId en el JSON antes de crear el User
      final usuario = User.fromJson({
        ...json,
        'usuarioId': usuarioId,
      });

      currentUser = usuario;

      // ✅ Guardar token localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      print('🧠 Token guardado: $token');
      return usuario;
    } else {
      final error = jsonDecode(resp.body);
      throw Exception(error['message'] ?? 'Error al autenticar');
    }
  }


  static Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      try {
        final uri = Uri.parse('$_baseUrl/Usuarios/perfil');
        final resp = await http.get(
          uri,
          headers: {'Authorization': 'Bearer $token'},
        );

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          currentUser = User.fromJson({...data, 'token': token});
          print('🔄 Usuario restaurado: ${currentUser?.nombre}');
        }
      } catch (e) {
        print('❌ Error al restaurar sesión: $e');
      }
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usarBiometria');
    currentUser = null;
    print('🔓 Sesión cerrada y datos limpiados');
  }

  static Future<void> register({
    required String nombre,
    required String email,
    required String contrasena,
    required String direccion,
    required String telefono,
    required String captchaToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/Auth/registrar');
    final body = jsonEncode({
      'nombre': nombre,
      'email': email,
      'contrasena': contrasena,
      'direccion': direccion,
      'telefono': telefono,
      'esAdmin': false,
      'captchaToken': captchaToken,
    });

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('REGISTER ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode != 200) {
      final err = jsonDecode(resp.body);
      throw Exception(err['message'] ?? 'Error al registrar');
    }
  }

  static Future<List<Product>> fetchProducts() async {
    final user = currentUser;
    if (user == null || user.token == null) throw Exception('Usuario no autenticado');

    final uri = Uri.parse('$_baseUrl/Productos');
    final resp = await http.get(uri, headers: {
      'Authorization': 'Bearer ${user.token!}',
    });

    print('PRODUCTOS ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(resp.body);
      return jsonList.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar los productos');
    }
  }

  static Future<Product> getProductoById(int id) async {
    final user = currentUser;
    if (user == null || user.token == null) throw Exception('Usuario no autenticado');

    final uri = Uri.parse('$_baseUrl/Productos/$id');
    final resp = await http.get(uri, headers: {
      'Authorization': 'Bearer ${user.token!}',
    });

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return Product.fromJson(data);
    } else {
      throw Exception('Error al obtener el producto');
    }
  }

  static Future<void> createProductWithImage({
    required String nombre,
    required String descripcion,
    required double precio,
    required int stock,
    required File imagenFile,
  }) async {
    final user = currentUser;
    if (user == null || user.token == null || user.token!.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    final uri = Uri.parse('$_baseUrl/Productos');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${user.token!}'
      ..fields['Nombre'] = nombre
      ..fields['Descripcion'] = descripcion
      ..fields['Precio'] = precio.toString()
      ..fields['Stock'] = stock.toString()
      ..files.add(await http.MultipartFile.fromPath(
        'Imagen',
        imagenFile.path,
        contentType: MediaType('image', imagenFile.path.split('.').last),
      ));

    // Debug opcional
    request.fields.forEach((k, v) => print('🟦 $k: $v'));

    final streamedResp = await request.send();
    final respStr = await streamedResp.stream.bytesToString();
    print('CREAR PRODUCTO ${streamedResp.statusCode}: $respStr');

    if (streamedResp.statusCode != 200) {
      throw Exception('Error al crear producto');
    }
  }

  static Future<void> actualizarProducto({
    required int id,
    required String nombre,
    required String descripcion,
    required double precio,
    required int stock,
  }) async {
    final user = currentUser;
    if (user == null || user.token == null) throw Exception('Usuario no autenticado');

    final uri = Uri.parse('$_baseUrl/Productos/$id');
    final body = jsonEncode({
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
    });

    final resp = await http.put(uri, headers: {
      'Authorization': 'Bearer ${user.token!}',
      'Content-Type': 'application/json',
    }, body: body);

    print('ACTUALIZAR ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('Error al actualizar producto');
    }
  }

  static Future<void> actualizarProductoConImagen({
    required int id,
    required String nombre,
    required String descripcion,
    required double precio,
    required int stock,
    File? imagen,
    String? imagenUrlAnterior,
  }) async {
    final user = currentUser;
    if (user == null || user.token == null || user.token!.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    final uri = Uri.parse('$_baseUrl/Productos/$id');
    final request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer ${user.token!}'
      ..fields['Id'] = id.toString()
      ..fields['Nombre'] = nombre
      ..fields['Descripcion'] = descripcion
      ..fields['Precio'] = precio.toString()
      ..fields['Stock'] = stock.toString();

    if (imagenUrlAnterior != null) {
      request.fields['ImagenUrlAnterior'] = imagenUrlAnterior;
    }

    if (imagen != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'Imagen',
        imagen.path,
        contentType: MediaType('image', imagen.path.split('.').last),
      ));
    }

    // Debug opcional
    request.fields.forEach((k, v) => print('🟦 $k: $v'));

    final streamedResp = await request.send();
    final respStr = await streamedResp.stream.bytesToString();
    print('ACTUALIZAR CON IMAGEN ${streamedResp.statusCode}: $respStr');

    if (streamedResp.statusCode != 200) {
      throw Exception('Error al actualizar producto');
    }
  }


  static Future<void> eliminarProducto(int id) async {
    final user = currentUser;
    if (user == null || user.token == null) throw Exception('Usuario no autenticado');

    final uri = Uri.parse('$_baseUrl/Productos/$id');
    final resp = await http.delete(uri, headers: {
      'Authorization': 'Bearer ${user.token!}',
    });

    print('ELIMINAR ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('Error al eliminar producto');
    }
  }
  // -------------------- VALORACIONES --------------------

  static Future<void> crearValoracion({
    required int productoId,
    required int usuarioId,
    required double calificacion,
    required String comentario,
  }) async {
    final user = currentUser;
    if (user == null || user.token == null || user.token!.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    final uri = Uri.parse('$_baseUrl/Valoraciones');
    final body = jsonEncode({
      'productoId': productoId,
      'usuarioId': usuarioId,
      'valor': calificacion, // CAMBIADO de "calificacion" a "valor"
      'comentario': comentario,
    });

    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${user.token!}',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('VALORAR ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode != 200) {
      final error = jsonDecode(resp.body);
      throw Exception(error['message'] ?? 'Error al valorar producto');
    }
  }


  static Future<double> fetchCalificacionPromedio(int productoId) async {
    final uri = Uri.parse('$_baseUrl/Valoraciones/producto/$productoId/promedio');
    final resp = await http.get(uri);

    print('CALIFICACION ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data['promedio'] as num).toDouble();
    } else {
      throw Exception('Error al obtener calificación');
    }
  }

  static Future<void> eliminarValoracion(int valoracionId) async {
    final user = currentUser;
    if (user == null || user.token == null || user.token!.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    final uri = Uri.parse('$_baseUrl/Valoraciones/$valoracionId');
    final resp = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer ${user.token!}'},
    );

    print('ELIMINAR VALORACION ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('Error al eliminar la valoración');
    }
  }

  // -------------------- PERFIL --------------------

  static Future<User> fetchUserProfile() async {
    final user = currentUser;
    if (user == null || user.token == null || user.token!.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    final uri = Uri.parse('$_baseUrl/Usuarios/perfil');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${user.token!}'},
    );

    print('PERFIL ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return User.fromJson({...data, 'token': user.token});
    } else {
      throw Exception('Error al obtener el perfil');
    }
  }

  static Future<void> actualizarPerfil({
    required String nombre,
    required String email,
    required String telefono,
    required String direccion,
  }) async {
    final user = currentUser;
    if (user == null || user.token == null || user.token!.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    final uri = Uri.parse('$_baseUrl/Usuarios/perfil/editar');
    final resp = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer ${user.token!}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'direccion': direccion,
      }),
    );

    print('ACTUALIZAR PERFIL ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('No se pudo actualizar el perfil');
    }
  }

  static Future<String> subirFotoPerfil(File imagen) async {
    final user = currentUser;
    if (user == null || user.token == null || user.token!.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    final uri = Uri.parse('$_baseUrl/Usuarios/perfil/foto');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${user.token!}'
      ..files.add(await http.MultipartFile.fromPath(
        'archivo',
        imagen.path,
        contentType: MediaType('image', imagen.path.split('.').last),
      ));

    final streamedResp = await request.send();
    final respStr = await streamedResp.stream.bytesToString();
    print('SUBIR FOTO ${streamedResp.statusCode}: $respStr');

    if (streamedResp.statusCode != 200) {
      throw Exception('No se pudo subir la foto');
    }

    final data = jsonDecode(respStr);
    return data['fotoUrl'];
  }

  static Future<void> eliminarFotoPerfil() async {
    final user = currentUser;
    if (user == null || user.token == null || user.token!.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    final uri = Uri.parse('$_baseUrl/Usuarios/perfil/foto');
    final resp = await http.delete(uri, headers: {
      'Authorization': 'Bearer ${user.token!}',
    });

    print('ELIMINAR FOTO ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('No se pudo eliminar la foto de perfil');
    }
  }
  //-------------------- Usuarios --------------------------
  static Future<List<User>> fetchUsers() async {
    final user = currentUser;
    if (user == null || user.token == null) throw Exception('Usuario no autenticado');

    final uri = Uri.parse('https://deliverylp.shop/api/Usuarios/listar');
    final resp = await http.get(uri, headers: {
      'Authorization': 'Bearer ${user.token!}',
    });

    if (resp.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(resp.body);
      return jsonList.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener usuarios');
    }
  }

  static Future<void> actualizarUsuario({
    required int id,
    required String nombre,
    required String email,
    required String telefono,
    required String direccion,
    required bool esAdmin, // <-- cambiar a bool
  }) async {
    final user = currentUser;
    if (user == null || user.token == null || user.token!.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    final uri = Uri.parse('$_baseUrl/Usuarios/actualizar/$id');
    final body = jsonEncode({
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'esAdmin': esAdmin, // <-- clave correcta
    });

    final resp = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer ${user.token!}',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('ACTUALIZAR USUARIO ${resp.statusCode}: ${resp.body}');

    if (resp.statusCode != 200) {
      final error = jsonDecode(resp.body);
      throw Exception(error['message'] ?? 'Error al actualizar usuario');
    }
  }



  static Future<void> eliminarUsuario(int id) async {
    final user = currentUser;
    if (user == null || user.token == null) throw Exception('Usuario no autenticado');

    final uri = Uri.parse('$_baseUrl/Usuarios/$id');
    final resp = await http.delete(uri, headers: {
      'Authorization': 'Bearer ${user.token!}',
    });

    if (resp.statusCode != 200) {
      throw Exception('No se pudo eliminar el usuario');
    }
  }


  // -------------------- ENTREGA CON QR --------------------

  static Future<String> entregarPedidoConQR(String qrCode) async {
    final user = currentUser;
    if (user == null || user.token == null || user.token!.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    final uri = Uri.parse('$_baseUrl/Pedidos/entregar-qr');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${user.token!}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(qrCode),
    );

    print('ENTREGAR QR ${response.statusCode}: ${response.body}');
    final data = jsonDecode(response.body);
    final mensaje = data['mensaje'] ?? 'Respuesta sin mensaje';

    if (response.statusCode == 200) {
      return mensaje;
    } else {
      throw Exception(mensaje);
    }
  }


// -------------------- PEDIDOS --------------------

  static Future<List<Order>> fetchOrders() async {
    final user = currentUser;
    if (user == null || user.token == null) throw Exception('Usuario no autenticado');

    final uri = Uri.parse('$_baseUrl/Pedidos');
    final resp = await http.get(uri, headers: {
      'Authorization': 'Bearer ${user.token!}',
    });

    print('PEDIDOS ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(resp.body);
      return jsonList.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener pedidos');
    }
  }

  static Future<void> entregarPedido(int id) async {
    final user = currentUser;
    if (user == null || user.token == null) throw Exception('Usuario no autenticado');

    final uri = Uri.parse('$_baseUrl/Pedidos/$id/entregar');
    final resp = await http.put(uri, headers: {
      'Authorization': 'Bearer ${user.token!}',
    });

    print('ENTREGAR PEDIDO ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('No se pudo entregar el pedido');
    }
  }

  static Future<void> eliminarPedido(int id) async {
    final user = currentUser;
    if (user == null || user.token == null) throw Exception('Usuario no autenticado');

    final uri = Uri.parse('$_baseUrl/Pedidos/$id');
    final resp = await http.delete(uri, headers: {
      'Authorization': 'Bearer ${user.token!}',
    });

    print('ELIMINAR PEDIDO ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('No se pudo eliminar el pedido');
    }
  }

  static Future<http.Response> createOrder(Map<String, dynamic> orderData) async {
    final user = currentUser;
    if (user == null || user.token == null || user.token!.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    final uri = Uri.parse('$_baseUrl/Pedidos/crear');
    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${user.token!}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(orderData),
    );

    print('CREAR PEDIDO ${resp.statusCode}: ${resp.body}');
    return resp;
  }

  static String extractErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      } else if (data is Map && data.containsKey('title')) {
        return data['title'];
      }
      return 'Error desconocido';
    } catch (_) {
      return responseBody;
    }
  }
  static Future<Map<String, dynamic>> createPaymentMethodAndReturnId({
    required int usuarioId,
    required String tipo,
  }) async {
    final uri = Uri.parse('$_baseUrl/MetodosPago');

    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${currentUser?.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'usuarioId': usuarioId,
        'tipo': tipo,
        'activo': true,
        'detalles': '',
      }),
    );

    print('CREATE METODO ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body);
    } else {
      throw Exception('Error al registrar el método de pago');
    }
  }
  static Future<List<Map<String, dynamic>>> getOrders() async {
    final user = currentUser;
    if (user == null || user.token == null) throw Exception('Usuario no autenticado');

    final uri = Uri.parse('$_baseUrl/Pedidos');
    final resp = await http.get(uri, headers: {
      'Authorization': 'Bearer ${user.token!}',
    });

    print('GET ORDERS JSON ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(resp.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al obtener pedidos');
    }
  }


}
