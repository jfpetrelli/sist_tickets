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
}
