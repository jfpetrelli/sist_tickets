class Cliente {
  // Atributos del cliente
  int idCliente;
  String? razonSocial;
  String? domicilio;
  int? idLocalidad;
  String? codigoPostal;
  String? telefono;
  String? telefonoMovil;
  String? email;
  String? cuit;
  int? idTipoCliente;

  Cliente({
    required this.idCliente,
    required this.razonSocial,
    this.domicilio,
    this.idLocalidad,
    this.codigoPostal,
    this.telefono,
    this.telefonoMovil,
    this.email,
    this.cuit,
    this.idTipoCliente,
  });

  // Método para crear un objeto Cliente a partir de un Map
  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      idCliente: json['id_cliente'] as int,
      razonSocial: json['razonsocial'] as String?,
      domicilio: json['domicilio'] as String?,
      idLocalidad: json['id_localidad'] as int?,
      codigoPostal: json['codigopostal'] as String?,
      telefono: json['telefono'] as String?,
      telefonoMovil: json['telefonomovil'] as String?,
      email: json['email'] as String?,
      cuit: json['cuit'] as String?,
      idTipoCliente: json['id_tipocliente'] as int?,
    );
  }

  // Método para convertir un objeto Cliente a un Map
  Map<String, dynamic> toJson() {
    return {
      'id_cliente': idCliente,
      'razonsocial': razonSocial,
      'domicilio': domicilio,
      'id_localidad': idLocalidad,
      'codigopostal': codigoPostal,
      'telefono': telefono,
      'telefonomovil': telefonoMovil,
      'email': email,
      'cuit': cuit,
      'id_tipocliente': idTipoCliente,
    };
  }
}
