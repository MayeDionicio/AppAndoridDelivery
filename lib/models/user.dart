class User {
  final String? mensaje;
  final String? token;
  final String rol;

  final int? usuarioId;
  final String? nombre;
  final String? email;
  final String? telefono;
  final String? direccion;
  final String? fotoUrl;

  User({
    this.mensaje,
    this.token,
    required this.rol,
    this.usuarioId,
    this.nombre,
    this.email,
    this.telefono,
    this.direccion,
    this.fotoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      mensaje: json['mensaje'],
      token: json['token'],
      rol: json['rol'] ?? (json['esAdmin'] == true ? 'admin' : 'usuario'),
      usuarioId: json['usuarioId'] ?? json['id'],
      nombre: json['nombre'],
      email: json['email'],
      telefono: json['telefono'],
      direccion: json['direccion'],
      fotoUrl: json['fotoUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'mensaje': mensaje,
    'token': token,
    'rol': rol,
    'usuarioId': usuarioId,
    'nombre': nombre,
    'email': email,
    'telefono': telefono,
    'direccion': direccion,
    'fotoUrl': fotoUrl,
    'esAdmin': isAdmin,
  };

  bool get isAdmin => rol.toLowerCase() == 'admin';
  bool get isUser => rol.toLowerCase() == 'usuario';

  String get displayRol => isAdmin ? 'Administrador' : 'Usuario';
}
