class Usuario {
  final int idPersonal;
  final int idSucursal;
  final int idTipo;
  final String nombre;
  final String? telefonoMovil;
  final String? email;
  final DateTime? fechaIngreso;
  final DateTime? fechaEgreso;
  final String? profilePhotoUrl;

  Usuario({
    required this.idPersonal,
    required this.idSucursal,
    required this.idTipo,
    required this.nombre,
    this.telefonoMovil,
    this.email,
    this.fechaIngreso,
    this.fechaEgreso,
    this.profilePhotoUrl,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idPersonal: json['id_personal'],
      idSucursal: json['id_sucursal'],
      idTipo: json['id_tipo'],
      nombre: json['nombre'],
      telefonoMovil: json['telefono_movil'],
      email: json['email'],
      fechaIngreso: json['fecha_ingreso'] != null
          ? DateTime.parse(json['fecha_ingreso'])
          : null,
      fechaEgreso: json['fecha_egreso'] != null
          ? DateTime.parse(json['fecha_egreso'])
          : null,
      profilePhotoUrl: json['profile_photo_url'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id_sucursal': idSucursal,
      'id_tipo': idTipo,
      'nombre': nombre,
      'telefono_movil': telefonoMovil,
      'email': email,
      // Convertir DateTime a String ISO 8601 si no es nulo
      // El backend (Python) entenderá este formato
      'fecha_ingreso': fechaIngreso?.toIso8601String(),
      'fecha_egreso': fechaEgreso?.toIso8601String(),
      'profile_photo_url': profilePhotoUrl,
      // No incluimos 'id_personal' porque se usa en la URL del endpoint (ej: /usuarios/123)
    };
  }
}
