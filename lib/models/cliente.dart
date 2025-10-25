class Cliente {
  // Atributos del cliente
  int idCliente;
  String? razonSocial;
  String? domicilio;
  int? idLocalidad;
  String? nombreLocalidad;
  String? nombreProvincia;
  String? codigoPostal;
  String? telefono;
  String? telefonoMovil;
  String? email;
  String? cuit;
  int? idTipoCliente;
  bool activo; // Campo para indicar si el cliente está activo

  Cliente({
    required this.idCliente,
    required this.razonSocial,
    this.domicilio,
    this.idLocalidad,
    this.nombreLocalidad,
    this.nombreProvincia,
    this.codigoPostal,
    this.telefono,
    this.telefonoMovil,
    this.email,
    this.cuit,
    this.idTipoCliente,
    this.activo = true, // Por defecto activo
  });

  // Método para crear un objeto Cliente a partir de un Map
  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      idCliente: json['id_cliente'] as int,
      razonSocial: json['razonsocial'] as String?,
      domicilio: json['domicilio'] as String?,
      idLocalidad: json['id_localidad'] as int?,
      nombreLocalidad: json['nombre_localidad'] as String?,
      nombreProvincia: json['nombre_provincia'] as String?,
      codigoPostal: json['codigopostal'] as String?,
      telefono: json['telefono'] as String?,
      telefonoMovil: json['telefonomovil'] as String?,
      email: json['email'] as String?,
      cuit: json['cuit'] as String?,
      idTipoCliente: json['id_tipocliente'] as int?,
      activo: json['activo'] == 1 || json['activo'] == true,
    );
  }

  // Método para convertir un objeto Cliente a un Map
  Map<String, dynamic> toJson() {
    return {
      'id_cliente': idCliente,
      'razonsocial': razonSocial,
      'domicilio': domicilio,
      'id_localidad': idLocalidad,
      'nombre_localidad': nombreLocalidad,
      'nombre_provincia': nombreProvincia,
      'codigopostal': codigoPostal,
      'telefono': telefono,
      'telefonomovil': telefonoMovil,
      'email': email,
      'cuit': cuit,
      'id_tipocliente': idTipoCliente,
      'activo': activo ? 1 : 0,
    };
  }
}
